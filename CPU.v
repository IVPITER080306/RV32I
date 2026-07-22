module CPU
(
    input wire clk,   /// synchronous clock input
    input wire rst_n  /// asynchronous low enabled reset
);

/// First stage, the Instruction Fetch(IF)
wire [31:0] pc_curr_IF;
wire [31:0] pc_next_IF;
wire [31:0] inst_IF;
wire [31:0] pc_no_branch_IF;

wire PCSrc; /// signal to determine if we need to branch or not

PC PC_IF
(
    .clk(clk),
    .rst_n(rst_n),
    .PC_write(PC_write_ID), /// Route from Hazard Detection Unit in ID stage
    .pc_next(pc_next_IF),
    .pc_curr(pc_curr_IF)
);

PC_ADDER PC_ADDER_IF
(
    .pc_curr(pc_curr_IF),
    .pc_ofst(32'd4), /// default case: +4 for next instruction
    .pc_next(pc_no_branch_IF)
);

/// IF Mux to select next PC
assign pc_next_IF = (PCSrc) ? pc_branch_EX : pc_no_branch_IF; 

IMEM IMEM_IF
(
    .addr(pc_curr_IF),
    .inst(inst_IF)
);

/// IF/ID Pipeline Registers
reg [31:0] pc_curr_ID;
reg [31:0] inst_ID;

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        pc_curr_ID <= 32'd0;
        inst_ID <= 32'd0;
    end
    else
    begin
        if(PCSrc)
        begin
            pc_curr_ID <= 32'b0; /// If we are branching, we want to flush the instruction in the ID stage by setting it to 0 (NOP)
            inst_ID <= 32'b0; /// Flushing the instruction in the ID stage
        end
        else
        begin
            if (IF_ID_write_ID) /// Only update IF/ID registers if we are not stalling
            begin
                pc_curr_ID <= pc_curr_IF;
                inst_ID <= inst_IF;
            end
            else
            begin
                pc_curr_ID <= pc_curr_ID; /// Stall IF/ID registers, they remain unchanged
                inst_ID <= inst_ID; /// Stall IF/ID registers, they remain unchanged
            end
        end
    end
end

/// 2nd stage, the Instruction Decode Stage(ID)
wire [6:0] funct7_ID;
wire [4:0] rt_ID;
wire [4:0] rs_ID;
wire [2:0] funct3_ID;
wire [4:0] rd_ID;
wire [6:0] opcode_ID;
wire [31:0] IMM_ID;
wire REG_WR_ID;
wire ALU_SRC_ID;
wire MEM_RD_ID;
wire MEM_WR_ID;
wire branch_ID;
wire MEM_TO_REG_ID;
wire [1:0] ALU_OP_ID;
wire [31:0] rs_data_ID;
wire [31:0] rt_data_ID;

ISA_DEC ISA_DEC_ID
(
    .inst(inst_ID),
    .opcode(opcode_ID),
    .rd(rd_ID),
    .funct3(funct3_ID),
    .rs(rs_ID),
    .rt(rt_ID),
    .funct7(funct7_ID)
);

CON_UNIT CON_UNIT_ID
(
    .inst(inst_ID),
    .opcode(opcode_ID),
    .REG_WR(REG_WR_ID),
    .ALU_SRC(ALU_SRC_ID),
    .MEM_WR(MEM_WR_ID),
    .MEM_RD(MEM_RD_ID),
    .ALU_OP(ALU_OP_ID),
    .branch(branch_ID),
    .MEM_TO_REG(MEM_TO_REG_ID),
    .IMM(IMM_ID)
);

REGFILE REGFILE_ID
(
    .clk(clk),
    .rst_n(rst_n),
    .w_en(REG_WR_WB), /// Route from WB stage
    .rs(rs_ID),
    .rt(rt_ID),
    .rd(rd_WB),         /// Route from WB stage
    .w_data(W_DATA_WB), /// Route from WB stage
    .r_data_s(rs_data_ID),
    .r_data_t(rt_data_ID)
);

wire PC_write_ID;
wire IF_ID_write_ID;
wire bubble_ID;

HZD_UNIT HZD_UNIT_ID
(
    .rs_ID(rs_ID),
    .rt_ID(rt_ID),
    .rd_EX(rd_EX),
    .MEM_RD_EX(MEM_RD_EX),
    .PC_write(PC_write_ID),
    .IF_ID_write(IF_ID_write_ID),
    .bubble(bubble_ID)
);

/// ID/EX Pipeline Registers
reg [31:0] pc_curr_EX;
reg [31:0] rs_data_EX;
reg [31:0] rt_data_EX;
reg [31:0] IMM_EX;
reg [4:0] rs_EX;
reg [4:0] rt_EX;
reg [4:0] rd_EX;
reg [2:0] funct3_EX;
reg [6:0] funct7_EX;
reg [1:0] ALU_OP_EX;
reg ALU_SRC_EX;
reg branch_EX;
reg MEM_WR_EX;
reg MEM_RD_EX;
reg MEM_TO_REG_EX;
reg REG_WR_EX;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        pc_curr_EX <= 32'b0;
        rs_data_EX <= 32'b0;
        rt_data_EX <= 32'b0;
        IMM_EX <= 32'b0;
        rs_EX <= 5'b0;
        rt_EX <= 5'b0;
        rd_EX <= 5'b0;
        funct3_EX <= 3'b0;
        funct7_EX <= 7'b0;
        ALU_OP_EX <= 2'b0;
        ALU_SRC_EX <= 1'b0;
        branch_EX <= 1'b0;
        MEM_WR_EX <= 1'b0;
        MEM_RD_EX <= 1'b0;
        MEM_TO_REG_EX <=1'b0;
        REG_WR_EX <= 1'b0;
    end
    else
    begin
        pc_curr_EX <= pc_curr_ID;
        rs_data_EX <= rs_data_ID;
        rt_data_EX <= rt_data_ID;
        IMM_EX <= IMM_ID;
        rs_EX <= rs_ID;
        rt_EX <= rt_ID;
        rd_EX <= rd_ID;
        funct3_EX <= funct3_ID;
        funct7_EX <= funct7_ID;
        if (bubble_ID||PCSrc) /// If there is a bubble or process is flushed due to branching, we want to insert a NOP in the EX stage by setting control signals to 0
        begin
            ALU_OP_EX <= 2'b0;
            ALU_SRC_EX <= 1'b0;
            branch_EX <= 1'b0;
            MEM_WR_EX <= 1'b0;
            MEM_RD_EX <= 1'b0;
            MEM_TO_REG_EX <= 1'b0;
            REG_WR_EX <= 1'b0;
        end
        else
        begin
            ALU_OP_EX <= ALU_OP_ID;
            ALU_SRC_EX <= ALU_SRC_ID;
            branch_EX <= branch_ID;
            MEM_WR_EX <= MEM_WR_ID;
            MEM_RD_EX <= MEM_RD_ID;
            MEM_TO_REG_EX <= MEM_TO_REG_ID;
            REG_WR_EX <= REG_WR_ID;
        end
    end 
end

/// 3rd stage, the Execution Stage (EX)
wire [3:0] ALU_CON_EX;
wire [31:0] b_EX;
wire [31:0] res_EX;
wire zero_EX;
wire [31:0] pc_branch_EX;

ALU_DEC ALU_DEC_EX
(
    .ALU_OP(ALU_OP_EX),
    .funct3(funct3_EX),
    .funct7(funct7_EX),
    .ALU_CON(ALU_CON_EX)
);

wire [1:0] FWD_A;
wire [1:0] FWD_B;

FWD_UNIT fwd_unit_ex
(
    .rs_EX(rs_EX),
    .rt_EX(rt_EX),
    .rd_MEM(rd_MEM),
    .rd_WB(rd_WB),
    .REG_WR_MEM(REG_WR_MEM),
    .REG_WR_WB(REG_WR_WB),
    .FWD_A(FWD_A),
    .FWD_B(FWD_B)
);

reg [31:0] alu_input_a;
reg [31:0] fwd_input_rt;

always @(*)
begin
    /// Forwarding logic for input A of ALU
    case(FWD_A)
        2'b00: alu_input_a = rs_data_EX; /// No forwarding
        2'b01: alu_input_a = W_DATA_WB;  /// Forward from WB stage
        2'b10: alu_input_a = res_MEM;    /// Forward from MEM stage
        default: alu_input_a = rs_data_EX;
    endcase

    /// Forwarding logic for input B of ALU (pre-immediate)
    case(FWD_B)
        2'b00: fwd_input_rt = rt_data_EX; /// No forwarding
        2'b01: fwd_input_rt = W_DATA_WB;  /// Forward from WB stage
        2'b10: fwd_input_rt = res_MEM;    /// Forward from MEM stage
        default: fwd_input_rt = rt_data_EX;
    endcase
end

assign b_EX = (ALU_SRC_EX) ? IMM_EX : fwd_input_rt; 

ALU ALU_EX
(
    .a(alu_input_a),
    .b(b_EX),
    .ALU_CON(ALU_CON_EX),
    .res(res_EX),
    .zero(zero_EX)
);

PC_ADDER PC_ADDER_EX
(
    .pc_curr(pc_curr_EX),
    .pc_ofst(IMM_EX),
    .pc_next(pc_branch_EX)
);

/// Branch decision now selects on funct3 (BEQ/BNE/BLT/BGE/BLTU/BGEU)
/// Instead of only the ALU zero flag, operands are the forwarded rs or rt
wire PCSrc_take;
BRANCH_UNIT branch_unit_ex
(
    .a(alu_input_a),
    .b(fwd_input_rt),
    .funct3(funct3_EX),
    .branch(branch_EX),
    .take(PCSrc_take)
);
assign PCSrc = PCSrc_take;

/// EX/MEM Pipeline Registers
reg [31:0] res_MEM;
reg [31:0] rt_data_MEM;
reg [4:0] rd_MEM;
reg MEM_WR_MEM;
reg MEM_RD_MEM;
reg MEM_TO_REG_MEM;
reg REG_WR_MEM;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        res_MEM <= 32'b0;
        rt_data_MEM <= 32'b0;
        rd_MEM <= 5'b0;
        MEM_WR_MEM <= 1'b0;
        MEM_RD_MEM <= 1'b0;
        MEM_TO_REG_MEM <= 1'b0;
        REG_WR_MEM <= 1'b0;
    end
    else
    begin
        res_MEM <= res_EX;
        rt_data_MEM <= fwd_input_rt; 
        rd_MEM <= rd_EX;
        MEM_WR_MEM <= MEM_WR_EX;
        MEM_RD_MEM <= MEM_RD_EX;
        MEM_TO_REG_MEM <= MEM_TO_REG_EX;
        REG_WR_MEM <= REG_WR_EX;
    end
end

/// 4th stage, the Memory Stage (MEM)
wire [31:0] R_DATA_MEM;

DMEM DMEM_MEM
(
    .clk(clk),
    .MEM_RD(MEM_RD_MEM),
    .MEM_WR(MEM_WR_MEM),
    .addr(res_MEM),
    .W_DATA(rt_data_MEM),
    .R_DATA(R_DATA_MEM)
);

/// MEM/WB Pipeline Registers
reg [31:0] MEM_R_DATA_WB;
reg [31:0] res_WB;
reg [4:0] rd_WB;
reg MEM_TO_REG_WB;
reg REG_WR_WB;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        MEM_R_DATA_WB <= 32'b0;
        res_WB <= 32'b0;
        rd_WB <= 5'b0;
        MEM_TO_REG_WB <= 1'b0;
        REG_WR_WB <= 1'b0;
    end
    else
    begin
        MEM_R_DATA_WB <= R_DATA_MEM;
        res_WB <= res_MEM;
        rd_WB <= rd_MEM;
        MEM_TO_REG_WB <= MEM_TO_REG_MEM;
        REG_WR_WB <= REG_WR_MEM;
    end
end

/// 5th stage, the Write-Back Stage (WB)
wire [31:0] W_DATA_WB;

assign W_DATA_WB = (MEM_TO_REG_WB) ? MEM_R_DATA_WB : res_WB; 

endmodule