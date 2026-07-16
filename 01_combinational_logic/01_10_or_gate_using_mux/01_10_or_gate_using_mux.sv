//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module mux
(
  input  d0, d1,
  input  sel,
  output y
);

  assign y = sel ? d1 : d0;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module or_gate_using_mux
(
    input  a,
    input  b,
    output o
);

  // Task:

  // Implement or gate using instance(s) of mux,
  // constants 0 and 1, and wire connections
  
  wire f_res;

  mux first
  (
    .d0  (   0   ),
    .d1  (   1   ),
    .sel (   a   ),
    .y   ( f_res )
  );

  wire result;

  mux second
  (
    .d0  (  f_res ),
    .d1  (   1    ),
    .sel (   b    ),
    .y   ( result )
  );

  assign o = result;
  
endmodule
