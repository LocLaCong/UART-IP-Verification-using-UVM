`uvm_analysis_imp_decl(_uvip_tx)
`uvm_analysis_imp_decl(_uvip_rx)
`uvm_analysis_imp_decl(_ahb)
`uvm_analysis_imp_decl(_uvip_int)
`uvm_analysis_imp_decl(_uvip_parity_bit_time)
	

class uart_scoreboard extends uvm_scoreboard;
	`uvm_component_utils(uart_scoreboard)

	`include "coverage.sv"
	uvm_analysis_imp_uvip_tx#(uart_transaction, uart_scoreboard) uvip_tx_export;
	uvm_analysis_imp_uvip_rx#(uart_transaction, uart_scoreboard) uvip_rx_export;
	uvm_analysis_imp_ahb#(ahb_transaction, uart_scoreboard) ahb_export;
	uvm_analysis_imp_uvip_int#(time, uart_scoreboard) uvip_int_export;//Time that captured interrupt signal
	uvm_analysis_imp_uvip_parity_bit_time#(time, uart_scoreboard) uvip_parity_bit_time_export;//Time that capture parity bit on uart_rxd
	
	//Queue for saving tx/rx transaction
	uart_transaction uvip_tx_queue[$];
	uart_transaction uvip_rx_queue[$];
	uart_transaction ahb_tx_queue[$];
	uart_transaction ahb_rx_queue[$];

	//Coverage
	uart_configuration cfg;

	//Coverage mismatch
	bit[3:0] mis;

	//Cover reconfig
	int cur[4] ;
	int pre[4] ; 
	int is_first[4] = '{1,1,1,1}; 
	bit[4:0] reconfig = 0;																																	//
	//Coverage interrupt
	bit[4:0] int_test = 0;
	//cover access reserved region
	bit[9:0] access_rsvd = 0;
	bit[7:0] data_17th = 0;	
	
	function new(string name = "uart_scoreboard", uvm_component parent);
		super.new(name,parent);	
		cfg_fc = new();
		UART_GROUP = new();
	endfunction
	
	//Build_frame variable	
	bit[31:0] lcr;
	bit[31:0] tbr;
	bit[31:0] rbr;
	bit access_ier;
	bit[7:0] dll;
	bit[7:0] dlh;
	bit[15:0] div;
	bit[31:0] ier;
	bit[31:0] write_rsvd;
	bit[31:0] read_rsvd;
	bit is_tx;
	
	//Interrupt Variable
	int tx_fifo_count = 0;
	int rx_fifo_count = 0;
	int fifo_size = 17;
	int parity_err = 0;

	bit[4:0] fsr;  //fsr
	bit[4:0] exp_fsr;//expected fsr
	bit first_fsr = 1;
	bit write_fsr;
	bit parity_ip;
	bit parity_vip = 0;
	bit flag_uvip_tx = 0;
	bit flag_build_frame = 0;
	bit write_tx_fifo_full = 0;

	bit flag = 0;  //flag inform enter interrupt function
	//Interrupt event tracking
	time event_int = 0;  //event trigger time
	int event_pending = 0; // flag the event interrupt
	time event_parity = 0;;// flag the parity error event
	time interrupt_scb;
	int count_tx = 0;
	int count_rx = 0;

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		uvip_tx_export = new("uvip_tx_export",this);
		uvip_rx_export = new("uvip_rx_export",this);
		ahb_export = new("ahb_tx_export",this);
		uvip_int_export = new("uvip_int_export", this);
		uvip_parity_bit_time_export = new("uvip_parity_bit_time_export", this);
		
		//Receive config to perform coverage
	if(!uvm_config_db#(uart_configuration)::get(this,"","cfg",cfg))
		`uvm_fatal(get_type_name(),$sformatf("Failed to get cfg from config db"))
	endfunction

	virtual task run_phase(uvm_phase phase);

	endtask: run_phase

	//Receive uart_transaction tx,rx from uart monitor
	virtual function void write_uvip_tx(uart_transaction trans);	
		uvip_tx_queue.push_back(trans);
		parity_vip = trans.parity;
		flag_uvip_tx = 1;
		compare_vip_to_ip();		
		rx_fifo_count++;
		`uvm_info(get_type_name(), $sformatf("#%0d UART IP received in uart_rxd",++count_rx), UVM_LOW)
		if(rx_fifo_count == 16) begin sample_interrupt(4); pending(); end
	endfunction: write_uvip_tx

	virtual function void write_uvip_rx(uart_transaction trans);
		`uvm_info(get_type_name(), $sformatf("#%0d UART IP transmited data in uart_txd",++count_tx), UVM_LOW)
		uvip_rx_queue.push_back(trans);		
		compare_ip_to_vip();	
		tx_fifo_count--;
		if(tx_fifo_count == 1) begin sample_interrupt(1); if(access_ier)  pending(); end
		if(write_tx_fifo_full) begin
			if(trans.data == 8'h64) `uvm_error("get_type_name()", $sformatf("!SOS! 17th byte data found"))
		end
	endfunction: write_uvip_rx

	virtual function void write_ahb(ahb_transaction trans);
			if(trans.xact_type == ahb_transaction::WRITE) begin
				case(trans.addr)
					10'h0C: begin
										lcr = trans.data;
										sample_mismatch(cfg, div, lcr);//sample mismatch data frame
										cur[0] = div; cur[1] = lcr[1:0]; cur[2] = lcr[4:3]; cur[3] = lcr[2];//sample reconfig
										sample_reconfig(cur);
									end
					10'h10: begin
										access_ier = 1;
										ier = trans.data;
									end
					10'h04: begin
										dll = trans.data;
									end
					10'h08: begin
										dlh = trans.data;
										div = {dlh,dll}; 
									end
					10'h18: begin 	
										sample_uart_fc(cfg);
										tbr = trans.data;
										//Goi ham de dung frame va ham so sanh
										build_frame(lcr, tbr, 1);
										tx_fifo_count++;
										if(tx_fifo_count == 17) begin 
											sample_interrupt(2); 
											pending(); 
											write_tx_fifo_full = 1; 
											data_17th = trans.data;
											sample_error_handling(access_rsvd, data_17th);
										end
									end
					10'h14: begin
										write_fsr = trans.data[4];
										`uvm_info(get_type_name(), $sformatf("Bit %0b is written in to FSR[4]",write_fsr), UVM_LOW)
										sample_parity_w1c(write_fsr);
									end

				endcase
				//Access RESERVERD region
				if(trans.addr inside {[10'h020:10'h3FF]}) begin
					write_rsvd = trans.data;
					access_rsvd = trans.addr;
					sample_error_handling(access_rsvd, data_17th);
				end
	
			end

			if(trans.xact_type == ahb_transaction::READ) begin
				case(trans.addr)
				10'h1C: begin 
					//coverage
					sample_uart_fc(cfg);
					rbr = trans.data;
					//Goi ham de dung frame va ham so sanh
					build_frame(lcr, rbr, 0);
					rx_fifo_count--;
					if(rx_fifo_count == 0) begin sample_interrupt(3);  if(ier != 32'h10) pending(); end
				end
				10'h14: begin
					fsr = trans.data;
					if(first_fsr||write_fsr == 0) begin
						exp_fsr = expected_fsr();
						compare_fsr(exp_fsr, fsr);
						first_fsr = 0;
					end
					if(write_fsr) begin
						exp_fsr = expected_fsr();
						exp_fsr = exp_fsr & {~write_fsr,4'hF};
						`uvm_info(get_type_name(), $sformatf("Bit 1 is written in to FSR[4]"), UVM_LOW)
						compare_fsr(exp_fsr, fsr);
					end

				end
				endcase
				//Access RESERVED region
				if(trans.addr inside {[10'h020:10'h3FF]}) begin 	
					read_rsvd = trans.data;
					access_rsvd = trans.addr;
					sample_error_handling(access_rsvd, data_17th);
					compare_rsvd(write_rsvd, read_rsvd);
				end

			end
	endfunction: write_ahb
/*--------------------------------BUILD FRAME FROM CONFIGURATION REGISTER---------------------------*/

	function void build_frame(bit[31:0] lcr, bit[31:0] data, bit is_tx);	
		bit esp = lcr[4];
		bit pen = lcr[3];
		bit stb = lcr[2];
		bit [1:0] wls = lcr[1:0];
	
		int databits;
		
		uart_transaction frame;
		frame = uart_transaction::type_id::create("frame",this);
		flag_build_frame = 1;
		case(wls)
			2'b00:begin frame.data = data[4:0]; databits = 5; end
			2'b01:begin frame.data = data[5:0]; databits = 6; end
			2'b10:begin frame.data = data[6:0]; databits = 7; end
			2'b11:begin frame.data = data[7:0]; databits = 8; end
		endcase

		if(pen) begin
			bit parity = 0;
			for(int i = 0; i < databits; i++)
				parity ^= data[i];
			if(!esp)
				parity = ~parity;
				
			frame.parity = parity;
			parity_ip = parity;
		end


		frame.stopbit = (stb == 1'b0) ? 2'b01 : 2'b11;
		if(is_tx) begin
			ahb_tx_queue.push_back(frame);
			compare_ip_to_vip();
		//	`uvm_info(get_type_name(),$sformatf("UART IP sent frame: %s\n",frame.sprint()),UVM_LOW) 
		end
		else begin	
			ahb_rx_queue.push_back(frame);
			compare_vip_to_ip();
		//	`uvm_info(get_type_name(),$sformatf("UART IP receive frame: %s\n",frame.sprint()),UVM_LOW) 
		end
	endfunction:build_frame
/*---------------------------------------------------------------------------------------------------------*/



/*----------------------------------------------COMPARE DATA FRAME-----------------------------------------------*/
	function void compare_ip_to_vip();
		while(ahb_tx_queue.size() > 0 && uvip_rx_queue.size() > 0) begin
			uart_transaction tx_trans = ahb_tx_queue.pop_front();
			uart_transaction rx_trans = uvip_rx_queue.pop_front();
		if(tx_trans.data != rx_trans.data || tx_trans.parity != rx_trans.parity || tx_trans.stopbit != rx_trans.stopbit) begin
				`uvm_error(get_type_name(),$sformatf("Mismatch UART IP ==> VIP"))
				`uvm_info(get_type_name(), $sformatf("\nAHB_TX_trans: %s\nUART_RX_trans: %s",tx_trans.sprint(),rx_trans.sprint()),UVM_LOW)
		end
		else 	
			`uvm_info(get_type_name(),$sformatf("MATCH UART IP ==> VIP\nAHB_TX_trans: %s\nUART_RX_trans: %s",tx_trans.sprint(),rx_trans.sprint()),UVM_LOW)
		end
	endfunction

	function void compare_vip_to_ip();
		while(ahb_rx_queue.size() > 0 && uvip_tx_queue.size() > 0) begin
			uart_transaction tx_trans = uvip_tx_queue.pop_front();
			uart_transaction rx_trans = ahb_rx_queue.pop_front();
		if(tx_trans.data != rx_trans.data || tx_trans.parity != rx_trans.parity || tx_trans.stopbit != rx_trans.stopbit) begin
				`uvm_error(get_type_name(),$sformatf("Mismatch VIP ==> UART IP"))
				`uvm_info(get_type_name(), $sformatf("\nUART_TX_trans: %s\nAHB_RX_trans: %s",tx_trans.sprint(),rx_trans.sprint()),UVM_LOW)
				if(tx_trans.parity != rx_trans.parity) begin
					sample_interrupt(0);			
					if(event_parity!=0)
					begin
					 `uvm_info(get_type_name(), $sformatf("Parity error trigger at %0t", event_parity),UVM_LOW)
					 `uvm_info(get_type_name(), $sformatf("Interrupt valid at %0t", interrupt_scb),UVM_LOW)
					end
				end
		end
		else 	
			`uvm_info(get_type_name(),$sformatf("MATCH VIP ==> UART VIP\nUART_TX_trans: %s\nAHB_RX_trans: %s",tx_trans.sprint(),rx_trans.sprint()),UVM_LOW)
		end
	endfunction
/*---------------------------------------------------------------------------------------------------------------------------*/

/*----------------------------------------------EXPECTED VALUE OF FSR REGISTER-----------------------------------------------*/
	function bit[4:0] expected_fsr();
		bit[4:0] exp;
		exp[0] = (tx_fifo_count >= fifo_size) ? 1 : 0;
		exp[1] = (tx_fifo_count == 0);
		exp[2] = (rx_fifo_count	>= fifo_size-1);
		exp[3] = (rx_fifo_count == 0);
		exp[4] = (parity_ip != parity_vip && flag_uvip_tx == 1 && flag_build_frame == 1) ? 1 : 0;
		return exp;
	endfunction	

	function void compare_fsr(bit[4:0] exp_fsr, bit[4:0] fsr);
		if(exp_fsr != fsr)
			`uvm_error(get_type_name(),$sformatf("FSR mismatch! Expected: %b Actual: %b", exp_fsr, fsr))
		else
			`uvm_info(get_type_name(),$sformatf("FSR match! %b and Interrupt signal line is deasserted",fsr), UVM_LOW)
		if(flag) `uvm_error(get_type_name(),$sformatf("Interrupt invalid because IER disable"))
	endfunction

/*---------------------------------------------------------------------------------------------------------------------------*/

	virtual function void write_uvip_int(time interrupt);
	//	`uvm_info(get_type_name(),$sformatf("Da xay ra interrupt"), UVM_LOW);
		flag = 1;
		if(event_pending) begin
			interrupt_scb = interrupt;
			if(interrupt < event_int) `uvm_error(get_type_name(),$sformatf("Invalid interrupt"))
			else `uvm_info(get_type_name(),$sformatf("Interrupt valid at %0t", interrupt), UVM_LOW)
		event_pending = 0;
		end
	endfunction

	function void pending();
		if(access_ier) begin
			event_int = $time;
			event_pending = 1;
			`uvm_info(get_type_name(),$sformatf("Event trigger at %0t", event_int), UVM_LOW)
			fork 
				begin
					#1000us;
					if(event_pending) begin 
						`uvm_error(get_type_name(),$sformatf("Interrupt not onccured"))
						event_pending = 0;
					end
				end
			join_none
		end
	endfunction

	//Reserved region: compare data in, data out at RESERVED REGION
	function void compare_rsvd(bit[31:0] write_rsvd, bit[31:0] read_rsvd);
	//	if(read_rsvd != 32'hFFFF_FFFF) `uvm_error(get_type_name(),$sformatf("The value read from RESERVE region is 32'h%0h", read_rsvd))
		if(write_rsvd == read_rsvd) `uvm_error(get_type_name(),$sformatf("Writing to the RESERVED region take effects\nThe value read from RESERVED region is 32'h%0h", read_rsvd))
		else `uvm_info(get_type_name(), $sformatf("RESERVED DONE"), UVM_LOW)
	endfunction


	//Time that captured parity bit on uart_rxd
//////////////////////////////////////////////////////////////////////////////////////////////////////////
	virtual function void write_uvip_parity_bit_time(time parity_bit_time);																//
		sample_interrupt(0);																																								//	
		if(access_ier) begin																																								//
			event_parity = parity_bit_time;																																		//
			event_pending = 1;																																								//
			`uvm_info(get_type_name(),$sformatf("Parity error event trigger at %0t", event_parity), UVM_LOW)	//
			fork 																																															//
				begin																																														//	
					#1000us;																																											//		
					if(event_pending) begin																																				// 
						`uvm_error(get_type_name(),$sformatf("Interrupt not onccured"))															//		
						event_pending = 0;																																					//
					end																																														//	
				end																																															//
			join_none																																													//
		end																																																	//
	endfunction																																														//
//////////////////////////////////////////////////////////////////////////////////////////////////////////


/*---------------------------------SAMPLE COMBINATION TEST----------------------------------*/
	function void sample_uart_fc(uart_configuration cfg);																			//
		$cast(cfg_fc, cfg);																																			//
		UART_GROUP.sample();																																		//
	endfunction																																								//	
																																														//	
/*------------------------------------------------------------------------------------------*/


/*---------------------------------SAMPLE ERRO INJECTION------------------------------------*/
	function void sample_mismatch(uart_configuration cfg, bit[15:0] div, bit[31:0] lcr);			//
		mis[0] = (cfg.div != div);																															//
		mis[1] = ((cfg.data_bits -5) != lcr[1:0]);																							//
		mis[2] = (cfg.use_parity != lcr[3] || cfg.parity_even != lcr[4]) ? 1 : 0;								//
		mis[3] = ((cfg.stop_bits-1) != lcr[2]);																									//
		$cast(mis_fc,mis);																																			//
		UART_GROUP.sample();																																		//
		mis = 0; $cast(mis_fc,mis);																															//
	endfunction																																								//
/*------------------------------------------------------------------------------------------*/



/*------------------------------------SAMPLE RECONFIG---------------------------------------*/
																																														//
	function void sample_reconfig (int cur[]);																								//
		for(int i = 0; i < cur.size(); i++) begin																								//
			if(is_first[i]) begin 																																//
				pre[i] = cur[i];																																		//
				is_first[i] = 0;																																		//
			end																																										//
			else if(cur[i] != pre[i]) begin																												//
				pre[i] = cur[i];																																		//
				reconfig[i] = 1;																																		//
				$cast(reconfig_fc, reconfig);																												//
				UART_GROUP.sample();																																//
				reconfig = 0;																																				//
				$cast(reconfig_fc, reconfig);																												//
			end																																										//
		end																																											//
	endfunction																																								//
/*------------------------------------------------------------------------------------------*/


/*------------------------------------SAMPLE INTERRUPT--------------------------------------*/
	function void sample_interrupt(int index);																								//
		int_test[index] = 1;																																		//
		$cast(int_test_fc, int_test);																														//
		UART_GROUP.sample();																																		//
		int_test = 0;																																						//
		$cast(int_test_fc, int_test);																														//
	endfunction																																								//
																																														//


/*---------------------------------SAMPLE ERROR HANDLING------------------------------------*/
	function void sample_error_handling(bit[9:0] access_rsvd, bit[7:0] data_17th);						//
		$cast(access_rsvd_fc, access_rsvd);																											//
		$cast(data_17th_fc, data_17th);																													//
		UART_GROUP.sample();																																		//
		access_rsvd = 0;																																				//
		data_17th = 0;																																					//
		$cast(access_rsvd_fc, access_rsvd);																											//
		$cast(data_17th_fc, data_17th);																													//
	endfunction																																								//
/*------------------------------------------------------------------------------------------*/


/*---------------------------------SAMPLE ERROR HANDLING------------------------------------*/
	function void sample_parity_w1c(bit write_fsr);
		$cast(write_fsr_fc, write_fsr);
		UART_GROUP.sample();
		write_fsr = 0;
		$cast(write_fsr_fc, write_fsr);
	endfunction
/*------------------------------------------------------------------------------------------*/
endclass
