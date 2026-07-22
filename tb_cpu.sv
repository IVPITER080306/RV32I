`timescale 1ns / 1ps

module tb_cpu;

    // Standard testbench signals
    logic clk;
    logic rst_n;
    
    // CPU Instantiation
    CPU dut (
        .clk(clk),
        .rst_n(rst_n)
    );

    // Clock Generation (10ns period)
    always #5 clk = ~clk;

    // Self-Checking Task 
    int errors = 0;
    
    task automatic check_register(input int reg_num, input logic [31:0] expected_val);
        logic [31:0] actual_val; 
        begin
            // Use a case statement so Icarus gets the constant indices it needs during elaboration
            case (reg_num)
                0:  actual_val = 32'b0; // x0 is always hardwired to 0
                1:  actual_val = dut.REGFILE_ID.reg_gen_xi[1].reg_xi.q;
                2:  actual_val = dut.REGFILE_ID.reg_gen_xi[2].reg_xi.q;
                3:  actual_val = dut.REGFILE_ID.reg_gen_xi[3].reg_xi.q;
                4:  actual_val = dut.REGFILE_ID.reg_gen_xi[4].reg_xi.q;
                5:  actual_val = dut.REGFILE_ID.reg_gen_xi[5].reg_xi.q;
                6:  actual_val = dut.REGFILE_ID.reg_gen_xi[6].reg_xi.q;
                7:  actual_val = dut.REGFILE_ID.reg_gen_xi[7].reg_xi.q;
                8:  actual_val = dut.REGFILE_ID.reg_gen_xi[8].reg_xi.q;
                9:  actual_val = dut.REGFILE_ID.reg_gen_xi[9].reg_xi.q;
                10: actual_val = dut.REGFILE_ID.reg_gen_xi[10].reg_xi.q;
                11: actual_val = dut.REGFILE_ID.reg_gen_xi[11].reg_xi.q;
                12: actual_val = dut.REGFILE_ID.reg_gen_xi[12].reg_xi.q;
                13: actual_val = dut.REGFILE_ID.reg_gen_xi[13].reg_xi.q;
                14: actual_val = dut.REGFILE_ID.reg_gen_xi[14].reg_xi.q;
                15: actual_val = dut.REGFILE_ID.reg_gen_xi[15].reg_xi.q;
                16: actual_val = dut.REGFILE_ID.reg_gen_xi[16].reg_xi.q;
                17: actual_val = dut.REGFILE_ID.reg_gen_xi[17].reg_xi.q;
                18: actual_val = dut.REGFILE_ID.reg_gen_xi[18].reg_xi.q;
                19: actual_val = dut.REGFILE_ID.reg_gen_xi[19].reg_xi.q;
                20: actual_val = dut.REGFILE_ID.reg_gen_xi[20].reg_xi.q;
                21: actual_val = dut.REGFILE_ID.reg_gen_xi[21].reg_xi.q;
                22: actual_val = dut.REGFILE_ID.reg_gen_xi[22].reg_xi.q;
                23: actual_val = dut.REGFILE_ID.reg_gen_xi[23].reg_xi.q;
                24: actual_val = dut.REGFILE_ID.reg_gen_xi[24].reg_xi.q;
                25: actual_val = dut.REGFILE_ID.reg_gen_xi[25].reg_xi.q;
                26: actual_val = dut.REGFILE_ID.reg_gen_xi[26].reg_xi.q;
                27: actual_val = dut.REGFILE_ID.reg_gen_xi[27].reg_xi.q;
                28: actual_val = dut.REGFILE_ID.reg_gen_xi[28].reg_xi.q;
                29: actual_val = dut.REGFILE_ID.reg_gen_xi[29].reg_xi.q;
                30: actual_val = dut.REGFILE_ID.reg_gen_xi[30].reg_xi.q;
                31: actual_val = dut.REGFILE_ID.reg_gen_xi[31].reg_xi.q;
                default: actual_val = 32'bx;
            endcase
            
            if (actual_val !== expected_val) begin
                $display("[FAIL] x%0d: Expected %0d, Got %0d", reg_num, expected_val, actual_val);
                errors++;
            end else begin
                $display("[PASS] x%0d: Correctly holds %0d", reg_num, expected_val);
            end
        end
    endtask

    // Main Test Sequence
    initial 
    begin
        $display("========================================");
        $display("   STARTING CPU PIPELINE VERIFICATION   ");
        $display("========================================");

        // Initialize and Reset
        clk = 0;
        rst_n = 0;
        
        // Hold reset for a few cycles to clear all pipeline registers
        #20; 
        rst_n = 1;

        // Let the CPU run for 20 clock cycles to complete execution
        #200; 

        $display("\n--- Checking Pipeline Results ---");
        
        // 1. Check basic arithmetic and forwarding
        check_register(3, 32'd15); // x3 should be 15
        
        // 2. Check Load-Use Hazard Stall logic
        check_register(5, 32'd20); // x5 should be 20 

        // 3. Check Branch Control Hazard Flush logic
        check_register(6, 32'd0);  // x6 MUST be 0 (flushed instruction)
        
        // 4. Check Branch Target Execution
        check_register(7, 32'd42); // x7 should be 42

        $display("========================================");
        if (errors == 0)
            $display("  ALL TESTS PASSED! CPU IS FLAWLESS.  ");
        else
            $display("  TEST FAILED WITH %0d ERRORS.", errors);
        $display("========================================");

        $finish; /// End simulation
    end

endmodule