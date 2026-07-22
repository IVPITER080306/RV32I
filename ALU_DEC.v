module ALU_DEC
(
    input wire[1:0] ALU_OP, ///defines modes
    input wire[2:0] funct3, ///defines operation within mode 10/11
    input wire[6:0] funct7, ///defines operations like ADD, SUB, SRA and SRL
    output reg[3:0] ALU_CON ///outputs the control signal to be sent to the ALU
);

    always @(*)
    begin
        case (ALU_OP)
            2'b00: ALU_CON = `ADD; ///forces addition (useful for S-TYPE and LW)
            2'b01: ALU_CON = `SUB; ///forces substraction (useful for B-TYPE)
            2'b10: ///This is made for R-TYPE instructions, where funct3 and funct7 are used to distinguish between the operations. So, we can use funct3 and funct7[5] to distinguish between the operations.
                begin
                    case (funct3)
                        3'b000: ALU_CON = funct7[5] ? `SUB : `ADD; ///In R-TYPE, funct7[5] distinguishes ADD/SUB
                        3'b001: ALU_CON = `SLL; ///SLL
                        3'b010: ALU_CON = `SLT; ///SLT
                        3'b011: ALU_CON = `SLTU; ///SLTU
                        3'b100: ALU_CON = `XOR; ///XOR
                        3'b101: ALU_CON = funct7[5] ? `SRA : `SRL; ///SRA/SRL
                        3'b110: ALU_CON = `OR; ///OR
                        3'b111: ALU_CON = `AND; ///AND
                        default: ALU_CON = `ADD; ///To avoid unintentional latches
                    endcase
                end
            2'b11: ///This is made for I-TYPE instructions, where funct7 is not really funct7, but imm[11:0] is used to distinguish between SRLI and SRAI. So, we can use funct7[5] to distinguish between the two.
                begin
                    case (funct3)
                        3'b000: ALU_CON = `ADD; ///ADDI, there is no SUBI
                        3'b001: ALU_CON = `SLL; ///SLLI
                        3'b010: ALU_CON = `SLT; ///SLTI
                        3'b011: ALU_CON = `SLTU; ///SLTIU
                        3'b100: ALU_CON = `XOR; ///XORI
                        3'b101: ALU_CON = funct7[5] ? `SRA : `SRL; ///SRLI/SRAI: spec fixes imm[11:5], so funct7[5]=inst[30] is a valid SRL/SRA selector
                        3'b110: ALU_CON = `OR;  ///ORI
                        3'b111: ALU_CON = `AND; ///ANDI
                        default: ALU_CON = `ADD; ///To avoid unintentional latches
                    endcase
                end
            default: ALU_CON = `ADD; ///made default case to avoid unintentional latches
        endcase
    end
endmodule