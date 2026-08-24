[BITS 64]
mov rsi, [rsp + 8];
mov rdx, [rsi];
push rdx;

; malloc string buffer
mov rdi, 0x1;
mov rax, 0x400000;
call rax;

; place char in string buffer
pop rdx;
mov [rax], dl;

; make string
mov rdi, rax;
mov rsi, 0x1;
mov rax, 0x400007;
call rax;

ret;
