module PC_ADDER
(
    input wire[31:0] pc_curr, ///takes current PC value form PC
    input wire[31:0] pc_ofst, ///takes ofset value computed from CON_UNIT or through general instruction flow
    output reg[31:0] pc_next ///outputs next PC value for PC
);

always @(*)
begin
    pc_next = pc_curr + pc_ofst; ///simple calculation
end

endmodule