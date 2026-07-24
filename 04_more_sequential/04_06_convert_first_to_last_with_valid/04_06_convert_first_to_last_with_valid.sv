//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module conv_first_to_last_no_ready
# (
    parameter width = 8
)
(
    input                clock,
    input                reset,

    input                up_valid,
    input                up_first,
    input  [width - 1:0] up_data,

    output               down_valid,
    output               down_last,
    output [width - 1:0] down_data
);
    // Task:
    // Implement a module that converts 'first' input status signal
    // to the 'last' output status signal.
    //
    // See README for full description of the task with timing diagram.

    logic [width - 1 : 0] prev_packet;
    logic prev_valid;
    logic first;
    logic flag;

    always_ff @(posedge clock) 
    begin
        if (reset)
        begin
            prev_valid  <=  0;
            prev_packet <= '0; 
            first       <=  1;
        end
        else
        begin
            if (up_valid)
            begin
                prev_packet <= up_data;
                prev_valid <= 1; 
            end
            else
                prev_valid <= 0;

            first <= 0;

        end     
    end

    assign down_valid = prev_valid;
    assign down_last  = up_first && up_valid && ~first;
    assign down_data  = prev_packet;

endmodule
