; f S_get(string: S, idx: I) -> C
[BITS 64]
    ; allocate space for the return value
    mov rdi, 0x8;
    mov rax, 0x400000;
    call rax;

    ; get idx
    mov rsi, [rsp + 16];
    mov rsi, [rsi];

    ; get ptr to char
    mov rdi, [rsp + 8];
    mov rdi, [rdi];
    add rdi, rsi;

    ; get char and write to return allocation
    xor rcx, rcx;
    mov cl, [rdi];
    mov [rax], rcx;
    
    ret;
