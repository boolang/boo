; f S_len(string: S) -> I
[BITS 64]
    ; the length is stored at a +8 offset of the string buffer!
    mov rax, [rsp + 8];
    add rax, 8;
    ret;
