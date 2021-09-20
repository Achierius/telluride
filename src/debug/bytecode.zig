const std = @import("std");
const print = std.debug.print;

usingnamespace @import("../bytecode.zig");
const values = @import("../values.zig");
const Value = values.Value; const ValueTypeTag = values.ValueTypeTag;

// OP_RETURN, OP_ACCEPT, OP_REJECT, OP_TAPE_ZERO, 
fn simpleInstr(opcode : Opcode, index : usize) usize {
    var name = mnemonic(opcode);
    print("{s}\n", .{name});
    return index + 1;
}

// TODO make this function actually retrieve values
fn immediateInstr(opcode : Opcode, code : *const BytecodeChunk, index : usize) usize {
    const name = mnemonic(opcode);
    const reg : reg_t = code.byteAtIndex(index + 1);
    //const name = std.meta.tagName(opcode);
    //const type_tag = values.opcodeToTag(opcode);

    //const constant_number : usize = code.byteAtIndex(index + 1);
    //const constant_val : Value = code.getConstant(constant_number);

    print("{s:<10} R{d:0>2} <- ", .{name, reg});
    switch (opcode) {
        .OP_IMM_WORD => {
            const val : u32 = (@intCast(u32, code.byteAtIndex(index + 2)) <<  0)
                            + (@intCast(u32, code.byteAtIndex(index + 3)) <<  8)
                            + (@intCast(u32, code.byteAtIndex(index + 4)) << 16)
                            + (@intCast(u32, code.byteAtIndex(index + 5)) << 24);
            print("{d}\n", .{1010}); // TODO
            return index + 6;
        },
        .OP_IMM_HALF => {
            const val : u16 = (@intCast(u16, code.byteAtIndex(index + 2)) << 0)
                            + (@intCast(u16, code.byteAtIndex(index + 3)) << 8);
            print("{d}\n", .{val}); // TODO
            return index + 4;
        },
        .OP_IMM_BYTE => {
            const val : u8 = code.byteAtIndex(index + 2);
            print("{d}\n", .{val});
            return index + 3;
        },
        .OP_CONST_0 => {
            print("{d}\n", .{0});
            return index + 2;
        },
        .OP_CONST_1 => {
            print("{d}\n", .{1});
            return index + 2;
        },
        .OP_CONST_N1 => {
            print("{d}\n", .{-1});
            return index + 2;
        },
        else => {
            print("Not a constant opcode {x}\n", .{opcode});
            return index + 1;
        },
    }
    //print("{s:<16} {d:0>4} ", .{name, constant_number});
    //const bytes_consumed : usize = switch (type_tag) {
    //    .NULL_TYPE => blk: {
    //        print("<null>", .{});
    //        break :blk 2; // TODO refactor at some point to only use one byte
    //    },
    //    .SIZE_TYPE => blk: {
    //        print("{d}", .{constant_val.SIZE_TYPE});
    //        break :blk 2;
    //    },
    //};
    print("\n", .{});

    return index + bytes_consumed;
}

fn threeAddressCodeInstr(opcode : Opcode, code : *const BytecodeChunk, index : usize) usize {
    print("{s:<10} R{d:0>2} <- R{d:0>2}, R{d:0>2}\n",
          .{mnemonic(opcode),
            code.byteAtIndex(index + 1),
            code.byteAtIndex(index + 2),
            code.byteAtIndex(index + 3)});
    return index + 4;
}

