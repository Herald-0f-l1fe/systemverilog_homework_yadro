module put_in_order
# (
    parameter width    = 16,
              n_inputs = 4
)
(
    input                       clk,
    input                       rst,

    input  [ n_inputs - 1 : 0 ] up_vlds,
    input  [ n_inputs - 1 : 0 ]
           [ width    - 1 : 0 ] up_data,

    output                      down_vld,
    output [ width   - 1 : 0 ]  down_data
);

    // Task:
    //
    // Implement a module that accepts many outputs of the computational blocks
    // and outputs them one by one in order. Input signals "up_vlds" and "up_data"
    // are coming from an array of non-pipelined computational blocks.
    // These external computational blocks have a variable latency.
    //
    // The order of incoming "up_vlds" is not determent, and the task is to
    // output "down_vld" and corresponding data in a round-robin manner,
    // one after another, in order.
    //
    // Comment:
    // The idea of the block is kinda similar to the "parallel_to_serial" block
    // from Homework 2, but here block should also preserve the output order.

    localparam W_PTR = $clog2(n_inputs);

    logic [W_PTR - 1:0]                 ptr;
    logic [n_inputs - 1:0]              ready;
    
    // ИСПРАВЛЕНО: Делаем unpacked array (сначала ширина, потом размер)
    logic [width - 1:0] data_reg [0:n_inputs - 1]; 

    logic                      int_down_vld;
    logic [ width   - 1 : 0 ]  int_down_data;

    assign down_vld  = int_down_vld;
    assign down_data = int_down_data;

    always_ff @(posedge clk or posedge rst) 
    begin
        if (rst) 
        begin
            ptr      <= '0;
            ready    <= '0;
            // Unpacked array безопаснее сбрасывать циклом
            for (int i = 0; i < n_inputs; i++)
                data_reg[i] <= '0;
        end 
        else 
        begin
            for (int i = 0; i < n_inputs; i++)
            begin
                if (up_vlds[i])
                begin
                    data_reg[i] <= up_data[i];
                    ready[i]    <= 1'b1; 
                end
            end
            
            if (ready[ptr] == 1 || up_vlds[ptr] == 1)
            begin
                ready[ptr] <= 0;
                ptr <= (ptr == (n_inputs - 1)) ? 0 : ptr + 1;
            end
        end
    end

    // ==========================================
    // БЛОК Б: Комбинационная логика (Выдача)
    // ==========================================
    
    // ЗАДАНИЕ 3: Формирование int_down_vld
    // В каких случаях мы отдаем данные наружу? 
    // (Подсказка: либо они уже лежат в регистре, либо курьер привез их прямо сейчас).
    
    // ЗАДАНИЕ 4: Формирование int_down_data (Мультиплексор с Bypass-ом)
    // Если данные для ptr пришли прямо сейчас (и в регистре их еще не было) -> отдаем up_data[ptr].
    // Иначе -> отдаем data_reg[ptr].
    assign int_down_vld = up_vlds[ptr] || ready[ptr];
    
    always_comb 
    begin
        int_down_data = '0; 
        
        // ИСПРАВЛЕНО: Цикл гарантирует, что Icarus не выдаст 'xx' 
        // при чтении up_data[ptr] и data_reg[ptr]
        for (int i = 0; i < n_inputs; i++)
        begin
            if (i == ptr)
            begin
                if (ready[i])
                    int_down_data = data_reg[i];      // Берем с "полки"
                else if (up_vlds[i])
                    int_down_data = up_data[i];       // Берем "из рук курьера" (Bypass!)
            end
        end
    end

endmodule
