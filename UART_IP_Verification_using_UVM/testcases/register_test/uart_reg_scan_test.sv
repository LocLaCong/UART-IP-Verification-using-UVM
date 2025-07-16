class uart_reg_scan_test extends uart_base_test;
  `uvm_component_utils(uart_reg_scan_test)

	uvm_reg_hw_reset_seq reset_seq;
	uvm_reg_bit_bash_seq bit_bash_seq;

  function new(string name="uart_reg_scan_test", uvm_component parent);
    super.new(name,parent);
  endfunction: new

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env.register_test = 0;
	endfunction

  virtual task run_phase(uvm_phase phase); 
		reset_seq = uvm_reg_hw_reset_seq::type_id::create("reset_seq");
		bit_bash_seq = uvm_reg_bit_bash_seq::type_id::create("bit_bash_seq");

    phase.raise_objection(this);
			reset_seq.model = regmodel;
			bit_bash_seq.model = regmodel;

			reset_seq.start(null);
			bit_bash_seq.start(null);

    phase.drop_objection(this);
  endtask

endclass
