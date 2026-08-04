module sys_ctrl
(
    input  wire clk,
    input  wire rst_n,
    input  wire wr,             /// write strobe coming from CPU
    input  wire rd,             /// read strobe coming from CPU
    input  wire [31:0] addr,           /// address needed from CPU to select the register to read/write
    input  wire [31:0] wdata,          /// write data from CPU
    output reg [31:0] rdata,          /// read data to CPU (0 when not addressed)
    output reg array_clear,    /// pulse to zero all accumulators at run start
    output reg [31:0] a_r0, a_r1, a_r2, a_r3,   // A edge inputs (row lefts)
    output reg [31:0] b_c0, b_c1, b_c2, b_c3,   // B edge inputs (col tops)
    output reg va_r0, va_r1, va_r2, va_r3, // valid_a per row
    output reg vb_c0, vb_c1, vb_c2, vb_c3, // valid_b per col
    input  wire signed [63:0] c_out [0:3][0:3]     // array accumulators
);

    localparam IDLE = 2'd0,INIT = 2'd1, RUN = 2'd2, DONE = 2'd3;
    reg [1:0] state;

    reg [31:0] a_buff [0:3][0:3];   /// A[i][j], natural order from CPU
    reg [31:0] b_buff [0:3][0:3];   /// B[i][j], natural order from CPU

    reg [3:0] cyc;                 /// acts as a counter for the skewed edge outputs, and also as a state machine counter for the RUN state
    localparam FINISH = 4'd9;      /// 9 counts needed to complete the 4x4 systolic array operation (4 rows + 4 cols - 1)

    reg done_flag; /// flag to indicate that the systolic array has completed its operation and the results are ready to be read

    reg[6:0] r_index; /// index for reading c_out in row-major order
    reg half_rd; ///flag for reading upper or lower part of word
    reg[3:0] element; /// element index for reading c_out in row-major order
    reg[1:0] i_rd, j_rd; ///i and j indices for reading c_out in row-major order


    always @(posedge clk or negedge rst_n) ///state machine for write operations
    begin
        if (!rst_n) /// reset state machine to IDLE state, reset cyc, array_clear, and done_flag to 0
         begin
            state <= IDLE;
            cyc <= 0;
            array_clear <= 0;
            done_flag <= 0;
        end 
        else 
        begin
            case (state)
                IDLE: /// in IDLE state, we can write to the a_buf and b_buf, and also check for the START bit to go to RUN state
                begin
                    done_flag <= 1'b0; ///reset done_flag in IDLE state
                    array_clear <= 1'b0; ///reset array_clear in IDLE state
                    if(wr)
                    begin
                        if(addr[8:2] <= 7'd15)
                        begin
                            a_buff[addr[5:4]][addr[3:2]] <= wdata; ///write to a_buf if addr in A-block
                        end
                        else if(addr[8:2] >= 7'd16 && addr[8:2] <= 7'd31)
                        begin
                            b_buff[addr[5:4]][addr[3:2]] <= wdata; ///write to b_buf if addr in B-block
                        end
                        else if(addr[8:2] == 7'd32)
                        begin
                            if(wdata[0]) ///if START bit is high, pulse array_clear, reset cyc, and go to RUN state
                            begin
                                array_clear <= 1'b1;
                                cyc <= 4'd0;
                                state <= INIT;
                            end
                        end
                    end
                end
                INIT:
                begin
                    array_clear <= 1'b0; ///reset array_clear in INIT state
                    cyc <= 1'b0; ///reset cyc in INIT state
                    state <= RUN; ///go to RUN state
                end
                RUN: /// when in RUN state, we ignore writes to a_buf and b_buf, and we drive the skewed edge outputs based on cyc, and increment cyc until FINISH is reached
                begin
                    array_clear <= 1'b0; ///reset array_clear in RUN state
                    cyc <= cyc +4'd1; ///increment cyc in RUN state
                    if(cyc == FINISH)
                    begin
                        state <= DONE;
                    end
                end
                DONE: ///in DONE state, we can read the results from c_out, and we can also check for the CLEAR bit to go back to IDLE state 
                begin
                    done_flag <= 1'b1; ///set done_flag high in DONE state
                    if(wr && addr[8:2] == 7'd32 && wdata[1]) ///if CLEAR bit is high, go to IDLE state
                    begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

    always @(*)
    begin
        rdata = 32'b0; ///default value for rdata when not addressed
        r_index = 6'b0; ///default value for r_index when not addressed
        half_rd = 1'b0; ///default value for half_rd when not addressed
        element = 4'b0; ///default value for element when not addressed
        i_rd = 2'b0; ///default value for i_rd when not addressed
        j_rd = 2'b0; ///default value for j_rd when not addressed
        if(rd) /// when rd is high, we read the status or the c_out values based on the address
        begin
            if(addr[8:2] == 7'd32)
            begin
                rdata = {30'd0, (state == RUN), (state == DONE)}; ///status read: bit 0 = done, bit 1 = busy
            end
            else if(addr[8:2] >= 7'd33 && addr[8:2] <= 7'd64) ///c_out read: addr[8:2] = 33..64 maps to c_out[0][0]..c_out[3][3] in row-major order
            begin
                r_index = addr[8:2] - 7'd33; ///index of c_out[i][j] in row-major order
                element = r_index[4:1]; ///element index in row-major order
                i_rd = element[3:2]; ///row index
                j_rd = element[1:0]; ///column index
                half_rd = r_index[0]; ///low or high half
                rdata = half_rd ? c_out[i_rd][j_rd][63:32] : c_out[i_rd][j_rd][31:0]; ///select low or high half of c_out[i][j]
            end
        end
    end
        always @(*)
        begin
            a_r0 = 32'b0; a_r1 = 32'b0; a_r2 = 32'b0; a_r3 = 32'b0; ///default values for a_r0..a_r3 when not driven
            va_r0 = 1'b0; va_r1 = 1'b0; va_r2 = 1'b0; va_r3 = 1'b0; ///default values for va_r0..va_r3 when not driven
            b_c0 = 32'b0; b_c1 = 32'b0; b_c2 = 32'b0; b_c3 = 32'b0; ///default values for b_c0..b_c3 when not driven
            vb_c0 = 1'b0; vb_c1 = 1'b0; vb_c2 = 1'b0; vb_c3 = 1'b0; ///default values for vb_c0..vb_c3 when not driven
            if (state == RUN) ///when in RUN state, we drive the skewed edge outputs based on cyc
            begin
                if (cyc <= 4'd3) ///for cyc = 0..3, we drive the edge outputs with the corresponding a_buff values, and set the valid bits high
                begin
                    a_r0 = a_buff[0][cyc];
                    va_r0 = 1'b1;
                end
                if (cyc >= 4'd1 && cyc <= 4'd4) ///for cyc = 1..4, we drive the edge outputs with the corresponding a_buff values, and set the valid bits high   
                begin
                    a_r1 = a_buff[1][cyc-1];
                    va_r1 = 1'b1;
                end
                if (cyc >= 4'd2 && cyc <= 4'd5) ///for cyc = 2..5, we drive the edge outputs with the corresponding  a_buff values, and set the valid bits high
                begin
                    a_r2 = a_buff[2][cyc-2];
                    va_r2 = 1'b1;
                end
                if (cyc >= 4'd3 && cyc <= 4'd6) ///for cyc = 3..6, we drive the edge outputs with the corresponding a_buff values, and set the valid bits high
                begin
                    a_r3 = a_buff[3][cyc-3];
                    va_r3 = 1'b1;
                end
                if (cyc <= 4'd3) ///for cyc = 0..3, we drive the edge outputs with the corresponding  b_buff values, and set the valid bits high
                begin
                    b_c0 = b_buff[cyc][0];
                    vb_c0 = 1'b1;
                end
                if (cyc >= 4'd1 && cyc <= 4'd4) ///for cyc = 1..4, we drive the edge outputs with the corresponding  b_buff values, and set the valid bits high
                begin
                    b_c1 = b_buff[cyc-1][1];
                    vb_c1 = 1'b1;
                end
                if (cyc >= 4'd2 && cyc <= 4'd5) ///for cyc = 2..5, we drive the edge outputs with the corresponding  b_buff values, and set the valid bits high
                begin
                    b_c2 = b_buff[cyc-2][2];
                    vb_c2 = 1'b1;
                end
                if (cyc >= 4'd3 && cyc <= 4'd6) ///for cyc = 3..6, we drive the edge outputs with the corresponding  b_buff values, and set the valid bits high
                begin
                    b_c3 = b_buff[cyc-3][3];
                    vb_c3 = 1'b1;
                end
            end
        end
endmodule