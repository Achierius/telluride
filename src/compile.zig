usingnamespace @import("bytecode.zig");

pub fn emitOpcode(code : *BytecodeChunk, source_line : usize, opcode : Opcode) !void {
    try code.*.text.append(.{
        .byte = @enumToInt(opcode),
        .source_line = source_line,
    });
}

pub fn emitRegister(code : *BytecodeChunk, source_line : usize, register : reg_t) !void {
    try code.*.text.append(.{
        .byte = register,
        .source_line = source_line,
    });
}

pub fn emitByte(code : *BytecodeChunk, source_line : usize, byte : reg_t) !void {
        try code.*.text.append(.{
            .byte = byte,
            .source_line = source_line,
        });
}
// TODO figure out desired sign-extension behavior
pub fn emitLoadImmediate(code : *BytecodeChunk, source_line : usize,
                         register : reg_t, imm : u32) !void {
    if (imm == 0) {
        try emitOpcode(code, source_line, .OP_CONST_0);
        try emitRegister(code, source_line, register);
    } else if (imm == 1) {
        try emitOpcode(code, source_line, .OP_CONST_1);
        try emitRegister(code, source_line, register);
    } else if (imm == -1) {
        try emitOpcode(code, source_line, .OP_CONST_N1);
        try emitRegister(code, source_line, register);
    } else if (imm <= 0x000000FF) {
        try emitOpcode(code, source_line, .OP_IMM_BYTE);
        try emitRegister(code, source_line, register);
        try emitByte(code, source_line, @intCast(u8, imm & 0xFF));
    } else if (imm <= 0x0000FFFF) {
        try emitOpcode(code, source_line, .OP_IMM_HALF);
        try emitRegister(code, source_line, register);
        try emitByte(code, source_line, @intCast(u8, (imm >> 0) & 0xFF));
        try emitByte(code, source_line, @intCast(u8, (imm >> 8) & 0xFF));
    } else {
        try emitOpcode(code, source_line, .OP_IMM_WORD);
        try emitRegister(code, source_line, register);
        try emitByte(code, source_line, @intCast(u8, (imm >>  0) & 0xFF));
        try emitByte(code, source_line, @intCast(u8, (imm >>  8) & 0xFF));
        try emitByte(code, source_line, @intCast(u8, (imm >> 16) & 0xFF));
        try emitByte(code, source_line, @intCast(u8, (imm >> 24) & 0xFF));
    }
}

pub fn emitRegisterTAC(code : *BytecodeChunk, source_line : usize, opcode : Opcode,
                       rd : reg_t, rs1 : reg_t, rs2 : reg_t) !void {
    try emitOpcode(code, source_line, opcode);
    try code.*.text.append(.{
        .byte = rd,
        .source_line = source_line,
    });
    try code.*.text.append(.{
        .byte = rs1,
        .source_line = source_line,
    });
    try code.*.text.append(.{
        .byte = rs2,
        .source_line = source_line,
    });
}

pub fn emitPrint(code : *BytecodeChunk, source_line : usize, 
                 rs1 : reg_t, mode : PrintMode) !void {
    try emitOpcode(code, source_line, .OP_PRINT);
    try code.*.text.append(.{
        .byte = @enumToInt(mode),
        .source_line = source_line,
    });
    try emitRegister(code, source_line, rs1);
}