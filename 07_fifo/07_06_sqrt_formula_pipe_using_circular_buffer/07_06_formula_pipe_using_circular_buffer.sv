//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe_using_circular
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output        res_vld,
    output [31:0] res
);

    // Task:
    //
    // Implement a pipelined module formula_2_pipe_using_circular
    // that computes the result of the formula defined in the file formula_2_fn.svh.
    //
    // The requirements:
    //
    // 1. The module formula_2_pipe has to be pipelined.
    //
    // It should be able to accept a new set of arguments a, b and c
    // arriving at every clock cycle.
    //
    // It also should be able to produce a new result every clock cycle
    // with a fixed latency after accepting the arguments.
    //
    // 2. Your solution should instantiate exactly 3 instances
    // of a pipelined isqrt module, which computes the integer square root.
    //
    // 3. Your solution should use circular buffers instead of shift registers
    // which were used in 06_04_formula_2_pipe.sv.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.org/fsm#state_0

    

    logic [15:0] temp1, temp2, temp3;
    logic temp1_vld, temp2_vld, temp3_vld;

    isqrt sqrt_1
    (
        .clk        (   clk   ),
        .rst        (   rst   ),
        .x_vld      ( arg_vld ),
        .x          (    c    ),
        .y_vld      (temp1_vld),
        .y          (  temp1  )
    );

    logic [31:0] b_delayed;
    logic b_delayed_vld;

    circular_buffer_with_valid #(.width(32), .depth(16)) inst_b_uf_1
    (
        .clk      (     clk     ),
        .rst      (     rst     ),
        .in_valid (   arg_vld   ),
        .in_data  (      b      ),
        .out_valid(b_delayed_vld),
        .out_data (  b_delayed  )
    );

    wire [31:0] sum1 = b_delayed + 32'(temp1);
    wire sum1_vld = b_delayed_vld & temp1_vld;

    isqrt sqrt_2
    (
        .clk        (   clk   ),
        .rst        (   rst   ),
        .x_vld      (sum1_vld ),
        .x          (  sum1   ),
        .y_vld      (temp2_vld),
        .y          (  temp2  )
    );

    logic [31:0] a_delayed;
    logic a_delayed_vld;

    circular_buffer_with_valid #(.width(32), .depth(32)) inst_a_uf_1
    (
        .clk      (     clk     ),
        .rst      (     rst     ),
        .in_valid (   arg_vld   ),
        .in_data  (      a      ),
        .out_valid(a_delayed_vld),
        .out_data (  a_delayed  )
    );

    wire [31:0] sum2 = a_delayed + 32'(temp2);
    wire sum2_vld = a_delayed_vld & temp2_vld;

    isqrt sqrt_3
    (
        .clk        (   clk   ),
        .rst        (   rst   ),
        .x_vld      ( sum2_vld),
        .x          (  sum2   ),
        .y_vld      ( res_vld ),
        .y          (   res   )
    );

    

endmodule
