module DMEM
(
    input wire clk, ///for synchrous writes to memory
    input wire MEM_RD, ///received from CON_UNIT, decides whether to read from memory or not
    input wire MEM_WR, ///received from CON_UNIT, decides whether to write on memory or not
    input wire[31:0] addr, ///address for memory access, received from ALU
    input wire[31:0] W_DATA, ///data to write on memory, received from ALU
    output reg[31:0] R_DATA ///data read from memory, sent to REGFILE
);

reg[31:0] ram [0:63]; ///maps 32 register to 64 rams to account for upto 64 storage locations in memory, total size of data memory is 64*32 bits = 256 bytes


always @(posedge clk) ///synchrous writes to memory
    begin
        if (MEM_WR) 
            begin
                ram[addr[7:2]] <= W_DATA; ///using 6 bits of adress for ram since the no. of rams is 64 which is 2^6, and since the address is in bytes, we need to right shift by 2 to get the word address
            end
    end

always @(*) ///asynchronous reads from memory
    begin
        if (MEM_RD)
            begin
                R_DATA = ram[addr[7:2]]; ///same logic as applied in writes
            end
        else
            begin
                R_DATA = 32'b0; ///if not reading from memory, output is 0
            end
    end
endmodule