; f V_push<T>(vec: &V<T>, element: T)
[BITS 64]
    mov rdi, [rsp + 8];
    ; read size
    mov rsi, [rdi + 8];
    ; read capacity
    mov rdx, [rdi + 16];
    cmp rsi, rdx;
    jl append;

    ; resize
    ; r10 = old_buf, rax = new_buffer
    ; alloc new buffer
    mov rdi, rdx;
    shl rdi, 1;
    push rdi;
    mov rax, 0x400000;
    call rax;
    pop rdi;

    ; store new buf and cap; save old buf to rdi
    mov rsi, [rsp + 8];
    mov rdi, [rsi];
    mov [rsi], rax;
    mov [rsi + 16], rdi;

    ; copy rdx bytes from rdi to rax with r9 as index
    mov rdx, [rsi + 8];
    mov r9, 0;
loop:
    ; copy
    mov r10, [rdi];
    mov [rax], r10;

    ; inc pointers etc
    inc rdi;
    inc rax;
    inc r9;
    cmp r9, rdx;
    jl loop;

append:
    ; get cell
    mov rdi, [rsp + 8];
    mov rsi, [rdi];
    mov rdx, [rdi + 8];
    lea rax, [rdx * 8 + rsi];

    ; get element and set
    mov rsi, [rsp + 16];
    mov [rax], rsi;

    ; inc size
    inc rdx;
    mov [rdi + 8], rdx;
    ret
