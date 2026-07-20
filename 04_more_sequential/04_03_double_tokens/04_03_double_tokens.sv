    //----------------------------------------------------------------------------
    // Task
    //----------------------------------------------------------------------------

    module double_tokens
    (
        input        clk,
        input        rst,
        input        a,
        output       b,
        output logic overflow
    );
        // Task:
        // Implement a serial module that doubles each incoming token '1' two times.
        // The module should handle doubling for at least 200 tokens '1' arriving in a row.
        //
        // In case module detects more than 200 sequential tokens '1', it should assert
        // an overflow error. The overflow error should be sticky. Once the error is on,
        // the only way to clear it is by using the "rst" reset signal.
        //
        // Note:
        // Check the waveform diagram in the README for better understanding.
        //
        // Example:
        // a -> 10010011000110100001100100
        // b -> 11011011110111111001111110

        logic [8:0] counter;
        logic [7:0] seq_ones;

        always_ff @( posedge clk ) 
        begin
            if (rst)
            begin
                counter  <= 0;
                overflow <= 0;
                seq_ones <= 0;
            end
            else if (~overflow)
            begin
                if (a)
                begin
                    seq_ones <= seq_ones + 1;
                end
                else 
                    seq_ones <= 0;
                
                if (seq_ones > 200)
                    overflow <= 1;
                else 
                begin
                    counter <= counter + (a ? 2 : 0) - (counter || a ? 1 : 0);   
                end
                
            end
            
        end     
        assign b = ((counter > 0 || a) && ~overflow);
    endmodule
