const BytecodeChunk = @import("bytecode.zig").BytecodeChunk;
const mnemonic = @import("bytecode.zig").mnemonic;
const Opcode = @import("bytecode.zig").Opcode;

// Machine consists of:
// - header
//   - dispatcher width
//   - record width
//   - # of records
//   - # of states
//   - index of the start state
// - bootstrapper
//   1. Load start state index to register r0
//   2. Move $mbp to the start of the first state-record
//   3. Goto state at index r0 — "gst r0"
// - controller: array of state-rules, each consisting of
//   - dispatcher:
//     1. Load *(%th) to register r0 — "read r0"
//     2. Calculate offset of target record based on *(%th), place in r0
//     4. Goto record at that offset from current $mp — "skip r0"
//   - records:
//    *1. Write immediate char to *(%th) — "writ IMM"
//    *2. Move tape head — "movr", "movl"
//     3. Either:
//       A) Goto state at index immediate — "gst IMM"
//       B) Terminate execution — "accept", "reject"

// Execution environment:
//   Special registers:
//    - $ip (instruction pointer)
//    - $mp (machine pointer)
//    - $mbp (machine base pointer) (??? mb eventually replace, like $ebp in C)
//    - $thp (tape head pointer)
//    - $tbp (tape base pointer) (VERY necessary, cannot compile-time determine this offset lmao)
//   Consumed general-purpose registers:
//    - r0: primary working register
//    - r1: auxiliary working register (freely modified)
//    - r2: return value ­­— reject (0) / accept (1)
//    - r3: return value — final state
//   Structures:
//    - Common Machine Tape


/// Temporary definition until I get to dealing with the variable-width records and such
/// Eventual definition will need to have generic widths for dispatchers/records
pub const TuringMachine = packed struct {
    pub const Header = struct {
        pub const dispatch_width : usize = 8;
        pub const record_width : usize = 8;
        pub const n_records : usize = 256;     // |Σ| = |Γ|
        pub const n_states : usize;            // |Q \ {ACCEPT, REJECT}|
        pub const start_state : usize;         // q_0
    };

    pub const State = struct {
        pub const dispatcher : [8]u8;
        pub var records : [256]([8]u8);
    };

    pub const header : Header;
    pub const bootstrapper : [8]u8;
    pub const controller : []State;
};


// TODO Maybe split the logical representations (i.e. those not directly mapping to on-disk bytes) off into their own file?
const MachineAction = enum(u8) {
    Invalid,
    HaltReject,
    HaltAccept,
    MoveLeft,
    MoveRight,
}

CharDiscriminator : type = fn(u8)struct{write_sym : u8, action : MachineAction};