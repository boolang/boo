; f V_len<T>(vec: &V<T>) -> I
[BITS 64]
    ; allocate space for return value
    mov rdi, 0x8;
    mov rax, 0x400000;
    call rax;

    mov rdi, [rsp + 8];
    mov rdi, [rdi + 8];
    mov [rax], rdi;
    ret
