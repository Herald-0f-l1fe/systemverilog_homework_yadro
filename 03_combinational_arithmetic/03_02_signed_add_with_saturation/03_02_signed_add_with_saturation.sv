//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module add
(
  input  [3:0] a, b,
  output [3:0] sum
);

  assign sum = a + b;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------
module signed_add_with_saturation
(
  input  [3:0] a, b,
  output [3:0] sum
);

  wire [3:0] inter;
  wire overflow;
  
  add u_add
  (
    .a   ( a     ),
    .b   ( b     ),
    .sum ( inter )
  );
  
  assign overflow = (a[3] == b[3]) && (inter[3] != a[3]);
  
  assign sum = overflow ? 
               (a[3] ? 4'b1000 : 4'b0111) : inter;

endmodule