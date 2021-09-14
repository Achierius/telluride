const std = @import("std");
const print = std.debug.print;
usingnamespace @import("../ast.zig");
const token_module = @import("../token.zig");
const Token = token_module.Token;
const TokenType = token_module.TokenType;

pub fn printAst(ast : *ProgramAst) void {
    printAstNode(ProgramAst, ast);
}


fn printAstNode(comptime t : type, node : *t) void {
    comptime const t_name = @typeName(t);
    comptime const tail_len = "Node".len;
    comptime const t_name_sans_node = t_name[0..(t_name.len - tail_len)]; // We want "Let", not "LetNode"
    print(" ({s}", .{t_name_sans_node});
    defer print(")", .{});

    switch (t) {
        BinaryOpNode => {
            const leaf = AstLeaf { .bin_op = node.operator };
            printAstLeaf(&leaf);
            printAstNode(ExpressionNode, node.lhs);
            printAstNode(ExpressionNode, node.rhs);
        },
        UnaryOpNode => {
            // TODO unify this with other operators
            //print(" {s}", .{@tagName(node.operator)});
            const leaf = AstLeaf { .un_op = node.operator };
            printAstLeaf(&leaf);
            printAstNode(ExpressionNode, node.rhs);
            //printAstNode(ExpressionNode, node.*.)
        },
        CallNode => {
            const leaf = AstLeaf { .id = node.callee };
            printAstLeaf(&leaf);
            print(" (", .{});
            for (node.arguments.items) |*arg| {
                printAstNode(ExpressionNode, arg);
            }
            print(")", .{});
        },
        LetNode => {
            const leaf = AstLeaf { .id = node.id };
            printAstLeaf(&leaf);
            printAstNode(ExpressionNode, node.value);
        },
        IfNode => {
            printAstNode(ExpressionNode, node.condition);
            print(" (Then", .{});
            printAstNode(BlockNode, node.then_block);
            print(") (Else", .{});
            printAstNode(BlockNode, node.else_block);
            print(")", .{});
        },
        ReturnNode => {
            printAstNode(ExpressionNode, node.return_value);
        },
        ExpressionNode => {
            printExpressionNodeBody(node);
        },
        StatementNode => {
            printStatementNodeBody(node);
        },
        BlockNode => {
            for (node.statements.items) |*statement| {
                printAstNode(StatementNode, statement);
            }
        },
        ProgramNode => {
            for (node.statements.items) |*statement| {
                printAstNode(StatementNode, statement);
            }
        },
        else => {
            unreachable;
        }
    }
}

fn printAstLeaf(leaf : *const AstLeaf) void {
    print(" [{s}", .{@tagName(leaf.*)});
    defer print("]", .{});

    switch (leaf.*) {
        // TODO do this better
        .id, .lit => |tok| switch (tok.token_type) {
            .ID => {
                print(" <{s}>", .{leaf.id.location});
            },
            .STRING => {
                print(" \"{s}\"", .{leaf.lit.value.STRING});
            },
            .NUMBER => {
                print(" {d}", .{leaf.lit.value.INT});
            },
            else => unreachable,
        },
        .bin_op => |op| {
            print(" {s}", .{@tagName(op.*)});
        },
        .un_op => |op| {
            print(" {s}", .{@tagName(op.*)});
        },
    }
}

fn printStatementNodeBody(node : *StatementNode) void {
    switch (node.body) {
        .let_stmt    => |val| printAstNode(LetNode, val),
        .if_stmt     => |val| printAstNode(IfNode, val),
        .return_stmt => |val| printAstNode(ReturnNode, val),
        .expr_stmt   => |val| printAstNode(ExpressionNode, val),
    }
}

fn printExpressionNodeBody(node : *ExpressionNode) void {
    switch (node.body) {
        .literal    => |val| {
            const leaf = AstLeaf { .lit = val };
            printAstLeaf(&leaf);
        },
        .identifier  => |val| {
            const leaf = AstLeaf { .id = val };
            printAstLeaf(&leaf);
        },
        .binop_expr => |val| printAstNode(BinaryOpNode, val),
        .unop_expr  => |val| printAstNode(UnaryOpNode, val),
        .call_expr  => |val| printAstNode(CallNode, val),
    }
}

fn printSpace() void {
    print(" ", .{});
}