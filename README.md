# Mandacaru RISC-V 

<p align="center">
<img width="500" height="300" alt="Mandacaru risc-v" src="https://github.com/user-attachments/assets/d4d222d7-b3d2-4218-b12e-e607eefae5a7" />
</p>

Processador RISC-V monociclo minimalista (subconjunto do RV32I) implementado em **Verilog**, projetado para fins educacionais e experimentação em FPGAs da Gowin, utilizando exclusivamente o ecossistema de ferramentas abertas (*Open-Source FPGA Toolchain*).

O projeto evoluiu em duas etapas principais:
1. **Sipeed Tang Nano 1K (Gowin GW1NZ-1):** Validação do datapath monociclo básico e controle de I/O para piscar um LED integrado.
2. **Sipeed Tang Nano 9K (Gowin GW1N-9C):** Expansão dos recursos lógicos para execução de instruções aritméticas e manipulação de registradores em hardware real.


## Visão Geral da Arquitetura

O `datapath` entrega `opcode` e `funct3` ao `control`, que devolve os sinais de controle. O barramento de dados do `datapath` (`data_addr`, `data_wdata`, `mem_write_en`) só tem um destinatário: o registrador dos LEDs, no módulo `risc` (top).
 
```
 clk (27 MHz) ─────────────────────────────────────────────────────┐
      │                                                            │
      ▼                                                            │
 ┌──────────────────────────┐                                      │
 │ clk_div (contador 26 b)  │                                      │
 │ cpu_clk = clk_div[24]    │  ≈ 0,8 Hz                            │
 └────────────┬─────────────┘                                      │
              │ cpu_clk                                            │
              ▼                                                    │
 ┌──────────────────────────┐    opcode, funct3   ┌────────────┐   │
 │        datapath          │────────────────────►│   control  │   │
 │  PC · ROM · RF · ULA     │◄────────────────────│            │   │
 └────────────┬─────────────┘  RegWrite, ALUSrc,  └────────────┘   │
              │                MemWrite, ALUControl                │
              │ data_addr, data_wdata, mem_write_en                │
              ▼                                                    │
 ┌──────────────────────────────────────────────┐                  │
 │ periférico MMIO (registrado em clk, 27 MHz)  │◄─────────────────┘
 │ se mem_write_en && data_addr == 0:           │
 │         led <= ~data_wdata[5:0]              │
 └──────────────────────┬───────────────────────┘
                        ▼
                led[5:0]  (ativos em nível baixo)
```

### Módulos
---
 
| Arquivo | Módulo | Responsabilidade |
|---|---|---|
| `risc.v` | `risc` (top) | Divisor de clock (`cpu_clk`), instancia `control` e `datapath` e implementa o periférico MMIO de LEDs |
| `datapath.v` | `datapath` | PC, ROM de instruções, decodificação de campos e imediatos, banco de registradores, ULA e saídas do barramento de dados |
| `control.v` | `control` | Decodifica o `opcode` e gera `RegWrite`, `ALUSrc`, `MemWrite` e `ALUControl` |


### Ciclo de instrução
---
Tudo acontece dentro de um período de `cpu_clk`:
 
1. **Busca:** `instr = rom[pc]` (leitura combinacional).
2. **Decodificação:** extração de `opcode`, `funct3`, `rs1`, `rs2`, `rd` e dos imediatos `imm_i` e `imm_s` (com extensão de sinal). O `control` gera os sinais de controle a partir do `opcode`.
3. **Leitura de registradores:** `rd1` e `rd2` (combinacional; o índice x0 devolve 0).
4. **Execução:** `srcB = ALUSrc ? imm : rd2` e `alu_result = rd1 + srcB`.
5. **Barramento de dados:** `data_addr = alu_result`, `data_wdata = rd2` e `mem_write_en = MemWrite`.
6. **Escrita e próximo PC:** na borda de subida de `cpu_clk`, `rf[rd] <= alu_result` (se `RegWrite` e o índice de `rd` não for 0) e `pc <= pc + 1`.

## Detalhes de Implementação

### Clock 
---
O oscilador de 27 MHz da placa (`clk`) alimenta um contador livre de 26 bits (`clk_div`, sem reset). O **bit 24** é usado como clock da CPU:
 
```
f_cpu = 27 MHz / 2^(bit+1)      →   bit 24: 27 MHz / 2^25 ≈ 0,80 Hz  (T ≈ 1,24 s)
```
 
