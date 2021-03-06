const std = @import("std");
usingnamespace @import("values.zig");

pub const reg_t = u8;

pub const Opcode = enum(u8) {
    OP_NULL_OPCODE,
    OP_NOP,

    // Control Flow LULW
    OP_RETURN,
    OP_SKIP,

    // Immediates & Constants
    OP_IMM_WORD, // 4B
    OP_IMM_HALF, // 2B
    OP_IMM_BYTE, // 1B
    OP_CONST_0,
    OP_CONST_1,
    OP_CONST_N1,

    // Arithmetic
    OP_AR_ADD,
    OP_AR_SUB,
    OP_AR_MUL,
    OP_AR_AND,
    OP_AR_OR,
    OP_AR_XOR,
    OP_AR_SLL,
    OP_AR_SRL,
    OP_AR_SRA,
  //OP_AR_DIV,
  //OP_AR_NOT,
  //OP_AR_NEG


    // Machine-state management
    OP_ENTER, // Loads machine pointer, enters Machine Mode
    OP_ACCEPT,
    OP_REJECT,
    OP_GOTO_STATE,

    // Tape management
    OP_TAPE_DEPOSIT,
    OP_TAPE_WITHDRAW,
  //OP_TAPE_GETLEN,
    OP_TAPE_OVERWRITE,

    // Tape head manipulation
    OP_MOVE_HEAD_L,
    OP_MOVE_HEAD_L_N,
    OP_MOVE_HEAD_R,
    OP_MOVE_HEAD_R_N,
    OP_WRITE_HEAD,
    OP_READ_HEAD,
    
  //OP_LOAD_WORD
  //OP_LOAD_HALF
  //OP_LOAD_BYTE

    OP_PRINT,
};

pub const PrintMode = enum(u8) {
    ASINT,
    ASHEX,
    ASCHAR,
};

pub const OpcodeData = struct {
    opcode : Opcode,
    mnemonic : []u8,

};

pub fn mnemonic(opcode : Opcode) []const u8 {
    return switch(opcode) {

        .OP_NULL_OPCODE      => { return "<null>"; },
        .OP_NOP,             => { return "NOP"; },

        .OP_SKIP             => { return "SKP"; },
        .OP_RETURN           => { return "RETURN"; },

        .OP_IMM_WORD         => { return "LI"; },
        .OP_IMM_HALF         => { return "LI"; },
        .OP_IMM_BYTE         => { return "LI"; },
        .OP_CONST_0          => { return "LI"; },
        .OP_CONST_1          => { return "LI"; },
        .OP_CONST_N1         => { return "LI"; },

        .OP_AR_ADD           => { return "ADD"; },
        .OP_AR_SUB           => { return "SUB"; },
        .OP_AR_MUL           => { return "MUL"; },
        .OP_AR_AND           => { return "AND"; },
        .OP_AR_OR            => { return "OR"; },
        .OP_AR_XOR           => { return "XOR"; },
        .OP_AR_SLL           => { return "SLL"; },
        .OP_AR_SRL           => { return "SRL"; },
        .OP_AR_SRA           => { return "SRA"; },

        .OP_ENTER            => { return "ENTER"; },  // TODO debug.zig
        .OP_ACCEPT           => { return "ACCEPT"; },
        .OP_REJECT           => { return "REJECT"; },
        .OP_GOTO_STATE       => { return "GST"; },    // TODO debug.zig

        .OP_TAPE_DEPOSIT     => { return "TAPED"; },  // TODO debug.zig
        .OP_TAPE_WITHDRAW    => { return "TAPEW"; },  // TODO debug.zig
      //.OP_TAPE_GETLEN      => { return "TAPEL"; },  // TODO debug.zig
        .OP_TAPE_OVERWRITE   => { return "ZTAPE"; },  // TODO debug.zig

        .OP_MOVE_HEAD_L_N    => { return "MOVL"; },
        .OP_MOVE_HEAD_L      => { return "MOVL"; },
        .OP_MOVE_HEAD_R_N    => { return "MOVR"; },
        .OP_MOVE_HEAD_R      => { return "MOVR"; },
        .OP_WRITE_HEAD       => { return "WRIT"; },
        .OP_READ_HEAD        => { return "READ"; },

        .OP_PRINT            => { return "PRINT"; }, // Keep at the end of the list, it's our sentinel
    } ;
}

pub const BytecodeChunk = struct {
    const Self = @This();

    const LineInfo = struct {
        source_line : usize,
    };

    text      : std.ArrayList(u8),
    lines     : std.ArrayList(LineInfo),
    constants : std.ArrayList(Value),

    pub fn init(allocator: *std.mem.Allocator) Self {
        return BytecodeChunk{
            .text      = std.ArrayList(u8).init(allocator),
            .lines     = std.ArrayList(LineInfo).init(allocator),
            .constants = std.ArrayList(Value).init(allocator),
        };
    }

    pub fn deinit(self: Self) void {
        self.text.deinit();
        self.lines.deinit();
        self.constants.deinit();
    }

    pub fn byteAtIndex(self: Self, index: usize) u8 {
        return self.text.items[index];
    }

    pub fn opcodeAtIndex(self: Self, index: usize) Opcode {
        return @intToEnum(Opcode, byteAtIndex(self, index));
    }

    pub fn lineAtIndex(self: Self, index: usize) usize {
        return self.lines.items[index].source_line;
    }

    pub fn getConstant(self: Self, index: usize) Value {
        return self.constants.items[index];
    }
};