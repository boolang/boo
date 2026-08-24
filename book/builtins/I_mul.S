[BITS 64]
mov rsi, [rsp + 8];
mov rdx, [rsi];
mov rsi, [rsp + 16];
imul rdx, [rsi];
push rdx;
mov rdi, 0x8;
mov rax, 0x400000;
call rax;
pop rdx;
mov [rax], rdx;
ret;
