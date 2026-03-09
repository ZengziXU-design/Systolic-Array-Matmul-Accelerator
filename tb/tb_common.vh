`ifndef TB_COMMON_VH
`define TB_COMMON_VH

task automatic do_reset;
begin
  reset = 1'b1;
  xcel_reqstream_val = 1'b0;
  xcel_reqstream_msg = '0;
  xcel_respstream_rdy = 1'b1;

  repeat (5) @(posedge clk);
  reset = 1'b0;
  repeat (2) @(posedge clk);
end
endtask

task automatic xcel_write;
  input [4:0]  addr;
  input [31:0] data;
begin
  @(posedge clk);
  xcel_reqstream_val       <= 1'b1;
  xcel_reqstream_msg.type_ <= `VC_XCEL_REQ_MSG_TYPE_WRITE;
  xcel_reqstream_msg.addr  <= addr;
  xcel_reqstream_msg.data  <= data;

  while (!xcel_reqstream_rdy) @(posedge clk);

  @(posedge clk);
  xcel_reqstream_val <= 1'b0;
  xcel_reqstream_msg <= '0;

  while (!xcel_respstream_val) @(posedge clk);

  if (xcel_respstream_msg.type_ !== `VC_XCEL_RESP_MSG_TYPE_WRITE ||
      xcel_respstream_msg.data  !== 32'd0) begin
    $display("[FAIL] WRITE rsp mismatch addr=%0d type=%0d data=0x%08x",
             addr, xcel_respstream_msg.type_, xcel_respstream_msg.data);
    $fatal;
  end
end
endtask

task automatic xcel_read;
  input  [4:0]  addr;
  output [31:0] data;
begin
  @(posedge clk);
  xcel_reqstream_val       <= 1'b1;
  xcel_reqstream_msg.type_ <= `VC_XCEL_REQ_MSG_TYPE_READ;
  xcel_reqstream_msg.addr  <= addr;
  xcel_reqstream_msg.data  <= 32'd0;

  while (!xcel_reqstream_rdy) @(posedge clk);

  @(posedge clk);
  xcel_reqstream_val <= 1'b0;
  xcel_reqstream_msg <= '0;

  while (!xcel_respstream_val) @(posedge clk);

  if (xcel_respstream_msg.type_ !== `VC_XCEL_RESP_MSG_TYPE_READ) begin
    $display("[FAIL] READ rsp type mismatch addr=%0d type=%0d",
             addr, xcel_respstream_msg.type_);
    $fatal;
  end

  data = xcel_respstream_msg.data;
end
endtask

function automatic [31:0] pack4;
  input integer a0, a1, a2, a3;
  reg [7:0] b0, b1, b2, b3;
begin
  b0 = a0[7:0];
  b1 = a1[7:0];
  b2 = a2[7:0];
  b3 = a3[7:0];
  pack4 = { b3, b2, b1, b0 };
end
endfunction

task automatic matmul_4x4;
  integer row, col, k;
begin
  for (row = 0; row < 4; row = row + 1) begin
    for (col = 0; col < 4; col = col + 1) begin
      C[row*4+col] = 0;
      for (k = 0; k < 4; k = k + 1) begin
        C[row*4+col] = C[row*4+col] + A[row*4+k] * B[k*4+col];
      end
    end
  end
end
endtask

task automatic write_matrix_A;
  integer r;
begin
  for (r = 0; r < 4; r = r + 1) begin
    xcel_write(r, pack4(A[r*4+0], A[r*4+1], A[r*4+2], A[r*4+3]));
  end
end
endtask

task automatic write_matrix_B;
  integer r;
begin
  for (r = 0; r < 4; r = r + 1) begin
    xcel_write(r+4, pack4(B[r*4+0], B[r*4+1], B[r*4+2], B[r*4+3]));
  end
end
endtask

task automatic check_full_C;
  integer i;
  reg [31:0] got;
begin
  for (i = 0; i < 16; i = i + 1) begin
    xcel_read(i+8, got);
    if ($signed(got) !== C[i]) begin
      $display("[FAIL] C[%0d] exp=%0d got=%0d (0x%08x)",
               i, C[i], $signed(got), got);
      $fatal;
    end
    else begin
      $display("[PASS] C[%0d] = %0d", i, $signed(got));
    end
  end
end
endtask

`endif