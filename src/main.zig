const std = @import("std");
const fs = std.fs;
const warn = std.debug.warn;
const print = std.debug.print;
const debug = @import("debug.zig");
const emit_bytecode = @import("emit_bytecode.zig");
const compile = @import("compile.zig");
const values = @import("values.zig");
const Value = values.Value;
usingnamespace @import("bytecode.zig");
const interpret = @import("interpret.zig");
usingnamespace @import("alloc.zig");

fn readFile(path : []const u8) ![]u8 {
    const flags = fs.File.OpenFlags {};
    var file = try fs.openFileAbsolute(path, flags);

    const fsize = try file.getEndPos();

    var buff = try allocator.alloc(u8, fsize);

    const bytes_read = try file.read(buff[0..fsize]);
    
    return buff;
}

pub fn main() anyerror!void {

    const contents = try readFile("C:\\Users\\Marcus Plutowski\\Development\\zig-tarmac\\example.tl");

    print("{s}\n", .{contents});

    compile.compileBytecode(contents);
}