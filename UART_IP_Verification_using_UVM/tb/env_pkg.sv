//=============================================================================
// Project       : UART VIP
//=============================================================================
// Filename      : env_pkg.sv
// Author        : La Cong Loc
// Company       : NO
// Date          : 30-June-2025
//=============================================================================
// Description   : 
//
//
//
//=============================================================================
`ifndef GUARD_UART_ENV_PKG__SV
`define GUARD_UART_ENV_PKG__SV

package env_pkg;
  import uvm_pkg::*;
  import uart_pkg::*;
	import ahb_pkg::*;
	import uart_regmodel_pkg::*;

  // Include your file

	`include "uart_scoreboard.sv"
	`include "uart_environment.sv"
	`include "coverage.sv"
	
endpackage: env_pkg

`endif


