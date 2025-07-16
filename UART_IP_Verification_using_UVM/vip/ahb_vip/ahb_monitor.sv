class ahb_monitor extends uvm_monitor;
	`uvm_component_utils(ahb_monitor)
	//interface
	virtual ahb_if ahb_vif;
	ahb_transaction trans;
	uvm_analysis_port #(ahb_transaction) ahb_observe_port;
	bit event_pending = 0;

  function new(string name="ahb_monitor", uvm_component parent);
    super.new(name,parent);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
//		trans = ahb_transaction::type_id::create("trans",this);
		ahb_observe_port = new("ahb_observe_port",this);
		if(!uvm_config_db#(virtual ahb_if)::get(this,"","ahb_vif",ahb_vif))
		`uvm_fatal(get_type_name(),$sformatf("Failed to get ahb_vif from uvm_config_db"))
		
  endfunction: build_phase

  virtual task run_phase(uvm_phase phase);
		ahb_transaction ahb_trans;
		wait(ahb_vif.HRESETn ===1'b1);
	fork
		forever begin
			do
				@(posedge ahb_vif.HCLK);
			while(!(ahb_vif.HTRANS ==2'b10));
				`uvm_info(get_type_name(),"Start capture AHB transaction",UVM_LOW)
				ahb_trans = ahb_transaction::type_id::create("ahb_trans",this);
				ahb_trans.addr = ahb_vif.HADDR;
				$cast(ahb_trans.xact_type, ahb_vif.HWRITE);
				$cast(ahb_trans.xfer_size, ahb_vif.HSIZE);
				$cast(ahb_trans.burst_type, ahb_vif.HBURST);
				ahb_trans.prot = ahb_vif.HPROT;
				ahb_trans.lock = ahb_vif.HMASTLOCK;
				do 
					@(posedge ahb_vif.HCLK);
				while(!(ahb_vif.HREADYOUT == 1'b1));
				ahb_trans.data = (ahb_trans.xact_type == ahb_transaction::WRITE) ? ahb_vif.HWDATA : ahb_vif.HRDATA;
				`uvm_info(get_type_name(),$sformatf("Observed transaction:\n%s",ahb_trans.sprint()),UVM_LOW)
				ahb_observe_port.write(ahb_trans);
		
		end
/////////////////////////////////////////////////////////////////////////////////////////////////////////		
		forever begin
			@(posedge ahb_vif.HCLK);

			if(ahb_vif.HADDR inside {[10'h020:10'h3FF]})begin
				event_pending = 1;
				`uvm_info(get_type_name(), $sformatf("Access RESERVED region at %0t", $time), UVM_LOW)
 			@(posedge ahb_vif.HRESP);	
				event_pending = 0;
				`uvm_info(get_type_name(), $sformatf("HRESP trigger at %0t", $time), UVM_LOW)

				fork 
					begin
						repeat (10) @(posedge ahb_vif.HCLK);			
						if(event_pending) begin
							`uvm_error(get_type_name(), $sformatf("!SOS HRESP does not trigger"))
							event_pending = 0;
						end
					end
				join_none
			end		
		end
///////////////////////////////////////////////////////////////////////////////////////////////////////
	join	

	
  endtask: run_phase

endclass: ahb_monitor

