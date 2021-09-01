usingnamespace @import("ast.zig");

const std = @import("std");
const Allocator = std.mem.Allocator;
const Scanner = @import("scanner.zig").Scanner;
const token_module = @import("token.zig");
const Token = token_module.Token;
const TokenType = token_module.TokenType;
const TokenValue = token_module.TokenValue;
const TokenValueType = token_module.TokenValueType;


fn typeInSet(token : Token, set : []const TokenType) bool {
    for (set) |val| {
        if (token.token_type == val) {
            return true;
        }
    }
    return false;
}

const expression_first_set =
    [_]TokenType {
        TokenType.MINUS, TokenType.BANG, // Unary operators
        TokenType.ID, TokenType.STRING, TokenType.NUMBER,
        TokenType.TRUE, TokenType.FALSE
    };

const statement_first_set  =
    [_]TokenType {
        TokenType.LET, TokenType.RETURN, TokenType.IF
    } ++ expression_first_set;

pub const Parser = struct {
    const Self = @This();

    scanner : *Scanner,
    allocator : *Allocator,
    sym : Token,

    pub fn init(allocator : *Allocator, scanner : *Scanner) Self {
        var self = Self {
            .scanner = scanner,
            .allocator = allocator,
            .sym = Token {
                .token_type = TokenType.LEX_ERROR,
                .location = "Dummy token!",
                .line = 0,
            },
        };

        self.advance();

        return self;
    }

    fn advance(self : *Self) void {
        self.sym = self.scanner.*.scanToken();
    }

    // Consumes
    fn accept(self : *Self, s : TokenType) bool {
        if (self.matches(s)) {
            self.advance();
            return true;
        }
        return false;
    }

    // Does not consume
    fn matches(self : *Self, s : TokenType) bool {
        if (self.sym.token_type == s) {
            return true;
        }
        return false;
    }

    fn expect(self : *Self, s : TokenType) anyerror!void {
        if (self.accept(s)) {
            return;
        }
        std.debug.print("Expected: {s}\nActual: {s}\n", .{@tagName(s), @tagName(self.sym.token_type)});
        @panic("Expected token not found");
    }

    //TODO do I want this here like this?
    fn parseIdentifier(self : *Self) anyerror!*Identifier {
        var id : *Identifier = try self.allocator.create(Identifier);
        const sym = self.sym;

        try self.expect(.ID);
        id.* = sym;

        return id;
    }

    fn parseExpression(self : *Self) anyerror!*ExpressionNode {
        var expr : *ExpressionNode = try self.allocator.create(ExpressionNode);

        // TODO PRATT PARSER
        const id = try self.parseIdentifier();

        expr.* = ExpressionNode{
            .identifier = id
        };

        return expr;
    }

    fn parseLet(self : *Self) anyerror!*LetNode {
        var let : *LetNode = try self.allocator.create(LetNode);

        try self.expect(.LET);
        const id : *Identifier = try self.parseIdentifier();
        try self.expect(.EQ);
        const value : *ExpressionNode = try self.parseExpression();

        let.* = LetNode {
            .id = id,
            .value = value,
        };

        return let;
    }

    fn parseIf(self : *Self) anyerror!*IfNode {
        var if_ : *IfNode = try self.allocator.create(IfNode);

        try self.expect(.IF);
        const condition : *ExpressionNode = try self.parseExpression();
        try self.expect(.THEN);
        const then_block : *BlockNode = try self.parseBlock();
        try self.expect(.ELSE);
        const else_block : *BlockNode = try self.parseBlock();

        if_.* = IfNode {
            .condition = condition,
            .then_block = then_block,
            .else_block = else_block,
        };

        return if_;
    }

    fn parseReturn(self : *Self) anyerror!*ReturnNode {
        var return_ : *ReturnNode = try self.allocator.create(ReturnNode);

        try self.expect(.RETURN);
        const return_value : *ExpressionNode = try self.parseExpression();

        return_.* = ReturnNode {
            .return_value = return_value
        };

        return return_;
    }

    fn parseStatement(self : *Self) anyerror!*StatementNode {
        var statement : *StatementNode = try self.allocator.create(StatementNode);

        if (self.matches(.LET)) {
            var let = try self.parseLet();
            statement.* = StatementNode { .let_stmt = let };
        } else if (self.matches(.RETURN)) {
            var ret = try self.parseReturn();
            statement.* = StatementNode { .return_stmt = ret };
        } else if (self.matches(.IF)) {
            var if_ = try self.parseIf();
            statement.* = StatementNode { .if_stmt = if_ };
        } else if (typeInSet(self.sym, expression_first_set[0..])) {
            var expr = try self.parseExpression();
            statement.* = StatementNode { .expr_stmt = expr };
        } else {
            @panic("Invalid statement");
        }
        try self.expect(.SEMICOLON);

        return statement;
    }

    fn parseBlock(self : *Self) anyerror!*BlockNode {
        var block : *BlockNode = try self.allocator.create(BlockNode);
        var statements = std.ArrayList(StatementNode).init(self.allocator);

        while (typeInSet(self.sym, statement_first_set[0..])) {
            var statement = try self.parseStatement();
            try statements.append(statement.*);
            // TODO this causes kinda a memory leak - the old statement gets lost!
        }

        block.* = BlockNode {
            .statements = statements,
        };

        return block;
    }

    // TODO figure out how to carry around the program state properly (rn it's duped b/w scanner and the param)
    pub fn parseProgram(self : *Self, program : []const u8) anyerror!ProgramAst {
        const block : *BlockNode = try self.parseBlock();
        try self.expect(.EOF);    

        return ProgramAst { 
            .source_location = program,
            .statements = block,
        };
    }
};