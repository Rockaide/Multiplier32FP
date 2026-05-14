`timescale 1ns/1ps

module fpu_fsm (
    input  logic clk,
    input  logic rst_n,
    input  logic start_i,
    output logic done_o,
    output logic start_delay_o,
    output logic update_out_o
);

    typedef enum logic {WAITING, BUSY} state_t;
    state_t state;
    
    logic [3:0] count;
    logic       start_i_delay;

    // Delay start signal by 1 cycle for pre_norm_mul latency
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_i_delay <= 1'b0;
        end else begin
            start_i_delay <= start_i;
        end
    end
    
    assign start_delay_o = start_i_delay;

    // State Machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= WAITING;
            count        <= 4'd0;
            done_o       <= 1'b0;
            update_out_o <= 1'b0;
        end else begin
            case (state)
                WAITING: begin
                    done_o       <= 1'b0;
                    update_out_o <= 1'b0;
                    
                    if (start_i) begin
                        state <= BUSY;
                        count <= 4'd0;
                    end
                end
                
                BUSY: begin
                    if (count == 4'd12) begin
                        state        <= WAITING;
                        done_o       <= 1'b1;
                        count        <= 4'd0;
                    end else if (count == 4'd11) begin
                        count        <= count + 4'd1;
                        done_o       <= 1'b0;
                        update_out_o <= 1'b1;
                    end else begin
                        count        <= count + 4'd1;
                        done_o       <= 1'b0;
                        update_out_o <= 1'b0;
                    end
                end
                
                default: begin
                    state <= WAITING;
                end
            endcase
        end
    end

endmodule