| Bit de `clk_div` | `f_cpu` | Período |
|---|---|---|
| 24 (atual) | 0,80 Hz | 1,24 s |
| 23 | 1,61 Hz | 0,62 s |
| 22 | 3,22 Hz | 0,31 s |
 
Para mudar a velocidade, troque o índice em `wire cpu_clk = clk_div[24];` (o bit 25 do contador não é usado). Como os sinais do `datapath` só mudam uma vez por período de `cpu_clk`, o registrador dos LEDs, que opera no clock rápido de 27 MHz, os captura com segurança.
 
### Memória de instruções e PC
---
 
- O `pc` tem 3 bits (parâmetro `instrucoes = 3`) e é incrementado em 1 a cada `cpu_clk`. Ele conta **palavras**, não bytes, e dá a volta após 8 posições (0 → 7 → 0 …): o firmware roda em loop. Uma volta completa leva ≈ 9,9 s.
- A ROM é `reg [31:0] rom [0:7]`, preenchida por `$readmemh("firmware/firmware.hex", rom)` **em tempo de síntese**. O firmware, portanto, faz parte do bitstream: mudar o programa exige regerar o `.hex` e ressintetizar.


### Banco de registradores
---
 
- `reg [31:0] rf [3:0]`: quatro registradores de 32 bits, reduzidos para manter o design pequeno (o que também o torna viável na Tang Nano 1K).
- Leitura combinacional e escrita síncrona em `cpu_clk`. O índice 0 sempre lê 0, e escritas nele são ignoradas.
- Só os **2 bits menos significativos** de `rs1`, `rs2` e `rd` são usados.


### ULA
---
 
Soma de 32 bits: `alu_result = rd1 + srcB`. O sinal `ALUControl` (2 bits) já existe no projeto, mas qualquer valor resulta em soma (fica reservado para novas operações). O imediato é `imm_s` para `sw` (opcode `0100011`) e `imm_i` nos demais casos.


### Unidade de controle
---
 
A decodificação usa apenas o `opcode`:
 
| `opcode` | Instrução | `RegWrite` | `ALUSrc` | `MemWrite` | `ALUControl` |
|---|---|:---:|:---:|:---:|:---:|
| `0110011` | `ADD` (tipo R) | 1 | 0 | 0 | `00` |
| `0010011` | `ADDI` (tipo I) | 1 | 1 | 0 | `00` |
| `0100011` | `SW` (tipo S) | 0 | 1 | 1 | `00` |
| qualquer outro | tratado como NOP | 0 | 0 | 0 | `00` |


### Periférico de LEDs (MMIO)
---
 
No `risc.v`, um `sw` cujo endereço efetivo seja `0x00000000` grava os 6 bits menos significativos do dado no registrador `led`:
 
| Endereço | Acesso | Função |
|---|---|---|
| `0x00000000` | escrita (`sw`) | Bits `[5:0]` do dado → `led[5:0]`. Escrever `1` acende o LED |
| demais | n/a | Não decodificados: o `sw` não tem efeito |
 
Os LEDs da Tang Nano 9K são **ativos em nível baixo**, então o hardware inverte o dado (`led <= ~data_wdata[5:0]`) e inicia com `6'b111111` (todos apagados). Para o programador, vale a regra direta: o bit `n` do valor escrito controla `led[n]`.
 
## Conjunto de instruções
---
 
| Instrução | Formato | Codificação (campos, do bit 31 ao 0) | Efeito |
|---|---|---|---|
| `add rd, rs1, rs2` | R | `0000000` `rs2` `rs1` `000` `rd` `0110011` | `rd ← rs1 + rs2` |
| `addi rd, rs1, imm` | I | `imm[11:0]` `rs1` `000` `rd` `0010011` | `rd ← rs1 + sext(imm)` |
| `sw rs2, imm(rs1)` | S | `imm[11:5]` `rs2` `rs1` `010` `imm[4:0]` `0100011` | `mem[rs1 + sext(imm)] ← rs2` (só tem efeito em `0x0`, nos LEDs) |
| `nop` (`addi x0, x0, 0`) | I | `0x00000013` | Nenhum (a escrita em `x0` é ignorada) |
 
