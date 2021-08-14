const std = @import("std");
const print = std.debug.print;
const debug = @import("debug.zig");
const compile = @import("compile.zig");
const values = @import("values.zig");
const Value = values.Value;
usingnamespace @import("bytecode.zig");
const interpret = @import("interpret.zig");

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var allocator = &arena.allocator;

pub fn main() anyerror!void {
    var code = BytecodeChunk.init(allocator);
    defer code.deinit();

    try compile.emitLoadImmediate(&code, 1, 1, 1355);
    try compile.emitLoadImmediate(&code, 2, 2, 1);
    try compile.emitLoadImmediate(&code, 3, 3, 2);
    try compile.emitRegisterTAC(&code, 4, .OP_AR_SUB, 1, 1, 2);
    try compile.emitRegisterTAC(&code, 5, .OP_AR_MUL, 1, 1, 3);
    try compile.emitPrint(&code, 6, 1, .ASINT);

    try compile.emitLoadImmediate(&code, 7, 10, '\n');
    try compile.emitPrint(&code, 7, 10, .ASCHAR);

    try compile.emitOpcode(&code, 8, .OP_RETURN);

    debug.disassembleByteCode(&code, "disassembly");
    
    const vm = interpret.VirtualMachine.init(allocator, &code);
    print("== program output ==\n\n", .{});
    const result = vm.run();
    print("\n====================\n", .{});
    if (result == .INTERPRET_SUCCESS) {
        print("Program completed successfully\n", .{});
    } else {
        print("Program failed with error code {d}: {s}\n", .{
            @enumToInt(result),
            std.meta.tagName(result),
        });
    }
}
