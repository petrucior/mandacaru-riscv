// Módulo de controle
module control ( opcode, funct3, RegWrite, ALUSrc, MemWrite, ALUControl );
   input wire [6:0] opcode;
   input wire [2:0] funct3;
   output reg 	    RegWrite;
   output reg 	    ALUSrc;
   output reg 	    MemWrite;
   output reg [1:0] ALUControl;

   always @(*) begin
      // Iniciando todos os comandos com 0
      RegWrite   = 1'b0;
      ALUSrc     = 1'b0;
      MemWrite   = 1'b0;
      ALUControl = 2'b00;

      case (opcode)
        7'b0010011: begin // ADDI
           RegWrite   = 1'b1;
           ALUSrc     = 1'b1;
           ALUControl = 2'b00;
        end
        7'b0100011: begin // SW
           MemWrite   = 1'b1;
           ALUSrc     = 1'b1;
           ALUControl = 2'b00;
        end
        default: ;
      endcase
   end
endmodule
