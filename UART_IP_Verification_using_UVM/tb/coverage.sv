uart_configuration cfg_fc;
bit[15:0] div_fc;
//cover error_injection test
bit[3:0] mis_fc = 0;
//cover reconfig test
bit[3:0] reconfig_fc = 0;
//cover interrupt test
bit[4:0] int_test_fc;
//cover access reserved region
bit[9:0] access_rsvd_fc;
//cover 17th_data: write_tx_fifo_full
bit[7:0] data_17th_fc;
//cover w1c FSR
bit write_fsr_fc;
covergroup UART_GROUP;
	mode: coverpoint cfg_fc.mode {
		bins TX = {uart_configuration::TX};
		bins RX = {uart_configuration::RX};
		bins TX_RX = {uart_configuration::TX_RX};
	}

	smp: coverpoint cfg_fc.smp{
		bins smp[] = {13,16};	
	}


	baudrate: coverpoint cfg_fc.baudrate{
		bins baud[] = {2400, 4800, 9600, 19200, 38400, 76800, 115200, 230400};
	}

	data_bits: coverpoint cfg_fc.data_bits{
		bins data_bits[] = {[5:8]};
	}

	stop_bits: coverpoint cfg_fc.stop_bits{
		bins stop_bits[] = {[1:2]};
	}

	use_parity: coverpoint cfg_fc.use_parity{
		bins use_parity[] = {[0:1]};
	} 
	
	parity_even: coverpoint cfg_fc.parity_even{
		bins parity_even[] = {[0:1]};

	}

	cs_oversampling: cross smp, baudrate;

	cs_combine_parity: cross mode, baudrate, data_bits, stop_bits, use_parity, parity_even{
		ignore_bins no_parity = binsof(use_parity) intersect {0};
	} 

	cs_combine_no_parity: cross mode, baudrate, data_bits, stop_bits, use_parity{
		ignore_bins use_parity = binsof(use_parity) intersect {1};
	}


	//Coverage baudrate mismatch	

	error_injection: coverpoint mis_fc{
		bins error_injection[] = {1,2,4,8};
	}
	
	reconfig: coverpoint reconfig_fc{
		bins reconfig[] = {1,2,4,8};
	}

	cs_reconfig_mode: cross mode, reconfig;

	interrupt: coverpoint int_test_fc{
		bins interrupt[] = {1,2,4,8,16};
	}

	access_rsvd: coverpoint access_rsvd_fc{
		bins access_rsvd = {[10'h020:10'h3FF]};
	}

	write_tx_fifo_full: coverpoint data_17th_fc{
		bins data_17th = {8'h64};
	}
	w1c_FSR_parity_error: coverpoint write_fsr_fc{
		bins write_fsr[] = {0,1};
	}

endgroup
