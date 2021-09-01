const std = @import("std");
const allocator = @import("alloc.zig").allocator;
const print = std.debug.print;
const scan = @import("scanner.zig");
const Token = scan.Token;
const TokenType = scan.TokenType;
const TokenValueType = scan.TokenValueType;
const Parser = @import("parser.zig").Parser;

pub fn printScannerOutput(token : Token, local_line : *usize) void {
        if(token.line != local_line.*) {
            print("{d:>4} ", .{token.line});
            local_line.* = token.line;
        } else {
            print("   | ", .{});
        }

        // TODO emit token name instead
        print("{s:<12} '{s}'", .{
            @tagName(token.token_type),
            token.location,
        });

        switch (token.value) {
            TokenValueType.NONE => {},
            TokenValueType.STRING => {
                print(" -- val: \"{s}\"", .{token.value.STRING});
            },
            TokenValueType.INT => {
                print(" -- val: {d}", .{token.value.INT});
            },
        }

        print("\n", .{});
}

pub fn compileBytecode(source : []u8) void {
    var scanner = scan.initScanner(source);
    var parser = Parser.init(allocator, &scanner);

    var line : usize = 0xFFFFFFFF;

    var program_ast = parser.parseProgram("");


    //while (true) {
    //    var token : Token = scanner.scanToken();

    //    printScannerOutput(token, &line);

    //    if (token.token_type == .EOF) { break; }
    //}
}