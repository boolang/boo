[BITS 64]
mov rsi, [rsp + 24];
mov rdx, [rsi];
mov rsi, [rsp + 16];
add rdx, [rsi];
mov rsi, [rsp + 8];
mov [rsi], rdx;
ret;
