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
        // TODO populate
        unreachable;
    }

    fn lexInt(self : *Self) Token {
        // TODO populate
        unreachable;
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