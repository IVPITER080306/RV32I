module REG (
input wire[31:0] d,  ///D flip flop input
input wire clk, ///synchronous clock input
input wire w_en, ///synchronous high enabled write
input wire rst_n, ///asynchronous low enabled reset
output reg[31:0] q ///D flip flop output
);
///simple register cell with asynchrous low enabled reset and synchronous high enabled write
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        q <= 32'b0; ///reset value of register is 0
    end
   else
        if (w_en)
        begin
            q <= d; ///write value on register when write enable is high
        end
        else
        begin
            q <= q; ///hold value of register when write enable is low
        end
end
endmodule