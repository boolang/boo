; f V_new<T>() -> V<T>
; // buffer stores `cap` many 8 byte cells storing pointers to `T`s
; s V {
;    buf: pointer,
;    size: I, // in cells
;    cap: I, // in cells
; }
[BITS 64]
    mov rdi, 0x18;
    mov rax, 0x400000;
    call rax;
    ; initial cap is 16 i guess idk
    mov qword [rax+8], 0;
    mov qword [rax+16], 16;
    mov r10, rax;
    ; malloc (16*8)
    mov rdi, 0x80;
    mov rax, 0x400000;
    call rax;
    mov [rdi], rax;
    mov rax, rdi;
    ret
