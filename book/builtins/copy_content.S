[BITS 64]
mov r9, rax
mov r10, rbx
mov rsi, [r9 - 8]
mov rdi, 0
cmp rdi, rsi
jz exit
loop:
mov rdx, [r9]
mov [r10], rdx
add r9, 8
add r10, 8
add rdi, 8
cmp rdi, rsi
jl loop
exit:
ret
