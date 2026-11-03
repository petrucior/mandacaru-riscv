# RISC-V Monociclo Softcore (Tang Nano 1K & 9K)

Um processador RISC-V monociclo minimalista (subset RV32I) implementado em **Verilog**, projetado para fins educacionais e experimentação em FPGA, utilizando exclusivamente o ecossistema de ferramentas abertas (*Open-Source FPGA Toolchain*).

O projeto evoluiu em duas etapas principais:
1. **Tang Nano 1K (Gowin GW1NZ-1):** Validação do datapath monociclo básico e controle de I/O para piscar um LED integrado.
2. **Tang Nano 9K (Gowin GW1N-9C):** Expansão dos recursos lógicos para execução de instruções aritméticas e manipulação de registradores em hardware real.

---

## 🚀 Visão Geral da Arquitetura

O núcleo implementa uma arquitetura RISC-V monociclo de 32 bits (*Single-Cycle Datapath*), contemplando:
* **Unidade de Controle:** Decodificação de instruções e geração de sinais de controle.
* **Banco de Registradores:** 32 registradores de 32 bits (`x0` a `x31`).
* **ALU (Unidade Lógica Aritmética):** Suporte a operações aritméticas e lógicas fundamentais (`ADD`, `ADDI`, `SW`, etc.).
* **Unidade de Busca de Instruções (PC):** Lógica sequencial.

---

## 🛠️ Ferramentas Utilizadas (Toolchain 100% Open Source)

O projeto dispensa softwares proprietários de EDA, rodando inteiramente sobre ferramentas livres:

* **[Yosys](https://github.com/YosysHQ/yosys):** Síntese lógica de Verilog para netlist de FPGA.
* **[nextpnr](https://github.com/YosysHQ/nextpnr) (himbaechel):** Posicionamento e roteamento (*Place-and-Route*).
* **[gowin_pack](https://github.com/YosysHQ/prjtrellis):** Geração do arquivo de bitstream (`.fs` / `.bin`).
* **[openFPGALoader](https://github.com/trabucayre/openFPGALoader):** Gravação do bitstream na placa via USB.

---

## 📂 Estrutura do Repositório

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
