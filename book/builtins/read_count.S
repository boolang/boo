; f read_count(path: S, count: I)
; no idea if this works
[BITS 64]
    ; malloc(count)
    mov rdi, [rsp + 16];
    mov rdx, [rdi];
    mov r12, rdx;
    mov rax, 0x400000;
    call rax;
    mov r11, rax;
    ; open
    mov rdi, [rsp + 8];
    mov rdi, [rdi];
    xor rsi, rsi;
    mov rdx, 64;
    mov eax, 2;
    syscall;
    mov r10, rax;
    ; read
    mov rdi, [rsp + 16];
    mov rdx, [rdi];
    mov rdi, rax;
    mov rsi, r11;
    xor rax, rax;
    syscall
    ; close
    mov rdi, rax;
    mov eax, 3;
    syscall
    ; malloc(0x10)
    mov rdi, 0x10;
    mov rax, 0x400000;
    call rax;
    mov [rax], r11;
    mov qword [rax + 8], r12;
    ret
