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

    localparam N =        50;
    localparam W = $clog2(N);

    logic [N-1:0]    mod_res_vld, in_vld;
    logic [N-1:0] [31:0] mod_res, a_r, b_r, c_r;
    
    logic [W-1:0] index;

    counter_index i_counter
    (
        .clk    (  clk  ),
        .rst    (  rst  ),
        .en     (arg_vld),
        .index  ( index )
    );

    always_ff @( posedge clk ) begin
        if (rst) begin
            a_r <= '0;
            b_r <= '0;
            c_r <= '0;
        end
        else begin
            for (int i = 0; i < N; i ++)  begin
                if ((index == W'(i)) && arg_vld) begin
                    a_r[i] <= a;
                    b_r[i] <= b;
                    c_r[i] <= c;
                end
            end 
        end
    end

    always_ff @( posedge clk ) begin
        if (rst) begin
            in_vld <= '0;
        end
        else begin
            for (int i = 0; i < N; i ++) begin
                if ((index == W'(i))  && arg_vld)
                    in_vld[i] <= arg_vld;
                else begin
                    in_vld[i] <= '0;
                end
            end 
        end
    end               

    genvar i;
    generate
        for (i = 0; i < N; i ++)
        begin : gen_block
            // wire sel = arg_vld & (index == W'(i));
            if (formula == 1 && impl == 1)
                formula_1_impl_1_top u_blk (
                    .clk     (clk),
                    .rst     (rst),
                    .arg_vld (in_vld[i]),
                    .a       (a_r[i]),
                    .b       (b_r[i]),
                    .c       (c_r[i]),
                    .res_vld (mod_res_vld[i]),
                    .res     (mod_res[i])
                );
            else if (formula == 1 && impl == 2)
                formula_1_impl_2_top u_blk (
                    .clk     (clk),
                    .rst     (rst),
                    .arg_vld (in_vld[i]),
                    .a       (a_r[i]),
                    .b       (b_r[i]),
                    .c       (c_r[i]),
                    .res_vld (mod_res_vld[i]),
                    .res     (mod_res[i])
                );
            else // formula == 2
                formula_2_top u_blk (
                    .clk     (clk),
                    .rst     (rst),
                    .arg_vld (in_vld[i]),
                    .a       (a_r[i]),
                    .b       (b_r[i]),
                    .c       (c_r[i]),
                    .res_vld (mod_res_vld[i]),
                    .res     (mod_res[i])
                );
        end
    endgenerate

    mux_n_to_1 i_mux
    (
        .mod_res_vld (mod_res_vld),
        .mod_res     (  mod_res  ),
        .out_res     (     res   )
    );

    assign res_vld = |mod_res_vld;
endmodule



module mux_n_to_1
# (
    parameter N = 50
)
(
    input        [N-1:0]        mod_res_vld, 
    input        [N-1:0][31:0]  mod_res,     
    output logic [31:0]         out_res      
);

    always_comb begin
        out_res = 32'd0;

        for (int i = 0; i < N; i ++) 
        begin
            if (mod_res_vld[i])
                out_res = mod_res[i];
        end
    end

endmodule


module counter_index
# (
    parameter N = 50 // Количество обслуживаемых модулей (Instances)
)
(
    input                        clk,
    input                        rst,
    input                        en,  
    output logic [$clog2(N)-1:0] index
);

    always_ff @ (posedge clk) 
    begin
        if (rst) 
            index <= '0;
        else if (en) 
        begin
            if (index == N - 1)
                index <= '0;
            else
                index <= index + 1'b1;
        end
    end

endmodule