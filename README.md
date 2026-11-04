# Mandacaru RISC-V 

<p align="center">
<img width="500" height="300" alt="Mandacaru risc-v" src="https://github.com/user-attachments/assets/d4d222d7-b3d2-4218-b12e-e607eefae5a7" />
</p>

Processador RISC-V monociclo minimalista (subconjunto do RV32I) implementado em **Verilog**, projetado para fins educacionais e experimentação em FPGAs Gowin, utilizando exclusivamente o ecossistema de ferramentas abertas (*Open-Source FPGA Toolchain*).

O projeto evoluiu em duas etapas principais:
1. **Sipeed Tang Nano 1K (Gowin GW1NZ-1):** Validação do datapath monociclo básico e controle de I/O para piscar um LED integrado.
2. **Sipeed Tang Nano 9K (Gowin GW1N-9C):** Expansão dos recursos lógicos para execução de instruções aritméticas e manipulação de registradores em hardware real.

---

## Visão Geral da Arquitetura

O núcleo implementa uma arquitetura RISC-V monociclo de 32 bits (*Single-Cycle Datapath*), contemplando:
* **Unidade de Controle:** Decodificação de instruções e geração de sinais de controle.
* **Banco de Registradores:** 32 registradores de 32 bits (`x0` a `x31`).
* **ALU (Unidade Lógica Aritmética):** Suporte a operações aritméticas e lógicas fundamentais (`ADD`, `ADDI`, `SW`, etc.).
* **Unidade de Busca de Instruções (PC):** Lógica sequencial.

---

## Ferramentas Utilizadas (Toolchain 100% Open Source)

O projeto dispensa softwares proprietários de EDA, rodando inteiramente sobre ferramentas livres:

* **[Yosys](https://github.com/YosysHQ/yosys):** Síntese lógica de Verilog para netlist de FPGA.
* **[nextpnr](https://github.com/YosysHQ/nextpnr) (himbaechel):** Posicionamento e roteamento (*Place-and-Route*).
* **[gowin_pack](https://github.com/YosysHQ/prjtrellis):** Geração do arquivo de bitstream (`.fs` / `.bin`).
* **[openFPGALoader](https://github.com/trabucayre/openFPGALoader):** Gravação do bitstream na placa via USB.

---

## Estrutura do Repositório

```tree
.
├── rtl/                  # Código-fonte em Verilog do processador
│   ├── riscv_top.v       # Top-level do processador
│   ├── alu.v             # Unidade Lógica Aritmética
│   ├── regfile.v         # Banco de registradores
│   └── control.v         # Unidade de controle
├── constraints/          # Arquivos de pinagem (.cst)
│   ├── tangnano1k.cst    # Pinout para Tang Nano 1K (LED blink)
│   └── tangnano9k.cst    # Pinout para Tang Nano 9K (Operação aritmética)
├── sim/                  # Bancos de teste (Testbenches em Icarus Verilog)
│   └── tb_riscv.v
├── Makefile              # Automação de síntese, place-and-route e gravação
└── README.md

```


## Como Compilar e Executar

Este projeto utiliza uma árvore de compilação automatizada via **Makefile** para alternar facilmente entre os alvos de hardware (`tangnano1k` e `tangnano9k`).

### 1. Pré-requisitos (Toolchain Open-Source)

Certifique-se de ter as ferramentas open-source instaladas em seu ambiente Linux (Ubuntu/Debian):

```bash
sudo apt update
sudo apt install yosys nextpnr-gowin openfpgaloader iverilog gtkwave make

