s Constant {
    content: S
}

s Local {
    name: S,
    size: I,
    offset: I
}

s AsmWriter {
    base_addr: I,
    buf: S,
    // Maps symbol names to absolute offsets
    jumps: MMap<I>,
    // Stores locations of jumps that are waiting to be rewritten to the given block.
    pending_jumps: MMap<V<I>>,
    function_prelude_location: I,
    locals: V<Local>,
}

f AW_idx(wr: AsmWriter) -> I {
    r S_len(wr.buf);
}

f AW_write(wr: &AsmWriter, data: S) {
    wr.buf = S_concat(wr.buf, data);
}

f AW_emit_builtin_function(wr: &AsmWriter, ident: S, fn: BuiltinFunction) {
    l fn_idx = AW_idx(wr);
    MMap_insert<I>(&wr.jumps, MMKey { ident: ident, generic_args: V_new<Type>() }, fn_idx);
    AW_write(&wr, fn.asm);

    // Fill in pending jumps
    l addr = I_add(fn_idx, wr.base_addr);
    l lookup = MMap_get<V<I>>(wr.pending_jumps, MMKey { ident: ident, generic_args: V_new<Type>() });
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

f AW_begin_function(wr: &AsmWriter, key: MMKey) {
    l fn_idx = AW_idx(wr);

    // Fill in pending jumps
    l addr = I_add(fn_idx, wr.base_addr);
    l lookup = MMap_get<V<I>>(wr.pending_jumps, key);
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
    wr.locals = V_new<Local>();
    AW_write(&wr, code);
}

f AW_finalize_function(wr: &AsmWriter, is_main: B) {
    // Add up 'locals' to figure out stack frame size. Emit function prelude
    // to function_prelude_location
    v frame_size = 0;
    l nlocals = V_len<Local>(wr.locals);
    i (I_gt(nlocals, 0)) {
        l last_local = V_get<Local>(wr.locals, I_sub(nlocals, 1));
        frame_size = I_add(last_local.offset, last_local.size);
    }

    S_set_range(&wr.buf, wr.function_prelude_location, I_u16_to_bytes(frame_size));

    i (is_main) {
        AW_exit(&wr, 0);
    } e {
        //  0:   c9                      leave
        //  1:   c3                      ret
        AW_write(&wr, I_u16_to_bytes(0xc3c9));
    }

    wr.locals = V_new<Local>();
}

f AW_exit(wr: &AsmWriter, status: I) {
    l idx = AW_create_heap_local(&wr, "exit_status", 8);
    AW_mov_constant_int_to_heap_local(&wr, idx, status);
    AW_mov_local_to_rax(&wr, idx);
    AW_push_argument_from_rax(&wr);
    AW_call(&wr, MMKey_new("exit"));
}

f AW_create_arg_local(wr: &AsmWriter, name: S, idx: I, size: I) -> I {
    // Add to locals and return the local index
    l local = AW_create_local(&wr, name, size);
    //  0:   48 8b 85 99 98 ff ff    mov    -0x6767(%rbp),%rax
    l offset = I_mul(idx, 8);
    v code = I_u16_to_bytes(0x8b48);
    code = S_push(code, I_chr(0x85));
    code = S_concat(code, I_i32_to_bytes(offset));
    AW_write(&wr, code);
    AW_mov_rax_to_local(&wr, local);
    r local;
}

f AW_create_local(wr: &AsmWriter, name: S, size: I) -> I {
    // Add to locals and return the local index
    v offset = 0;
    l local_count = V_len<Local>(wr.locals);
    i (I_gt(local_count, 0)) {
        l last_var = V_get<Local>(wr.locals, I_sub(local_count, 1));
        offset = I_add(last_var.offset, last_var.size);
    }
    l local = Local {
        name: name,
        size: size,
        offset: offset
    };
    V_push<Local>(&wr.locals, local);

    r local_count;
}

f AW_create_heap_local(wr: &AsmWriter, name: S, size: I) -> I {
    l idx = AW_create_local(&wr, name, 8);
    AW_malloc(&wr, size);
    AW_mov_rax_to_local(&wr, idx);
    r idx;
}

f AW_local_rbp_offset(wr: AsmWriter, local_idx: I, offset: I) -> I {
    l var = V_get<Local>(wr.locals, local_idx);
    // RBP addressing is backwards, which makes this a bit weird
    r I_add(var.offset, I_sub(var.size, offset));
}

f AW_mov_constant_int_to_local(wr: &AsmWriter, dst_idx: I, value: I) {
    // Write a constant value to an offset within a stack variable
    //  0:   48 b8 67 67 67 67 67    movabs $0x6767676767676767,%rax
    //  7:   67 67 67
    v code = I_u16_to_bytes(0xb848);
    code = S_concat(code, I_u64_to_bytes(value));
    AW_write(&wr, code);

    AW_mov_rax_to_local(&wr, dst_idx);
}

f AW_mov_constant_int_to_heap_local(wr: &AsmWriter, dst_idx: I, value: I) {
    // Write a constant value to an offset within a stack variable
    //  0:   48 b8 67 67 67 67 67    movabs $0x6767676767676767,%rax
    //  7:   67 67 67
    v code = I_u16_to_bytes(0xb848);
    code = S_concat(code, I_u64_to_bytes(value));
    AW_write(&wr, code);

    AW_mov_local_to_rbx(&wr, dst_idx);
    AW_mov_rax_to_rbx_ptr(&wr);
}

// f AW_mov_rbx_to_rax(wr: &AsmWriter) {
//     
// }
// 

f AW_mov_rax_to_rbx_ptr(wr: &AsmWriter) {
    //  0:   48 89 03                mov    %rax,(%rbx)
    l code = S_push(I_u16_to_bytes(0x8948), I_chr(0x03));
    AW_write(&wr, code);
}

f AW_mov_local_to_rbx(wr: &AsmWriter, local_idx: I) {
    l offset = AW_local_rbp_offset(wr, local_idx, 0);
    AW_mov_stack_to_rbx(&wr, I_neg(offset));
}

f AW_mov_rax_to_local(wr: &AsmWriter, dst_idx: I) {
    //  a:   48 89 85 ff ff 44 44    mov    %rax,0x4444ffff(%rbp)
    l offset = AW_local_rbp_offset(wr, dst_idx, 0);
    v code = I_u16_to_bytes(0x8948);
    code = S_push(code, I_chr(0x85));
    code = S_concat(code, I_i32_to_bytes(I_neg(offset)));
    AW_write(&wr, code);
}

f AW_mov_rax_to_heap_local(wr: &AsmWriter, dst_idx: I, dst_offset: I) {
    //  0:   48 8b 9d ff ff 44 44    mov    0x4444ffff(%rbp),%rbx
    AW_mov_local_to_rbx(&wr, dst_idx);

    //  7:   48 89 83 55 55 55 55    mov    %rax,0x55555555(%rbx)
    v code = I_u16_to_bytes(0x8948);
    code = S_push(code, I_chr(0x83));
    code = S_concat(code, I_i32_to_bytes(dst_offset));
    AW_write(&wr, code);
}

// Assuming that rax holds a pointer, add a constant offset to the pointer and deref it
f AW_deref_rax(wr: &AsmWriter, offset: I) {
    //  0:   48 8b 80 42 42 41 41    mov    0x41414242(%rax),%rax
    v code = I_u16_to_bytes(0x8b48);
    code = S_push(code, I_chr(0x80));
    code = S_concat(code, I_i32_to_bytes(offset));
    AW_write(&wr, code);
}

// Assuming that rbx holds a pointer, add a constant offset to the pointer and deref it
f AW_deref_rbx(wr: &AsmWriter, offset: I) {
    //  0:   48 8b 9b 42 42 41 41    mov    0x41414242(%rbx),%rbx
    v code = I_u16_to_bytes(0x8b48);
    code = S_push(code, I_chr(0x9b));
    code = S_concat(code, I_i32_to_bytes(offset));
    AW_write(&wr, code);
}

f AW_str_literal_to_rdi(wr: &AsmWriter, literal: S) {
    // 0:   48 8d 3d 05 00 00 00    lea    0x5(%rip),%rdi        # 0xc
    // 7:   e9 00 01 00 00          jmp    0x10c

    v code = I_u32_to_bytes(0x053d8d48);
    code = S_concat(code, I_u32_to_bytes(0xe9000000));
    code = S_concat(code, I_u32_to_bytes(S_len(literal)));
    code = S_concat(code, literal);
    AW_write(&wr, code);
}

f AW_write_mov_rsi(wr: &AsmWriter, value: I) {
    //  0:   48 be 67 67 67 67 67    movabs $0x6767676767676767,%rsi
    //  7:   67 67 67
    l code = S_concat(I_u16_to_bytes(0xbe48), I_u64_to_bytes(value));
    AW_write(&wr, code);
}

f AW_write_mov_rdi(wr: &AsmWriter, value: I) {
    //  0:   48 bf 67 67 67 67 67    movabs $0x6767676767676767,%rdi
    //  7:   67 67 67
    l code = S_concat(I_u16_to_bytes(0xbf48), I_u64_to_bytes(value));
    AW_write(&wr, code);
}

f AW_make_string(wr: &AsmWriter, literal: S) {
    AW_str_literal_to_rdi(&wr, literal);
    AW_write_mov_rsi(&wr, S_len(literal));
    AW_call(&wr, MMKey_new("make_str"));
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

f AW_create_jump(wr: &AsmWriter, dst_offset: I) {
    // Emit an unconditional jump to the given offset
    l addr = I_add(dst_offset, wr.base_addr);
    l code = S_concat(encode_mov_rax(addr), I_u16_to_bytes(0xe0ff));
    AW_write(&wr, code);
}

f AW_create_overwritable_jump(wr: &AsmWriter) -> I {
    // Emit a dummy jump and return the index of an overwriteable jump offset
    l offset = I_add(AW_idx(wr), 1);
    l code = S_concat(encode_mov_rax(0xdeadbeef), I_u16_to_bytes(0xe0ff));
    AW_write(&wr, code);
    r offset;
}

f AW_mov_uconst_to_rbx(wr: &AsmWriter, value: I) {
    //  0:   48 bb ef be ad de ef    movabs $0xdeadbeefdeadbeef,%rbx
    //  7:   be ad de
    l code = S_concat(I_u16_to_bytes(0xbb48), I_u64_to_bytes(value));
    AW_write(&wr, code);
}

f AW_cmp_rax_to_uconst(wr: &AsmWriter, value: I) {
    //  a:   48 39 d8                cmp    %rbx,%rax
    AW_mov_uconst_to_rbx(&wr, value);
    l code = S_concat(I_u16_to_bytes(0x3948), S_new_from_char(I_chr(0xd8)));
    AW_write(&wr, code);
}

// Expects condition to be pointed to by RAX (hence 'deref')
f AW_create_overwritable_rax_jz_deref(wr: &AsmWriter) -> I {
    // Emit a dummy jump-if-rax-is-zero and return the index of an overwriteable jump offset
    // ba ef be ad de 80 38 00 75 02 ff e2 (cmp [rax], 0)
    // ba ef be ad de 48 83 f8 00 75 02 ff e2 (cmp rax, 0)
    l offset = I_add(AW_idx(wr), 1);
    l code = S_concat(I_u64_to_bytes(0x003880deadbeefba), I_u32_to_bytes(0xe2ff0275));
    // l code = S_push(S_concat(I_u64_to_bytes(0xf88348deadbeefba), I_u32_to_bytes(0xff027500)), I_chr(0xe2));
    AW_write(&wr, code);
    r offset;
}

// Expects comparison to already have been done (unlike AW_create_overwritable_rax_jz_deref which also derefs rax and performs a cmp)
f AW_create_overwritable_jnz(wr: &AsmWriter) -> I {
    // Emit a dummy jump-if-rax-is-not-zero and return the index of an overwriteable jump offset
    //  0:   ba ef be ad de          mov    $0xdeadbeef,%edx
    //  5:   74 02                   je     0x9
    //  7:   ff e2                   jmp    *%rdx
    l offset = I_add(AW_idx(wr), 1);
    l code = S_concat(I_u64_to_bytes(0xff027467676767ba), S_new_from_char(I_chr(0xe2)));
    AW_write(&wr, code);
    r offset;
}

f AW_overwrite_jump(wr: &AsmWriter, instr: I, dst_offset: I) {
    l addr = I_add(dst_offset, wr.base_addr);
    S_set_range(&wr.buf, instr, I_u32_to_bytes(addr));
}

f AW_mov_stack_to_rax(wr: &AsmWriter, rbp_offset: I) {
    v code = I_u16_to_bytes(0x8b48);
    code = S_push(code, I_chr(0x85));
    code = S_concat(code, I_i32_to_bytes(rbp_offset));
    AW_write(&wr, code);
}

f AW_mov_stack_to_rbx(wr: &AsmWriter, rbp_offset: I) {
    //  0:   48 8b 9d 99 98 ff ff    mov    -0x6767(%rbp),%rbx
    v code = I_u16_to_bytes(0x8b48);
    code = S_push(code, I_chr(0x9d));
    code = S_concat(code, I_i32_to_bytes(rbp_offset));
    AW_write(&wr, code);
}

f AW_mov_local_to_rax(wr: &AsmWriter, local_idx: I) {
    //  0:   48 8b 85 99 98 ff ff    mov    -0x6767(%rbp),%rax
    l offset = AW_local_rbp_offset(wr, local_idx, 0);
    AW_mov_stack_to_rax(&wr, I_neg(offset));
}

f AW_push_argument_from_rax(wr: &AsmWriter) {
    // Push address to local onto stack as a function argument

    //  7:   50                      push   %rax
    AW_write(&wr, S_new_from_char(I_chr(0x50)));
}

f AW_expand_stack(wr: &AsmWriter, sz: I) {
    // Instructions to expand stack
}

f AW_shrink_stack(wr: &AsmWriter, sz: I) {
    // Instructions to shrink stack
    v code = "";
    v idx = 0;
    // 0:  5b      pop rax
    // repeated sz times
    w (I_lt(I_mul(idx, 8), sz)) {
        code = S_push(code, I_chr(0x5b));
        idx = I_add(idx, 1);
    }
    AW_write(&wr, code);
}

f AW_malloc(wr: &AsmWriter, sz: I) {
    AW_write_mov_rdi(&wr, sz);
    AW_call(&wr, MMKey_new("malloc"));
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

f MMap_V_push<T>(map: &MMap<V<T>>, key: MMKey, value: T) {
    l vec = MMap_get<V<T>>(map, key);
    i (O_is_some<V<T>>(vec)) {
        v new_vec = O_get<V<T>>(vec);
        V_push<T>(&new_vec, value);
        MMap_insert<V<T>>(&map, key, new_vec);
    } e {
        v new_vec = V_new<T>();
        V_push<T>(&new_vec, value);
        MMap_insert<V<T>>(&map, key, new_vec);
    }
}

f encode_mov_rax(value: I) -> S {
    r S_concat(S_new_from_char(I_chr(0xb8)), I_u32_to_bytes(value));
}

f encode_mov_rcx(value: I) -> S {
    //  0:   b9 41 41 41 41          mov    $0x41414141,%ecx
    r S_concat(S_new_from_char(I_chr(0xb9)), I_u32_to_bytes(value));
}

f AW_call(wr: &AsmWriter, symbol: MMKey) {
    // If symbol in jumps, emit concrete call instr
    // Otherwise, emit space for call instr
    l lookup = MMap_get<I>(wr.jumps, symbol);
    v addr = 0x41414141;
    i (O_is_some<I>(lookup)) {
        addr = I_add(O_get<I>(lookup), wr.base_addr);
    } e {
        // Save offset for later
        l offset = I_add(S_length(wr.buf), 1);
        MMap_V_push<I>(&wr.pending_jumps, symbol, offset);
    }

    //  a:   ff d1                   call   *%rcx
    l code = S_concat(encode_mov_rcx(addr), I_u16_to_bytes(0xd1ff));
    AW_write(&wr, code);
}

f AW_ret(wr: &AsmWriter) {
    //  0:   c9                      leave
    //  1:   c3                      ret
    AW_write(&wr, I_u16_to_bytes(0xc3c9));
}
