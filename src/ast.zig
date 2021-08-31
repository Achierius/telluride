const std = @import("std");
const scanner = @import("scanner.zig");
const TokenType = scanner.TokenType,
const TokenValue = scanner.TokenValue,
const Token = scanner.Token,


pub const Identifier = Token;

pub const Literal = Token;

pub const UnaryOperation = enum {
    negate,
    not,
};

pub const BinaryOperation = enum {
    add,
    sub,
    idiv,
    mul,
    sll,
    srl,
    sra,
    cmp_eq,
    cmp_neq,
    cmp_lt,
    cmp_gt,
    cmp_lte,
    cmp_gte,
    log_and,
    log_or,
    bin_and,
    bin_or,
    bin_xor,
};

pub const BinaryOpNode = struct {
    lhs : ExpressionNode,
    operator : BinaryOperation,
    rhs : ExpressionNode,
};

pub const UnaryOpNode = struct {
    operator : UnaryOperation,
    rhs : ExpressionNode,
};

pub const CallNode = struct {
    callee : Identifier,
    arguments : std.ArrayList(ExpressionNode),
};

pub const LetNode = struct {
    id : Identifier, // Must have type ID
    value : ExpressionNode,
};

pub const IfNode = struct {
    condition : ExpressionNode,
    then_statements : std.ArrayList(StatementNode),
    else_statements : std.ArrayList(StatementNode),
};

pub const ReturnNode = struct {
    return_value : ExpressionNode,
};

pub const const ExpressionNode = union(enum) {
    literal : Literal,
    identifier : Identifier,
    binop_expr : BinaryOpNode,
    unop_expr : UnaryOpNode,
    call_expr : CallNode,
};

pub const StatementNode = union(enum) {
    let_stmt  : LetNode,
    if_stmt : IfNode,
    return_stmt : ReturnNode,
    expr_stmt : ExpressionNode,
};

const ProgramNode = struct {
    source_location : []const u8,
    statements : std.ArrayList(StatementNode),
};