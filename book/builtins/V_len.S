; f V_len<T>(vec: &V<T>) -> I
[BITS 64]
    mov rdi, [rsp + 8];
    mov rax, [rdi + 8];
    ret
