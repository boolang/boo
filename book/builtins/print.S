; f print(string: S)
[BITS 64]
; get string pointer from stack
mov rdi, [rsp + 8];
mov rdx, [rdi + 8];
mov rsi, [rdi];
mov rdi, 1;
mov rax, 1;
syscall;
mov rdx, 1;
lea rsi, [rel buf];
mov rdi, 1;
mov rax, 1;
syscall;
ret;
buf:
    db 0x0a
