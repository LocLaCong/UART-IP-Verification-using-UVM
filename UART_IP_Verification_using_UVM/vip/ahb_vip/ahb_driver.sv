class ahb_driver extends uvm_driver #(ahb_transaction);
  `uvm_component_utils(ahb_driver)

  virtual ahb_if ahb_vif;

  function new(string name="ahb_driver", uvm_component parent);
    super.new(name,parent);
  endfunction: new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    /** Applying the virtual interface received through the config db - learn detail in next session*/
    if(!uvm_config_db#(virtual ahb_if)::get(this,"","ahb_vif",ahb_vif))
      `uvm_fatal(get_type_name(),$sformatf("Failed to get from uvm_config_db. Please check!"))
  endfunction: build_phase

  /** User can use ahb_vif to control real interface like systemverilog part*/
  virtual task run_phase(uvm_phase phase);
		init_signal();
		wait(ahb_vif.HRESETn === 1'b1);
		forever begin 
			seq_item_port.get(req);
			drive(req);
			$cast(rsp, req.clone());
			rsp.set_id_info(req);
			seq_item_port.put(rsp);
		end
  endtask: run_phase

	virtual task drive(inout ahb_transaction req);
		@(posedge ahb_vif.HCLK); #1ps;
		ahb_vif.HADDR     = req.addr;
		ahb_vif.HBURST    = req.burst_type;
		ahb_vif.HMASTLOCK = req.lock;
		ahb_vif.HPROT     = req.prot;
		ahb_vif.HSIZE 		= req.xfer_size;
		ahb_vif.HTRANS 		= 2'h2;
		ahb_vif.HWRITE  	= req.xact_type;
		
		@(posedge ahb_vif.HCLK); #1ps;
		if(req.xact_type == ahb_transaction::WRITE) begin 
			ahb_vif.HWDATA  = req.data;
		end	
		ahb_vif.HADDR     = 'h0;
		ahb_vif.HBURST    = 'h0;
		ahb_vif.HMASTLOCK = 'h0;
		ahb_vif.HPROT     = 'h0;
		ahb_vif.HSIZE 		= 'h0;
		ahb_vif.HTRANS 		= 'h0;
		ahb_vif.HWRITE  	= 'h0;
		
		@(posedge ahb_vif.HREADYOUT);
		if(req.xact_type == ahb_transaction::READ) begin 
			@(posedge ahb_vif.HCLK);
			req.data = ahb_vif.HRDATA;
		end

	endtask 
		
	virtual function void init_signal();
		ahb_vif.HADDR     = 'h0;
		ahb_vif.HBURST    = 'h0;
		ahb_vif.HMASTLOCK = 'h0;
		ahb_vif.HPROT     = 'h0;
		ahb_vif.HSIZE 		= 'h0;
		ahb_vif.HTRANS 		= 'h0;
		ahb_vif.HWRITE  	= 'h0;
	
	endfunction

endclass: ahb_driver

