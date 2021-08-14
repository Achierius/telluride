const std = @import("std");
const Opcode = @import("bytecode.zig").Opcode;

// Types available in the Telluride bytecode
pub const ValueTypeTag = enum(u8) {
    NULL_TYPE,
    SIZE_TYPE,
};

pub const Value = union(ValueTypeTag) {
    NULL_TYPE : void,
    SIZE_TYPE : usize,
};

// TODO add in error support
pub fn opcodeToTag(opcode : Opcode) ValueTypeTag {
    const opcode_as_int = @enumToInt(opcode);
    const tag_base = @enumToInt(Opcode.OP_IMM_WORD);
    return @intToEnum(ValueTypeTag, opcode_as_int - tag_base);
}

pub fn tagToOpcode(tag : ValueTypeTag) Opcode {
    const tag_as_int = @enumToInt(tag);
    const opcode_base = @enumToInt(Opcode.OP_IMM_WORD);
    return @intToEnum(Opcode, tag_as_int + opcode_base);
}