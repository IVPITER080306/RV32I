module systolic_array
(
    input wire clk, ///synchronous clock input
    input wire clear, ///synchronous high enabled clear
    input wire[31:0] a_in_r0, a_in_r1, a_in_r2, a_in_r3, ///input for operand a for each row at each new defined edge each clock cycle
    input wire[31:0] b_in_c0, b_in_c1, b_in_c2, b_in_c3, ///input for operand b for each column at each new defined edge each clock cycle
    input wire valid_a_in_r0, valid_a_in_r1, valid_a_in_r2, valid_a_in_r3, ///synchronous high enabled valid for a_in for each row
    input wire valid_b_in_c0, valid_b_in_c1, valid_b_in_c2, valid_b_in_c3, ///synchronous high enabled valid for b_in for each column
    output wire signed [63:0] c_out [0:3][0:3] ///64 bit signed output for accumulation of a*b for each PE in the systollic array
);

wire [31:0] a_wire [0:3][0:4]; ///elements of A(i,j) entereing PE(i,j)
wire [31:0] b_wire [0:4][0:3]; ///elements of B(i,j) entereing PE(i,j)
wire valid_a_wire [0:3][0:4]; ///valid bits for a_wire
wire valid_b_wire [0:4][0:3]; ///valid bits for b_wire

assign a_wire[0][0] = a_in_r0; assign valid_a_wire[0][0] = valid_a_in_r0; ///assigning all the edges of A to the inputs of our PEs
assign a_wire[1][0] = a_in_r1; assign valid_a_wire[1][0] = valid_a_in_r1;
assign a_wire[2][0] = a_in_r2; assign valid_a_wire[2][0] = valid_a_in_r2;
assign a_wire[3][0] = a_in_r3; assign valid_a_wire[3][0] = valid_a_in_r3;

assign b_wire[0][0] = b_in_c0; assign valid_b_wire[0][0] = valid_b_in_c0; ///assigning all the edges of B to the inputs of our PEs
assign b_wire[0][1] = b_in_c1; assign valid_b_wire[0][1] = valid_b_in_c1;
assign b_wire[0][2] = b_in_c2; assign valid_b_wire[0][2] = valid_b_in_c2;
assign b_wire[0][3] = b_in_c3; assign valid_b_wire[0][3] = valid_b_in_c3;

genvar i, j;
generate
    for (i = 0; i < 4; i = i+1)
    begin : row
        for (j = 0; j < 4; j = j+1)
        begin : col
            PE pe
            (
                .clk(clk),
                .clear(clear),
                .valid_a_in(valid_a_wire[i][j]),
                .valid_b_in(valid_b_wire[i][j]),
                .a_in(a_wire[i][j]),
                .b_in(b_wire[i][j]),
                .a_out(a_wire[i][j+1]),
                .b_out(b_wire[i+1][j]),
                .valid_a_out(valid_a_wire[i][j+1]),
                .valid_b_out(valid_b_wire[i+1][j]),
                .c_out(c_out[i][j])
            ); ///simple wire connection of each PE in the systollic array to the next PE in the same row and column
        end
    end
endgenerate

endmodule