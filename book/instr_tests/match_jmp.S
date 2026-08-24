[BITS 64]
mov rdx, 0xdeadbeef;
; Conditional jumps can't jump to absolute address or register value, so we have to do this odd maneuvre
je body;
jmp rdx;
body:
