class uart_monitor extends uvm_monitor;
	`uvm_component_utils(uart_monitor)

	//interface
	virtual uart_if uart_vif;
	virtual ahb_if ahb_vif;

	//configuration
	uart_configuration cfg;
	uart_configuration re_cfg;
	//analysis port
	uvm_analysis_port #(uart_transaction) uart_observe_port_tx;	
	uvm_analysis_port #(uart_transaction) uart_observe_port_rx;
	uvm_analysis_port #(time) interrupt_time_port;
	uvm_analysis_port #(time) parity_bit_time_port;
	int count_tbr = 0;
	int count_rbr = 0;
	time interrupt = 0;
	time parity_bit_time = 0; // Time that captured parity bit in the line
	bit flag_reconfig = 0;
	bit parity_error  = 0;
	
	
	function new(string name = "uart_monitor", uvm_component parent);
		super.new(name, parent);
		//new analysis port
		uart_observe_port_tx = new("uart_observe_port_tx",this);
		uart_observe_port_rx = new("uart_observe_port_rx",this);
		interrupt_time_port = new("interrupt_time_port", this);
		parity_bit_time_port = new("parity_bit_time_port", this);
	endfunction: new	
	
	//build_phase
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if(!uvm_config_db #(virtual uart_if)::get(this,"","uart_vif", uart_vif))
			`uvm_fatal(get_type_name(),$sformatf("Failed to get uart_vif from uvm_config_db"))
		if(!uvm_config_db #(uart_configuration)::get(this,"","cfg", cfg))	
			`uvm_fatal(get_type_name(),$sformatf("Failed to get cfg from uvm_config_db"))
		// create transaction
		if(!uvm_config_db#(virtual ahb_if)::get(this,"","ahb_vif",ahb_vif))
			`uvm_fatal(get_type_name(),$sformatf("Failed to get ahb_vif from uvm_config_db"))

	endfunction: build_phase

	virtual task run_phase(uvm_phase phase);
		fork
			if(cfg.mode == uart_configuration::TX || cfg.mode == uart_configuration::TX_RX)
				capture_port(uart_vif.tx, 1);// 1: TX (expected frame)
			if(cfg.mode == uart_configuration::RX || cfg.mode == uart_configuration::TX_RX)	
				capture_port(uart_vif.rx, 0);// 0: RX (actual frame)\
			forever begin
				@(posedge uart_vif.interrupt);
				interrupt = $time;
			//	`uvm_info(get_type_name(),$sformatf("Interrupt occured at %0t",interrupt),UVM_LOW)
				interrupt_time_port.write(interrupt);
			end
		join
		endtask: run_phase

	task wait_n_clk(input int n);
		repeat(n) @(posedge ahb_vif.HCLK);
	endtask

	task capture_port(ref logic port, input bit is_tx);
					
		//transaction
		uart_transaction trans;
		int data_bits = cfg.data_bits;
		int use_parity = cfg.use_parity;
		int parity_even = cfg.parity_even;
		int stop_bits = cfg.stop_bits;
		int baudrate 	= cfg.baudrate;
		int n = cfg.div*cfg.smp;
	
		forever begin

			//wait for start bit (falling edge)
			@(negedge port);
			//	if(port !== 1'b0) continue;
			if(flag_reconfig) begin
				data_bits = re_cfg.data_bits;
				use_parity = re_cfg.use_parity;
				parity_even = re_cfg.parity_even;
				stop_bits = re_cfg.stop_bits;
				baudrate 	= re_cfg.baudrate;
				n = re_cfg.div*re_cfg.smp;
				`uvm_info(get_type_name(),$sformatf("RE-Configuration: \n%s",re_cfg.sprint()),UVM_LOW)	
 
			end
			//middle of start bit
			wait_n_clk(n/2);

			trans = uart_transaction::type_id::create("trans", this);
			
			//Data bits
			for(int i = 0; i < data_bits; i++) begin
				wait_n_clk(n);
				trans.data[i] = port;
			end
			
			//parity bis
			if(use_parity) begin
				wait_n_clk(n);
				trans.parity = port;
				if(parity_error) begin
					parity_bit_time = $time;//Time that captured parity bit
					parity_bit_time_port.write(parity_bit_time);
				end
			end
			
			//stop bits
			trans.stopbit = 2'b00;
			for(int i = 0; i < stop_bits; i++) begin 
				wait_n_clk(n);
				trans.stopbit[i] = port;
				if(trans.stopbit[i] == 0) 
					`uvm_error(get_type_name(), $sformatf("Invalid stop bit"))
			end
		
			//Send transaction to analysis port
			if(is_tx) begin
			//	`uvm_info(get_type_name(),$sformatf("tx_frame: %s\n", trans.sprint()),UVM_LOW)
				uart_observe_port_tx.write(trans);
				count_rbr++;
			end
			else begin
		//		`uvm_info(get_type_name(),$sformatf("rx_frame: %s\n", trans.sprint()),UVM_LOW)
				uart_observe_port_rx.write(trans);
				count_tbr--;
			end
		end  
	
	endtask: capture_port

	function void reconfig();
		if(!uvm_config_db #(uart_configuration)::get(this,"","re_cfg", re_cfg))	
		`uvm_fatal(get_type_name(),$sformatf("Failed to get re_cfg from uvm_config_db"))
		else begin
			flag_reconfig = 1;
		end

	endfunction



endclass: uart_monitor
