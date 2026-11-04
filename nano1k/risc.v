// risc-v processor single core
module risc(
    input wire clk,      
    output wire led
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

    // Mapeamento de E/S (MMIO): Endereço 32'h0 controla o LED
    reg led = 1'b1; 
    always @(posedge cpu_clk) begin
        if (mem_write_en && (data_addr == 32'h0)) begin
            led <= ~data_wdata[0]; 
        end
    end

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
endmodule // risc
