; return the concatenation of two strings.
; f S_concat(first: S, second: S) -> S
[BITS 64]
    ; compute new size
    mov rdi, [rsp + 8];
    mov rsi, [rdi + 8];
    mov rdi, [rsp + 16];
    add rsi, [rdi + 8];
    mov r11, rsi;
    ; malloc(first.size + second.size)
    mov rdi, r11;
    mov rax, 0x400000;
    call rax;
    mov r9, r11;
    mov r10, rax;
    ; malloc(10) for the new string
    mov rdi, 0x10;
    mov rax, 0x400000;
    ; buf = r10, size = first.size + second.size
    mov [rax], r10;
    mov [rax + 8], r9;

    ; now to actually copy..............
    ; r9 = new string addr + offset, rsi stores first/second str + offset, rdi stores index, r10 stores len of first/second
    mov r9, rax;

    mov rdi, [rsp + 8];
    mov r10, [rdi + 8];
    mov rdi, 0;
    cmp r10, 0;
    jz first_exit
    mov rsi, [rdi];
first_loop:
    mov rdx, [rsi];
    mov [r9], rdx;
    inc r9;
    inc rsi;
    inc rdi;
    cmp rdi, r10;
    jl first_loop;
first_exit:

    mov rdi, [rsp + 16];
    mov r10, [rdi + 8];
    mov rdi, 0;
    cmp r10, 0;
    jz second_exit
    mov rsi, [rdi];
second_loop:
    mov rdx, [rsi];
    mov [r9], rdx;
    inc r9;
    inc rsi;
    inc rdi;
    cmp rdi, r10;
    jl second_loop;
second_exit:
    ; rax is still set!
    ret
