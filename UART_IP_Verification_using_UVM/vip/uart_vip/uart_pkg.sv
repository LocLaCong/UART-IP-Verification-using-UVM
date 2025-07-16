//=============================================================================
// Project       : UART VIP
//=============================================================================
// Filename      : uart_pkg.sv
// Author        : La Cong Loc
// Company       : NO
// Date          : 30-June-2025
//=============================================================================
// Description   : 
//
//
//
//=============================================================================
`ifndef GUARD_UART_PKG__SV
`define GUARD_UART_PKG__SV
package uart_pkg;
  import uvm_pkg::*;

  // Include your file
	`include "uart_error_catcher.sv"
	`include "uart_configuration.sv"
	`include "uart_transaction.sv"
	`include "uart_sequencer.sv"
	`include "uart_driver.sv"
	`include "uart_monitor.sv"
	`include "uart_agent.sv"
		

endpackage: uart_pkg

`endif

