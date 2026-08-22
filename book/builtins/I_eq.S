[BITS 64]
mov rsi, [rsp + 24];
mov rdx, [rsi];
mov rsi, [rsp + 16];
cmp rdx, [rsi];
mov rsi, [rsp + 8];
mov r9, 1;
xor r10, r10;
cmove r8, r9;
cmovne r8, r10;
mov [rsi], r8
ret;

