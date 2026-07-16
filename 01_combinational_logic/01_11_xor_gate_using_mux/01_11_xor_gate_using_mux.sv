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

module xor_gate_using_mux
(
    input  a,
    input  b,
    output o
);

  // Task:
  // Implement xor gate using instance(s) of mux,
  // constants 0 and 1, and wire connections

  wire invent_b;

  mux inventor
  (
    .d0  (   1   ),
    .d1  (   0   ),
    .sel (   b   ),
    .y   ( invent_b )
  );

  wire result;

  mux second
  (
    .d0  (     b    ),
    .d1  ( invent_b ),
    .sel (     a    ),
    .y   (  result  )
  );

  assign o = result;
  
endmodule
