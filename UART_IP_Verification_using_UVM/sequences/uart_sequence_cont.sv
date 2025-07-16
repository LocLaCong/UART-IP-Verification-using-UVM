class uart_sequence_cont extends uvm_sequence #(uart_transaction);
	`uvm_object_utils(uart_sequence_cont)

	function new(string name = "uart_sequence_cont");
		super.new(name);
	endfunction

	virtual task body();
		for(int i = 0; i < 2; i++) begin 
			req = uart_transaction::type_id::create("req");
			start_item(req);
		 	if(req.randomize() with {req.data != 0;} ) begin 
				`uvm_info(get_type_name(),$sformatf("Send req to driver: \n %s", req.sprint()),UVM_LOW)
			end
			else begin
				`uvm_fatal(get_type_name(),$sformatf("Randomize failure"))
			end
			finish_item(req);
			get_response(rsp);
	
		end
	endtask
endclass
