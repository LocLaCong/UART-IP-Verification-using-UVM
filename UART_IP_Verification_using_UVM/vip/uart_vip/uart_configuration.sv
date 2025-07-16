class uart_configuration extends uvm_object;
	typedef enum {
		TX,
		RX,
		TX_RX
	} uart_mode_enum;
	
	rand uart_mode_enum mode;
	rand int baudrate;
	rand int data_bits; // 5 - 9 bits 
	rand int stop_bits;
	rand bit use_parity; 	// 1: parity used, 0: none parity
	rand bit parity_even;	// 1: even, 0: odd
	rand int div;//divisor
	rand int smp;//oversampling


	//constraint
	constraint c_baudrate  { baudrate inside {2400, 4800, 9600, 19200, 38400, 76800, 115200, 128000};}
  constraint c_data_bits { 
		if(use_parity == 1)
			data_bits inside {[5:8]};
		else
			data_bits inside {[5:9]};
	 }
	constraint c_parity_9_bits{
		if(data_bits == 9) use_parity == 0;	
	}
  constraint c_stop_bits { stop_bits inside {[1:2]}; }
  constraint c_mode      { mode inside {TX, RX, TX_RX}; } 		

	`uvm_object_utils_begin (uart_configuration)
		`uvm_field_enum				(uart_mode_enum, mode, UVM_ALL_ON| UVM_STRING)
		`uvm_field_int				(baudrate						 , UVM_ALL_ON| UVM_DEC	 )
		`uvm_field_int				(data_bits					 , UVM_ALL_ON| UVM_DEC	 )
		`uvm_field_int				(stop_bits					 , UVM_ALL_ON| UVM_DEC	 )
		`uvm_field_int				(use_parity					 , UVM_ALL_ON| UVM_DEC	 )
		`uvm_field_int				(parity_even				 , UVM_ALL_ON| UVM_DEC	 )
		`uvm_field_int				(smp								 , UVM_ALL_ON| UVM_DEC	 )
		`uvm_field_int				(div								 , UVM_ALL_ON| UVM_DEC	 )
	`uvm_object_utils_end

	function new(string name = "uart_configuration");
		super.new(name);
/*		mode 				= TX_RX;
		baudrate		= 9600;
		data_bits		= 9;
		stop_bits		= 2;
		use_parity  = 0;
		parity_even = 1;*/
	endfunction: new

endclass: uart_configuration
