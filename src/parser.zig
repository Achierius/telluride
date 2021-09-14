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
    fn parseToken(self : *Self, token_type : TokenType) anyerror!*Token {
        var token : *Token = try self.allocator.create(Token);
        const sym = self.sym;

        try self.expect(token_type);
        token.* = sym;

        return token;
    }

    fn parseExpression(self : *Self) anyerror!*ExpressionNode {
        var expr : *ExpressionNode = try self.allocator.create(ExpressionNode);

        // Consume outer parentheses
        if (self.accept(.L_PAREN)) {
            expr = try self.parseExpression();
            try self.expect(.R_PAREN);
            return expr;
        }
        
        // TODO PRATT PARSER
        if (self.matches(.STRING)) {
            const string = try self.parseToken(.STRING);

            expr.body = ExpressionBody {
                .literal = string
            };
        } else if (self.matches(.NUMBER)) {
            const number = try self.parseToken(.NUMBER);

            expr.body = ExpressionBody {
                .literal = number
            };
        } else if (self.matches(.ID)) {
            const id = try self.parseToken(.ID);

            expr.body = ExpressionBody {
                .identifier = id
            };
        } else {
            unreachable;
        }

        // Check to see if type annotation was included
        if (self.accept(.COLON)) {
            expr.type_annotation = try self.parseToken(.ID);
        } else {
            expr.type_annotation = null;
        }

        return expr;
    }

    fn parseLet(self : *Self) anyerror!*LetNode {
        var let : *LetNode = try self.allocator.create(LetNode);

        try self.expect(.LET);
        const id : *Identifier = try self.parseToken(.ID);
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
            statement.* = StatementNode { .body = StatementBody { .let_stmt = let } };
        } else if (self.matches(.RETURN)) {
            var ret = try self.parseReturn();
            statement.* = StatementNode { .body = StatementBody { .return_stmt = ret } };
        } else if (self.matches(.IF)) {
            var if_ = try self.parseIf();
            statement.* = StatementNode { .body = StatementBody { .if_stmt = if_ } };
        } else if (typeInSet(self.sym, expression_first_set[0..])) {
            var expr = try self.parseExpression();
            statement.* = StatementNode { .body = StatementBody { .expr_stmt = expr } };
        } else {
            @panic("Invalid statement");
        }
        try self.expect(.SEMICOLON);

        return statement;
    }

    fn parseStatementSequence(self : *Self, allow_epsilon : bool) anyerror!std.ArrayList(StatementNode) {
        var statements = std.ArrayList(StatementNode).init(self.allocator);

        if (!allow_epsilon) {
            var statement = try self.parseStatement();
            try statements.append(statement.*);
        }

        while (typeInSet(self.sym, statement_first_set[0..])) {
            var statement = try self.parseStatement();
            try statements.append(statement.*);
            // TODO this causes kinda a memory leak - the old statement gets lost!
        }

        return statements;
    }

    fn parseBlock(self : *Self) anyerror!*BlockNode {
        var block : *BlockNode = try self.allocator.create(BlockNode);
        var statements : std.ArrayList(StatementNode) = undefined;

        try self.expect(.L_BRACE);
        statements = try self.parseStatementSequence(true);
        try self.expect(.R_BRACE);

        block.* = BlockNode {
            .statements = statements,
        };

        return block;
    }

    // TODO figure out how to carry around the program state properly (rn it's duped b/w scanner and the param)
    pub fn parseProgram(self : *Self, program : []const u8) anyerror!ProgramAst {
        var statements : std.ArrayList(StatementNode) = undefined;

        statements = try self.parseStatementSequence(false);

        try self.expect(.EOF);    

        return ProgramAst { 
            .node = AstNode {
                .source_location = program,
            },
            .statements = statements,
        };
    }
};