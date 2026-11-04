#!/bin/bash

# compila o codigo main.c usando compilador risc-v
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -O1 -nostdlib -ffreestanding -fno-delete-null-pointer-checks -Wl,-Ttext=0x0 -o prog.elf main.c

# exibe o disassembly do prog.elf
riscv64-unknown-elf-objdump -d -M no-aliases prog.elf
