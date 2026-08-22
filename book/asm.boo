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

f AW_idx(wr: AsmWriter) {
    r S_len(wr.buf);
}

f AW_write(wr: &AsmWriter, data: S) {
    wr.buf = S_concat(wr.buf, data);
}

f AW_emit_builtin_function(wr: &AsmWriter, ident: S, fn: BuiltinFunction) {
    l idx = AW_idx(wr);
    Map_insert(&wr.jumps, ident, idx);
    AW_write(&wr, fn.asm);
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
    r -1;
}

f AW_mov_constant_int_to_local(wr: &AsmWriter, dst_idx: I, dst_offset: I, value: I) {
    // Write a constant value to an offset within a stack variable
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

f AW_create_constant(wr: &AsmWriter, data: S) -> I {
    // Create constant and return index that people can use to call AW_load_constant
    // Could emit relative jmp with length of data and then emit data and store the
    // offset of the constant to AsmWriter somewhere to be used from AW_load_constant
}

f AW_load_constant(wr: &AsmWriter, reg: Reg, constant_idx: I) {
    // Emit enough dummy bytes to fit an imm64 mov, and add
    // the location of the first byte to constant_loads
}

f AW_push_argument_ptr(wr: &AsmWriter, local_idx: I) {
    // Push address to local onto stack as a function argument
}

f AW_expand_stack(wr: &AsmWriter, sz: I) {
    // Instructions to expand stack
}

f AW_shrink_stack(wr: &AsmWriter, sz: I) {
    // Instructions to shrink stack
}

f AW_call(wr: &AsmWriter, symbol: S) {
    // If symbol in jumps, emit concrete call instr
    // Otherwise, emit space for call instr
    l lookup = Map_get<I>(wr.jumps, symbol);
    i (Opt_is_some<I>(lookup)) {
        l addr = V_get<I>(lookup.value, 0);
        l code = S_concat(S_concat(S_new_from_char(I_chr(0xb8)), I_u32_to_bytes(addr)), I_u16_to_bytes(0xd0ff));
    } e {
        l addr = 0xffffffff;
        l code = S_concat(S_concat(S_new_from_char(I_chr(0xb8)), I_u32_to_bytes(addr)), I_u16_to_bytes(0xd0ff));
        l offset = I_add(S_length(wr.buf), 1);
        l cur_pending = Map_get<V<I>>(wr.pending_jumps, symbol);
        i (Opt_is_some<V<I>>(cur_pending)) {
            l pending = cur_pending.value[0];
            Map_insert(wr.pending_jumps, V_push<I>(pending, offset));
        } e {
            l pending = V_new<I>();
            Map_insert(wr.pending_jumps, V_push<I>(pending, offset));
        }
    }
    wr.buf = S_concat(wr.buf, code);
}
