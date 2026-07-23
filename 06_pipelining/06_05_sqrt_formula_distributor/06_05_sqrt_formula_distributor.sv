module sqrt_formula_distributor
# (
    parameter formula = 1,
              impl    = 1
)
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
    // Implement a module that will calculate formula 1 or formula 2
    // based on the parameter values. The module must be pipelined.
    // It should be able to accept new triple of arguments a, b, c arriving
    // at every clock cycle.
    //
    // The idea of the task is to implement hardware task distributor,
    // that will accept triplet of the arguments and assign the task
    // of the calculation formula 1 or formula 2 with these arguments
    // to the free FSM-based internal module.
    //
    // The first step to solve the task is to fill 03_04 and 03_05 files.
    //
    // Note 1:
    // Latency of the module "formula_1_isqrt" should be clarified from the corresponding waveform
    // or simply assumed to be equal 50 clock cycles.
    //
    // Note 2:
    // The task assumes idealized distributor (with 50 internal computational blocks),
    // because in practice engineers rarely use more than 10 modules at ones.
    // Usually people use 3-5 blocks and utilize stall in case of high load.
    //
    // Hint:
    // Instantiate sufficient number of "formula_1_impl_1_top", "formula_1_impl_2_top",
    // or "formula_2_top" modules to achieve desired performance.


    localparam N_BLOCKS = 50;
    localparam IDX_W    = $clog2 (N_BLOCKS);

    //------------------------------------------------------------------------
    // Round-robin pointer
    //------------------------------------------------------------------------
    logic [IDX_W - 1:0] ptr;

    always_ff @ (posedge clk or posedge rst)
    begin
        if (rst)
            ptr <= '0;
        else if (arg_vld)
            ptr <= (ptr == IDX_W' (N_BLOCKS - 1)) ? '0
                                                  : ptr + 1'b1;
    end

    //------------------------------------------------------------------------
    // Per-block output wires
    //------------------------------------------------------------------------
    wire [N_BLOCKS - 1:0]      blk_vld;
    wire [N_BLOCKS * 32 - 1:0] blk_res;

    //------------------------------------------------------------------------
    // Instantiate N_BLOCKS computational blocks
    //------------------------------------------------------------------------
    genvar i;

    generate
        for (i = 0; i < N_BLOCKS; i = i + 1)
        begin : gen_blk

            wire sel = arg_vld & (ptr == IDX_W' (i));

            wire        b_vld;
            wire [31:0] b_res;

            if (formula == 1 && impl == 1)
            begin : f1_i1
                formula_1_impl_1_top i_top
                (
                    .clk     ( clk   ),
                    .rst     ( rst   ),
                    .arg_vld ( sel   ),
                    .a       ( a     ),
                    .b       ( b     ),
                    .c       ( c     ),
                    .res_vld ( b_vld ),
                    .res     ( b_res )
                );
            end
            else if (formula == 1 && impl == 2)
            begin : f1_i2
                formula_1_impl_2_top i_top
                (
                    .clk     ( clk   ),
                    .rst     ( rst   ),
                    .arg_vld ( sel   ),
                    .a       ( a     ),
                    .b       ( b     ),
                    .c       ( c     ),
                    .res_vld ( b_vld ),
                    .res     ( b_res )
                );
            end
            else
            begin : f2
                formula_2_top i_top
                (
                    .clk     ( clk   ),
                    .rst     ( rst   ),
                    .arg_vld ( sel   ),
                    .a       ( a     ),
                    .b       ( b     ),
                    .c       ( c     ),
                    .res_vld ( b_vld ),
                    .res     ( b_res )
                );
            end

            assign blk_vld [i]            = b_vld;
            assign blk_res [i * 32 +: 32] = b_res;

        end
    endgenerate

    //------------------------------------------------------------------------
    // Output mux — через промежуточные logic-переменные
    //------------------------------------------------------------------------
    logic        res_vld_comb;
    logic [31:0] res_comb;

    assign res_vld_comb = | blk_vld;

    always_comb
    begin
        res_comb = '0;

        for (int j = 0; j < N_BLOCKS; j ++)
            if (blk_vld [j])
                res_comb = blk_res [j * 32 +: 32];
    end

    assign res_vld = res_vld_comb;
    assign res     = res_comb;

endmodule