module testbench;
  import uvm_pkg::*;
  import test_pkg::*;
	import uart_pkg::*;
	import ahb_pkg::*;


  ahb_if ahb_vif();
	uart_if uart_if();

  uart_top u_dut(
                 .HCLK(ahb_vif.HCLK), 
                 .HRESETN(ahb_vif.HRESETn),
                 .HADDR(ahb_vif.HADDR), 
                 .HBURST(ahb_vif.HBURST), 
                 .HTRANS(ahb_vif.HTRANS), 
                 .HSIZE(ahb_vif.HSIZE), 
                 .HPROT(ahb_vif.HPROT), 
                 .HWRITE(ahb_vif.HWRITE), 
                 .HWDATA(ahb_vif.HWDATA),
                 .HSEL(ahb_vif.HSEL),
                 .HREADYOUT(ahb_vif.HREADYOUT), 
                 .HRDATA(ahb_vif.HRDATA), 
                 .HRESP(ahb_vif.HRESP),
								 .uart_rxd(uart_if.tx),
								 .uart_txd(uart_if.rx),
								 .interrupt(uart_if.interrupt)						
								
);

  assign ahb_vif.HSEL = 1'b1;

	

  initial begin
		uart_if.tx = 1;
    ahb_vif.HRESETn = 0;
    #100ns ahb_vif.HRESETn = 1;
		
  end

  // 50 MHz
  initial begin
    ahb_vif.HCLK = 0;
    forever begin 
      #5ns;
      ahb_vif.HCLK = ~ahb_vif.HCLK;
    end
  end

  initial begin
    /** Set virtual interface to driver for control, learn detail in next session */
    uvm_config_db#(virtual ahb_if)::set(null,"uvm_test_top","ahb_vif",ahb_vif);
		
		uvm_config_db#(virtual uart_if)::set(uvm_root::get(),"uvm_test_top","uart_vif",uart_if);

    /** Start the UVM test */
    run_test();
    

  end

endmodule


