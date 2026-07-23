//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_pipe_aware_fsm
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
    output logic        isqrt_x_vld,
    output logic [31:0] isqrt_x,
    input               isqrt_y_vld,
    input        [15:0] isqrt_y
);

    // 1. Состояния FSM
    typedef enum logic [2:0] {
        ST_IDLE   = 3'd0,
        ST_SEND_B = 3'd1,
        ST_SEND_C = 3'd2,
        ST_WAIT   = 3'd3
    } state_t;

    state_t state, next_state;

    logic [31:0] res_next;
    logic [1:0]  res_cnt, res_cnt_next;
    logic        isqrt_x_vld_next;
    logic [31:0] isqrt_x_next;

    always_comb 
    begin
        next_state       = state;
        res_next         = res;
        res_cnt_next     = res_cnt;
        isqrt_x_vld_next = 1'b0;
        isqrt_x_next     = 32'd0;

        case (state)
            ST_IDLE: 
            begin
                if (arg_vld) 
                begin
                    next_state       = ST_SEND_B;
                    isqrt_x_vld_next = 1'b1;
                    isqrt_x_next     = a; 
                end
            end

            ST_SEND_B: 
            begin
                next_state       = ST_SEND_C;
                isqrt_x_vld_next = 1'b1;
                isqrt_x_next     = b; // Отправляем 'b' во втором такте (конвейер!)
            end

            ST_SEND_C: 
            begin
                next_state       = ST_WAIT;
                isqrt_x_vld_next = 1'b1;
                isqrt_x_next     = c; // Отправляем 'c' в третьем такте
            end

            ST_WAIT: 
            begin
                // Ждем, пока не придут все 3 результата
                if (isqrt_y_vld && res_cnt == 2'd2)
                    next_state = ST_IDLE; // Все 3 получены, возвращаемся в начало
            end
        endcase

        if (state != ST_IDLE && isqrt_y_vld) 
        begin
            res_next     = res + {16'd0, isqrt_y};
            res_cnt_next = res_cnt + 2'd1;
        end 
        else if (state == ST_IDLE) 
        begin
            res_next     = 32'd0;
            res_cnt_next = 2'd0;
        end
    end

    // 4. Регистровая логика (ВСЁ в одном блоке, чтобы избежать множественных драйверов)
    always_ff @(posedge clk) 
    begin
        if (rst) 
        begin
            state       <= ST_IDLE;
            res         <= 32'd0;
            res_cnt     <= 2'd0;
            isqrt_x_vld <= 1'b0;
            isqrt_x     <= 32'd0;
            res_vld     <= 1'b0;
        end 
        else 
        begin
            state       <= next_state;
            res         <= res_next;
            res_cnt     <= res_cnt_next;
            isqrt_x_vld <= isqrt_x_vld_next;
            isqrt_x     <= isqrt_x_next;

            // Формирование выходного флага valid
            if (state == ST_IDLE) 
                res_vld <= 1'b0;
            else if (isqrt_y_vld && res_cnt == 2'd2)
                // Пришел 3-й (последний) результат. Выдаем импульс valid.
                res_vld <= 1'b1;
            else
                res_vld <= 1'b0;
        end
    end

endmodule