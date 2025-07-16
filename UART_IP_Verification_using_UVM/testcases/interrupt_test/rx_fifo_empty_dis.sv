class rx_fifo_empty_dis extends uart_base_test;
	`uvm_component_utils(rx_fifo_empty_dis)
	
	uart_sequence_cont uart_seq;
	uart_configuration cfg_tmp;

	function new(string name = "rx_fifo_empty_dis", uvm_component parent);
		super.new(name,parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

				cfg_tmp = uart_configuration::type_id::create("cfg_tmp",this);
	//	assert(cfg_tmp.randomize() with {mode == uart_configuration::TX_RX;});
    // Config LHS
		cfg_tmp.mode = uart_configuration::TX;
		cfg_tmp.baudrate = 115200;
		cfg_tmp.div = 54;
		cfg_tmp.smp = 16;
		cfg_tmp.data_bits = 5;
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
		`uvm_info(get_type_name(),$sformatf("Configuration UART VIP : \n%s",cfg_tmp.sprint()),UVM_LOW)	

  endfunction	
	virtual task run_phase(uvm_phase phase); 
		bit[7:0] rdata;
		uvm_status_e status;


		phase.raise_objection(this);

		
		uart_seq = uart_sequence_cont::type_id::create("uart_seq");
	//	regmodel.IER.write(status,32'h08);	
		//config register	

		config_register(cfg_tmp);

		
		uart_seq.start(env.uart_agt.sequencer);	
		
		wait(env.uart_agt.monitor.count_rbr == 2);
		for(int i = 0; i < 2; i++) begin
			regmodel.RBR.read(status,rdata);
		end
		#1000ns;
		regmodel.FSR.read(status,rdata);
		phase.drop_objection(this);
	endtask

endclass
