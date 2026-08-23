[BITS 64]
mov rsi, [rsp + 24];
mov rax, [rsi];
mov rsi, [rsp + 16];
mov rdx, [rsi];
div rdx; rax = rax / rdx
mov rdx, rax;
; malloc(8)
mov rdi, 0x8;
mov rax, 0x400000;
mov [rax], rdx;
ret;
