class baudrate_mismatch extends uart_base_test;
	`uvm_component_utils(baudrate_mismatch)
	
	uart_sequence uart_seq;
	uart_configuration cfg_tmp;
	uart_configuration cfg_reg;


	function new(string name = "baudrate_mismatch", uvm_component parent);
		super.new(name,parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

				cfg_tmp = uart_configuration::type_id::create("cfg_tmp",this);
	//	assert(cfg_tmp.randomize() with {mode == uart_configuration::TX_RX;});
    // Config LHS
		cfg_tmp.mode = uart_configuration::TX_RX;
		cfg_tmp.baudrate = 76800;
		cfg_tmp.smp = 16;
		cfg_tmp.div = 81;
		cfg_tmp.data_bits = 8;
		cfg_tmp.stop_bits = 1;
		cfg_tmp.use_parity = 1;
		cfg_tmp.parity_even = 1;

    set_lhs_mode(cfg_tmp.mode);
		set_lhs_div(cfg_tmp.div);
		set_lhs_smp(cfg_tmp.smp);
		set_lhs_baudrate(cfg_tmp.baudrate);
    set_lhs_data_bits(cfg_tmp.data_bits);
    set_lhs_stop_bits(cfg_tmp.stop_bits);
    set_lhs_use_parity(cfg_tmp.use_parity);
    set_lhs_parity_even(cfg_tmp.parity_even); 
		`uvm_info(get_type_name(),$sformatf("Configuration UART VIP : \n%s",cfg_tmp.sprint()),UVM_LOW)	

  endfunction


	virtual task main_phase(uvm_phase phase);
		phase.raise_objection(this);

		err_catcher.add_error_catcher_msg("Mismatch UART IP ==> VIP");
		err_catcher.add_error_catcher_msg("Mismatch VIP ==> UART IP");
		err_catcher.add_error_catcher_msg("Invalid stop bit");	
		phase.drop_objection(this);
	endtask

	
	virtual task run_phase(uvm_phase phase); 
		bit[31:0] rdata;
		bit[31:0] wtbr;
		uvm_status_e status;

		phase.raise_objection(this);

		uart_seq = uart_sequence::type_id::create("uart_seq");

		//config register	
		cfg_reg = uart_configuration::type_id::create("reg",this);
		cfg_reg.mode = uart_configuration::TX_RX;
		cfg_reg.baudrate = 115200;
		cfg_reg.div = 54;
		cfg_reg.smp = 16;
		cfg_reg.data_bits = 8;
		cfg_reg.stop_bits = 1;
		cfg_reg.use_parity = 1;
		cfg_reg.parity_even = 1;	
		`uvm_info(get_type_name(),$sformatf("Configuration UART IP: \n%s",cfg_reg.sprint()),UVM_LOW)	
		config_register(cfg_reg);


		for(int i = 0; i < 1; i++) begin
			wtbr = $urandom_range(32'hAA,32'hFF);
			regmodel.TBR.write(status, wtbr);
			env.uart_agt.monitor.count_tbr++;
		end
		
		uart_seq.start(env.uart_agt.sequencer);	
		
		wait(env.uart_agt.monitor.count_tbr == 0&& env.uart_agt.monitor.count_rbr == 1);
		for(int i = 0; i < 1; i++) begin
			regmodel.RBR.read(status,rdata);
		end


		phase.drop_objection(this);
	endtask

endclass
