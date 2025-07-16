//=============================================================================
// Project       : UART VIP
//=============================================================================
// Filename      : seq_pkg.sv
// Author        : La Cong Loc
// Company       : NO
// Date          : 30-June-2025
//=============================================================================
// Description   : 
//
//
//
//=============================================================================
`ifndef GUARD_UART_SEQ_PKG__SV
`define GUARD_UART_SEQ_PKG__SV

package seq_pkg;
  import uvm_pkg::*;
  import uart_pkg::*;
	import ahb_pkg::*;
  // Include your file
	`include "uart_sequence.sv" 
	`include "uart_sequence_cont.sv" 
	`include "uart_sequence_cont_17.sv"
	`include "access_rsvd_sequence.sv" 

endpackage: seq_pkg

`endif


