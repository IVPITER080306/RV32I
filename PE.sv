module PE (
    input  wire clk,  ///synchronous clock input
    input  wire clear,  ///synchronous high enabled clear      
    input  wire valid_a_in, ///synchronous high enabled valid for a_in
    input  wire valid_b_in, ///synchronous high enabled valid for b_in
    input  wire [31:0] a_in, ///input for operand a
    input  wire [31:0] b_in, ///input for operand b
    output reg [31:0] a_out, ///output for operand a
    output reg [31:0] b_out, ///output for operand b
    output reg valid_a_out, ///outflow for next PE
    output reg valid_b_out, ///outflow for next PE 
    output reg signed [63:0] c_out ///64 bit signed output for accumulation of a*b      
);
    always @(posedge clk) 
    begin
        a_out <= a_in; ///pass through a_in to a_out
        b_out <= b_in; ///pass through b_in to b_out
        valid_a_out <= valid_a_in; ///pass through valid_a_in to valid_a_out
        valid_b_out <= valid_b_in; ///pass through valid_b_in to valid_b_out

        if(clear)
        begin
            c_out <= 0; ///clear the accumulation value when clear is high
        end
        else if(valid_a_in && valid_b_in) ///both valid_a_in and valid_b_in are high, we accumulate the product of a_in and b_in to c_out
        begin
            c_out <= c_out + ($signed(a_in) * $signed(b_in)); ///accumulate the product of a_in and b_in to c_out
        end
        else
        begin
            c_out <= c_out; ///hold the value of c_out when either valid_a_in or valid_b_in is low
        end
    end
endmodule