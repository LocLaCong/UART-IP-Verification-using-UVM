class uart_base_test extends uvm_test;
  `uvm_component_utils(uart_base_test)

  uvm_report_server  svr;
  uart_environment  env;

  uart_reg_block   regmodel;
  virtual ahb_if    ahb_vif;

  time usr_timeout=1s;


	//uart_vip
	virtual uart_if uart_vif;
	uart_configuration cfg;
	uart_configuration re_cfg;
	uart_error_catcher err_catcher;
	

  function new(string name="uart_base_test", uvm_component parent);
    super.new(name,parent);
  endfunction: new

// ===== Setter functions for lhs_cfg =====
  virtual function void set_lhs_mode(uart_configuration::uart_mode_enum mode);
    cfg.mode = mode;
  endfunction

  virtual function void set_lhs_baudrate(int baudrate);
    cfg.baudrate = baudrate;
  endfunction

  virtual function void set_lhs_div(int div);
    cfg.div = div;
  endfunction 

	virtual function void set_lhs_smp(int smp);
    cfg.smp = smp;
  endfunction

  virtual function void set_lhs_data_bits(int data_bits);
    cfg.data_bits = data_bits;
  endfunction

  virtual function void set_lhs_stop_bits(int stop_bits);
    cfg.stop_bits = stop_bits;
  endfunction

  virtual function void set_lhs_use_parity(bit use_parity);
    cfg.use_parity = use_parity;
  endfunction

  virtual function void set_lhs_parity_even(bit parity_even);
    cfg.parity_even = parity_even;
  endfunction




  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual ahb_if)::get(this,"","ahb_vif",ahb_vif))
      `uvm_fatal(get_type_name(),$sformatf("Failed to get ahb_vif from uvm_config_db"))

    env     = uart_environment::type_id::create("env",this);

    uvm_config_db#(virtual ahb_if)::set(this,"env","ahb_vif",ahb_vif);

    uvm_top.set_timeout(usr_timeout);

		//uart_vip
		if(!uvm_config_db #(virtual uart_if)::get(this,"","uart_vif",uart_vif))
			`uvm_fatal(get_type_name(),$sformatf("Failed to get uart_vif from config db"))

		err_catcher = uart_error_catcher::type_id::create("err_catcher");
		uvm_report_cb::add(null,err_catcher);	

		cfg = uart_configuration::type_id::create("cfg", this);

		uvm_config_db #(virtual uart_if)::set(this,"env","uart_vif",uart_vif);
		uvm_config_db #(uart_configuration)::set(this,"env","cfg",cfg);

  endfunction: build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    this.regmodel = env.regmodel;
  endfunction: connect_phase

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction: end_of_elaboration_phase
  
  virtual function void final_phase(uvm_phase phase);
    super.final_phase(phase);
    `uvm_info("final_phase","Entered...",UVM_HIGH)
    svr = uvm_report_server::get_server();
    if(svr.get_severity_count(UVM_FATAL)+
       svr.get_severity_count(UVM_ERROR)) begin
     `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
     `uvm_info(get_type_name(), "----           TEST FAILED         ----", UVM_NONE)
     `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
    end
    else begin
     `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
     `uvm_info(get_type_name(), "----           TEST PASSED         ----", UVM_NONE)
     `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
    end
    `uvm_info("final_phase","Exiting...",UVM_HIGH)
  endfunction: final_phase



	virtual task config_register(uart_configuration cfg);
		uvm_status_e status;
		int mdr, dll, dlh, lcr;
	
		//MDR: oversampling mode select
		mdr = (cfg.smp == 13) ? 1 : 0;

		//DLL, DLH
		dll = cfg.div & 8'hFF;
		dlh = (cfg.div >> 8) & 8'hFF;
		
		//LCR
		lcr = 0;
		lcr |= (1 << 5);										// [5] BGE
		lcr |= ((cfg.parity_even & 1) << 4);// [4] ESP
		lcr	|= ((cfg.use_parity & 1) << 3); // [3] PEN
		lcr |= (((cfg.stop_bits == 2) ? 1 : 0) << 2);// [2] STB
		lcr |= ((cfg.data_bits - 5) & 2'b11); // [1:0] WLS


    `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
    `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
		`uvm_info(get_type_name(),$sformatf("UART IP REGISTER CONFIGURATION:\n MDR = 0x%0h\n DLH = 0x%0h		DLL = 0x%0h\n LCR = 0x%0h", mdr, dlh, dll, lcr),UVM_LOW)
		 `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
    `uvm_info(get_type_name(), "---------------------------------------", UVM_NONE)
		regmodel.MDR.write(status, mdr);
		regmodel.DLL.write(status, dll);
		regmodel.DLH.write(status, dlh);
		regmodel.LCR.write(status, lcr);
	endtask
	
	



	virtual function void reconfig(uart_configuration cfg_tmp);
		re_cfg = uart_configuration::type_id::create("re_cfg", this);
		re_cfg = cfg_tmp;
		uvm_config_db #(uart_configuration)::set(this,"env","re_cfg",re_cfg);
		env.reconfig();
	endfunction


endclass: uart_base_test
