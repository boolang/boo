; f S_len(string: S) -> I
[BITS 64]
    mov rax, [rsp + 8];
    ; the length is stored at a +8 offset of the string buffer!
    add rax, 8;
    ret;
