//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_impl_2_fsm
(
    input               clk,
    input               rst,

    input               arg_vld,
    input        [31:0] a,
    input        [31:0] b,
    input        [31:0] c,

    output logic        res_vld,
    output logic [31:0] res,

    // isqrt interface

    output logic        isqrt_1_x_vld,
    output logic [31:0] isqrt_1_x,

    input               isqrt_1_y_vld,
    input        [15:0] isqrt_1_y,

    output logic        isqrt_2_x_vld,
    output logic [31:0] isqrt_2_x,

    input               isqrt_2_y_vld,
    input        [15:0] isqrt_2_y
);

    // FSM states
    enum logic [1:0] {
        st_idle,
        st_busy
    } state, next_state;

    // Flags and stored results
    logic        got_a, got_b, got_c;
    logic [15:0] sqrt_a, sqrt_b, sqrt_c;

    // State transition
    always_comb begin
        next_state = state;
        case (state)
            st_idle: next_state <= arg_vld ? st_busy : st_idle;
            st_busy: next_state <= st_busy;   // will go to idle when all results are ready
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= st_idle;
            got_a <= 0;
            got_b <= 0;
            got_c <= 0;
            res_vld <= 0;
            res <= 0;
            isqrt_1_x_vld <= 0;
            isqrt_2_x_vld <= 0;
        end else begin
            // Default assignments
            isqrt_1_x_vld <= 0;
            isqrt_2_x_vld <= 0;
            res_vld <= 0;   // de-assert by default

            case (state)
                st_idle: begin
                    if (arg_vld) begin
                        // Start sqrt(a) and sqrt(b) in parallel
                        isqrt_1_x_vld <= 1;
                        isqrt_1_x     <= a;
                        isqrt_2_x_vld <= 1;
                        isqrt_2_x     <= b;

                        // Clear all flags and result
                        got_a <= 0;
                        got_b <= 0;
                        got_c <= 0;
                        res   <= 0;

                        state <= st_busy;
                    end
                end

                st_busy: begin
                    // Handle result from isqrt_1 (can be sqrt(a) or sqrt(c))
                    if (isqrt_1_y_vld) begin
                        if (!got_a) begin
                            // This is sqrt(a)
                            got_a   <= 1;
                            sqrt_a  <= isqrt_1_y;
                            // Start sqrt(c) immediately
                            isqrt_1_x_vld <= 1;
                            isqrt_1_x     <= c;
                        end else begin
                            // This is sqrt(c) (since got_a is already set)
                            got_c  <= 1;
                            sqrt_c <= isqrt_1_y;
                        end
                    end

                    // Handle result from isqrt_2 (sqrt(b))
                    if (isqrt_2_y_vld) begin
                        got_b  <= 1;
                        sqrt_b <= isqrt_2_y;
                    end

                    // If all three results are ready, compute the final answer
                    if (got_a && got_b && got_c) begin
                        res     <= {16'd0, sqrt_a} + {16'd0, sqrt_b} + {16'd0, sqrt_c};
                        res_vld <= 1;
                        state   <= st_idle;
                    end
                end
            endcase
        end
    end

endmodule