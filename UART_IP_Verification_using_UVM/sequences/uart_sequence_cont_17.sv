class uart_sequence_cont_17 extends uvm_sequence #(uart_transaction);
	`uvm_object_utils(uart_sequence_cont_17)

	function new(string name = "uart_sequence_cont_17");
		super.new(name);
	endfunction

	virtual task body();
		for(int i = 0; i < 17; i++) begin 
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
