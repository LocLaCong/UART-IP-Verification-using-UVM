class uart_MDR_reg extends uvm_reg;
	`uvm_object_utils(uart_MDR_reg);

	uvm_reg_field rsvd;
	rand uvm_reg_field OSM_SEL;

	function new(string name = "uart_MDR_reg");
		super.new(name,32,UVM_NO_COVERAGE);
	endfunction

	virtual function void build();
		//Create object instance for each field
		rsvd = uvm_reg_field::type_id::create("rsvd");
		OSM_SEL = uvm_reg_field::type_id::create("OSM_SEL");

		//Configure each field
		rsvd.configure(this,31,1,"RO",1'b0,31'h0,1,1,1);
		OSM_SEL.configure(this,1,0,"RW",1'b0,1'b0,1,1,1);
		
	endfunction
	
endclass
