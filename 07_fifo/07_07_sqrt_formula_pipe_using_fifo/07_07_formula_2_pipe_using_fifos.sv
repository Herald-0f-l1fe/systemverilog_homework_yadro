//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe_using_fifos
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
    // Implement a pipelined module formula_2_pipe_using_fifos that computes the result
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
    // 3. Your solution should use FIFOs instead of shift registers
    // which were used in 06_04_formula_2_pipe.sv.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.org/fsm#state_0

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

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

    ff_fifo_with_reg_empty_full #(.width(32), .depth(16)) inst_b_uf_1
    (
        .clk        (     clk     ),
        .rst        (     rst     ),
        .push       (   arg_vld   ),
        .pop        ( temp1_vld   ),
        .write_data (      b      ),
        .read_data  (  b_delayed  ),
        .empty      (             ),
        .full       (             )
        );

    wire [31:0] sum1 = b_delayed + 32'(temp1);
    wire sum1_vld = temp1_vld;

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
    logic a_delayed_vld = temp2_vld;

    ff_fifo_with_reg_empty_full #(.width(32), .depth(32)) inst_a_uf_1
    (
        .clk        (     clk     ),
        .rst        (     rst     ),
        .push       (   arg_vld   ),
        .pop        ( temp2_vld   ),
        .write_data (      a      ),
        .read_data  (  a_delayed  ),
        .empty      (             ),
        .full       (             )
        );

    wire [31:0] sum2 = a_delayed + 32'(temp2);
    wire sum2_vld = temp2_vld;

    wire [15:0] res16;
    isqrt sqrt_3
    (
        .clk        (   clk   ),
        .rst        (   rst   ),
        .x_vld      ( sum2_vld),
        .x          (  sum2   ),
        .y_vld      ( res_vld ),
        .y          (   res16   )
    );
    
    assign res = {16'b0, res16};
endmodule


module ff_fifo_with_reg_empty_full
# (
    parameter width = 8, depth = 10
)
(
    input                      clk,
    input                      rst,
    input                      push,
    input                      pop,
    input        [width - 1:0] write_data,
    output       [width - 1:0] read_data,
    output logic               empty,
    output logic               full
);

    //------------------------------------------------------------------------

    localparam pointer_width = $clog2 (depth),
               counter_width = $clog2 (depth + 1);

    localparam [counter_width - 1:0] max_ptr = counter_width' (depth - 1);

    //------------------------------------------------------------------------

    logic [pointer_width - 1:0] wr_ptr_d, rd_ptr_d, wr_ptr_q, rd_ptr_q;
    logic empty_d, full_d;
    logic [width - 1:0] data [0: depth - 1];

    //------------------------------------------------------------------------

    always_comb
    begin

        // Example
        if (push)
            wr_ptr_d = wr_ptr_q == max_ptr ? '0 : wr_ptr_q + 1'b1;
        else
            wr_ptr_d = wr_ptr_q;

        // Task: Add logic for pop to make the FIFO work

        if (pop)
            rd_ptr_d = rd_ptr_q == max_ptr ? '0 : rd_ptr_q + 1'b1;
        else
            rd_ptr_d = rd_ptr_q;

        case ({ push, pop })

        // Example
        2'b10:
        begin
            empty_d = 1'b0;
            full_d  = wr_ptr_d == rd_ptr_q;
        end

        // Task: Add { push, pop } == 2'b01 case to make the FIFO work
        2'b01:
        begin
            empty_d = rd_ptr_d == wr_ptr_q;
            full_d  = 1'b0;
        end

        2'b11:
        begin
            empty_d = empty;
            full_d  = full;
        end
        
        default:
        begin
            empty_d  = empty;
            full_d   = full;
        end
        endcase
    end

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            wr_ptr_q <= '0;
            rd_ptr_q <= '0;
            empty    <= 1'b1;
            full     <= 1'b0;
        end
        else
        begin
            wr_ptr_q <= wr_ptr_d;
            rd_ptr_q <= rd_ptr_d;
            empty    <= empty_d;
            full     <= full_d;
        end

    //------------------------------------------------------------------------

    always_ff @ (posedge clk)
        if (push)
            data [wr_ptr_q] <= write_data;

    assign read_data = data [rd_ptr_q];

endmodule
