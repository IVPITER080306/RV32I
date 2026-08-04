module BRANCH_UNIT
(
    input  wire [31:0] a,       /// forwarded rs, its not an immediate, but the value of the register after forwarding (fwd_input_rs)
    input  wire [31:0] b,       /// forwarded rt, its not an immediate, but the value of the register after forwarding (fwd_input_rt)
    input  wire [2:0] funct3,  /// branch type selector
    input  wire branch,  /// branch enable from control (branch_EX)
    output reg  take     ///redirect PC to branch target
);

    /// Three primitive comparisons computed in parallel; the funct3 mux
    /// picks which one (and its polarity) decides the branch.
    wire eq   = (a == b);                  /// equality
    wire lt_s = ($signed(a) < $signed(b)); /// signed less-than
    wire lt_u = (a < b);                   /// unsigned less-than

    always @(*)
    begin
        case (funct3)
            3'b000: take = branch &  eq;   /// BEQ
            3'b001: take = branch & ~eq;   /// BNE
            3'b100: take = branch &  lt_s; /// BLT
            3'b101: take = branch & ~lt_s; /// BGE
            3'b110: take = branch &  lt_u; /// BLTU
            3'b111: take = branch & ~lt_u; /// BGEU
            default: take = 1'b0;          /// default case, should never happen
        endcase
    end
endmodule