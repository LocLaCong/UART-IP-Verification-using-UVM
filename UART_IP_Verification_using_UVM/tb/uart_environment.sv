class uart_environment extends uvm_env;
  `uvm_component_utils(uart_environment)
  //ahb agent
  virtual ahb_if  ahb_vif;
  ahb_agent       ahb_agt;

	uart_reg_block regmodel;
	uart_reg2ahb_adapter ahb_adapter;

  // Predictor class creation
  uvm_reg_predictor #(ahb_transaction) ahb_predictor;

	bit register_test = 1;

	//uart agent
	virtual uart_if uart_vif;
	uart_configuration cfg;
	uart_configuration re_cfg;
	uart_agent uart_agt;

	uart_scoreboard scoreboard;

  function new(string name="uart_environment", uvm_component parent);
    super.new(name,parent);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
		`uvm_info("build_phase","Entered...",UVM_HIGH)

    if(!uvm_config_db#(virtual ahb_if)::get(this,"","ahb_vif",ahb_vif))
      `uvm_fatal(get_type_name(),$sformatf("Failed to get ahb_vif from uvm_config_db"))

    ahb_agt = ahb_agent::type_id::create("ahb_agt",this);
		
		ahb_adapter = uart_reg2ahb_adapter::type_id::create("ahb_adapter");

		regmodel = uart_reg_block::type_id::create("reg_model",this);
		regmodel.build();

    ahb_predictor = uvm_reg_predictor#(ahb_transaction)::type_id::create("ahb_predictor",this);

    uvm_config_db#(virtual ahb_if)::set(this,"ahb_agt","ahb_vif",ahb_vif);


	//uart_agent
	//Get uart_vif anh uart_configuration from uvm_db config
	if(!uvm_config_db#(virtual uart_if)::get(this,"","uart_vif",uart_vif))
		`uvm_fatal(get_type_name(),$sformatf("Failed to get uart_vif from config db"))	
	if(!uvm_config_db#(uart_configuration)::get(this,"","cfg",cfg))
		`uvm_fatal(get_type_name(),$sformatf("Failed to get cfg from config db"))


	scoreboard = uart_scoreboard::type_id::create("scoreboard",this);
	uart_agt = uart_agent::type_id::create("uart_agt",this);
	//SET uart_vif and uart_configurationsd to agent
	uvm_config_db #(virtual uart_if)::set(this,"uart_agt","uart_vif",uart_vif);
	uvm_config_db #(uart_configuration)::set(this,"uart_agt","cfg",cfg);
	uvm_config_db #(virtual ahb_if)::set(this,"uart_agt","ahb_vif",ahb_vif);

	//Send config to scoreboard to perform coverage
	
	uvm_config_db #(uart_configuration)::set(this,"scoreboard","cfg",cfg);
	
	`uvm_info("build_phase","Exitting...",UVM_HIGH)
  endfunction: build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
		`uvm_info("connect_phase","Entered",UVM_HIGH)
		if(regmodel.get_parent() == null)
			regmodel.ahb_map.set_sequencer(ahb_agt.sequencer, ahb_adapter);

    
    // Predictor connection
    ahb_predictor.map = regmodel.ahb_map;
    ahb_predictor.adapter = ahb_adapter;
    ahb_agt.monitor.ahb_observe_port.connect(ahb_predictor.bus_in);
    
    // Connect monitor to scoreboard
		if(register_test) begin
			uart_agt.monitor.uart_observe_port_tx.connect(scoreboard.uvip_tx_export);
			uart_agt.monitor.uart_observe_port_rx.connect(scoreboard.uvip_rx_export);
			ahb_agt.monitor.ahb_observe_port.connect(scoreboard.ahb_export);
			uart_agt.monitor.interrupt_time_port.connect(scoreboard.uvip_int_export);
			uart_agt.monitor.parity_bit_time_port.connect(scoreboard.uvip_parity_bit_time_export);
		end
		`uvm_info("connect_phase","Exitting...",UVM_HIGH)
  endfunction: connect_phase
		
	function void reconfig();
		if(!uvm_config_db#(uart_configuration)::get(this,"","re_cfg",re_cfg))
		`uvm_fatal(get_type_name(),$sformatf("Failed to get cfg from config db"))

		uvm_config_db #(uart_configuration)::set(this,"uart_agt","re_cfg",re_cfg);
		uart_agt.reconfig();

	endfunction

	
endclass

