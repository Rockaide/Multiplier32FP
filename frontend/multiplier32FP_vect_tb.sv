`timescale 1ns / 1ps

module multiplier32FP_vect_tb #(
    // Parameters passed from the Makefile via xrun -defparam
    parameter integer HALF_PERIOD_PS = 5000, 
    parameter integer WAIT_TIME_NS   = 5,
    parameter integer SIM_RUNTIME    = 0
)();

    // System Signals
    logic        clk;
    logic        rst_n;
    
    // Data and Control Inputs
    logic [31:0] a_i;
    logic [31:0] b_i;
    logic        start_i;
    
    // Data and Status Outputs
    logic [31:0] product_o;
    logic        done_o;
    logic        nan_o;
    logic        infinit_o;
    logic        overflow_o;
    logic        underflow_o;

    // File Variables
    integer fd_in;
    integer fd_out;
    integer scan_count;
    logic [31:0] val_a;
    logic [31:0] val_b;
    integer test_count;

    // Variables for verification
    logic [31:0] expected_val;
    integer error_count = 0;
    
    // Clock scaling variable
    real half_period_ns;

    // DUV
    multiplier32FP DUV (
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

    // Task to verify the results
    // Bit-accurate Golden Reference Model for the specific VHDL architecture
    function automatic logic [31:0] get_expected_product(input logic [31:0] a, input logic [31:0] b);
        logic sign_a, sign_b, sign_out;
        logic [7:0] exp_a, exp_b;
        logic [23:0] frac_a, frac_b;
        logic [47:0] frac_prod;
        logic signed [11:0] exp_sum; // Signed to handle negative intermediate exponents
        logic [22:0] frac_out;
        
        // 1. Extract Fields & Append Implicit Bits
        sign_a = a[31]; 
        exp_a = a[30:23]; 
        frac_a = (exp_a == 0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]};
        
        sign_b = b[31]; 
        exp_b = b[30:23]; 
        frac_b = (exp_b == 0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]};
        
        sign_out = sign_a ^ sign_b;
        
        // 2. Exception Handling (Evaluated before math)
        // NaN: Exponent is 255 and fraction is not zero
        if ((exp_a == 8'hFF && a[22:0] != 0) || (exp_b == 8'hFF && b[22:0] != 0)) 
            return 32'h00000000; 
            
        // Infinity * Zero -> NaN
        if ((exp_a == 8'hFF && a[22:0] == 0 && exp_b == 0 && b[22:0] == 0) || 
            (exp_b == 8'hFF && b[22:0] == 0 && exp_a == 0 && a[22:0] == 0)) 
            return 32'h00000000; 
            
        // Infinity
        if (exp_a == 8'hFF || exp_b == 8'hFF) 
            return {sign_out, 8'hFF, 23'd0}; 
            
        // True Zero
        if ((exp_a == 0 && a[22:0] == 0) || (exp_b == 0 && b[22:0] == 0)) 
            return {sign_out, 31'd0}; 
        
        // 3. Datapath Arithmetic
        frac_prod = frac_a * frac_b;
        // Align dirty zero exponents to 1 for calculation
        exp_sum = (exp_a == 0 ? 1 : exp_a) + (exp_b == 0 ? 1 : exp_b) - 127;
        
        // 4. Normalization & Truncation
        if (frac_prod[47] == 1'b1) begin
            exp_sum = exp_sum + 1;
            frac_out = frac_prod[46:24]; // Standard Truncation
        end else if (frac_prod[46] == 1'b1) begin
            frac_out = frac_prod[45:23];
        end else begin
            // Denormalization shift loop
            while (frac_prod[46] == 1'b0 && exp_sum > 1) begin
                frac_prod = frac_prod << 1;
                exp_sum = exp_sum - 1;
            end
            frac_out = frac_prod[45:23];
            
        end
        // Custom Underflow: If exponent drops below representable limits
        if (exp_sum <= 0 || (exp_sum == 1 && frac_prod[46] == 1'b0)) begin
            return 32'h00000000; 
        end
        
        // 5. Final Packing and Overflow
        if (exp_sum >= 255) 
            return 32'h7FFFFFFF; 
            
        return {sign_out, exp_sum[7:0], frac_out};
    endfunction

    // Clock Generation dynamically scaled by Makefile frequency
    initial begin
        half_period_ns = HALF_PERIOD_PS / 1000.0;
        clk = 1'b0;
        forever #(half_period_ns) clk = ~clk; 
    end

    // Main Test Stimulus
    initial begin
        // 1. Initialization
        rst_n      = 1'b1;
        a_i        = 32'h00000000;
        b_i        = 32'h00000000;
        start_i    = 1'b0;
        test_count = 0;

        // Wait for half_period_ns assignment to process
        #1;

        // Open input stimulus file
        fd_in = $fopen("vetor.txt", "r");
        if (fd_in == 0) begin
            $display("[ERROR] Could not open vetor.txt");
            $finish;
        end
        
        // Create output logging file
        fd_out = $fopen("resultado_vetor.txt", "w");
        if (fd_out == 0) begin
            $display("[ERROR] Could not create resultado_vetor.txt");
            $finish;
        end

        $display("========================================");
        $display("    Starting Vector-Based Simulation    ");
        $display("    Freq: %0d MHz (Half-Period: %0.3f ns) ", (1000.0 / (half_period_ns * 2)), half_period_ns);
        $display("========================================");

        // 2. Reset Sequence (scaled)
        #(half_period_ns) rst_n = 1'b0;
        #(half_period_ns) rst_n = 1'b1; 

        // 3. First execution timing alignment
        #(half_period_ns); 
        
        // 4. File processing loop
        while (!$feof(fd_in)) begin
            scan_count = $fscanf(fd_in, "%h %h", val_a, val_b);
            
            if (scan_count == 2) begin
                a_i <= val_a;
                b_i <= val_b;
                
                if (test_count > 0) begin
                    repeat(2) @(posedge clk);
                end

                start_i <= 1'b1;
                @(posedge clk);
                start_i <= 1'b0;

                @(posedge done_o);
                
                // --- NEW SELF-CHECKING LOGIC ---
                expected_val = get_expected_product(val_a, val_b);
                
                if (product_o !== expected_val) begin
                    $display("[ERROR] Vector %0d Mismatch | A: %h, B: %h", test_count, val_a, val_b);
                    $display("        Expected: %h | Got: %h", expected_val, product_o);
                    $fwrite(fd_out, "FAIL | A: %h B: %h | Exp: %h Got: %h\n", val_a, val_b, expected_val, product_o);
                    error_count++;
                end else begin
                    $fwrite(fd_out, "PASS | A: %h B: %h | Out: %h\n", val_a, val_b, product_o);
                end
                
                test_count++;
            end
        end

        // Extra clock cycles to ensure final write completes
        repeat(5) @(posedge clk);

        $display("========================================");
        $display("          Vectors Processed             ");
        $display(" Processed: %0d vectors.", test_count);
        $display(" Errors:    %0d", error_count);
        $display(" Vector End Time: %0t ns", $realtime);
        $display(" -------------------------------------- ");
        $display(" -> Base RUNTIME needed: %0d", $ceil($realtime + 100));
        
        // --- NEW IDLE WAITING LOGIC ---
        if (SIM_RUNTIME > 0 && $realtime < SIM_RUNTIME) begin
            $display(" Padding simulation with idle clock cycles...");
            $display(" Waiting until requested SIM_RUNTIME of %0d ns...", SIM_RUNTIME);
            #(SIM_RUNTIME - $realtime);
        end else begin
            repeat(5) @(posedge clk);
        end
        
        $display("========================================");
        $display(" Final Exit Time: %0t ns", $realtime);
        $display("========================================");

        $fclose(fd_in);
        $fclose(fd_out);
        
        $finish;
    end

endmodule