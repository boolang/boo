; f V_new<T>() -> V<T>
; // buffer stores `cap` many 8 byte cells storing pointers to `T`s
; s V {
;    buf: pointer,
;    size: I, // in cells
;    cap: I, // in cells
; }
[BITS 64]
    ; malloc 16*8 initial buffer
    mov rdi, 0x80;
    mov rax, 0x400000;
    call rax;
    push rax;

    ; malloc vec struct
    mov rdi, 0x18;
    mov rax, 0x400000;
    call rax;

    ; initial cap is 16 i guess idk
    pop rbx;
    mov qword [rax], rbx;
    mov qword [rax+8], 0;
    mov qword [rax+16], 16;

    ret
