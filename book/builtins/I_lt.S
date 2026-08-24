[BITS 64]
mov rdi, 8;
mov rax, 0x400000;
call rax;
xor rcx, rcx;
mov rsi, [rsp + 8];
mov rdx, [rsi];
mov rsi, [rsp + 16];
cmp rdx, [rsi];
setl cl;
mov [rax], rcx;
ret;
