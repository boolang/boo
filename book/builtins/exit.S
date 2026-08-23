[BITS 64]
mov rdi, [rsp + 16];
mov rdi, [rdi];
mov rax, 60;
syscall;
