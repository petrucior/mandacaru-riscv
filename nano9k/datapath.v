module datapath ( clk, rst_n, RegWrite, ALUSrc, MemWrite, ALUControl, opcode_out, funct3_out, data_addr, data_wdata, mem_write_en );
   
   input wire 	   clk;
   input wire 	   rst_n;
   // Sinais da Unidade de Controle
   input wire 	   RegWrite;
   input wire 	   ALUSrc;
   input wire 	   MemWrite;
   input wire [1:0] ALUControl;
   // Sinais para a Unidade de Controle
   output wire [6:0] opcode_out;
   output wire [2:0] funct3_out;
   // Barramento de Dados
   output reg [31:0] data_addr;
   output reg [31:0] data_wdata;
   output wire 	     mem_write_en;

   parameter instrucoes = 3;
   
   // Program Counter cíclico de 3 bits (8 instruções)
   reg [instrucoes-1:0] pc = 3'b0;
   always @(posedge clk) begin
      pc <= pc + 2'b1;
   end

   // Memória de Instruções carregada via arquivo do GCC
   reg [31:0] rom [0:(1<<instrucoes)-1];
   initial begin
      $readmemh("firmware/firmware.hex", rom);
   end
   wire [31:0] instr = rom[pc];

   // Decodificação dos campos da instrução
   wire [4:0]  rs1    = instr[19:15];
   wire [4:0]  rs2    = instr[24:20];
   wire [4:0]  rd     = instr[11:7];
   assign opcode_out = instr[6:0];
   assign funct3_out = instr[14:12];

   // Extensão de sinal dos imediatos (Tipo I e Tipo S)
   wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};
   wire [31:0] imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
   wire [31:0] imm   = (opcode_out == 7'b0100011) ? imm_s : imm_i;

   // Banco de Registradores reduzido para caber na tangnano (Apenas 4 registradores: x0 a x3)
   reg [31:0]  rf [3:0];
   wire [31:0] rd1 = (rs1[1:0] == 2'b0) ? 32'b0 : rf[rs1[1:0]];
   wire [31:0] rd2 = (rs2[1:0] == 2'b0) ? 32'b0 : rf[rs2[1:0]];
   
   // Banco de Registradores síncrono
   integer     i;
   always @(posedge clk) begin
      if (RegWrite && (rd[1:0] != 2'b0)) begin
         rf[rd[1:0]] <= alu_result;
      end
   end

   // ALU (Arithmetic Logic Unit)
   wire [31:0] srcB = ALUSrc ? imm : rd2;
   reg [31:0]  alu_result;
   always @(*) begin
      case (ALUControl)
        2'b00: alu_result = rd1 + srcB;
        default: alu_result = rd1 + srcB;
      endcase
   end

   // Saídas para o barramento de dados
   always @(*) begin
      data_addr  = alu_result;
      data_wdata = rd2;
   end
   
   assign mem_write_en = MemWrite;
endmodule
