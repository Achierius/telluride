const std = @import("std");
const print = std.debug.print;
const scan = @import("scanner.zig");
const Token = scan.Token;
const TokenType = scan.TokenType;

pub fn printScannerOutput(token : Token, local_line : *usize) void {
        if(token.line != local_line.*) {
            print("{d:>4} ", .{token.line});
            local_line.* = token.line;
        } else {
            print("   | ", .{});
        }

        // TODO emit token name instead
        print("{s:<10} '{s}'\n", .{
            @tagName(token.token_type),
            token.location,
        });
}

pub fn compileBytecode(source : []u8) void {
    var scanner = scan.initScanner(source);

    var line : usize = 0xFFFFFFFF;

    while (true) {
        var token : Token = scanner.scanToken();

        printScannerOutput(token, &line);

        if (token.token_type == .EOF) { break; }
    }
}