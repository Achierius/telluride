const std = @import("std");
const print = std.debug.print;
const bytecode = @import("bytecode.zig");
const BytecodeChunk = bytecode.BytecodeChunk;
const Opcode = bytecode.Opcode;
const Allocator = @import("std").mem.Allocator;

pub const InterpreterResult = enum {
    INTERPRET_SUCCESS,
    COMPILE_ERROR,
    RUNTIME_ERROR,
    INVALID_OPCODE,
};

pub const VirtualMachine = struct {
    const Self = @This();

    code : *BytecodeChunk,
    ip : usize,
    reg : []u32,
    tape : std.ArrayList(u8),

    pub fn init(allocator : *Allocator, code : *BytecodeChunk) Self {
        var arr = allocator.allocWithOptions(u32, 256, 32, null) catch unreachable; // im very cool

        var self = Self{
            .code = code,
            .ip = 0,
            .reg = arr,
            .tape = std.ArrayList(u8).init(allocator),
        };

        for (self.reg[0..256]) |*v| v.* = 0;
        return self;
    }

    pub fn byteAtOffset(self : Self, offset : usize) u8 {
        return self.code.byteAtIndex(self.ip + offset);
    }

    pub fn run(slf : Self) InterpreterResult {
        var self = slf;
        var opcode = Opcode.OP_RETURN;
        while (true) {
            const ibyte = self.byteAtOffset(0);
            if (ibyte > @enumToInt(Opcode.OP_PRINT)) {
                print("Error: Unrecognized opcode", .{});
                return .INVALID_OPCODE;
            }
            opcode = @intToEnum(Opcode, ibyte);
            switch (opcode) {
                .OP_RETURN => {
                    return .INTERPRET_SUCCESS;
                },
                .OP_AR_ADD => {
                    const rd  : u8 = self.byteAtOffset(1);
                    const rs1 : u8 = self.byteAtOffset(2);
                    const rs2 : u8 = self.byteAtOffset(3);
                    self.reg[rd] = self.reg[rs1] + self.reg[rs2];
                    self.ip += 4;
                },
                .OP_AR_SUB => {
                    const rd  : u8 = self.byteAtOffset(1);
                    const rs1 : u8 = self.byteAtOffset(2);
                    const rs2 : u8 = self.byteAtOffset(3);
                    self.reg[rd] = self.reg[rs1] - self.reg[rs2];
                    self.ip += 4;
                },
                .OP_AR_MUL => {
                    const rd  : u8 = self.byteAtOffset(1);
                    const rs1 : u8 = self.byteAtOffset(2);
                    const rs2 : u8 = self.byteAtOffset(3);
                    self.reg[rd] = self.reg[rs1] * self.reg[rs2];
                    self.ip += 4;
                },
                .OP_AR_AND => {
                    const rd  : u8 = self.byteAtOffset(1);
                    const rs1 : u8 = self.byteAtOffset(2);
                    const rs2 : u8 = self.byteAtOffset(3);
                    self.reg[rd] = self.reg[rs1] & self.reg[rs2];
                    self.ip += 4;
                },
                .OP_AR_OR  => {
                    const rd  : u8 = self.byteAtOffset(1);
                    const rs1 : u8 = self.byteAtOffset(2);
                    const rs2 : u8 = self.byteAtOffset(3);
                    self.reg[rd] = self.reg[rs1] | self.reg[rs2];
                    self.ip += 4;
                },
                .OP_AR_XOR => {
                    const rd  : u8 = self.byteAtOffset(1);
                    const rs1 : u8 = self.byteAtOffset(2);
                    const rs2 : u8 = self.byteAtOffset(3);
                    self.reg[rd] = self.reg[rs1] ^ self.reg[rs2];
                    self.ip += 4;
                },
                //.OP_AR_SLL => {
                //    self.ip += 4;
                //},
                //.OP_AR_SRL => {
                //    self.ip += 4;
                //},
                //.OP_AR_SRA => {
                //    self.ip += 4;
                //},
                .OP_IMM_BYTE => {
                    const rd : u8 = self.byteAtOffset(1);
                    const val : u8 = self.byteAtOffset(1);
                    self.reg[rd] = val;
                    self.ip += 3;
                },
                .OP_IMM_HALF => {
                    const rd : u8 = self.byteAtOffset(1);
                    const val : u16 = (@intCast(u16, self.byteAtOffset(2)) << 0)
                                    + (@intCast(u16, self.byteAtOffset(3)) << 8);
                    self.reg[rd] = val;
                    self.ip += 4;
                },
                .OP_IMM_WORD => {
                    const rd : u8 = self.byteAtOffset(1);
                    const val : u32 = (@intCast(u32, self.byteAtOffset(2)) <<  0)
                                    + (@intCast(u32, self.byteAtOffset(3)) <<  8)
                                    + (@intCast(u32, self.byteAtOffset(4)) << 16)
                                    + (@intCast(u32, self.byteAtOffset(5)) << 24);
                    self.reg[rd] = val;
                    self.ip += 6;
                },
                .OP_CONST_0 => {
                    const rd : u8 = self.byteAtOffset(1);
                    self.reg[rd] = 0;
                    self.ip += 2;
                },
                .OP_CONST_1 => {
                    const rd : u8 = self.byteAtOffset(1);
                    self.reg[rd] = 1;
                    self.ip += 2;
                },
                .OP_CONST_N1 => {
                    const rd : u8 = self.byteAtOffset(1);
                    self.reg[rd] = 0xFFFFFFFF;
                    self.ip += 2;
                },
                .OP_PRINT => {
                    const mode = @intToEnum(bytecode.PrintMode,
                                            self.byteAtOffset(1));
                    const reg : u8 = self.byteAtOffset(2);
                    const val : u32 = self.reg[reg];
                    switch (mode) {
                        .ASINT  => { print("{d}", .{val}); },
                        .ASHEX  => { print("{x}", .{val}); },
                        .ASCHAR => { print("{c}", .{@intCast(u8, val & 0xFF)}); },
                    }
                    self.ip += 3;
                },
                else => {
                    print("Error: Unimplemented Opcode [{d}]\n", .{ibyte});
                    return .RUNTIME_ERROR;
                },
            }
        }
    }
};