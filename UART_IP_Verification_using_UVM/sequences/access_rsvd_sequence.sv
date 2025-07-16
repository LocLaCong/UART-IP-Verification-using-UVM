class access_rsvd_sequence extends uvm_sequence #(ahb_transaction);
	`uvm_object_utils(access_rsvd_sequence)


	function new(string name = "access_rsvd_sequence");
		super.new(name);
	endfunction

  virtual task body();
		bit[31:0] wdata;
		bit[9:0] rsvd;
		bit ok;
    for(int i=0; i<1;i=i+4) begin
			//WRITE TRANSFER
			rsvd = $urandom_range(10'h020, 10'h3FF);
			wdata = $urandom_range(32'hAA, 32'hFF);
			
      req = ahb_transaction::type_id::create("req");
      start_item(req);
   		ok = req.randomize() with {addr        == rsvd;
														data 				== wdata;
                            xact_type   == ahb_transaction::WRITE;
                            burst_type  == ahb_transaction::SINGLE;
                            xfer_size   == ahb_transaction::SIZE_32BIT;};
      `uvm_info(get_type_name(),$sformatf("Send req to driver: \n %s",req.sprint()),UVM_LOW);
      finish_item(req);
      get_response(rsp);

			//READ TRANSFER
		  req = ahb_transaction::type_id::create("req");
      start_item(req);
     	ok = req.randomize() with {addr        == rsvd;
	                          xact_type   == ahb_transaction::READ;
                            burst_type  == ahb_transaction::SINGLE;
                            xfer_size   == ahb_transaction::SIZE_32BIT;};
      `uvm_info(get_type_name(),$sformatf("Send req to driver: \n %s",req.sprint()),UVM_LOW);
      finish_item(req);
      get_response(rsp);
			`uvm_info(get_type_name(),$sformatf("Recevied rsp to driver: \n %s",rsp.sprint()),UVM_LOW);
		end
	endtask

endclass
