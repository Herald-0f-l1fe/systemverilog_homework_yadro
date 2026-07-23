//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe
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
    // Implement a pipelined module formula_2_pipe that computes the result
    // of the formula defined in the file formula_2_fn.svh.
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
    // 3. Your solution should save dynamic power by properly connecting
    // the valid bits.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.org/fsm#state_0
//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

    localparam int ISQRT_LATENCY = 16;
    
    localparam int DELAY_A = ISQRT_LATENCY + 1 + ISQRT_LATENCY;

    logic [15:0] sq_c;
    logic        sq_c_vld;

    logic [31:0] b_delayed;
    logic        b_delayed_vld;

    shift_register_with_valid #(.width (32), .depth (ISQRT_LATENCY)) u_delay_b 
    (
        .clk      (clk),
        .rst      (rst),
        .in_vld   (arg_vld),
        .in_data  (b),
        .out_vld  (b_delayed_vld),
        .out_data (b_delayed)
    );

    isqrt #(.n_pipe_stages(ISQRT_LATENCY)) u_isqrt1 
    (
        .clk    (clk),
        .rst    (rst),
        .x      (c),
        .x_vld  (arg_vld),
        .y      (sq_c),
        .y_vld  (sq_c_vld)
    );

    logic [31:0] sum1;
    logic        sum1_vld;

    always_ff @(posedge clk) 
    begin
        if (rst) 
        begin
            sum1     <= 32'd0;
            sum1_vld <= 1'b0;
        end 
        else if (sq_c_vld) 
        begin
            sum1     <= b_delayed + {16'd0, sq_c}; 
            sum1_vld <= 1'b1;
        end 
        else 
        begin
            sum1_vld <= 1'b0;
        end
    end

    logic [15:0] sq_b_c;
    logic        sq_b_c_vld;

    isqrt #(.n_pipe_stages(ISQRT_LATENCY)) u_isqrt2 
    (
        .clk    (clk),
        .rst    (rst),
        .x      (sum1),
        .x_vld  (sum1_vld),
        .y      (sq_b_c),
        .y_vld  (sq_b_c_vld)
    );

    logic [31:0] a_delayed;
    logic        a_delayed_vld;

    shift_register_with_valid #(.width (32), .depth (DELAY_A)) u_delay_a 
    (
        .clk      (clk),
        .rst      (rst),
        .in_vld   (arg_vld),
        .in_data  (a),
        .out_vld  (a_delayed_vld),
        .out_data (a_delayed)
    );

    logic [31:0] sum2;
    logic        sum2_vld;

    always_ff @(posedge clk) 
    begin
        if (rst) 
        begin
            sum2     <= 32'd0;
            sum2_vld <= 1'b0;
        end 
        else if (sq_b_c_vld) 
        begin
            sum2     <= a_delayed + {16'd0, sq_b_c};
            sum2_vld <= 1'b1;
        end 
        else 
        begin
            sum2_vld <= 1'b0;
        end
    end

    isqrt #(.n_pipe_stages(ISQRT_LATENCY)) u_isqrt3 
    (
        .clk    (clk),
        .rst    (rst),
        .x      (sum2),
        .x_vld  (sum2_vld),
        .y      (res),
        .y_vld  (res_vld)
    );

endmodule