`ifndef V_XCEL_MSG_V
`define V_XCEL_MSG_V

//========================================================================
// Accelerator Request Message
//========================================================================
// Accelerator request messages can either be to read or write an
// accelerator register. Read requests include just a register specifier,
// while write requests include an accelerator register specifier and the
// actual data to write to the accelerator register.
//
// Message Format:
//
//    1b     5b      32b
//  +------+-------+-----------+
//  | type | raddr | data      |
//  +------+-------+-----------+
//

typedef struct packed
{
  logic [0:0]  type_;
  logic [4:0]  addr;
  logic [31:0] data;
}
xcel_req_t;

`define VC_XCEL_REQ_MSG_TYPE_READ  1'd0
`define VC_XCEL_REQ_MSG_TYPE_WRITE 1'd1
`define VC_XCEL_REQ_MSG_TYPE_X     1'dx

//========================================================================
// Accelerator Response Message
//========================================================================
// Accelerator response messages can either be from a read or write of an
// accelerator register. Read requests include the actual value read from
// the accelerator register, while write requests currently include
// nothing other than the type.
//
// Message Format:
//
//    1b     32b
//  +------+-----------+
//  | type | data      |
//  +------+-----------+
//
typedef struct packed
{
  logic [0:0]  type_;
  logic [31:0] data;
}
xcel_resp_t;

`define VC_XCEL_RESP_MSG_TYPE_READ  1'd0
`define VC_XCEL_RESP_MSG_TYPE_WRITE 1'd1
`define VC_XCEL_RESP_MSG_TYPE_X     1'dx

`endif /* VC_XCEL_MSG_V */