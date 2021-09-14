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

pub const AstNode = struct {
    source_location : []const u8 = "",
  //type : Type,
  //value : Value,
};

pub const BinaryOpNode = struct {
    node : AstNode = AstNode {},
    lhs : *ExpressionNode,
    operator : *BinaryOperation,
    rhs : *ExpressionNode,
};

pub const UnaryOpNode = struct {
    node : AstNode = AstNode {},
    operator : *UnaryOperation,
    rhs : *ExpressionNode,
};

pub const CallNode = struct {
    node : AstNode = AstNode {},
    callee : *Identifier,
    arguments : std.ArrayList(ExpressionNode),
};

pub const LetNode = struct {
    node : AstNode = AstNode {},
    id : *Identifier, // Must have type ID
    value : *ExpressionNode,
};

pub const IfNode = struct {
    node : AstNode = AstNode {},
    condition : *ExpressionNode,
    then_block : *BlockNode,
    else_block : *BlockNode,
};

pub const ReturnNode = struct {
    node : AstNode = AstNode {},
    return_value : *ExpressionNode,
};

pub const ExpressionNode = struct {
    node : AstNode = AstNode {},
    type_annotation : ?*Identifier, // TODO merge into node, or idk?
    body : ExpressionBody,
};

pub const ExpressionBody = union(enum) {
    literal : *Literal,
    identifier : *Identifier,
    binop_expr : *BinaryOpNode,
    unop_expr : *UnaryOpNode,
    call_expr : *CallNode,
};

pub const StatementNode = struct {
    node : AstNode = AstNode {},
    body : StatementBody,
};

pub const StatementBody = union(enum) {
    let_stmt  : *LetNode,
    if_stmt : *IfNode,
    return_stmt : *ReturnNode,
    expr_stmt : *ExpressionNode,
};

pub const BlockNode = struct {
    node : AstNode = AstNode {},
    statements : std.ArrayList(StatementNode),
};

pub const ProgramNode = struct {
    node : AstNode = AstNode {},
    statements : std.ArrayList(StatementNode),
};

pub const ProgramAst = ProgramNode;

pub const Nonterminal = enum {
    BinaryOp,
    UnaryOp,
    Call,
    Let,
    If,
    Return,
    Expression,
    Statement,
    Block,
    Program,
};


pub const AstNodePtr = union(Nonterminal) {
    BinaryOp : *BinaryOpNode,
    UnaryOp : *UnaryOpNode,
    Call : *CallNode,
    Let : *LetNode,
    If : *IfNode,
    Return : *ReturnNode,
    Expression : *ExpressionNode,
    Statement : *StatementNode,
    Block : *BlockNode,
    Program : *ProgramNode,
};

pub const Terminal = enum {
    id,
    lit,
    bin_op,
    un_op,
};

pub const AstLeaf = union(Terminal) {
    id : *Identifier,
    lit : *Literal,
    bin_op : *BinaryOperation,
    un_op : *UnaryOperation,
};