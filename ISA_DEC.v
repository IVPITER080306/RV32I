module ISA_DEC
(
    input wire[31:0] inst, ///takes instruction from IMEM
    output reg[6:0] opcode, ///otuputs opcode form CON_UNIT
    output reg[4:0] rd, ///outputs destination register
    output reg[2:0] funct3, ///outputs funct3 for ALU
    output reg[4:0] rs, ///outputs source register
    output reg[4:0] rt, ///outputs second source register
    output reg[6:0] funct7 ///outputs funct7 for ALU
);

always @(*)
begin
    ///its just bit splicing
    opcode = inst[6:0];
    rd = inst[11:7];
    funct3 = inst[14:12];
    rs = inst[19:15];
    rt = inst[24:20];
    funct7 = inst[31:25];
end
endmodule