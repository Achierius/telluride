const std = @import("std");
usingnamespace @import("values.zig");

pub const reg_t = u8;

pub const Opcode = enum(u8) {
    OP_NULL_OPCODE,
    OP_NOP,
    OP_RETURN,
    OP_IMM_WORD, // 4B
    OP_IMM_HALF, // 2B
    OP_IMM_BYTE, // 1B
    OP_CONST_0,
    OP_CONST_1,
    OP_CONST_N1,
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
    OP_MOVE_HEAD,
    OP_MOVE_HEAD_L,
    OP_MOVE_HEAD_R,
    OP_WRITE_HEAD,
    OP_READ_HEAD,

    OP_PRINT,
};

pub const PrintMode = enum(u8) {
    ASINT,
    ASHEX,
    ASCHAR,
};

pub fn mnemonic(opcode : Opcode) []const u8 {
    return switch(opcode) {

        .OP_NULL_OPCODE      => { return "<null>"; },
        .OP_NOP,             => { return "NOP"; },
        .OP_RETURN           => { return "RETURN"; },
        .OP_IMM_WORD         => { return "LI"; },
        .OP_IMM_HALF         => { return "LI"; },
        .OP_IMM_BYTE         => { return "LI"; },
        .OP_CONST_0          => { return "LI"; },
        .OP_CONST_1          => { return "LI"; },
        .OP_CONST_N1         => { return "LCN1"; },
        .OP_AR_ADD           => { return "ADD"; },
        .OP_AR_SUB           => { return "SUB"; },
        .OP_AR_MUL           => { return "MUL"; },
        .OP_AR_AND           => { return "AND"; },
        .OP_AR_OR            => { return "OR"; },
        .OP_AR_XOR           => { return "XOR"; },
        .OP_AR_SLL           => { return "SLL"; },
        .OP_AR_SRL           => { return "SRL"; },
        .OP_AR_SRA           => { return "SRA"; },

        .OP_ENTER            => { return "ENTER"; },
        .OP_ACCEPT           => { return "ACCEPT"; },
        .OP_REJECT           => { return "REJECT"; },
        .OP_GOTO_STATE       => { return "GST"; },

        .OP_TAPE_DEPOSIT     => { return "TAPED"; },
        .OP_TAPE_WITHDRAW    => { return "TAPEW"; },
      //.OP_TAPE_GETLEN      => { return "TAPEL"; },
        .OP_TAPE_OVERWRITE   => { return "ZTAPE"; },

        .OP_MOVE_HEAD        => { return "MOV"; },
        .OP_MOVE_HEAD_L      => { return "MOVL"; },
        .OP_MOVE_HEAD_R      => { return "MOVR"; },
        .OP_WRITE_HEAD       => { return "WRITE"; },
        .OP_READ_HEAD        => { return "READ"; },

        .OP_PRINT            => { return "PRINT"; }, // Keep at the end of the list, it's our sentinel
    } ;
}

pub const BytecodeChunk = struct {
    const Self = @This();

    // TODO swap this part out with a SoA type impl, a la https://github.com/ziglang/zig/commit/0808d98e10c5fea27cebf912c6296b760c2b837b\
    const TextList = std.ArrayList(struct {
        byte : u8,
        source_line : usize,
    });

    text : TextList,
    constants : std.ArrayList(Value),

    pub fn init(allocator: *std.mem.Allocator) Self {
        return BytecodeChunk{
            .text = TextList.init(allocator),
            .constants = std.ArrayList(Value).init(allocator),
        };
    }

    pub fn deinit(self: Self) void {
        self.text.deinit();
        self.constants.deinit();
    }

    pub fn byteAtIndex(self: Self, index: usize) u8 {
        return self.text.items[index].byte;
    }

    pub fn opcodeAtIndex(self: Self, index: usize) Opcode {
        return @intToEnum(Opcode, byteAtIndex(self, index));
    }

    pub fn lineAtIndex(self: Self, index: usize) usize {
        return self.text.items[index].source_line;
    }

    pub fn getConstant(self: Self, index: usize) Value {
        return self.constants.items[index];
    }
};