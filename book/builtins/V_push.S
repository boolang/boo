; f V_push<T>(vec: &V<T>, element: T)
[BITS 64]
    mov rdi, [rsp + 8];
    mov rsi, [rdi + 8];
    mov rdx, [rdi + 16];
    cmp rsi, rdx;
    jl append;

    ; resize
    ; r10 = old_buf, rax = new_buffer
    mov r10, [rdi];
    ; alloc new buffer
    mov rdi, rdx;
    shl rdi, 1;
    mov r11, rdi;
    mov rax, 0x400000;
    call rax;
    ; store new buf and cap;
    mov rdi, [rsp + 8];
    mov [rdi], rax;
    mov [rdi + 16], r11;
    ; r9 in 0..rdx, rdx > 0 because V_new sets it to 16
    mov r9, 0;
loop:
    ; copy
    mov r12, [r10];
    mov [rax], r12;
    ; inc pointers etc
    inc r10;
    inc rax;
    inc r9;
    cmp r9, rdx;
    jl loop;

append:
    ; get cell
    mov rdi, [rsp + 8];
    mov rsi, [rdi];
    mov rdx, [rdi + 8];
    lea rax, [rsi * 8 + rdx]
    ; get element and set
    mov rdi, [rsp + 16];
    mov [rax], rdi;
    ; inc size
    mov rdi, [rsp + 8];
    inc rdx;
    mov [rdi + 8], rdx;
    ret;
