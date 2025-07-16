class uart_transaction extends uvm_sequence_item;
	rand bit [8:0] data;
	bit parity;
	bit [1:0] stopbit;


	`uvm_object_utils_begin (uart_transaction)
		`uvm_field_int				(data										 , UVM_ALL_ON |UVM_HEX)	
		`uvm_field_int				(parity									 , UVM_ALL_ON |UVM_HEX)	
		`uvm_field_int				(stopbit								 , UVM_ALL_ON |UVM_HEX)	
	`uvm_object_utils_end

	function new(string name = "uart_transaction");
		super.new(name);
	endfunction: new

endclass: uart_transaction
