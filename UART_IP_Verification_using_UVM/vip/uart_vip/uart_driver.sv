class uart_driver extends uvm_driver #(uart_transaction);
	`uvm_component_utils(uart_driver)

	virtual uart_if uart_vif;
	virtual ahb_if ahb_vif;
	uart_configuration cfg; //configuration
	uart_configuration re_cfg;
	bit flag_reconfig = 0;
	
	function new(string name = "uart_driver", uvm_component parent);
		super.new(name,parent);
	endfunction: new

	virtual function void build_phase(uvm_phase phase); 
		super.build_phase(phase);
		if(!uvm_config_db#(virtual uart_if)::get(this,"","uart_vif",uart_vif))
			`uvm_fatal(get_type_name(), $sformatf("Failed to get uart_if from uvm_config_db"))
    if(!uvm_config_db#(virtual ahb_if)::get(this,"","ahb_vif",ahb_vif))
      `uvm_fatal(get_type_name(),$sformatf("Failed to get from uvm_config_db. Please check!"))


		if(!uvm_config_db#(uart_configuration)::get(this,"","cfg",cfg))
			`uvm_fatal(get_type_name(), $sformatf("Failed to get cfg from uvm_config_db"))
	endfunction: build_phase


	virtual task run_phase(uvm_phase phase);
		//////////
		forever begin 
			seq_item_port.get(req);
			
			case(cfg.mode)
				uart_configuration::TX: 	drive_tx_mode(req);
				uart_configuration::RX: 	drive_rx_mode(req);
				uart_configuration::TX_RX:drive_tx_rx_mode(req);
				default: `uvm_error(get_type_name(), $sformatf("Unknown mode"))
			endcase

			$cast(rsp, req.clone());
			rsp.set_id_info(req);
			seq_item_port.put(rsp);	
		end 
	endtask: run_phase

	//virtual task drive(inout uart_transaction req);
	//endtask: drive



	task wait_n_clk(input int n);
		repeat(n) @(posedge ahb_vif.HCLK); 
	endtask

	//TX mode: transmit only
	task drive_tx_mode(inout uart_transaction req);
		drive_tx(req);
	endtask: drive_tx_mode
	
	//RX mode: receive only
	task drive_rx_mode(inout uart_transaction req);
		`uvm_info(get_type_name(), $sformatf("RX_mode: Driver no transmit"), UVM_LOW)
	endtask: drive_rx_mode	

	//TX_RX mode: 
	task drive_tx_rx_mode(inout uart_transaction req);
		drive_tx(req);
	endtask: drive_tx_rx_mode

	//Transfer data function, support inject error
	task drive_tx(inout uart_transaction req);
		int data_bits = cfg.data_bits;
		int use_parity = cfg.use_parity;
		int parity_even = cfg.parity_even;
		int stop_bits = cfg.stop_bits;
		int baudrate = cfg.baudrate;
		int n = cfg.div*cfg.smp;
		if(flag_reconfig) begin
			data_bits = re_cfg.data_bits;
			use_parity = re_cfg.use_parity;
			parity_even = re_cfg.parity_even;
			stop_bits = re_cfg.stop_bits;
			baudrate = re_cfg.baudrate;
			n = re_cfg.div*re_cfg.smp;
		end
	
		//Start bis
		uart_vif.tx = 1'b0;
		wait_n_clk(n);
	
		//Data bits
		for(int i = 0; i < data_bits; i++) begin 
			uart_vif.tx = req.data[i];
			wait_n_clk(n);
		end
		
		//Parity
		if(use_parity) begin 
			bit parity_bit = calc_parity(req.data, data_bits, parity_even);
			uart_vif.tx = parity_bit;
			wait_n_clk(n);
		end

		//Stop_bits
		repeat (stop_bits) begin
			uart_vif.tx = 1'b1;	
			wait_n_clk(n);
		end
	endtask: drive_tx

	function bit calc_parity(bit [8:0] data, int data_bits, bit even);
		bit parity = 0;
		for(int i = 0; i < data_bits; i++)
			parity ^= data[i];
		if(!even)
			parity = ~parity;
		return parity;
	endfunction: calc_parity

	function void reconfig();
		if(!uvm_config_db#(uart_configuration)::get(this,"","re_cfg",re_cfg))
		`uvm_fatal(get_type_name(), $sformatf("Failed to get re_cfg from uvm_config_db"))
		else flag_reconfig = 1;
	endfunction

endclass: uart_driver
