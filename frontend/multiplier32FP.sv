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

    // Construção do PIPELINE do multiplicador.

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
        .ready_o() // FSM resolve o ready
    );

    // Sobre rmode_i : O multiplicador pode trabalhar com diferentes tipos de arredondamento.
    // round toward zero é 01
    // De acordo com a especificação: 
    // Arredondamento: round toward zero (arredonda em direção a zero): neste caso os bits que estão a mais são desprezados
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

    // Define as constantes que usa para comparar com o resultado e definir as flags e overwrites da saída
    
    // positivo/negativo infinito (infinit_o): o expoente contém um padrão de bits reservado
    // 11111111, a fração (mantissa) contém somente zeros, e o bit de sinal é 0 ou 1;
    assign is_inf   = ((post_out[30:23] == 8'b11111111) && !is_nan) ? 1'b1 : 1'b0;

    // not a number (nan_o): o expoente contém um padrão de bits reservado 11111111, a
    // fração (mantissa) é diferente de zero, e o bit de sinal é 0 ou 1. Neste caso, ambos
    // operandos devem ser testados, a multiplicação não deve ser realizada e esta flag deve
    // ir para ‘1’. Neste caso, o valor na saída deve ser 0x00000000;
    assign is_nan   = ((post_out[30:0] == QNAN) || (post_out[30:0] == SNAN)) ? 1'b1 : 1'b0;

    // overflow (overflow_o): ocorre quando o expoente resultante excede o valor máximo
    // permitido para este número normalizado. Neste caso, o valor na saída deve ser 0x7FFFFFFF;
    assign is_over  = ((post_out[30:23] == 8'b11111111) && post_ine && !is_nan) ? 1'b1 : 1'b0;

    // underflow (underflow_o): devolve um número menor que o permitido normalizado. O
    // underflow ocorre quando uma operação é executada e retorna um valor que é menor
    // que o menor número não zero.
    // Sobre underflow: No padrão IEEE 754 precisão simples isto significa um valor
    // que tem a magnitude (valor absoluto) menor que 1,0 x 1-149 (número
    // denormalizado). Normalmente quando um número chega a este patamar de
    // magnitude ele é arredondado para zero, o que pode não fazer muita diferença
    // em uma adição, mas tem um grande efeito na multiplicação. Neste caso, o valor
    // na saída deve ser 0x00000000;
    assign is_under = ((post_out[30:23] == 8'b00000000) && post_ine) ? 1'b1 : 1'b0;

    // Registradores de saída do módulo
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

                // Re-escrita das saídas dependendo das flags
                if (is_over) begin
                    product_o <= 32'h7FFFFFFF;          // Neste caso, o valor na saída deve ser 0x7FFFFFFF;
                // underflow ou not a number tem o mesmo valor de saída
                end else if (is_nan || is_under) begin  // Neste caso, o valor na saída deve ser 0x00000000;
                    product_o <= 32'h00000000;
                end else begin                          // Saida normal
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