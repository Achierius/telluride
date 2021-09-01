const std = @import("std");
const token_module = @import("token.zig");
const Token = token_module.Token;
const TokenType = token_module.TokenType;
const TokenValue = token_module.TokenValue;
const TokenValueType = token_module.TokenValueType;


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
    lhs : *ExpressionNode,
    operator : *BinaryOperation,
    rhs : *ExpressionNode,
};

pub const UnaryOpNode = struct {
    operator : *UnaryOperation,
    rhs : *ExpressionNode,
};

pub const CallNode = struct {
    callee : *Identifier,
    arguments : std.ArrayList(ExpressionNode),
};

pub const LetNode = struct {
    id : *Identifier, // Must have type ID
    value : *ExpressionNode,
};

pub const IfNode = struct {
    condition : *ExpressionNode,
    then_block : *BlockNode,
    else_block : *BlockNode,
};

pub const ReturnNode = struct {
    return_value : *ExpressionNode,
};

pub const ExpressionNode = union(enum) {
    literal : *Literal,
    identifier : *Identifier,
    binop_expr : *BinaryOpNode,
    unop_expr : *UnaryOpNode,
    call_expr : *CallNode,
};

pub const StatementNode = union(enum) {
    let_stmt  : *LetNode,
    if_stmt : *IfNode,
    return_stmt : *ReturnNode,
    expr_stmt : *ExpressionNode,
};

pub const BlockNode = struct {
    statements : std.ArrayList(StatementNode),
};

pub const ProgramNode = struct {
    source_location : []const u8,
    statements : *BlockNode,
};

pub const ProgramAst = ProgramNode;

pub const Nonterminal = enum {
    binary_op,
    unary_op,
    call,
    let,
    if_,
    return_,
    expression,
    statement,
    block,
    program,
};

pub const AstNode = union(Nonterminal) {
    binary_op : BinaryOpNode,
    unary_op : UnaryOpNode,
    call : CallNode,
    let : LetNode,
    if_ : IfNode,
    return_ : ReturnNode,
    expression : ExpressionNode,
    statement : StatementNode,
    block : BlockNode,
    program : ProgramNode,
};

pub fn printAstNode(node : *AstNode) void {
    const n_children = switch (node.*) {
        binary_op => 3,
        unary_op => 2,
        call => 2,
        let => 1,//2,
        if_ => 3,
        return_ => 1,
        expression => 1,
        statement => 1,
        block => 1,
        program => 1,
    };

    const fmt_str = "({s}" ++ (" {s}" ** n_children) ++ ")";

    std.debug.print(fmt_str, .{@typeName(node.*), "x"});
}

pub fn printAst(ast : *ProgramAst) void {
    printAstNode(ast.*);
}