; f V_get<T>(vec: &V<T>, idx: I) -> T
[BITS 64]
    mov rdi, [rsp + 8];
    mov rsi, [rdi];
    mov rdi, [rsp + 16];
    mov rdx, [rdi];
    ; yay lea
    lea rax, [rdx * 8 + rsi];
    mov rax, [rax];
    ret
