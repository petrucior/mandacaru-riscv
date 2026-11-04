// risc-v processor single core
module risc(
    input wire 	     clk, 
    output reg [5:0] led
);
    // Divisor de clock sem reset
    reg [25:0] clk_div = 26'd0;
    always @(posedge clk) begin
        clk_div <= clk_div + 1'b1;
    end
    wire cpu_clk = clk_div[24]; 

    // Sinais de interconexão
    wire RegWrite, ALUSrc, MemWrite;
    wire [1:0] ALUControl;
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [31:0] data_addr;
    wire [31:0] data_wdata;
    wire mem_write_en;
   
    // Instanciação da Unidade de Controle
    control u_control (
        .opcode(opcode),
        .funct3(funct3),
        .RegWrite(RegWrite),
        .ALUSrc(ALUSrc),
        .MemWrite(MemWrite),
        .ALUControl(ALUControl)
    );

    // Instanciação do Caminho de Dados (Datapath)
    datapath u_datapath (
        .clk(cpu_clk),
        .rst_n(1'b1),
        .RegWrite(RegWrite),
        .ALUSrc(ALUSrc),
        .MemWrite(MemWrite),
        .ALUControl(ALUControl),
        .opcode_out(opcode),
        .funct3_out(funct3),
        .data_addr(data_addr),
        .data_wdata(data_wdata),
        .mem_write_en(mem_write_en)
    );

   // Periférico MMIO: sw no endereço 0 grava os 6 bits baixos nos LEDs.
   // Os LEDs da Tang Nano 9K são ATIVOS EM NÍVEL BAIXO (0 = aceso),
   // por isso o valor é invertido.
   initial led = 6'b111111;   // todos apagados no início
   always @(posedge clk) begin
      if (mem_write_en && data_addr == 32'h0)
        led <= ~data_wdata[5:0];
   end

   
endmodule // risc
