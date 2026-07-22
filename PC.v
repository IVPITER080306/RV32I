module PC
(
    input wire clk, ///synchrous device (on clock)
    input wire rst_n, ///asynchronous low enabled reset
    input wire PC_write, ///very important for stalling to implement the hazard detection unit
    input wire[31:0] pc_next, ///takes in next value form PC_ADDER 
    output reg[31:0] pc_curr ///outputs current value for PC and goes to PC_ADDER
);

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        pc_curr <= 32'b0; ///reset triggers PC value to go to start
    end
    else
    begin
        if (PC_write) ///if PC_write is high, we update the PC value to the next value
        begin
            pc_curr <= pc_next;
        end
         ///if PC_write is low, we stall and keep the current PC value unchanged
         else
         begin
            pc_curr <= pc_curr; ///stalling the PC, it remains unchanged
         end
    end
end
endmodule