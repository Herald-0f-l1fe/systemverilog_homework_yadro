//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module gearbox_1_to_2
# (
    parameter width = 0
)
(
    input                    clk,
    input                    rst,

    input                    up_vld,    // upstream
    input  [    width - 1:0] up_data,

    output                   down_vld,  // downstream
    output [2 * width - 1:0] down_data
);
    // Task:
    // Implement a module that transforms a stream of data
    // from 'width' to the 2*'width' data width.
    //`
    // The module should be capable to accept new data at each
    // clock cycle and produce concatenated 'down_data'
    // at each second clock cycle.
    //
    // The module should work properly with reset 'rst'
    // and valid 'vld' signals
    
    logic counter;
    logic [width - 1 : 0] half;

    always_ff @(posedge clk) 
    begin
        if (rst)
        begin
            counter <= 0;
        end    
        else 
        begin
            if (up_vld)
            begin
                counter <=  counter + 1;
                if (~counter)
                    half <= up_data;
            end 
        end
    end

    assign down_vld = (up_vld && counter);
    assign down_data = {half, up_data};

endmodule
