; Technically not needed to be an assembly routine but it's way faster this way
[BITS 64]
    ; malloc(0x10);
    mov rdi, 0x10;
    mov rax, 0x400000;
    call rax;

    ; r9 = offset
    mov rdi, [rsp + 16];
    mov r9, [rdi];
    
    mov rdi, [rsp + 8];
    mov rsi, [rdi];
    add rsi, r9;
    mov [rax], rsi;
    mov rsi, [rdi + 8];
    sub rsi, r9;
    mov [rax + 8], rsi;

    ret