// Includes head-related opcodes
fn tapeInstr(opcode : Opcode, code : *const BytecodeChunk, index : usize) usize {
    switch (opcode) {
        .OP_READ_HEAD => {
            print("{s:<10} R[{d:0>2}] <- Tape[R[H]]\n",
                .{mnemonic(opcode),
                    code.byteAtIndex(index + 1)});
            return index + 2;
        },
        .OP_WRITE_HEAD => {
            print("{s:<10} R[{d:0>2}] -> Tape[R[H]]\n",
                .{mnemonic(opcode),
                    code.byteAtIndex(index + 1)});
            return index + 2;
        },
        .OP_MOVE_HEAD_L_N, .OP_MOVE_HEAD_L, .OP_MOVE_HEAD_R_N, .OP_MOVE_HEAD_R => {
            print("{s:<10} R[H] <- R[H] {s:<1} ",
                  .{.mnemonic(opcode),
                    switch(opcode) {
                        .OP_MOVE_HEAD_R_N, .OP_MOVE_HEAD_R => ' ',
                        .OP_MOVE_HEAD_L_N, .OP_MOVE_HEAD_L => '-',
                        else => unreachable,
                    }
                   });
            switch(opcode) {
                .OP_MOVE_HEAD_R_N, .OP_MOVE_HEAD_L_N => {
                     print("{d}{s:<1}\n",
                           .{mnemonic(opcode),
                             direction});
                },
                .OP_MOVE_HEAD_R, .OP_MOVE_HEAD_L => {
                     print("1{s:<1}\n", .{direction});
                },
                else => {
                    unreachable;
                },
            }
        },
        .OP_TAPE_DEPOSIT => {
            // TODO
            return unimplementedInstr(opcode, index);
        },
        .OP_TAPE_WITHDRAW => {
            // TODO
            return unimplementedInstr(opcode, index);
        },
        .OP_TAPE_OVERWRITE => {
            // TODO
            return unimplementedInstr(opcode, index);
        },
        else => {
            print("Not a tape- or head-related opcode {x}\n", .{opcode});
            return index + 1;
        }
    }
}

fn genericOneRegInstr(opcode : Opcode, code : *const BytecodeChunk, index : usize) usize {
    print("{s:<10} R[{d:0>2}]\n",
          .{mnemonic(opcode),
            code.byteAtIndex(index + 1)});
    return index + 2;
}

// TODO maybe let the byte be printed as a char at some point?
fn genericOneByteInstr(opcode : Opcode, code : *const BytecodeChunk, index : usize) usize {
    print("{s:<10} {d}\n",
          .{mnemonic(opcode),
            code.byteAtIndex(index + 1)});
    return index + 2;
}

fn printInstr(code : *const BytecodeChunk, index : usize) usize {
    var reg = code.byteAtIndex(index + 2);
    var mode = @intToEnum(PrintMode, code.byteAtIndex(index + 1));
    var mode_text = switch (mode) {
        .ASINT =>  "int",
        .ASHEX =>  "hex",
        .ASCHAR => "char",
    };
    print("{s:<10} R{d:0>2} as {s}\n", .{
        "PRINT",
        reg,
        mode_text,
    });
    return index + 3;
}

fn unimplementedInstr(opcode : Opcode, index : usize) usize {
    print("Unimplemented opcode: {x}\n", .{opcode});
    return index + 1;
}

fn disassembleInstr(code : *const BytecodeChunk, index : usize) usize {
    print("{d:0>4} ", .{index});
    if (index > 0 and
        code.lineAtIndex(index) == code.lineAtIndex(index - 1)) {
        print("   | ", .{});
    } else {
        print("{d:>4} ", .{code.lineAtIndex(index)});
    }
    var instruction : Opcode = code.*.opcodeAtIndex(index);
    const name = std.meta.tagName(instruction);

    print("{s:<16}", .{name});

    switch (instruction) {
        .OP_RETURN, .OP_ACCEPT, .OP_REJECT => {
            return simpleInstr(instruction, index);
        },
        .OP_IMM_WORD, .OP_IMM_HALF, .OP_IMM_BYTE,
        .OP_CONST_0, .OP_CONST_1, .OP_CONST_N1 => {
            return immediateInstr(instruction, code, index);
        },
        .OP_AR_ADD, .OP_AR_SUB, .OP_AR_MUL, .OP_AR_AND, .OP_AR_OR,
        .OP_AR_SLL, .OP_AR_SRL, .OP_AR_SRA => {
            return threeAddressCodeInstr(instruction, code, index);
        },
        .OP_PRINT => {
            return printInstr(code, index);
        },
        else => {
            print("Unknown opcode {x}\n", .{instruction});
            return index + 1;
        },
    }
}

pub fn disassembleByteCode(code : *const BytecodeChunk, name : []const u8) void {
    print("== {s} ==\n", .{name});

    var index : usize = 0;
    while (true) {
        if (index >= code.*.text.items.len) {
            break;
        } else {
            index = disassembleInstr(code, index);
        }
    }
}