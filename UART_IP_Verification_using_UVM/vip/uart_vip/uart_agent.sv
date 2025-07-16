class uart_agent extends uvm_agent;
	`uvm_component_utils(uart_agent)

	//interface
	virtual uart_if uart_vif;
	virtual ahb_if ahb_vif;
	
	//configuration
	uart_configuration cfg;
	uart_configuration re_cfg;
	
	uart_sequencer sequencer;
	uart_driver driver;
	uart_monitor monitor;

	function new(string name = "uart_agent", uvm_component parent);
		super.new(name,parent);
	endfunction

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		//GET uart_vif from config_db
		if(!uvm_config_db #(virtual uart_if)::get(this,"","uart_vif", uart_vif))
			`uvm_fatal(get_type_name(), $sformatf("Failed to get ahb_vif from uvm_config_fb"))
		//GET uart_configuration from config_db
		if(!uvm_config_db #(uart_configuration)::get(this,"","cfg", cfg))
			`uvm_fatal(get_type_name(), $sformatf("Failed to get cfg(config) from uvm_config_fb"))
		if(!uvm_config_db#(virtual ahb_if)::get(this,"","ahb_vif",ahb_vif))
			`uvm_fatal(get_type_name(), $sformatf("Failed to get ahb_vif from uvm_config_db"))

	
		if(cfg.mode == uart_configuration::RX) is_active = UVM_PASSIVE;
		else is_active = UVM_ACTIVE;

		if(is_active == UVM_ACTIVE) begin 
			`uvm_info(get_type_name(), $sformatf("Active agent is configured"), UVM_LOW)
			sequencer = uart_sequencer::type_id::create("sequencer", this);
			driver = uart_driver::type_id::create("driver", this);
			monitor = uart_monitor::type_id::create("monitor", this);
		
			//SET uart_vif to uvm_config_db
			uvm_config_db #(virtual uart_if)::set(this,"driver","uart_vif", uart_vif);
			uvm_config_db #(virtual uart_if)::set(this,"monitor","uart_vif", uart_vif);
			uvm_config_db #(virtual ahb_if)::set(this,"driver","ahb_vif", ahb_vif);
			uvm_config_db #(virtual ahb_if)::set(this,"monitor","ahb_vif", ahb_vif);
			//SET uart_configuration
			uvm_config_db #(uart_configuration)::set(this,"driver","cfg", cfg);
			uvm_config_db #(uart_configuration)::set(this,"monitor","cfg", cfg);
		end
		else begin
			`uvm_info(get_type_name(), $sformatf("Passive agent is configured"), UVM_LOW)	
			monitor = uart_monitor::type_id::create("monitor", this);

			uvm_config_db #(virtual uart_if)::set(this,"monitor","uart_vif", uart_vif);
			uvm_config_db #(uart_configuration)::set(this,"monitor","cfg", cfg);
			uvm_config_db #(virtual ahb_if)::set(this,"monitor","ahb_vif", ahb_vif);
		end
	endfunction: build_phase
	
	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		if(get_is_active() == UVM_ACTIVE) begin
			driver.seq_item_port.connect(sequencer.seq_item_export);
		end
	endfunction: connect_phase
	
	function void reconfig();
		if(!uvm_config_db #(uart_configuration)::get(this,"","re_cfg", re_cfg))
		`uvm_fatal(get_type_name(), $sformatf("Failed to get re_cfg(config) from uvm_config_fb"))
		if(is_active == UVM_ACTIVE) begin 
			//SET uart_configuration
			uvm_config_db #(uart_configuration)::set(this,"driver","re_cfg", re_cfg);
			uvm_config_db #(uart_configuration)::set(this,"monitor","re_cfg", re_cfg);
			fork
				driver.reconfig();
				monitor.reconfig();
			join_none
		end
		else begin	
			uvm_config_db #(uart_configuration)::set(this,"monitor","re_cfg", re_cfg);
			monitor.reconfig();
		end
	endfunction
		
endclass: uart_agent
