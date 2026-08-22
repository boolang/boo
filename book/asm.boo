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

f AW_idx(wr: AsmWriter) -> I {
    r S_len(wr.buf);
}

f AW_write(wr: &AsmWriter, data: S) {
    wr.buf = S_concat(wr.buf, data);
}

f AW_emit_builtin_function(wr: &AsmWriter, ident: S, fn: BuiltinFunction) {
    l fn_idx = AW_idx(wr);
    Map_insert<I>(&wr.jumps, ident, fn_idx);
    AW_write(&wr, fn.asm);

    // Fill in pending jumps
    l addr = I_add(fn_idx, wr.base_addr);
    l lookup = Map_get<V<I>>(wr.pending_jumps, ident);
    i (O_is_some<V<I>>(lookup)) {
        l offsets = O_get<V<I>>(lookup);
        v idx = 0;
        w (I_lt(idx, V_len<I>(offsets))) {
            l offset = V_get<I>(offsets, idx);
            print("Emitting relocation");
            S_set_range(&wr.buf, offset, I_u32_to_bytes(addr));

            idx = I_add(idx, 1);
        }
    }
}

f AW_emit_dummy_function_prelude(wr: &AsmWriter, ident: S) {
    l fn_idx = AW_idx(wr);

    // Fill in pending jumps
    l addr = I_add(fn_idx, wr.base_addr);
    l lookup = Map_get<V<I>>(wr.pending_jumps, ident);
    i (O_is_some<V<I>>(lookup)) {
        l offsets = O_get<V<I>>(lookup);
        v idx = 0;
        w (I_lt(idx, V_len<I>(offsets))) {
            l offset = V_get<I>(offsets, idx);
            print("Emitting relocation");
            S_set_range(&wr.buf, offset, I_u32_to_bytes(addr));

            idx = I_add(idx, 1);
        }
    }

    // Emit space for instructions to create stack frame and set
    // function_prelude_location
    //  0:   c8 67 67 00             enter  $0x6767,$0x0
    v code = S_new_from_char(I_chr(0xc8));
    // Dummy value to replace
    code = S_concat(code, I_u16_to_bytes(0x4141));
    code = S_push(code, I_chr(0));
    wr.function_prelude_location = I_add(fn_idx, 1);
    AW_write(&wr, code);
}

f AW_finalize_function(wr: &AsmWriter) {
    // Add up 'locals' to figure out stack frame size. Emit function prelude
    // to function_prelude_location
    v frame_size = 0;
    l nlocals = V_len<Local>(wr.locals);
    i (I_gt(nlocals, 0)) {
        l last_local = V_get<Local>(wr.locals, I_sub(nlocals, 1));
        frame_size = I_add(last_local.offset, last_local.size);
    }

    S_set_range(&wr.buf, wr.function_prelude_location, I_u16_to_bytes(frame_size));

    //  0:   c9                      leave
    //  1:   c3                      ret
    AW_write(&wr, I_u16_to_bytes(0xc3c9));
}

f AW_create_local(wr: &AsmWriter, name: S, size: I) -> I {
    // Add to locals and return the local index
    v offset = 0;
    l local_count = V_len<Local>(wr.locals);
    i (I_gt(local_count, 0)) {
        offset = V_get<Local>(wr.locals, I_sub(local_count, 1)).offset;
    }
    l local = Local {
        name: name,
        size: size,
        offset: offset
    };
    V_push<Local>(&wr.locals, local);
    r local_count;
}

f AW_local_rbp_offset(wr: AsmWriter, local_idx: I, offset: I) -> I {
    l var = V_get<Local>(wr.locals, local_idx);
    // RBP addressing is backwards, which makes this a bit weird
    r I_add(var.offset, I_sub(var.size, offset));
}

f AW_mov_constant_int_to_local(wr: &AsmWriter, dst_idx: I, dst_offset: I, value: I) {
    // Write a constant value to an offset within a stack variable
    //  0:   48 b8 67 67 67 67 67    movabs $0x6767676767676767,%rax
    //  7:   67 67 67
    //  a:   48 89 85 ff ff 44 44    mov    %rax,0x4444ffff(%rbp)
    v code = I_u16_to_bytes(0xb848);
    l offset = AW_local_rbp_offset(wr, dst_idx, dst_offset);
    code = S_concat(code, I_u64_to_bytes(value));
    code = S_concat(code, I_u16_to_bytes(0x8948));
    code = S_push(code, I_chr(0x85));
    code = S_concat(code, I_u32_to_bytes(offset));
    AW_write(&wr, code);
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
    l offset = AW_local_rbp_offset(wr, local_idx, 0);

    //  0:   48 8d 85 67 67 00 00    lea    0x6767(%rbp),%rax
    //  7:   50                      push   %rax
    v code = S_push(I_u16_to_bytes(0x8d48), I_chr(0x85));
    code = S_concat(code, I_i32_to_bytes(offset));
    code = S_push(code, I_chr(0x50));
    AW_write(&wr, code);
}

f AW_expand_stack(wr: &AsmWriter, sz: I) {
    // Instructions to expand stack
}

f AW_shrink_stack(wr: &AsmWriter, sz: I) {
    // Instructions to shrink stack
}

// Pushes to the vector under the given key. If the map doesn't
// contain the key, it creates a new vector under the key.
f Map_V_push<T>(map: &Map<V<T>>, key: S, value: T) {
    l vec = Map_get<V<T>>(map, key);
    i (O_is_some<V<T>>(vec)) {
        v new_vec = O_get<V<T>>(vec);
        V_push<T>(&new_vec, value);
        Map_insert<V<T>>(&map, key, new_vec);
    } e {
        v new_vec = V_new<T>();
        V_push<T>(&new_vec, value);
        Map_insert<V<T>>(&map, key, new_vec);
    }
}

f encode_mov_rax(value: I) -> S {
    r S_concat(S_new_from_char(I_chr(0xb8)), I_u32_to_bytes(value));
}

f AW_call(wr: &AsmWriter, symbol: S) {
    // If symbol in jumps, emit concrete call instr
    // Otherwise, emit space for call instr
    l lookup = Map_get<I>(wr.jumps, symbol);
    v addr = 0x41414141;
    i (O_is_some<I>(lookup)) {
        addr = I_add(O_get<I>(lookup), wr.base_addr);
    } e {
        // Save offset for later
        l offset = I_add(S_length(wr.buf), 1);
        Map_V_push<I>(&wr.pending_jumps, symbol, offset);
    }

    l code = S_concat(encode_mov_rax(addr), I_u16_to_bytes(0xd0ff));
    AW_write(&wr, code);
}
