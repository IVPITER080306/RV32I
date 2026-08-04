module HZD_UNIT
(
    input wire[4:0] rs_ID,
    input wire[4:0] rt_ID,
    input wire[4:0] rd_EX,
    input wire MEM_RD_EX,
    output reg PC_write,
    output reg IF_ID_write,
    output reg bubble
);

always @(*)
begin
    ///under no hazard conditions, we want to write to the PC and IF/ID registers and we do not want to insert a bubble
    PC_write = 1'b1;
    IF_ID_write = 1'b1;
    bubble = 1'b0;

    if(MEM_RD_EX && ((rd_EX == rs_ID) || (rd_EX == rt_ID))) ///if there is a load instruction in the EX stage and its destination register matches either source register of the instruction in the ID stage, we have a hazard
    begin
        PC_write = 1'b0; ///stall the PC
        IF_ID_write = 1'b0; ///stall the IF/ID pipeline register
        bubble = 1'b1; ///insert a bubble in the EX stage to resolve the hazard
    end
    else
    begin
        PC_write = 1'b1; ///no hazard, normal operation
        IF_ID_write = 1'b1; ///no hazard, normal operation
        bubble = 1'b0; ///no hazard, normal operation
    end
end
endmodule