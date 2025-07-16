class full_baudrate_reconfig extends uart_base_test;
	`uvm_component_utils(full_baudrate_reconfig)
	
	uart_sequence_cont uart_seq;
	uart_sequence_cont uart_seq_x;
	uart_configuration cfg_tmp;
	uart_configuration re_cfg;

	function new(string name = "full_baudrate_reconfig", uvm_component parent);
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
		cfg_tmp.use_parity = 0;
		cfg_tmp.parity_even = 1;

    set_lhs_mode(cfg_tmp.mode);
		set_lhs_div(cfg_tmp.div);
		set_lhs_smp(cfg_tmp.smp);
		set_lhs_baudrate(cfg_tmp.baudrate);
    set_lhs_data_bits(cfg_tmp.data_bits);
    set_lhs_stop_bits(cfg_tmp.stop_bits);
    set_lhs_use_parity(cfg_tmp.use_parity);
    set_lhs_parity_even(cfg_tmp.parity_even); 
		`uvm_info(get_type_name(),$sformatf("Configuration: \n%s",cfg_tmp.sprint()),UVM_LOW)	

  endfunction
	
	virtual task run_phase(uvm_phase phase); 
		bit[31:0] rdata;
		bit[31:0] wtbr;
		uvm_status_e status;

		phase.raise_objection(this);

		uart_seq = uart_sequence_cont::type_id::create("uart_seq");
		config_register(cfg_tmp);

		for(int i = 0; i < 2; i++) begin
			wtbr = $urandom_range(32'hAA,32'hFF);
			regmodel.TBR.write(status, wtbr);
			env.uart_agt.monitor.count_tbr++;
		end
		
		uart_seq.start(env.uart_agt.sequencer);	
		
		wait(env.uart_agt.monitor.count_tbr == 0&& env.uart_agt.monitor.count_rbr == 2);
		for(int i = 0; i < 2; i++) begin
			env.uart_agt.monitor.count_rbr--;
			regmodel.RBR.read(status,rdata);
		end
		#100us;
		//RECONFIG	
		uart_seq_x = uart_sequence_cont::type_id::create("uart_seq_x");
		re_cfg = uart_configuration::type_id::create("re_cfg",this);
		re_cfg.mode = uart_configuration::TX_RX;
		re_cfg.baudrate = 115200;
		re_cfg.smp = 16;
		re_cfg.div = 54;
		re_cfg.data_bits = 8;
		re_cfg.stop_bits = 1;
		re_cfg.use_parity = 0;
		re_cfg.parity_even = 1;
		`uvm_info(get_type_name(),$sformatf("RE-Configuration: \n%s",re_cfg.sprint()),UVM_LOW)	
		reconfig(re_cfg);
		#1us;
		config_register(re_cfg);
		
		for(int i = 0; i < 2; i++) begin
			wtbr = $urandom_range(32'hAA,32'hFF);
			regmodel.TBR.write(status, wtbr);
			env.uart_agt.monitor.count_tbr++;
		end
		
		uart_seq_x.start(env.uart_agt.sequencer);	
		
		wait(env.uart_agt.monitor.count_tbr == 0);
		wait(env.uart_agt.monitor.count_rbr == 2);
		for(int i = 0; i < 2; i++) begin
			regmodel.RBR.read(status,rdata);
		end

		phase.drop_objection(this);
	endtask

endclass
