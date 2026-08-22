[BITS 64]
mov rdi, [rsp + 16];
mov rdx, [rdi];
mov rdi, [rsp + 8];
mov rsi, [rdi];
mov rdi, 1;
mov rax, 1;
syscall;
ret;
