module IMEM
(
    input wire[31:0] addr, ///takes address from PC
    output reg[31:0] inst ///outputs instruction
);
reg[31:0] rom [0:63]; ///64 roms of 32 bits each, to store 64 instructions, total size of instruction memory is 64*32 bits = 256 bytes

initial
    begin
        $readmemh("program.txt", rom); ///read from program file and store in rom
    end

    always @(*)
    begin
        inst = rom[addr[7:2]]; ///instruction is a 32 bit value which is composed of right shifted by 2 values of rom which each is 6 bits long(due to rom size of 64 which is 2^6)
    end
endmodule