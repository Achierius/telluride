const std = @import("std");
const mem = std.mem;
usingnamespace @import("alloc.zig");
const token_module = @import("token.zig");
const Token = token_module.Token;
const TokenType = token_module.TokenType;
const TokenValue = token_module.TokenValue;
const TokenValueType = token_module.TokenValueType;

fn isDigit(c : u8, base : usize) bool {
    std.debug.assert((base == 2) or (base == 8) or
                        (base == 10) or (base == 16));
    return switch (c) {
        '0', '1' => true,
        '2', '3', '4', '5', '6', '7' => (base >= 8),
        '8', '9' => (base >= 10),
        'A', 'B', 'C', 'D', 'E', 'F', 'a', 'b', 'c', 'd', 'e', 'f' => (base >= 16),
        else => false,
    };
}

fn isAlpha(c : u8) bool {
    return switch (c) {
        'a'...'z' => true,
        'A'...'Z' => true,
        else      => false,
    };
}

fn isIdBodyChar(c : u8) bool {
    return isAlpha(c)
        or isDigit(c, 10)
        or (c == '_');
}

pub const Scanner = struct {
    const Self = @This();

    text : []const u8,
    head : usize,
    line : usize,

    fn makeToken(self : *Self, token_type : TokenType) Token {
        return Token {
            .token_type = token_type,
            .location = self.text[0..self.head],
            .line = self.line,
        };
    }

    fn makeValueToken(self : *Self, token_type : TokenType, value : TokenValue) Token {
        return Token {
            .token_type = token_type,
            .location = self.text[0..self.head],
            .line = self.line,
            .value = value,
        };
    }

    fn makeErrorToken(self : *Self, message : []const u8) Token {
        return Token {
            .token_type = .LEX_ERROR,
            .location = message,
            .line = self.line,
        };
    }

    fn endFound(self : Self) bool {
        return self.head >= self.text.len;
    }


    fn peek(self : *Self) u8 {
        return self.text[self.head];
    }

    fn match(self : *Self, c : u8) bool {
        if (self.endFound()) { return false; }

        if (self.peek() == c) {
            self.head += 1;
            return true;
        } else {
            // Don't advance, we need to parse this token on its own on the next step
            return false;
        }
    }

    fn advance(self : *Self) u8 {
        const c = self.peek();
        self.head += 1;
        return c;
    }

    // Does NOT allow us to roll back the start of our current scan-element,
    // only to walk back WITHIN it; originally just used to avoid horrible
    // spaghetti code in lexInt with regards to base-10 integer literals
    fn backtrack(self : *Self, n : usize) void {
        self.head = if (self.head >= n) self.head - n else 0;
    }

    fn consumeWhitespace(self : *Self) void {
        while (true) {
            if (self.endFound()) {
                return;
            }

            const c = self.peek();
            switch (c) {
                ' ', '\r', '\t' => {
                    _ = self.advance();
                },
                '\n' => {
                    self.line += 1;
                    _ = self.advance();
                },
                '%' => {
                    while (!self.endFound() and self.peek() != '\n') {
                        _ = self.advance();
                    }
                },
                else => { return; },
            }
        }
    }

    fn lexString(self : *Self) Token {
        while ((self.peek() != '"') and (!self.endFound())) {
            if (self.peek() == '\n') {
                self.line += 1;
            } else {
                _ = self.advance();
            }
        }

        if (self.endFound()) {
            return self.makeErrorToken("Unterminated string.");
        }

        // Make sure to not include opening/closing '"'
        const str_slice = self.text[1..self.head];
        var str_mem = allocator.alloc(u8, str_slice.len) catch unreachable; // TODO meh
        
        // The memory is owned by the Token, and should be freed
        // by the parser when it stores the associated string elsewhere
        mem.copy(u8, str_mem, str_slice);

        _ = self.advance(); // consume closing quote
        return self.makeValueToken(.STRING, TokenValue{ .STRING = str_mem });
    }

    fn lexIdentifier(self : *Self) Token {
        while (isIdBodyChar(self.peek())) {
            _ = self.advance();
        }

        // Default is ID, so if we fail to match any keyword we fall back to it
        var id_type : TokenType = .ID;
        checkKeyword: {
            const Payload = struct {
                bgn : usize,
                match : []const u8,
                result : TokenType,
            };
            const target : Payload = switch (self.text[0]) {
                'o' => Payload {.bgn = 1, .match = "r", .result = .OR},
                'i' => Payload {.bgn = 1, .match = "f", .result = .IF},
                'a' => Payload {.bgn = 1, .match = "nd", .result = .AND},
                'l' => Payload {.bgn = 1, .match = "et", .result = .LET},
                'f' => Payload {.bgn = 1, .match = "alse", .result = .FALSE},
                'c' => Payload {.bgn = 1, .match = "ase", .result = .CASE},
                'r' => Payload {.bgn = 1, .match = "eturn", .result = .RETURN},
                'u' => Payload {.bgn = 1, .match = "nion", .result = .UNION},
                // TODO right now this probably overruns end of file if the file ends in a first-matching identifier (e.g. "el")
                's' => switch (self.text[1]) {
                    'w' => Payload {.bgn = 2, .match = "itch", .result = .SWITCH},
                    't' => Payload {.bgn = 2, .match = "ruct", .result = .STRUCT},
                    else => { break :checkKeyword; },
                },
                't' => switch (self.text[1]) {
                    'r' => Payload {.bgn = 2, .match = "ue", .result = .TRUE},
                    'h' => Payload {.bgn = 2, .match = "en", .result = .THEN},
                    else => { break :checkKeyword; },
                },
                'e' => switch (self.text[1]) {
                    'x' => Payload {.bgn = 2, .match = "xecute", .result = .EXECUTE},
                    'l' => switch (self.text[2]) {
                        'i' => Payload {.bgn = 3, .match = "f", .result = .ELIF},
                        's' => Payload {.bgn = 3, .match = "e", .result = .ELSE},
                        else => { break :checkKeyword; },
                    },
                    else => { break :checkKeyword; },
                },
                else => { break :checkKeyword; }, // Default to generic identifier
            };
            if (mem.eql(u8, self.text[target.bgn..self.head], target.match)) {
                id_type = target.result;
            }
        }
        
        return self.makeToken(id_type);
    }

    fn lexInt(self : *Self) Token {
        var base : usize = 0;
        var c = self.text[0]; // We assume it was consumed by an outer call to 'self.advance()'
        if (c == '0') {
            base = switch(self.peek()) {
                'x' => blk: {
                    _ = self.advance();
                    c = self.peek();
                    break :blk 16;
                },
                'b' => blk: {
                    _ = self.advance();
                    c = self.peek();
                    break :blk 2;
                },
                else => 8,
            };
        } else {
            base = 10;
            self.backtrack(1);
        }

        var total : usize = 0;
        digitizer: while(true) : ({ c = self.peek(); }) {
            // TODO make the error handling here nicer;
            // right now e.g. 0b101120101 will be lexed as '0b1011' and '20101',
            // rather than throwing an error on the '2'
            if (isDigit(c, base)) {
                var digit = switch(c) {
                    '0'...'9' => (c - '0'),
                    'A'...'F' => ((c - 'A') + 10),
                    'a'...'f' => ((c - 'a') + 10),
                    else => break :digitizer,
                };
                total *= base;
                total += digit;
                _ = self.advance();
            } else {
                break :digitizer;
            }
        }
        return self.makeValueToken(.NUMBER, TokenValue{ .INT = total });
    }

    pub fn scanToken(self : *Self) Token {
        self.consumeWhitespace();

        self.text = self.text[self.head..];
        self.head = 0;

        if (self.endFound()) {
            return self.makeToken(.EOF);
        }

        const c = self.advance();

        return switch(c) {
            '(' => self.makeToken(.L_PAREN),
            ')' => self.makeToken(.R_PAREN),
            '{' => self.makeToken(.L_BRACE),
            '}' => self.makeToken(.R_BRACE),
            '[' => self.makeToken(.L_S_BRACKET),
            ']' => self.makeToken(.R_S_BRACKET),
            ',' => self.makeToken(.COMMA),
            '.' => self.makeToken(.DOT),
            ':' => self.makeToken(.COLON),
            ';' => self.makeToken(.SEMICOLON),
            '+' => self.makeToken(.PLUS),
            '*' => self.makeToken(.STAR),
            '^' => self.makeToken(.CARET),
            '?' => self.makeToken(.QUERY),
            '~' => self.makeToken(.TILDE),
            '_' => self.makeToken(.UNDERSCORE),
            '-' => self.makeToken(if (self.match('>')) .RARROW_SINGLE
                                  else                 .MINUS),
            '/' => self.makeToken(if (self.match('/')) .SLASH_SLASH
                                  else                 .SLASH),
            '&' => self.makeToken(if (self.match('&')) .AMP_AMP
                                  else                 .AMP),
            '|' => self.makeToken(if (self.match('|')) .PIPE_PIPE
                                  else                 .PIPE),
            '!' => self.makeToken(if (self.match('=')) .BANG_EQ
                                  else                 .BANG),
            '=' => self.makeToken(if (self.match('='))       .EQ_EQ
                                  else (if (self.match('>')) TokenType.RARROW_DOUBLE
                                        else                 TokenType.EQ)),
            '<' => self.makeToken(if (self.match('='))       .LT_EQ
                                  else (if (self.match('<')) TokenType.SLL // Can't use enum literal here bc Zig bug
                                        else                 TokenType.LT)),
            '>' => blk: {
                if (self.match('=')) {
                    break :blk self.makeToken(.GT_EQ);
                } else if (self.match('>')) {
                    if (self.match('>')) {
                        break :blk self.makeToken(.SRA);
                    } else {
                        break :blk self.makeToken(.SRL);
                    }
                } else {
                    break :blk self.makeToken(.GT);
                }
            },
            '"' => self.lexString(),
            'a'...'z', 'A'...'Z' => self.lexIdentifier(),
            '0'...'9' => self.lexInt(),
            else => self.makeErrorToken("Unexpected character."),
        };
    }
};

pub fn initScanner(source : []const u8) Scanner {
    return Scanner {
        .text = source,
        .head = 0,
        .line = 1,
    };
}