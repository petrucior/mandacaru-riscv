.global _start
.section .text

_start:
    #addi x1, x0, 1     # Carrega o valor 1 em x1
    #sw   x1, 0(x0)     # Escreve x1 no endereço 0 (Liga o LED)
    addi x2, x0, 0     # Carrega o valor 0 em x2
    sw   x2, 0(x0)     # Escreve x2 no endereço 0 (Desliga o LED)
