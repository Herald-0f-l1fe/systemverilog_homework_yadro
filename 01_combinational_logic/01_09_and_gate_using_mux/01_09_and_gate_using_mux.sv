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

module and_gate_using_mux
(
    input  a,
    input  b,
    output o
);

  // Task:
  // Implement and gate using instance(s) of mux,
  // constants 0 and 1, and wire connections
  wire first_res;
  mux first
  (
    .d0  (     0     ),
    .d1  (     1     ),
    .sel (     a     ),
    .y   ( first_res )
  );

  wire result;
  mux second
  (
    .d0  (    0    ),
    .d1  (first_res),
    .sel (    b    ),
    .y   (  result )
  );

  assign o = result;

endmodule
