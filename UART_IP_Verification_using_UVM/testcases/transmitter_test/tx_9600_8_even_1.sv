class tx_9600_8_even_1 extends uart_base_test;
	`uvm_component_utils(tx_9600_8_even_1)
	
	uart_sequence_cont uart_seq;
	uart_configuration cfg_tmp;

	function new(string name = "tx_9600_8_even_1", uvm_component parent);
		super.new(name,parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

			cfg_tmp = uart_configuration::type_id::create("cfg_tmp",this);
    // Configuration
		cfg_tmp.mode = uart_configuration::RX;
		cfg_tmp.baudrate = 9600;
		cfg_tmp.smp = 16;
		cfg_tmp.div = 651;
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
		`uvm_info(get_type_name(),$sformatf("Configuration: \n%s",cfg_tmp.sprint()),UVM_LOW)	
  endfunction	

	virtual task run_phase(uvm_phase phase); 
		bit[31:0] rdata;
		bit[31:0] wtbr;
		uvm_status_e status;

		phase.raise_objection(this);

		uart_seq = uart_sequence_cont::type_id::create("uart_seq");
		//Config register
		config_register(cfg_tmp);

		for(int i = 0; i < 2; i++) begin
			wtbr = $urandom_range(32'hAA,32'hFF);
			regmodel.TBR.write(status,wtbr);
			env.uart_agt.monitor.count_tbr++;
		end		
		wait(env.uart_agt.monitor.count_tbr == 0);

		phase.drop_objection(this);
	endtask

endclass
