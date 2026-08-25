; malloc does not conform to the boo abi, and should only called in codegen!
; though... nothing bad would happen if a program did call malloc
; abi: rdi stores size, rax returns the address
;      also will nuke rsi and r9 sorry

[BITS 64]
    ; r9 now stores the buffer address
    mov rdi, 32;
    mov rsi, rdi;
    lea r9, [rel buf];
    ; PLEASE nasm make this a relative jump PLEASE
    jmp short after_buf;
buf:
    ; this buffer can just sit in the middle of the code since we're RWX :3
    dq 0;
after_buf:

    ; if the stored address is zero we don't know the breakpoint, so we call brk(0) to get it
    mov rdi, [r9];
    cmp rdi, 0;
    jnz non_zero_addr;

    ; brk(0)
    xor rdi, rdi;
    mov rax, 12;
    push r9;
    syscall;
    pop r9;
    mov [r9], rax;

non_zero_addr:
    ; brk(addr + size + 8);
    mov rdi, rsi;
    add rdi, [r9];
    add rdi, 8;
    mov rax, 12;
    push r9;
    syscall;
    pop r9;
    mov [r9], rax;

    ; write size to addr
    mov rdi, rax;
    sub rdi, rsi;
    sub rdi, 8;
    mov [rdi], rsi;

    ; return addr + 8
    sub rax, rsi;

    ret;
