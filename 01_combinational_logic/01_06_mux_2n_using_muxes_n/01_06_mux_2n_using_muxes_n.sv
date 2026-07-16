//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module mux_2_1
(
  input  [3:0] d0, d1,
  input        sel,
  output [3:0] y
);

  assign y = sel ? d1 : d0;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module mux_4_1
(
  input  [3:0] d0, d1, d2, d3,
  input  [1:0] sel,
  output [3:0] y
);

  // Task:
  // Implement mux_4_1 using three instances of mux_2_1

  wire [3:0] d_0;
  mux_2_1 first 
  (
    .d0  ( d0     ),
    .d1  ( d1     ),
    .sel ( sel[0] ),
    .y   ( d_0    )
  );

  wire [3:0] d_1;
  mux_2_1 second
  (
    .d0  ( d2     ),
    .d1  ( d3     ),
    .sel ( sel[0] ),
    .y   ( d_1    )
  );

  wire [3:0] d_finish;
  mux_2_1 third 
  (
    .d0  ( d_0          ),
    .d1  ( d_1         ),
    .sel ( sel[1]       ),
    .y   ( d_finish     )
  );

  assign y = d_finish;

endmodule
