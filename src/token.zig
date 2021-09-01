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
    QUERY,         // ?
    TILDE,         // ~
    UNDERSCORE,    // _
    // Tokens requiring a lookahead of 2
    MINUS,         // -
    RARROW_SINGLE, // ->
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
    RARROW_DOUBLE, // =>
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
    PRINT,         // "print"
    SWITCH,        // "switch"
    CASE,          // "case"
    AND,           // "and"
    OR,            // "or"
    EXECUTE,       // "execute"
    UNION,         // "union"
    STRUCT,        // "struct"
    TRUE,          // "true"
    FALSE,         // "false"
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