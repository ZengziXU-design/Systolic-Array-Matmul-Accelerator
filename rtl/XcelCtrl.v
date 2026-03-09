`ifndef PROJ_XCEL_CTRL_V
`define PROJ_XCEL_CTRL_V

`include "../rtl/xcel-msgs.v"

module XcelCtrl
(
  input  logic        clk,
  input  logic        reset,

  // Handshake signals
  input  logic        xcel_reqstream_val,
  output logic        xcel_reqstream_rdy,
  output logic        xcel_respstream_val,
  input  logic        xcel_respstream_rdy,

  // Status from Dpath
  input  logic [0:0]  req_type,
  input  logic [4:0]  req_addr,

  // Control to Dpath
  output logic        a_write_en,
  output logic        b_write_en,
  output logic        c_write_en,
  output logic        clear_regs,
  output logic [3:0]  calc_idx,
  output logic        resp_reg_en,
  output logic [0:0]  resp_type
);

  logic req_handshake;
  logic resp_handshake;
  assign req_handshake = xcel_reqstream_val && xcel_reqstream_rdy;
  assign resp_handshake = xcel_respstream_val && xcel_respstream_rdy;

  logic [3:0] a_row_valid;
  logic [3:0] b_row_valid;
  logic [3:0] calc_count;
  logic [3:0] read_count;

  typedef enum logic [1:0] { STATE_LOAD, STATE_CALC, STATE_READ } state_t;
  state_t state_q, state_d;

  // State transition logic
  always_ff @(posedge clk) begin
    if (reset) state_q <= STATE_LOAD;
    else       state_q <= state_d;
  end

  always_comb begin
    state_d = state_q;
    unique case (state_q)
      STATE_LOAD: if (a_row_valid == 4'b1111 && b_row_valid == 4'b1111) state_d = STATE_CALC;
      STATE_CALC: if (calc_count == 4'd9) state_d = STATE_READ;
      STATE_READ: if (read_count == 4'd15 && resp_handshake) state_d = STATE_LOAD;
      default:    state_d = STATE_LOAD;
    endcase
  end

  // Counters & Valid bits updating
  always_ff @(posedge clk) begin
    if (reset) begin
      a_row_valid <= 0;
      b_row_valid <= 0;
      calc_count  <= 0;
      read_count  <= 0;
    end else begin
      if (state_q == STATE_LOAD && req_handshake && req_type == `VC_XCEL_REQ_MSG_TYPE_WRITE) begin
        if (req_addr < 5'd4) a_row_valid[req_addr] <= 1'b1;
        else if (req_addr >= 5'd4 && req_addr < 5'd8) b_row_valid[req_addr - 5'd4] <= 1'b1;
      end else if (state_q == STATE_CALC && state_d == STATE_READ) begin
        a_row_valid <= 0;
        b_row_valid <= 0;
      end

      if (state_q == STATE_CALC) calc_count <= calc_count + 1;
      else calc_count <= 0;

      if (state_q == STATE_READ && resp_handshake) read_count <= read_count + 1;
      else if (state_q != STATE_READ) read_count <= 0;
    end
  end

  // Control Signal Generation (Outputs)
  always_comb begin
    a_write_en  = (state_q == STATE_LOAD && req_handshake && req_type == `VC_XCEL_REQ_MSG_TYPE_WRITE && req_addr < 5'd4);
    b_write_en  = (state_q == STATE_LOAD && req_handshake && req_type == `VC_XCEL_REQ_MSG_TYPE_WRITE && req_addr >= 5'd4 && req_addr < 5'd8);
    c_write_en  = (state_q == STATE_CALC);
    clear_regs  = (state_q == STATE_CALC && state_d == STATE_READ); // Clear A/B when calc is done, or clear C when read is done
    calc_idx    = calc_count;
    resp_reg_en = req_handshake;
    resp_type   = (state_q == STATE_LOAD) ? `VC_XCEL_RESP_MSG_TYPE_WRITE : `VC_XCEL_RESP_MSG_TYPE_READ;
  end

  // Ready/Valid generation
  logic resp_pending;
  assign xcel_respstream_val = resp_pending;

  always_comb begin
    xcel_reqstream_rdy = 1'b0;
    if (!resp_pending) begin
      if (state_q == STATE_LOAD && req_type == `VC_XCEL_REQ_MSG_TYPE_WRITE) xcel_reqstream_rdy = 1'b1;
      else if (state_q == STATE_READ && req_type == `VC_XCEL_REQ_MSG_TYPE_READ) xcel_reqstream_rdy = 1'b1;
    end
  end

  always_ff @(posedge clk) begin
    if (reset) resp_pending <= 0;
    else begin
      case ({req_handshake, resp_handshake})
        2'b10: resp_pending <= 1;
        2'b01: resp_pending <= 0;
        2'b11: resp_pending <= 1;
        default: resp_pending <= resp_pending;
      endcase
    end
  end

endmodule
`endif