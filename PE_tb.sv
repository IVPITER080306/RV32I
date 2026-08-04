`timescale 1ns/1ps
module PE_tb;

    // --- DUT interface signals ---
    reg         clk;
    reg         clear;
    reg         valid_a_in, valid_b_in;
    reg  [31:0] a_in, b_in;
    wire [31:0] a_out, b_out;
    wire        valid_a_out, valid_b_out;
    wire signed [63:0] c_out;

    // --- instantiate the PE under test ---
    PE dut (
        .clk(clk), .clear(clear),
        .valid_a_in(valid_a_in), .valid_b_in(valid_b_in),
        .a_in(a_in), .b_in(b_in),
        .a_out(a_out), .b_out(b_out),
        .valid_a_out(valid_a_out), .valid_b_out(valid_b_out),
        .c_out(c_out)
    );

    // --- waveform dump for GTKWave ---
    initial begin
        $dumpfile("PE_tb.vcd");
        $dumpvars(0, PE_tb);
    end

    // --- clock: 10ns period ---
    always #5 clk = ~clk;

    // --- independent reference accumulator ---
    reg signed [63:0] expected;
    integer errors = 0;

    // Drive one REAL operand pair (both valids high) and update the reference.
    // 64-bit signed inputs => full-width signed multiply in the reference.
    task drive_pair(input signed [63:0] a, input signed [63:0] b);
        begin
            a_in = a[31:0]; b_in = b[31:0];
            valid_a_in = 1'b1; valid_b_in = 1'b1;
            expected = expected + (a * b);
            @(posedge clk); #1;
        end
    endtask

    // Drive a pair with chosen valid bits; only update the reference if BOTH valid.
    task drive_pair_v(input signed [63:0] a, input signed [63:0] b,
                      input va, input vb);
        begin
            a_in = a[31:0]; b_in = b[31:0];
            valid_a_in = va; valid_b_in = vb;
            if (va && vb) expected = expected + (a * b);  // PE should accumulate iff both
            @(posedge clk); #1;
        end
    endtask

    task check(input [255:0] label);
        begin
            if (c_out !== expected) begin
                $display("[FAIL] %0s: c_out=%0d expected=%0d", label, c_out, expected);
                errors = errors + 1;
            end else
                $display("[PASS] %0s: c_out=%0d", label, c_out);
        end
    endtask

    initial begin
        // init + clear
        clk = 0; clear = 1; valid_a_in = 0; valid_b_in = 0;
        a_in = 0; b_in = 0; expected = 0;
        @(posedge clk); #1; clear = 0;

        // --- Test 1: dot product with negatives (both valids high) ---
        //   A=[5,3,-2,7]  B=[4,-6,8,2]  => 0
        drive_pair( 5,  4);
        drive_pair( 3, -6);
        drive_pair(-2,  8);
        drive_pair( 7,  2);
        valid_a_in = 0; valid_b_in = 0;
        @(posedge clk); #1;
        check("dot product with negatives");

        // --- Test 2: clear zeroes accumulator ---
        clear = 1; @(posedge clk); #1; clear = 0; expected = 0;
        check("clear zeroes accumulator");

        // --- Test 3: both valids low => holds ---
        drive_pair_v(100, 100, 1'b0, 1'b0);
        check("holds when both valids low");

        // --- Test 4: only valid_a high => must NOT accumulate ---
        drive_pair_v(50, 9, 1'b1, 1'b0);
        check("valid_a only -> no accumulate");

        // --- Test 5: only valid_b high => must NOT accumulate ---
        drive_pair_v(7, 8, 1'b0, 1'b1);
        check("valid_b only -> no accumulate");

        // --- Test 6: both valids high => DOES accumulate ---
        drive_pair_v(6, 6, 1'b1, 1'b1);   // +36 onto the (still 0) accumulator
        valid_a_in = 0; valid_b_in = 0;
        @(posedge clk); #1;
        check("both valids -> accumulate");

        // --- Test 7: large operands exercise 64-bit width ---
        clear = 1; @(posedge clk); #1; clear = 0; expected = 0;
        drive_pair(64'sh0000_0000_7FFF_FFFF, 64'sh0000_0000_0000_0002);
        valid_a_in = 0; valid_b_in = 0; @(posedge clk); #1;
        check("64-bit width (large product)");

        // --- Test 8: neg x neg = pos ---
        clear = 1; @(posedge clk); #1; clear = 0; expected = 0;
        drive_pair(-4, -5);
        valid_a_in = 0; valid_b_in = 0; @(posedge clk); #1;
        check("negative x negative = positive");

        if (errors == 0) $display("\n  ALL PE TESTS PASSED\n");
        else             $display("\n  %0d PE TEST(S) FAILED\n", errors);
        $finish;
    end
endmodule