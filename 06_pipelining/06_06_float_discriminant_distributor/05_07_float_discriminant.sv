module float_discriminant (
    input                     clk,
    input                     rst,

    input                     arg_vld,
    input        [FLEN - 1:0] a,
    input        [FLEN - 1:0] b,
    input        [FLEN - 1:0] c,

    output logic              res_vld,  
    output logic [FLEN - 1:0] res,
    output logic              res_negative,
    output logic              err,
    output logic              busy
);

    // ------------------------------------------------------------------------
    // 1. Объявление внутренних сигналов для связи модулей
    // ------------------------------------------------------------------------
    logic [FLEN-1:0] b_squared;
    logic            b_squared_vld, b_squared_busy, b_squared_err, b_squared_f;

    
    logic [FLEN-1:0] four_a;
    logic            four_a_vld, four_a_busy, four_a_err;
    
    logic [FLEN-1:0] four_ac;
    logic            four_ac_vld, four_ac_busy, four_ac_err, four_ac_f;
    
    logic [FLEN-1:0] discriminant;
    logic            discriminant_vld, discriminant_busy, discriminant_err;
    
    localparam [FLEN - 1:0] four = 64'h4010_0000_0000_0000;
    

    
    // b * b
    f_mult u_mul_b_b (
        .clk        (clk),
        .rst        (rst),
        .a          (b),
        .b          (b),
        .up_valid   (arg_vld),
        .res        (b_squared),
        .down_valid (b_squared_vld),
        .busy       (b_squared_busy),
        .error      (b_squared_err)
    );
    
    // 4 * a
    f_mult u_mul_4_a (
        .clk        (clk),
        .rst        (rst),
        .a          (four),
        .b          (a),
        .up_valid   (arg_vld),
        .res        (four_a),
        .down_valid (four_a_vld),
        .busy       (four_a_busy),
        .error      (four_a_err)
    );
    
    // (4*a) * c
    f_mult u_mul_4ac (
        .clk        (clk),
        .rst        (rst),
        .a          (four_a),
        .b          (c),
        .up_valid   (four_a_vld),  // Запускаем, когда готов результат 4*a
        .res        (four_ac),
        .down_valid (four_ac_vld),
        .busy       (four_ac_busy),
        .error      (four_ac_err)
    );
    
    // b*b - 4*a*c
    f_sub u_sub (
        .clk        (clk),
        .rst        (rst),
        .a          (b_squared),
        .b          (four_ac),
        .up_valid   (b_squared_f && four_ac_f),  // Запускаем, когда оба готовы
        .res        (discriminant),
        .down_valid (discriminant_vld),
        .busy       (discriminant_busy),
        .error      (discriminant_err)
    );

    // ------------------------------------------------------------------------
    // 3. Выходная логика
    // ------------------------------------------------------------------------
    always_ff @(posedge clk) 
    begin
        if (rst) 
        begin
            res_vld      <= 0;
            res          <= 0;
            res_negative <= 0;
            err          <= 0;
            b_squared_f  <= 0;
            four_ac_f    <= 0;
        end 
        else 
        begin
            res_vld      <= discriminant_vld;
            res          <= discriminant;
            res_negative <= discriminant[FLEN-1];  // Знаковый бит
            
            // Ошибка, если любой из модулей сообщил об ошибке
            err <= b_squared_err | four_a_err | four_ac_err | discriminant_err;

            if (b_squared_f && four_ac_f && !discriminant_busy) 
            begin
                b_squared_f <= 0;
                four_ac_f   <= 0;
            end 
            else 
            begin
                // Устанавливаем флаги, когда результаты готовы
                if (b_squared_vld)
                    b_squared_f <= 1;
                if (four_ac_vld)
                    four_ac_f <= 1;
            end
        end
    end


    // Busy активен, когда занят хотя бы один модуль
    assign busy = b_squared_busy | four_a_busy | four_ac_busy | discriminant_busy;

endmodule