Qualquer outra instrução vira NOP, pois o `control` não aciona nenhum sinal para opcodes desconhecidos. Veja também as [limitações](#limitações-conhecidas): como só o `opcode` é decodificado, instruções com os mesmos opcodes (por exemplo `sub`, `slli`, `sh`) seriam executadas como `add`, `addi` e `sw`.
 
## Programa de exemplo
 
`firmware/firmware.s`:
 
```asm
_start:
    addi x1, x0, 1      # x1 = 1
    addi x2, x0, 3      # x2 = 3
    add  x3, x1, x2     # x3 = 4
    sw   x3, 0(x0)      # LEDs = 4
    nop
```
 
Imagem de ROM gerada (`firmware/firmware.hex`) e execução:
 
| PC | Instrução | Hex | Efeito |
|:---:|---|---|---|
| 0 | `addi x1, x0, 1` | `00100093` | `x1 ← 1` |
| 1 | `addi x2, x0, 3` | `00300113` | `x2 ← 3` |
| 2 | `add x3, x1, x2` | `002081b3` | `x3 ← 4` |
| 3 | `sw x3, 0(x0)` | `00302023` | `mem[0x0] ← 4` → LEDs |
| 4 | `nop` | `00000013` | Nenhum |
| 5–7 | n/a | n/a | Não preenchidas pelo `.hex` (veja [limitações](#limitações-conhecidas)) |
 
O valor `4` (`0b000100`) chega ao registrador como `~000100 = 111011`, então **`led[2]` acende**. Cada instrução ocupa um período de `cpu_clk` (≈ 1,24 s): a primeira borda ocorre ≈ 0,62 s após a configuração, o `add` termina na terceira borda (≈ 3,1 s) e, em seguida, o `sw` grava o resultado. O programa se repete a cada 8 instruções (≈ 9,9 s), regravando o mesmo valor.
 
Variantes do mesmo programa:
 
- **`firmware/firmware.s_`:** igual ao anterior, mas com `addi x1, x0, 2`, o que dá `x3 = 5` (`0b000101`) e acende `led[0]` e `led[2]`.
- **`firmware/code/main.c`:** versão em C do mesmo conceito (`LEDS = 2 + 3`, resultado 5). Veja [Firmware em C](#b-firmware-em-c).
## Estrutura do repositório
 
```
risc-v/
├── Makefile                 # síntese → place & route → bitstream → gravação
├── risc.v                   # top: divisor de clock, instâncias e periférico de LEDs
├── control.v                # unidade de controle
├── datapath.v               # PC, ROM, banco de registradores, ULA e barramento de dados
├── tangnano9k.cst           # restrições de pinos da Tang Nano 9K
└── firmware/
    ├── configure.sh         # assembly → firmware.hex
    ├── firmware.s           # programa em assembly (LEDs = 4)
    ├── firmware.hex         # (gerado) imagem da ROM lida pelo $readmemh
    └── code/
        ├── main.c           # exemplo em C
        ├── configure.sh     # C → prog.elf + disassembly
        └── prog.elf         # (gerado)
```
 
Os arquivos marcados como *(gerado)* podem ser recriados pelo fluxo de build e normalmente não precisam ser versionados.


<a name="ferramentas"></a>
## Ferramentas Utilizadas (Toolchain 100% Open Source)

O projeto dispensa softwares proprietários de EDA, rodando inteiramente sobre ferramentas livres:

* **[Yosys](https://github.com/YosysHQ/yosys):** Síntese lógica de Verilog para netlist de FPGA.
* **[nextpnr](https://github.com/YosysHQ/nextpnr) (himbaechel):** Posicionamento e roteamento (*Place-and-Route*).
* **[gowin_pack](https://github.com/yosyshq/apicula):** Geração do arquivo de bitstream (`.fs` / `.bin`).
* **[openFPGALoader](https://github.com/trabucayre/openFPGALoader):** Gravação do bitstream na placa via USB.


## Guia Rápido de Uso
 
Com as [ferramentas instaladas](#ferramentas), a partir da raiz do projeto:
 
```bash
# 1) Gerar a imagem da ROM a partir do assembly (cria firmware/firmware.hex)
cd firmware && bash configure.sh && cd ..
 
# 2) Sintetizar, posicionar/rotear e gerar o bitstream (risc.fs)
make
 
# 3) Gravar na placa
make loadram        # SRAM da FPGA (volátil: some ao desligar)
# make loadflash    # flash da placa (persistente)
```
 
Com o firmware de exemplo, o LED `led[2]` acende cerca de 3 s depois que a FPGA é configurada (a CPU soma 1 + 3 e escreve `4` = `0b000100` nos LEDs).


