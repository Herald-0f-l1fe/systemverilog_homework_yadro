//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module round_robin_arbiter_with_2_requests
(
    input        clk,
    input        rst,
    input  [1:0] requests,
    output [1:0] grants
);
    // Task:
    // Implement a "arbiter" module that accepts up to two requests
    // and grants one of them to operate in a round-robin manner.
    //
    // The module should maintain an internal register
    // to keep track of which requester is next in line for a grant.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.
    //
    // Example:
    // requests -> 01 00 10 11 11 00 11 00 11 11
    // grants   -> 01 00 10 01 10 00 01 00 10 01


//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

    logic grant; 
    logic [1:0] grants_comb;
    assign grants = grants_comb;

    always_comb
    begin
        grants_comb = 2'b00; 

        if (requests == 2'b11)
        begin
            grants_comb[grant] = 1'b1;
        end
        
        else if (requests[0])
        begin 
            grants_comb = 2'b01;
        end
        
        else if (requests[1])
        begin
            grants_comb = 2'b10;
        end  
    end

    always_ff @(posedge clk)
    begin
        if (rst)
        begin
            grant <= 1'b0;
        end
        else 
        begin
            if (grants_comb == 2'b01)
            begin
                grant <= 1'b1; 
            end
            else if (grants_comb == 2'b10)
            begin
                grant <= 1'b0; 
            end
        end
    end

endmodule

