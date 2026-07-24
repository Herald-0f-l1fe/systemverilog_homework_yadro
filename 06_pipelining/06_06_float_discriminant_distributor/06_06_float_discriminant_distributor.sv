module float_discriminant_distributor (
    input                           clk,
    input                           rst,

    input                           arg_vld,
    input        [FLEN - 1:0]       a,
    input        [FLEN - 1:0]       b,
    input        [FLEN - 1:0]       c,

    output logic                    res_vld,
    output logic [FLEN - 1:0]       res,
    output logic                    res_negative,
    output logic                    err,

    output logic                    busy
);

    // Task:
    //
    // Implement a module that will calculate the discriminant based
    // on the triplet of input number a, b, c. The module must be pipelined.
    // It should be able to accept a new triple of arguments on each clock cycle
    // and also, after some time, provide the result on each clock cycle.
    // The idea of the task is similar to the task 04_11. The main difference is
    // in the underlying module 03_08 instead of formula modules.
    //
    // Note 1:
    // Reuse your file "03_08_float_discriminant.sv" from the Homework 03.
    //
    // Note 2:
    // Latency of the module "float_discriminant" should be clarified from the waveform.
    localparam N = 11;
    localparam W = $clog2(N);


    logic [N-1:0] [63:0] mod_res, a_r, b_r, c_r;
    logic [N-1:0] mod_res_vld, in_vld, mod_res_negative, mod_err, mod_busy; 

    logic [W-1:0] index;


    counter_index i_counter
    (
        .clk    (  clk  ),
        .rst    (  rst  ),
        .en     (arg_vld),
        .index  ( index )
    );

    always_ff @( posedge clk ) 
    begin
        if (rst) 
        begin
            a_r <= '0;
            b_r <= '0;
            c_r <= '0;
        end
        else 
        begin
            for (int i = 0; i < N; i ++)  
            begin
                if ((index == W'(i)) && arg_vld) 
                begin
                    a_r[i] <= a;
                    b_r[i] <= b;
                    c_r[i] <= c;
                end
            end 
        end
    end

    always_ff @( posedge clk ) 
    begin
        if (rst) 
            in_vld <= '0;
        else 
        begin
            for (int i = 0; i < N; i ++) 
            begin
                if ((index == W'(i))  && arg_vld && ~mod_busy[i])
                    in_vld[i] <= arg_vld;
                else 
                    in_vld[i] <= '0;
            end 
        end
    end               
    
    genvar i;
    generate
        for (i = 0; i < N; i ++)
        begin : gen_block
                        float_discriminant u_blk 
            (
                .clk          (         clk         ),
                .rst          (         rst         ),
                .arg_vld      (     in_vld[i]       ),
                .a            (       a_r[i]        ),
                .b            (       b_r[i]        ),
                .c            (       c_r[i]        ),
                .res_vld      (    mod_res_vld[i]   ),
                .res          (     mod_res[i]      ),
                .res_negative ( mod_res_negative[i] ),
                .err          (     mod_err[i]      ),
                .busy         (     mod_busy[i]     )
            );
        end
    endgenerate


    mux_n_to_1 i_mux
    (
        .mod_res_vld        (   mod_res_vld  ),
        .mod_err            (     mod_err    ),
        .mod_res_negative   (mod_res_negative),
        .mod_res            (     mod_res    ),
        .out_res_negative   (  res_negative  ),
        .out_err            (       err      ),
        .out_res            (       res      )

    );

    assign res_vld = |mod_res_vld;
    assign busy    = &mod_busy;

endmodule

module mux_n_to_1
# (
    parameter N = 11
)
(
    input        [N-1:0]        mod_res_vld,
    input        [N-1:0]        mod_err,
    input        [N-1:0]        mod_res_negative,
    input        [N-1:0][63:0]  mod_res,
    output logic                out_res_negative,
    output logic                out_err,      
    output logic [63:0]         out_res      
);

    always_comb 
    begin
        out_res          = 64'd0;
        out_err          = 0;
        out_res_negative = 0;

        for (int i = 0; i < N; i ++) 
        begin
            if (mod_res_vld[i])
            begin
                out_res           = mod_res[i];
                out_err           = mod_err[i];
                out_res_negative  = mod_res_negative[i];
            end
        end
    end
endmodule


module counter_index
# (
    parameter N = 11 // Количество обслуживаемых модулей (Instances)
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
    