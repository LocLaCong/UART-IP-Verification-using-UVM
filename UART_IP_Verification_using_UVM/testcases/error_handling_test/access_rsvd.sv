class access_rsvd extends uart_base_test;
	`uvm_component_utils(access_rsvd)

	function new(string name = "access_rsvd", uvm_component parent);
		super.new(name, parent);
	endfunction	

	access_rsvd_sequence access_rsvd_seq;

	virtual task run_phase(uvm_phase phase);
		phase.raise_objection(this);

		access_rsvd_seq = access_rsvd_sequence::type_id::create("access_rsvd_seq");
		access_rsvd_seq.start(env.ahb_agt.sequencer);
	
		phase.drop_objection(this);
	endtask




endclass
