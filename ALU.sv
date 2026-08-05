`define ADD 4'b0000
`define SUB 4'b0001
`define AND 4'b0010
`define OR  4'b0011
`define XOR 4'b0100
`define SLL 4'b0101
`define SRL 4'b0110
`define SRA 4'b0111
`define SLT 4'b1000
`define SLTU 4'b1001

///ALU which can handle ADD, SUB, AND, OR, XOR, shifting operations and comparison operators
///No multiplication operation in this ALU, we will be building a hardware accelerator for GEMM which can handle 1x1 scalar multiplication as well

module ALU (
input wire[31:0] a, b,
input wire[3:0] ALU_CON,
output reg[31:0] res,
output reg zero
);

always @(*)
begin
    case(ALU_CON)
        `ADD: res = a + b;
        `SUB: res = a - b;
        `AND: res = a & b;
        `OR:  res = a | b;
        `XOR: res = a ^ b;
        `SLL: res = a << b[4:0];
        `SRL: res = a >> b[4:0];
        `SRA: res = $signed(a) >>> b[4:0];
        `SLT: res = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
        `SLTU: res = (a < b) ? 32'b1 : 32'b0;

        default: res = 32'b0;
    endcase

    if (!res)
    begin
        zero = 1'b1;
    end
    else
        begin
            zero = 1'b0;
        end
end
endmodule