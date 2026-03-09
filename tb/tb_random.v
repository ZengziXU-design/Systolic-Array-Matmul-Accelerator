`timescale 1ns/1ps

`include "../rtl/xcel-msgs.v"

module tb_random;

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

  integer t;
  integer i;

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
    $dumpfile("tb_random.vcd");
    $dumpvars(0, tb_random);

    do_reset();

    // Run multiple random test iterations
    for (t = 0; t < 20; t = t + 1) begin

      // Generate random signed 8-bit-like values in a small range
      for (i = 0; i < 16; i = i + 1) begin
        A[i] = ($random % 16) - 8;   // range roughly [-8,7]
        B[i] = ($random % 16) - 8;
      end

      write_matrix_A();
      write_matrix_B();
      matmul_4x4();
      check_full_C();

      $display("[PASS] random iteration %0d completed", t);
    end

    $display("[PASS] tb_random completed");
    #20;
    $finish;
  end

endmodule