; f V_set<T>(vec: &V<T>, idx: I, new_value: T)
[BITS 64]
    mov rdi, [rsp + 8];
    mov rsi, [rdi];
    mov rdi, [rsp + 16];
    mov rdx, [rdi];
    ; get address of cell in buf
    lea rax, [rdx * 8 + rsi]
    ; store pointer that is new_value into location
    mov rdi, [rsp + 24];
    mov [rax], rdi;
    ret
