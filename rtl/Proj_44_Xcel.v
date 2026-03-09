//========================================================================
// 44_Xcel
//========================================================================
`ifndef PROJ_44_XCEL_V
`define PROJ_44_XCEL_V

`include "../rtl/xcel-msgs.v"
`include "../rtl/XcelCtrl.v"
`include "../rtl/XcelDpath.v"

module Proj_44_Xcel
(
  input  logic        clk,
  input  logic        reset,

  // Interface
  input  xcel_req_t   xcel_reqstream_msg,
  input  logic        xcel_reqstream_val,
  output logic        xcel_reqstream_rdy,

  output xcel_resp_t  xcel_respstream_msg,
  output logic        xcel_respstream_val,
  input  logic        xcel_respstream_rdy
);

  // Ctrl to Dpath
  logic        a_write_en;
  logic        b_write_en;
  logic        c_write_en;
  logic        clear_regs;
  logic [3:0]  calc_idx;
  logic        resp_reg_en;
  logic [0:0]  resp_type;

  // Dpath to Ctrl
  logic [0:0]  req_type;
  logic [4:0]  req_addr;

  // Extract status signals from the message
  assign req_type = xcel_reqstream_msg.type_;
  assign req_addr = xcel_reqstream_msg.addr;

  // force outputs to be zero if invalid
  xcel_resp_t xcel_respstream_msg_raw;
  assign xcel_respstream_msg = xcel_respstream_msg_raw & {$bits(xcel_resp_t){xcel_respstream_val}};

  //----------------------------------------------------------------------
  // Control Unit
  //----------------------------------------------------------------------
  XcelCtrl ctrl
  (
    .clk                  (clk),
    .reset                (reset),

    // Stream Handshake
    .xcel_reqstream_val   (xcel_reqstream_val),
    .xcel_reqstream_rdy   (xcel_reqstream_rdy),
    .xcel_respstream_val  (xcel_respstream_val),
    .xcel_respstream_rdy  (xcel_respstream_rdy),

    // Status from Dpath
    .req_type             (req_type),
    .req_addr             (req_addr),

    // Control to Dpath
    .a_write_en           (a_write_en),
    .b_write_en           (b_write_en),
    .c_write_en           (c_write_en),
    .clear_regs           (clear_regs),
    .calc_idx             (calc_idx),
    .resp_reg_en          (resp_reg_en),
    .resp_type            (resp_type)
  );

  //----------------------------------------------------------------------
  // Datapath Unit
  //----------------------------------------------------------------------
  XcelDpath dpath
  (
    .clk                  (clk),
    .reset                (reset),

    // Data Interfaces
    .req_msg              (xcel_reqstream_msg),
    .resp_msg_raw         (xcel_respstream_msg_raw),

    // Control from Ctrl
    .a_write_en           (a_write_en),
    .b_write_en           (b_write_en),
    .c_write_en           (c_write_en),
    .clear_regs           (clear_regs),
    .calc_idx             (calc_idx),
    .resp_reg_en          (resp_reg_en),
    .resp_type            (resp_type)
  );

endmodule

`endif 