usingnamespace @import("bytecode.zig");

// ======
// the write* functions just write their instruction to the slice given
// ======

pub fn writeOpcode(text : []u8, opcode : Opcode) void {
    text[0] = @enumToInt(opcode);
}

pub fn writeRegister(text : []u8, reg : reg_t) void {
    text[0] = reg;
}

pub fn writeByte(text : []u8, byte : u8) void {
    text[0] = byte;
}

// Requires text have length >= 3
pub fn writePrint(text : []u8, rs1 : reg_t, mode : PrintMode) void {
    writeOpcode(text, .OP_PRINT);
    writeByte(text[1..], @enumToInt(mode));
    writeRegister(text[2..], rs1);
}

// Returns how many bytes were written
// May require up to 6 bytes of space
pub fn writeLoadImmediate(text : []u8, rd : reg_t, imm : u32) usize {
    if (imm == 0) {
        writeOpcode(text, .OP_CONST_0);
        writeRegister(text[1..], rd);
        return 2;
    } else if (imm == 1) {
        writeOpcode(text, .OP_CONST_1);
        writeRegister(text[1..], rd);
        return 2;
    } else if (imm == -1) {
        writeOpcode(text, .OP_CONST_N1);
        writeRegister(text[1..], rd);
        return 2;
    } else if (imm <= 0x000000FF) {
        writeOpcode(text, .OP_IMM_BYTE);
        writeRegister(text[1..], rd);
        writeByte(text[2..], @intCast(u8, imm & 0xFF));
        return 3;
    } else if (imm <= 0x0000FFFF) {
        writeOpcode(text, .OP_IMM_HALF);
        writeRegister(text[1..], rd);
        writeByte(text[2..], @intCast(u8, (imm >> 0) & 0xFF));
        writeByte(text[3..], @intCast(u8, (imm >> 8) & 0xFF));
        return 4;
    } else {
        writeOpcode(text, .OP_IMM_WORD);
        writeRegister(text[1..], rd);
        writeByte(text[2..], @intCast(u8, (imm >>  0) & 0xFF));
        writeByte(text[3..], @intCast(u8, (imm >>  8) & 0xFF));
        writeByte(text[4..], @intCast(u8, (imm >> 16) & 0xFF));
        writeByte(text[5..], @intCast(u8, (imm >> 24) & 0xFF));
        return 6;
    }
}

// Requires text have length >= 4
pub fn writeRegisterTAC(text : []u8, opcode : Opcode, rd : reg_t, rs1 : reg_t, rs2 : reg_t) void {
    writeOpcode(text, opcode);
    writeRegister(text[1..], rd);
    writeRegister(text[2..], rs1);
    writeRegister(text[3..], rs2);
}

// =====
// the emit* functions allocate space in the chunk, write the instruction,
// and annotate the chunk with corresponding debug information
// =====

pub fn emitByte(code : *BytecodeChunk, source_line : usize, byte : reg_t) !void {
        try code.*.text.append(byte);
        try code.*.lines.append(.{
            .source_line = source_line,
        });
}

pub fn emitPrint(code : *BytecodeChunk, source_line : usize, 
                 rs1 : reg_t, mode : PrintMode) !void {
    var text = try code.*.text.addManyAsArray(3);
    var lines = try code.*.lines.appendNTimes(.{.source_line = source_line}, 3);
    writePrint(text, rs1, mode);
}

// TODO figure out desired sign-extension behavior
pub fn emitLoadImmediate(code : *BytecodeChunk, source_line : usize,
                         rd : reg_t, imm : u32) !void {
    // Annoying to figure out what the length will be in advance,
    // so just liberally allocate to begin with then return any unused space
    const len_0 = code.*.text.items.len;
    var text = try code.*.text.addManyAsArray(6);

    const bytes_used = writeLoadImmediate(text, rd, imm);
    code.*.text.shrinkRetainingCapacity(len_0 + bytes_used);

    // TODO this ordering is bad
    var lines = try code.*.lines.appendNTimes(.{.source_line = source_line}, bytes_used);
}

pub fn emitRegisterTAC(code : *BytecodeChunk, source_line : usize, opcode : Opcode,
                       rd : reg_t, rs1 : reg_t, rs2 : reg_t) !void {
    var text = try code.*.text.addManyAsArray(4);
    var lines = try code.*.lines.appendNTimes(.{.source_line = source_line}, 4);
    writeRegisterTAC(text, opcode, rd, rs1, rs2);
}