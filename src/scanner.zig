const std = @import("std");

pub const TokenType = enum {
    // Tokens requiring a lookahead of 1
    L_PAREN,       // (
    R_PAREN,       // )
    L_BRACE,       // {
    R_BRACE,       // }
 // L_A_BRACKET,   // <
 // R_A_BRACKET,   // >
    L_S_BRACKET,   // []
    R_S_BRACKET,   // ]
    COMMA,         // ,
    DOT,           // .
    PERCENT,       // %
    COLON,         // :
    SEMICOLON,     // ;
    MINUS,         // -
    PLUS,          // +
    STAR,          // *
    CARET,         // ^
    // Tokens requiring a lookahead of 2
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
    GT,            // >
    GT_EQ,         // >=
    LT,            // <
    LT_EQ,         // <=
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

pub const Token = struct {
    token_type : TokenType,
    location : []const u8,
    line : usize,
};

const Scanner = struct {
    const Self = @This();

    text : []const u8,
    head : usize,
    line : usize,

    fn isAtEnd(self : Self) bool {
        return self.head == self.text.len;
    }

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

    fn advance(self : *Self) u8 {
        self.head += 1;
        return self.text[self.head - 1];
    }

    pub fn scanToken(self : *Self) Token {
        self.text = self.text[self.head..];
        self.head = 0;

        if (self.isAtEnd()) {
            return self.makeToken(.EOF);
        }

        const c = self.advance();

        return self.makeErrorToken("Unexpected character.");
    }
};

pub fn initScanner(source : []const u8) Scanner {
    return Scanner {
        .text = source,
        .head = 0,
        .line = 1,
    };
}