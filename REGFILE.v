module REGFILE
(
    input wire clk, ///synchronous clock for register writes
    input wire rst_n, ///asynchronous low enabled reset for registers
    input wire w_en, ///synchronous high enabled write for registers, received from CON_UNIT
    input wire[4:0] rs, ///source register 1
    input wire[4:0] rt, ///source register 2
    input wire[4:0] rd, ///destination register
    input wire[31:0] w_data, ///input data to write on register
    output reg[31:0] r_data_s, ///read data from rs
    output reg[31:0] r_data_t ///read data from rt
);

wire[31:0] load_reg;

assign load_reg = w_en ?((32'd1 << rd) & (32'hFFFFFFFE)) : 32'b0; ///provides one-hot encoding and masking, provides enable signal for ith register

wire [31:0] reg_outputs [31:0];

genvar i; ///generates 32 registers using REG module
generate
    for (i = 0; i < 32; i = i+1)
    begin : reg_gen_xi
        REG reg_xi
        (
            .clk(clk),
            .rst_n(rst_n),
            .w_en(load_reg[i]),
            .d (w_data),
            .q (reg_outputs[i])
        );
    end
endgenerate

    always @(*) ///rs selection case statement for register reads
        begin
            if (w_en && (rd != 5'b0) && (rd == rs)) ///WB->ID write-first bypass
                r_data_s = w_data;
            else
            case (rs)
                5'b00000: r_data_s = 32'b0;
                5'b00001: r_data_s = reg_outputs[1];
                5'b00010: r_data_s = reg_outputs[2];
                5'b00011: r_data_s = reg_outputs[3];
                5'b00100: r_data_s = reg_outputs[4];
                5'b00101: r_data_s = reg_outputs[5];
                5'b00110: r_data_s = reg_outputs[6];
                5'b00111: r_data_s = reg_outputs[7];
                5'b01000: r_data_s = reg_outputs[8];
                5'b01001: r_data_s = reg_outputs[9];
                5'b01010: r_data_s = reg_outputs[10];
                5'b01011: r_data_s = reg_outputs[11];
                5'b01100: r_data_s = reg_outputs[12];
                5'b01101: r_data_s = reg_outputs[13];
                5'b01110: r_data_s = reg_outputs[14];
                5'b01111: r_data_s = reg_outputs[15];
                5'b10000: r_data_s = reg_outputs[16];
                5'b10001: r_data_s = reg_outputs[17];
                5'b10010: r_data_s = reg_outputs[18];
                5'b10011: r_data_s = reg_outputs[19];
                5'b10100: r_data_s = reg_outputs[20];
                5'b10101: r_data_s = reg_outputs[21];
                5'b10110: r_data_s = reg_outputs[22];
                5'b10111: r_data_s = reg_outputs[23];
                5'b11000: r_data_s = reg_outputs[24];
                5'b11001: r_data_s = reg_outputs[25];
                5'b11010: r_data_s = reg_outputs[26];
                5'b11011: r_data_s = reg_outputs[27];
                5'b11100: r_data_s = reg_outputs[28];
                5'b11101: r_data_s = reg_outputs[29];
                5'b11110: r_data_s = reg_outputs[30];
                5'b11111: r_data_s = reg_outputs[31];
                default: r_data_s = reg_outputs[rs];
            endcase
        end

        always @(*) ///rt selection case statements for register reads
        begin
            if (w_en && (rd != 5'b0) && (rd == rt)) ///WB->ID write-first bypass
                r_data_t = w_data;
            else
            case (rt)
                5'b00000: r_data_t = 32'b0;
                5'b00001: r_data_t = reg_outputs[1];
                5'b00010: r_data_t = reg_outputs[2];
                5'b00011: r_data_t = reg_outputs[3];
                5'b00100: r_data_t = reg_outputs[4];
                5'b00101: r_data_t = reg_outputs[5];
                5'b00110: r_data_t = reg_outputs[6];
                5'b00111: r_data_t = reg_outputs[7];
                5'b01000: r_data_t = reg_outputs[8];
                5'b01001: r_data_t = reg_outputs[9];
                5'b01010: r_data_t = reg_outputs[10];
                5'b01011: r_data_t = reg_outputs[11];
                5'b01100: r_data_t = reg_outputs[12];
                5'b01101: r_data_t = reg_outputs[13];
                5'b01110: r_data_t = reg_outputs[14];
                5'b01111: r_data_t = reg_outputs[15];
                5'b10000: r_data_t = reg_outputs[16];
                5'b10001: r_data_t = reg_outputs[17];
                5'b10010: r_data_t = reg_outputs[18];
                5'b10011: r_data_t = reg_outputs[19];
                5'b10100: r_data_t = reg_outputs[20];
                5'b10101: r_data_t = reg_outputs[21];
                5'b10110: r_data_t = reg_outputs[22];
                5'b10111: r_data_t = reg_outputs[23];
                5'b11000: r_data_t = reg_outputs[24];
                5'b11001: r_data_t = reg_outputs[25];
                5'b11010: r_data_t = reg_outputs[26];
                5'b11011: r_data_t = reg_outputs[27];
                5'b11100: r_data_t = reg_outputs[28];
                5'b11101: r_data_t = reg_outputs[29];
                5'b11110: r_data_t = reg_outputs[30];
                5'b11111: r_data_t = reg_outputs[31];
                default: r_data_t = reg_outputs[rt];
            endcase
        end
endmodule