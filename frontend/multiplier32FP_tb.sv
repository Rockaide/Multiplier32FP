`timescale 1ns / 1ps

module multiplier32FP_tb();

    // System Signals
    logic        clk;
    logic        rst_n;
    
    // Data and Control Inputs
    // Data and Control Inputs
    logic [31:0] a_i = 32'd0;
    logic [31:0] b_i = 32'd0;
    logic        start_i = 1'b0;
    
    // Data and Status Outputs
    logic [31:0] product_o;
    logic        done_o;
    logic        nan_o;
    logic        infinit_o;
    logic        overflow_o;
    logic        underflow_o;

    // Device Under Test (DUT) Instantiation
    multiplier32FP dut (
        .clk(clk),
        .rst_n(rst_n),
        .a_i(a_i),
        .b_i(b_i),
        .start_i(start_i),
        .product_o(product_o),
        .done_o(done_o),
        .nan_o(nan_o),
        .infinit_o(infinit_o),
        .overflow_o(overflow_o),
        .underflow_o(underflow_o)
    );

    // Clock Generation: 40 ns period (25 MHz)
    initial begin
        clk = 1'b1;
        forever #20 clk = ~clk; 
    end

    // Standardized Task for Subsequent Test Cases
    // Enforces the 2-cycle wait rule before starting a new operation
    task check_multiply(
        input logic [31:0] a_val, 
        input logic [31:0] b_val, 
        input logic [31:0] expected_out, 
        input string       test_name
    );
        // Apply inputs
        a_i <= a_val;
        b_i <= b_val;

        // Wait exactly 2 clock cycles after the previous done_o
        repeat(2) @(posedge clk);

        // Assert start using non-blocking assignment
        start_i <= 1'b1;
        @(posedge clk);
        start_i <= 1'b0;

        // Wait for completion
        @(posedge done_o);
        
        // Evaluate and Display
        if (product_o === expected_out) begin
            $display("[SUCCESS] %s | Output: %h", test_name, product_o);
        end else begin
            $display("[FAILED]  %s | Expected: %h | Got: %h", test_name, expected_out, product_o);
        end
    endtask

    // Main Test Stimulus
    initial begin
        // 1. Initialization
        rst_n   = 1'b1;
        a_i     = 32'h00000000;
        b_i     = 32'h00000000;
        start_i = 1'b0;

        $display("========================================");
        $display("   Starting FP Multiplier Simulation    ");
        $display("========================================");

        // 2. Reset Sequence
        #5  rst_n = 1'b0;
        #5  rst_n = 1'b1; 

        // 3. Test Vector 1: Standard Multiplication (2.0 * 3.0 = 6.0)
        a_i <= 32'h40000000; // 2.0
        b_i <= 32'h40400000; // 3.0
        
        #5; // Reach exactly 15 ns
        start_i <= 1'b1;
        @(posedge clk); 
        start_i <= 1'b0;

        @(posedge done_o);
        if (product_o === 32'h40C00000) begin
            $display("[SUCCESS] Test 1: 2.0 * 3.0 = 6.0 | Output: %h", product_o);
        end else begin
            $display("[FAILED]  Test 1: 2.0 * 3.0 = 6.0 | Expected: 40C00000 | Got: %h", product_o);
        end

        // 4. Test Vector 2: Zero Multiplication (6.0 * 0.0 = 0.0)
        check_multiply(32'h40C00000, 32'h00000000, 32'h00000000, "Test 2: 6.0 * 0.0 = 0.0");

        // 5. Test Vector 3: Custom Exception - Overflow Test (Max Float * 2.0)
        // Should output 0x7FFFFFFF per project specifications
        check_multiply(32'h7F7FFFFF, 32'h40000000, 32'h7FFFFFFF, "Test 3: Overflow Handling");

        // 6. Test Vector 4: Custom Exception - NaN Test (0.0 * Infinity)
        // Should output 0x00000000 per project specifications
        check_multiply(32'h00000000, 32'h7F800000, 32'h00000000, "Test 4: NaN Handling     ");

        // 7. Test Vector 5: Negative Multiplication (-1.5 * -2.0 = 3.0)
        // Verifies the XOR sign logic is functioning correctly
        check_multiply(32'hBFC00000, 32'hC0000000, 32'h40400000, "Test 5: -1.5 * -2.0 = 3.0");

        // 8. Test Vector 6: Mixed Sign Multiplication (-2.5 * 4.0 = -10.0)
        check_multiply(32'hC0200000, 32'h40800000, 32'hC1200000, "Test 6: -2.5 * 4.0 = -10.0");

        // 9. Test Vector 7: Custom Exception - Underflow Test
        // Multiplying two extremely small numbers (1.0 * 2^-125)
        // Should trigger underflow flag and output 0x00000000 per specifications
        check_multiply(32'h01000000, 32'h01000000, 32'h00000000, "Test 7: Underflow Handling");

        // 10. Test Vector 8: Denormalized "Dirty Zero" Handling
        // Multiplying a denormalized number (fraction = 5, exp = 0) by 2.0
        // Result should simply double the denormalized fraction to 10 (0x0A)
        check_multiply(32'h00000005, 32'h40000000, 32'h0000000A, "Test 8: Denormalized (Dirty Zero)");

        // 11. Test Vector 9: Explicit Infinity Handling
        // Multiplying +Infinity by 2.0. Result should remain +Infinity.
        check_multiply(32'h7F800000, 32'h40000000, 32'h7F800000, "Test 9: Infinity * Normal");

        $display("========================================");
        $display("          Simulation Complete           ");
        $display("========================================");
        
        repeat(5) @(posedge clk);
        $finish;
    end

endmodule