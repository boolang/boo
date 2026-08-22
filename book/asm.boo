s Constant {
    content: S
}

s Local {
    name: S,
    size: I,
    offset: I
}

s PendingMov {
    location: I,
    reg: Reg
}

s AsmWriter {
    base_addr: I,
    buf: S,
    // Maps symbol names to absolute offsets
    jumps: Map<I>,
    // Stores locations of jumps that are waiting to be rewritten to the given block.
    pending_jumps: Map<V<I>>,
    // Movs to rewrite when we emit constants (after emitting all functions). The map
    // is keyed by integers converted to strings
    constant_loads: Map<V<PendingMov>>,
    function_prelude_location: I,
    locals: V<Local>
}

t Reg {
    Rax,
    Rdi
}

f AW_emit_dummy_function_prelude(wr: &AsmWriter) {
    // Emit space for instructions to create stack frame and set
    // function_prelude_location
}

f AW_finalize_function(wr: &AsmWriter) {
    // Add up 'locals' to figure out stack frame size. Emit function prelude
    // to function_prelude_location
}

f AW_create_local(wr: &AsmWriter, name: S, size: I) -> I {
    // Add to locals and return the local index
}

f AW_mov_local_to_local(wr: &AsmWriter, dst_idx: I, src_idx: I) {
    // Emit instructions to move from one local to another
    // Defer to AW_mov_stack
}

f AW_mov_local_to_local_field(wr: &AsmWriter, dst_idx: I, dst_offset: I, src_idx: I) {
    // Move memory from src local to an offset within a destination local
    // Source local defines size
    // Defer to AW_mov_stack
}

f AW_mov_local_field_to_local(wr: &AsmWriter, dst_idx: I, src_idx: I, src_offset: I) {
    // Move memory from an offset within a src local to a destination local
    // Destination local defines size
    // Defer to AW_mov_stack
}

f AW_mov_stack(wr: &AsmWriter, dst_offset: I, src_offset: I, sz: I) {
    // Move from src offset within stack frame to dst offset within stack frame
}

f AW_mov_const(wr: &AsmWriter, reg: Reg, val: I) {
    // Move a concrete imm64 to the reg
}

f AW_create_constant(wr: &AsmWriter, data: S) -> I {
    // Create constant and return index that people can use to call AW_load_constant
    // Could emit relative jmp with length of data and then emit data and store the
    // offset of the constant to AsmWriter somewhere to be used from AW_load_constant
}

f AW_load_constant(wr: &AsmWriter, reg: Reg, constant_idx: I) {
    // Emit enough dummy bytes to fit an imm64 mov, and add
    // the location of the first byte to constant_loads
}

f AW_store_reg_to_local(wr: &AsmWriter, dst_idx: I, dst_offset: I, reg: Reg) {
    // Defer to AW_store_reg_to_stack
}

f AW_store_local_to_reg(wr: &AsmWriter, reg: Reg, src_idx: I, src_offset: I) {
    // Defer to AW_store_stack_to_reg
}

f AW_store_reg_to_stack(wr: &AsmWriter, dst_offset: I, reg: Reg) {
    // Store reg to stack from offset
}

f AW_store_stack_to_reg(wr: &AsmWriter, reg: Reg, src_offset: I) {
    // Load reg from stack frame offset
}

f AW_expand_stack(wr: &AsmWriter, sz: I) {
    // Instructions to expand stack
}

f AW_shrink_stack(wr: &AsmWriter, sz: I) {
    // Instructions to shrink stack
}

f AW_mov_reg(wr: &AsmWriter, dst: Reg, src: Reg) {
    // Emit instructions directly
}

f AW_call(wr: &AsmWriter, symbol: S) {
    // If symbol in jumps, emit concrete call instr
    // Otherwise, emit space for call instr
}
