#!/bin/bash

# 1. Compila o assembly para objeto ELF (forçando RV32I e ABI de 32 bits)
riscv64-unknown-elf-gcc -march=rv32i -mabi=ilp32 -nostdlib -Ttext=0x0 -c firmware.s -o firmware.o

# 2. Extrai o binário puro do arquivo ELF
riscv64-unknown-elf-objcopy -O binary firmware.o firmware.bin

# 3. Converte o binário cru em um arquivo de texto hexadecimal estruturado (firmware.hex)
python3 -c "
with open('firmware.bin', 'rb') as f:
    data = f.read()
with open('firmware.hex', 'w') as f:
    for i in range(0, len(data), 4):
        word = data[i:i+4]
        if len(word) < 4:
            word = word + b'\x00' * (4 - len(word))
        val = int.from_bytes(word, byteorder='little')
        f.write(f'{val:08x}\n')
"

rm -r *.o *.bin
