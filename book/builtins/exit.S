[BITS 64]
mov rdi, [rsp + 8];
mov rdi, [rdi];
mov rax, 60;
syscall;
