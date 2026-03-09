`timescale 1ns/1ps

`include "../rtl/xcel-msgs.v"

module tb_basic;

  logic clk;
  logic reset;

  xcel_req_t  xcel_reqstream_msg;
  logic       xcel_reqstream_val;
  logic       xcel_reqstream_rdy;

  xcel_resp_t xcel_respstream_msg;
  logic       xcel_respstream_val;
  logic       xcel_respstream_rdy;

  integer A [0:15];
  integer B [0:15];
  integer C [0:15];

  Proj_44_Xcel dut (
    .clk                 (clk),
    .reset               (reset),
    .xcel_reqstream_msg  (xcel_reqstream_msg),
    .xcel_reqstream_val  (xcel_reqstream_val),
    .xcel_reqstream_rdy  (xcel_reqstream_rdy),
    .xcel_respstream_msg (xcel_respstream_msg),
    .xcel_respstream_val (xcel_respstream_val),
    .xcel_respstream_rdy (xcel_respstream_rdy)
  );

  initial clk = 0;
  always #5 clk = ~clk;

  `include "tb_common.vh"

  initial begin
    $dumpfile("tb_basic.vcd");
    $dumpvars(0, tb_basic);

    // A
    A[ 0]=1; A[ 1]=2; A[ 2]=3; A[ 3]=4;
    A[ 4]=5; A[ 5]=6; A[ 6]=7; A[ 7]=8;
    A[ 8]=1; A[ 9]=0; A[10]=0; A[11]=1;
    A[12]=2; A[13]=1; A[14]=2; A[15]=1;

    // B
    B[ 0]=1; B[ 1]=0; B[ 2]=2; B[ 3]=1;
    B[ 4]=0; B[ 5]=1; B[ 6]=2; B[ 7]=0;
    B[ 8]=1; B[ 9]=1; B[10]=0; B[11]=2;
    B[12]=2; B[13]=0; B[14]=1; B[15]=1;

    do_reset();
    write_matrix_A();
    write_matrix_B();
    matmul_4x4();
    check_full_C();

    $display("[PASS] tb_basic completed");
    #20;
    $finish;
  end

endmodule