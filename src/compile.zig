const std = @import("std");
const print = std.debug.print;
const scan = @import("scanner.zig");
const Token = scan.Token;
const TokenType = scan.TokenType;

pub fn compileBytecode(source : []u8) void {
    var scanner = scan.initScanner(source);

    var line : usize = 0xFFFFFFFF;

    while (true) {
        var token : Token = scanner.scanToken();
        if(token.line != line) {
            print("{d:>4} ", .{token.line});
            line = token.line;
        } else {
            print("   | ", .{});
        }

        // TODO emit token name instead
        print("{d:>2} '{s}'\n", .{
            @enumToInt(token.token_type),
            token.location,
        });

        if (token.token_type == .EOF) { break; }
    }
}