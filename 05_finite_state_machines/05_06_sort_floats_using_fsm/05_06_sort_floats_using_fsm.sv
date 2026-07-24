module sort_floats_using_fsm (
    input                          clk,
    input                          rst,

    input                          valid_in,
    input        [0:2][FLEN - 1:0] unsorted,

    output logic                   valid_out,
    output logic [0:2][FLEN - 1:0] sorted,
    output logic                   err,
    output                         busy,

    // f_less_or_equal interface
    output logic      [FLEN - 1:0] f_le_a,
    output logic      [FLEN - 1:0] f_le_b,
    input                          f_le_res,
    input                          f_le_err
);

    enum logic [1:0] {
        ST_IDLE     = 2'd0,
        ST_CMP_01   = 2'd1,
        ST_CMP_12   = 2'd2,
        ST_CMP_01_2 = 2'd3
    } state, next_state;

    logic [FLEN-1:0] r0, r1, r2;
    logic [FLEN-1:0] r0_next, r1_next, r2_next;
    
    // Регистры для входов компаратора, чтобы разорвать комбинаторную петлю обратной связи
    logic [FLEN-1:0] f_le_a_next, f_le_b_next;

    // FSM Next State Logic
    always_comb 
    begin
        next_state = state;
        case (state)
            ST_IDLE:     if (valid_in) next_state = ST_CMP_01;
            ST_CMP_01:   next_state = ST_CMP_12;
            ST_CMP_12:   next_state = ST_CMP_01_2;
            ST_CMP_01_2: next_state = ST_IDLE;
        endcase
    end

    // FSM State Register
    always_ff @(posedge clk) 
    begin
        if (rst) 
            state <= ST_IDLE;
        else
             state <= next_state;
    end

    // Datapath and Control
    always_comb begin
        r0_next = r0;
        r1_next = r1;
        r2_next = r2;
        
        f_le_a_next = '0;
        f_le_b_next = '0;
        
        case (state)
            ST_IDLE: 
            begin
                if (valid_in) 
                begin
                    r0_next = unsorted[0];
                    r1_next = unsorted[1];
                    r2_next = unsorted[2];
                    f_le_a_next = unsorted[0];
                    f_le_b_next = unsorted[1];
                end
            end
            
            ST_CMP_01: 
            begin
                // f_le_res стабилен и содержит результат сравнения из ST_IDLE
                if (!f_le_res) 
                begin
                    r0_next = r1;
                    r1_next = r0;
                end
                // Готовим сравнение 2: новый элемент на позиции 1 с элементом 2
                f_le_a_next = r1_next;
                f_le_b_next = r2_next;
            end
            
            ST_CMP_12: 
            begin
                // f_le_res стабилен и содержит результат сравнения 2
                if (!f_le_res) 
                begin
                    r1_next = r2;
                    r2_next = r1;
                end
                // Готовим сравнение 3: элемент 0 с новым элементом на позиции 1
                f_le_a_next = r0_next;
                f_le_b_next = r1_next;
            end
            
            ST_CMP_01_2: 
            begin
                // f_le_res стабилен и содержит результат сравнения 3
                if (!f_le_res) 
                begin
                    r0_next = r1;
                    r1_next = r0;
                end
                // Сравнения больше не нужны
                f_le_a_next = '0;
                f_le_b_next = '0;
            end
        endcase
    end

    // Registers for Data and Comparator Inputs
    always_ff @(posedge clk) 
    begin
        if (rst) 
        begin
            r0 <= '0;
            r1 <= '0;
            r2 <= '0;
            f_le_a <= '0;
            f_le_b <= '0;
        end 
        else 
        begin
            r0 <= r0_next;
            r1 <= r1_next;
            r2 <= r2_next;
            f_le_a <= f_le_a_next;
            f_le_b <= f_le_b_next;
        end
    end

    // Output Valid Logic (ровно 3 такта задержки)
    logic valid_d1, valid_d2, valid_d3;
    always_ff @(posedge clk) begin
        if (rst) 
        begin
            valid_d1  <= 1'b0;
            valid_d2  <= 1'b0;
            valid_d3  <= 1'b0;
            valid_out <= 1'b0;
        end
        else 
        begin
            valid_d1  <= valid_in;
            valid_d2  <= valid_d1;
            valid_d3  <= valid_d2;
            valid_out <= valid_d3; // Становится 1 на 3-м такте
        end
    end
    
    // Error Logic (накопление ошибки)
    logic err_accum;
    always_ff @(posedge clk) 
    begin
        if (rst) 
        begin
            err_accum <= 1'b0;
            err       <= 1'b0;
        end 
        else 
        begin
            if (valid_in && state == ST_IDLE) 
            begin
                err_accum <= 1'b0;
                err       <= 1'b0;
            end 
            else 
            begin
                if (state == ST_CMP_01 || state == ST_CMP_12) 
                    if (f_le_err) err_accum <= 1'b1;

                if (state == ST_CMP_01_2) 
                    err <= err_accum | f_le_err;
                else 
                    err <= 1'b0;
            end
        end
    end

    assign sorted[0] = r0;
    assign sorted[1] = r1;
    assign sorted[2] = r2;
    
    assign busy = (state != ST_IDLE) || valid_in;

endmodule