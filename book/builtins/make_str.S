; Make a string struct on the heap. They have layout:
; s String {
;    buf: pointer,
;    size: u64,
; }
; abi: pointer in rdi and size in rsi, address stored in rax
[BITS 64]
    ; malloc(0x10)
    push rdi;
    push rsi;
    mov rdi, 0x10;
    mov rax, 0x400000;
    call rax;
    pop rsi;
    pop rdi;

    ; buf = rdi, size = rsi
    mov [rax], rdi;
    mov [rax+8], rsi;
    ret
