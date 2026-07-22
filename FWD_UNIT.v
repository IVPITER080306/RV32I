module FWD_UNIT
(
    input wire[4:0] rs_EX,   /// source register for EX stage
    input wire[4:0] rt_EX,   /// second source register for EX stage
    input wire[4:0] rd_MEM,  /// destination register for MEM stage
    input wire[4:0] rd_WB,   /// destination register for WB stage
    input wire REG_WR_MEM,   /// write enable for MEM stage
    input wire REG_WR_WB,    /// write enable for WB stage
    
    output reg[1:0] FWD_A,   /// forwarding control signal for source register 1 in EX stage
    output reg[1:0] FWD_B    /// forwarding control signal for source register 2 in EX stage
);

always @(*)
begin
    FWD_A = 2'b00; /// in cases where no forwarding is needed, we select the original register value
    FWD_B = 2'b00; /// same here for the second source register

    if (REG_WR_MEM && (rd_MEM != 5'b0) && (rd_MEM == rs_EX)) /// Check if MEM stage is writing to a register and if that register matches rs_EX
    begin
        FWD_A = 2'b10; /// Forward from MEM stage
    end
    else if (REG_WR_WB && (rd_WB != 5'b0) && (rd_WB == rs_EX)) /// Check if WB stage is writing to a register and if that register matches rs_EX
    begin
        FWD_A = 2'b01; /// Forward from WB stage
    end
    if (REG_WR_MEM && (rd_MEM != 5'b0) && (rd_MEM == rt_EX)) ///same logic for the second source register rt_EX
    begin
        FWD_B = 2'b10; /// Forward from MEM stage
    end
    else if (REG_WR_WB && (rd_WB != 5'b0) && (rd_WB == rt_EX)) ///same logic for the second source register rt_EX
    begin
        FWD_B = 2'b01; /// Forward from WB stage
    end
end
endmodule