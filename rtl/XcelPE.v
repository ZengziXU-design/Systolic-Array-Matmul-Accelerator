`ifndef PROJ_XCEL_PE_V
`define PROJ_XCEL_PE_V

// Processing Element (PE) module
module XCEL_PE
(
  input  logic               clk,
  input  logic               reset,

  input  logic               en,       
  input  logic               clear,    
  
  input  logic signed [7:0]  a_in,     
  input  logic signed [7:0]  b_in,     
  
  output logic signed [7:0]  a_out,    
  output logic signed [7:0]  b_out,    
  output logic signed [31:0] c_out     
);

  logic signed [15:0] prod;
  assign prod = a_in * b_in;

  always_ff @(posedge clk) begin
    if (reset) begin
      a_out <= '0;
      b_out <= '0;
      c_out <= '0;
    end else if (clear) begin
      c_out <= '0; 
      a_out <= '0;
      b_out <= '0;
    end else if (en) begin
      a_out <= a_in;
      b_out <= b_in;
      c_out <= c_out + 32'(prod); 
    end
  end

endmodule
`endif