`ifndef PROJ_XCEL_DPATH_V
`define PROJ_XCEL_DPATH_V

`include "../rtl/xcel-msgs.v"
`include "../rtl/XcelPE.v"

module XcelDpath
(
  input  logic        clk,
  input  logic        reset,

  // Data Interfaces
  input  xcel_req_t   req_msg,
  output xcel_resp_t  resp_msg_raw,

  // Control signals from Ctrl
  input  logic        a_write_en,
  input  logic        b_write_en,
  input  logic        c_write_en,
  input  logic        clear_regs,
  input  logic [3:0]  calc_idx,
  input  logic        resp_reg_en,
  input  logic [0:0]  resp_type
);

  // matrix A&B
  logic signed [7:0]  matrix_a [0:15];
  logic signed [7:0]  matrix_b [0:15];
  
  logic [4:0] req_addr;
  assign req_addr = req_msg.addr;

  // break the input msg into 8-bit block
  always_ff @(posedge clk) begin
    if (reset || clear_regs) begin
      for (int i=0; i<16; i++) begin
        matrix_a[i] <= '0;
        matrix_b[i] <= '0;
      end
    end else begin
      if (a_write_en) begin
        matrix_a[(req_addr<<2)+0] <= req_msg.data[7:0];
        matrix_a[(req_addr<<2)+1] <= req_msg.data[15:8];
        matrix_a[(req_addr<<2)+2] <= req_msg.data[23:16];
        matrix_a[(req_addr<<2)+3] <= req_msg.data[31:24];
      end
      if (b_write_en) begin
        matrix_b[((req_addr-5'd4)<<2)+0] <= req_msg.data[7:0];
        matrix_b[((req_addr-5'd4)<<2)+1] <= req_msg.data[15:8];
        matrix_b[((req_addr-5'd4)<<2)+2] <= req_msg.data[23:16];
        matrix_b[((req_addr-5'd4)<<2)+3] <= req_msg.data[31:24];
      end
    end
  end

  // Systolic Array
  // a_wires[row][col]: wire to PE[row][col] (col=0 is the edge input)
  logic signed [7:0]  a_wires [0:3][0:4]; 
  // b_wires[row][col]: wire to PE[row][col] (row=0 is the edge input)
  logic signed [7:0]  b_wires [0:4][0:3]; 
  // PE results
  logic signed [31:0] pe_c_out [0:3][0:3];

  // clear
  logic pe_clear;
  always_ff @(posedge clk) begin
    if (reset) pe_clear <= 1'b1;
    else if (a_write_en || b_write_en) pe_clear <= 1'b1;
    else pe_clear <= 1'b0;
  end

  // Data Skewing
  logic signed [7:0] pe_a_in [0:3];
  logic signed [7:0] pe_b_in [0:3];

  logic [3:0] c_minus_1;
  logic [3:0] c_minus_2;
  logic [3:0] c_minus_3;

  assign c_minus_1 = calc_idx - 4'd1;
  assign c_minus_2 = calc_idx - 4'd2;
  assign c_minus_3 = calc_idx - 4'd3;

  always_comb begin
    // default: input 0
    for (int i=0; i<4; i++) begin
      pe_a_in[i] = '0;
      pe_b_in[i] = '0;
    end

    // skew input: The i-th line is delayed by i cycles
    // matrix A
    if (calc_idx < 4) 
      pe_a_in[0] = matrix_a[{2'd0, calc_idx[1:0]}];
    if (calc_idx >= 1 && calc_idx < 5) 
      pe_a_in[1] = matrix_a[{2'd1, c_minus_1[1:0]}];
    if (calc_idx >= 2 && calc_idx < 6) 
      pe_a_in[2] = matrix_a[{2'd2, c_minus_2[1:0]}];
    if (calc_idx >= 3 && calc_idx < 7) 
      pe_a_in[3] = matrix_a[{2'd3, c_minus_3[1:0]}];

    // matrix B
    if (calc_idx < 4) 
      pe_b_in[0] = matrix_b[{calc_idx[1:0], 2'd0}];
    if (calc_idx >= 1 && calc_idx < 5) 
      pe_b_in[1] = matrix_b[{c_minus_1[1:0], 2'd1}];
    if (calc_idx >= 2 && calc_idx < 6) 
      pe_b_in[2] = matrix_b[{c_minus_2[1:0], 2'd2}];
    if (calc_idx >= 3 && calc_idx < 7) 
      pe_b_in[3] = matrix_b[{c_minus_3[1:0], 2'd3}];
  end

  // 4x4 PE
  genvar i, j;
  generate
    for (i = 0; i < 4; i++) begin : pe_rows
      // connect data to leftmost side and the top of the array.
      assign a_wires[i][0] = pe_a_in[i];
      assign b_wires[0][i] = pe_b_in[i];
      
      for (j = 0; j < 4; j++) begin : pe_cols
        XCEL_PE pe (
          .clk   (clk),
          .reset (reset),
          .en    (c_write_en),  // enable when in CALC state
          .clear (pe_clear),    // clear before loading data
          .a_in  (a_wires[i][j]),
          .b_in  (b_wires[i][j]),
          .a_out (a_wires[i][j+1]),
          .b_out (b_wires[i+1][j]),
          .c_out (pe_c_out[i][j])
        );
      end
    end
  endgenerate


  // Response Message Register
  logic [3:0] read_idx;
  logic [1:0] rd_row, rd_col;
  assign read_idx = req_addr - 5'd8;
  assign rd_row   = read_idx[3:2];
  assign rd_col   = read_idx[1:0];

  always_ff @(posedge clk) begin
    if (reset) resp_msg_raw <= '0;
    else if (resp_reg_en) begin
      resp_msg_raw.type_ <= resp_type;
      if (resp_type == `VC_XCEL_RESP_MSG_TYPE_WRITE) begin
        resp_msg_raw.data <= 32'b0;
      end else begin
        // Read response: fetch directly from the PE array output
        resp_msg_raw.data <= pe_c_out[rd_row][rd_col];
      end
    end
  end

endmodule

`endif