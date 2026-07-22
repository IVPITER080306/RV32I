`define R_TYPE 7'b0110011
`define I_TYPE 7'b0010011
`define S_TYPE 7'b0100011
`define LW 7'b0000011
`define B_TYPE 7'b1100011

module CON_UNIT
(
    input wire[31:0] inst, ///instruction form IMEM(taken for verifying the opcode during waveform assesment and calculating the immediate value, no practical use of the whole instruction in this module)
    input wire[6:0] opcode, ///opcode from ISA_DEC
    output reg REG_WR, ///decides whether to write o register(1) or not(0)
    output reg ALU_SRC, ///decides to take immediate value(1) or not(0)(from register)
    output reg MEM_WR, /// decides whether to write on DMEM(1) or not(0)
    output reg MEM_RD, ///decides whether to read from DMEM(1) or not(0)
    output reg[1:0] ALU_OP, ///decides mode of operation for ALU
    output reg branch, ///decides whether to branch(B-TYPE)(1) or not(0)
    output reg MEM_TO_REG, ///decides whether to write from DMEM to REG(1) or not(0)
    output reg[31:0] IMM ///computes immediate value
);

always @(*) 
begin
    ///defaults all control signals to 0
    REG_WR = 1'b0;      
    ALU_SRC = 1'b0;    
    MEM_WR = 1'b0;
    MEM_RD = 1'b0;
    ALU_OP = 2'b00;
    branch = 1'b0;
    MEM_TO_REG = 1'b0;
    IMM = 32'b0;

    case(opcode)
        `R_TYPE: /// R-TYPE
            begin
                REG_WR = 1'b1; ///writing on register
                ALU_SRC = 1'b0; ///using register values
                MEM_WR = 1'b0; ///no write on memory
                MEM_RD = 1'b0; ///no read from memory
                ALU_OP = 2'b10;///using R-TYPE mode in ALU_DEC to use a variety of operations
                branch = 1'b0; ///no branching
                MEM_TO_REG = 1'b0; ///no write from memory
                IMM = 32'b0; ///no immediate value in use
            end
        `I_TYPE: /// I-TYPE
            begin
                REG_WR = 1'b1; ///writing on register
                ALU_SRC = 1'b1; ///using immediate values
                MEM_WR = 1'b0; ///no writes on memory
                MEM_RD = 1'b0; ///no reads from memory
                ALU_OP = 2'b11; ///Using I-TYPE mode in ALU_DEC to use a variety of operations
                branch = 1'b0; ///no branching
                MEM_TO_REG = 1'b0; ///no writes on REG from memory
                IMM = {{20{inst[31]}}, inst[31:20]}; ///immediate vaule is taken from the the top 12 values from the instruction and then sign extended to make a 32 bit value which the ALU can use for computation
            end
        `S_TYPE: /// S-TYPE
            begin
                REG_WR = 1'b0; ///no writes to register
                ALU_SRC = 1'b1; ///immediate value is used
                MEM_WR = 1'b1; ///we are writing on memory
                MEM_RD = 1'b0; ///we are not reading from memory
                ALU_OP = 2'b00; ///we are forcing an addition (a trick to store memory without making a special operation for storing data) (essentially B(destination) = A(source) +0)
                branch = 1'b0; ///no branching
                MEM_TO_REG = 1'b0; ///no writing from memory to REG
                IMM = {{20{inst[31]}}, inst[31:25], inst[11:7]}; ///the immediate value is a 12 bit value from 31-15 and 11-7 with sign extension 
            end
        `LW: ///Load Word Instruction
            begin
                REG_WR = 1'b1; ///we are writing to registers
                ALU_SRC = 1'b1; ///we are using immediate value
                MEM_WR = 1'b0; ///we are not writing to memory
                MEM_RD = 1'b1; ///we are reading the word to be loaded from memory
                ALU_OP = 2'b00; ///again forcing addition (same logic as S-TYPE)
                branch = 1'b0; ///no branching involved
                MEM_TO_REG = 1'b1; /// we are writing from memory to register
                IMM = {{20{inst[31]}}, inst[31:20]}; /// similar immediate value as taken from I-TYPE
            end
        `B_TYPE: /// B-TYPE 
            begin
                REG_WR = 1'b0; ///no writing to registers
                ALU_SRC = 1'b0; ///not using immediate value for computation(we use immediate value to only find out where to branch to)
                MEM_WR = 1'b0; ///not writing on memory
                MEM_RD = 1'b0; ///not reading from memory
                ALU_OP = 2'b01; ///forcing a substraction (for comparison between 2 values)
                branch = 1'b1; ///ofc we are branching
                MEM_TO_REG = 1'b0; ///we are not writing from memory to register
                IMM = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0}; ///official immediate value calculation from RISC, with sign ecxtension
            end
    endcase
end
endmodule