[BITS 64]
mov rsi, [rsp + 8];
mov rdx, [rsi];
neg rdx;
push rdx;
mov rdi, 0x8;
mov rax, 0x400000;
call rax;
pop rdx;
mov [rax], rdx;
ret;
