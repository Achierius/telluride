const std = @import("std");

pub const TokenType = enum {
    // Tokens requiring a lookahead of 1
    L_PAREN,       // (
    R_PAREN,       // )
    L_BRACE,       // {
    R_BRACE,       // }
 // L_A_BRACKET,   // <
 // R_A_BRACKET,   // >
    L_S_BRACKET,   // [
    R_S_BRACKET,   // ]
    COMMA,         // ,
    DOT,           // .
    COLON,         // :
    SEMICOLON,     // ;
    PLUS,          // +
    STAR,          // *
    CARET,         // ^
    // Tokens requiring a lookahead of 2
    MINUS,         // -
    RARROW,        // ->
    SLASH,         // /
    SLASH_SLASH,   // //
    AMP,           // &
    AMP_AMP,       // &&
    PIPE,          // |
    PIPE_PIPE,     // ||
    BANG,          // !
    BANG_EQ,       // !=
    EQ,            // =
    EQ_EQ,         // ==
    LT,            // <
    LT_EQ,         // <=
    SLL,           // <<
    // Tokens requiring a lookahead of 3
    GT,            // >
    GT_EQ,         // >=
    SRL,           // >>
    SRA,           // >>>
    // Tokens for literals
    ID,            // ...
    STRING,        // ...
    NUMBER,        // [1-9][0-9]* | 0
    // Tokens for keywords
    IF,            // "if"
    THEN,          // "then"
    ELIF,          // "elif"
    ELSE,          // "else"
    RETURN,        // "return"
    LET,           // "let"
    // Control tokens
    EOF,
    LEX_ERROR,
};

pub const TokenValueType = enum {
    NONE,
    STRING,
    INT,
};

// TODO maybe unify this with value.zig?
pub const TokenValue = union(TokenValueType) {
    NONE : void,
    STRING : []const u8,
    INT : usize,
};

pub const Token = struct {
    token_type : TokenType,
    location : []const u8,
    line : usize,
    value : TokenValue = TokenValue.NONE,
    // TODO add a way to store a value
};

const Scanner = struct {
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

    fn isOnDigit(self : *Self, base : usize) bool {
        std.debug.assert((base == 2) or (base == 8) or
                         (base == 10) or (base == 16));
        return switch (self.peek()) {
            '0', '1' => true,
            '2', '3', '4', '5', '6', '7' => (base >= 8),
            '8', '9' => (base >= 10),
            'A', 'B', 'C', 'D', 'E', 'F', 'a', 'b', 'c', 'd', 'e', 'f' => (base >= 16),
            else => false,
        };
    }

    fn advance(self : *Self) u8 {
        const c = self.peek();
        self.head += 1;
        return c;
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
                    while (self.peek() != '\n' and !self.endFound()) {
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

        // don't include opening/closing quotes
        const str_val = self.text[1..self.head];
        _ = self.advance(); // consume closing quote
        return self.makeValueToken(.STRING, TokenValue{ .STRING = str_val });
    }

    fn lexInt(self : *Self, c_0 : u8) Token {
        var base : usize = 0;
        var c : u8 = c_0;
        if (c_0 == '0') {
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
        }

        var total : usize = 0;
        digitizer: while(true) : ({ c = self.peek(); }) {
            // TODO make the error handling here nicer;
            // right now e.g. 0b101120101 will be lexed as '0b1011' and '20101',
            // rather than throwing an error on the '2'
            if (self.isOnDigit(base)) {
                var digit = switch(c) {
                    '0'...'9' => (c - '0'),
                    'A'...'F' => (c - 'A'),
                    'a'...'f' => (c - 'a'),
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
            '-' => self.makeToken(if (self.match('>')) .RARROW
                                  else                 .MINUS),
            '/' => self.makeToken(if (self.match('/')) .SLASH_SLASH
                                  else                 .SLASH),
            '&' => self.makeToken(if (self.match('&')) .AMP_AMP
                                  else                 .AMP),
            '|' => self.makeToken(if (self.match('|')) .PIPE_PIPE
                                  else                 .PIPE),
            '!' => self.makeToken(if (self.match('=')) .BANG_EQ
                                  else                 .BANG),
            '=' => self.makeToken(if (self.match('=')) .EQ_EQ
                                  else                 .EQ),
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
            '0'...'9' => |x| self.lexInt(x),
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