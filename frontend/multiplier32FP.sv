`timescale 1ns/1ps

module multiplier32FP (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [31:0] a_i,
    input  logic [31:0] b_i,
    input  logic        start_i,
    output logic [31:0] product_o,
    output logic        done_o,
    output logic        nan_o,
    output logic        infinit_o,
    output logic        overflow_o,
    output logic        underflow_o
);

    // Internal routing signals
    logic [9:0]  exp_10;
    logic [23:0] fracta_24;
    logic [23:0] fractb_24;
    logic [47:0] fract_48;
    logic        sign_mul;
    
    logic [31:0] post_out;
    logic        post_ine;

    logic        start_delay;
    logic        update_out;

    logic        is_nan;
    logic        is_inf;
    logic        is_over;
    logic        is_under;

    // IEEE 754 Constants (from fpupack)
    localparam logic [30:0] QNAN = 31'b1111111110000000000000000000000;
    localparam logic [30:0] SNAN = 31'b1111111100000000000000000000001;

    // FSM Instantiation
    fpu_fsm u_fsm (
        .clk(clk),
        .rst_n(rst_n),
        .start_i(start_i),
        .done_o(done_o),
        .start_delay_o(start_delay),
        .update_out_o(update_out)
    );

    // VHDL Datapath Instantiations
    pre_norm_mul i_pre_norm_mul (
        .clk_i(clk),
        .opa_i(a_i),
        .opb_i(b_i),
        .exp_10_o(exp_10),
        .fracta_24_o(fracta_24),
        .fractb_24_o(fractb_24)
    );

    mul_24 i_mul_24 (
        .clk_i(clk),
        .fracta_i(fracta_24),
        .fractb_i(fractb_24),
        .signa_i(a_i[31]),
        .signb_i(b_i[31]),
        .start_i(start_delay),
        .fract_o(fract_48),
        .sign_o(sign_mul),
        .ready_o() // Unconnected, managed by custom FSM
    );

    post_norm_mul i_post_norm_mul (
        .clk_i(clk),
        .opa_i(a_i),
        .opb_i(b_i),
        .exp_10_i(exp_10),
        .fract_48_i(fract_48),
        .sign_i(sign_mul),
        .rmode_i(2'b01), // Hardwired to Round-to-Zero
        .output_o(post_out),
        .ine_o(post_ine)
    );

    // Map standard IEEE 754 flags to specification conditions
    assign is_nan   = ((post_out[30:0] == QNAN) || (post_out[30:0] == SNAN)) ? 1'b1 : 1'b0;
    assign is_over  = ((post_out[30:23] == 8'b11111111) && post_ine) ? 1'b1 : 1'b0;
    assign is_under = ((post_out[30:23] == 8'b00000000) && post_ine) ? 1'b1 : 1'b0;
    assign is_inf   = ((post_out[30:23] == 8'b11111111) && !is_nan) ? 1'b1 : 1'b0;

    // Output Registers
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nan_o       <= 1'b0;
            infinit_o   <= 1'b0;
            overflow_o  <= 1'b0;
            underflow_o <= 1'b0;
            product_o   <= 32'd0;
        end else begin
            if (update_out) begin
                nan_o       <= is_nan;
                infinit_o   <= is_inf;
                overflow_o  <= is_over;
                underflow_o <= is_under;

                // Overwrite output depending on specific custom exception formats
                if (is_over) begin
                    product_o <= 32'h7FFFFFFF;
                end else if (is_nan || is_under) begin
                    product_o <= 32'h00000000;
                end else begin
                    product_o <= post_out;
                end
            end else begin
                // Ensure flags only remain high for 1 clock cycle
                nan_o       <= 1'b0;
                infinit_o   <= 1'b0;
                overflow_o  <= 1'b0;
                underflow_o <= 1'b0;
            end
        end
    end

endmodule