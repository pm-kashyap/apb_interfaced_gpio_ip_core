`timescale 1ns/1ps

module io_interface_tb;

	reg  ext_clk_pad_i;
	reg  [31:0] out_pad_o;
	reg  [31:0] oen_padoe_o;
	
	wire [31:0] in_pad_i;
	wire gpio_eclk;

	wire [31:0] io_pad;

    	// Testbench control signals to simulate an external device driving the chip pins
	reg  [31:0] io_pad_driver;	//simulation signals
	reg  [31:0] io_pad_enable;
	
	genvar i;
	
	generate
		for(i=0; i<32; i=i+1)
		begin: external_block_simulator
			assign io_pad[i] = io_pad_enable[i] ? io_pad_driver[i] : 1'bz;
		end
	endgenerate

    
	io_interface DUT	(
				.ext_clk_pad_i(ext_clk_pad_i),
				.out_pad_o(out_pad_o),
				.oen_padoe_o(oen_padoe_o),
				.in_pad_i(in_pad_i),
				.io_pad(io_pad),
				.gpio_eclk(gpio_eclk)
				);
							
	initial ext_clk_pad_i = 1'b0;
	always #20 ext_clk_pad_i = ~ext_clk_pad_i;

	initial
	begin
		//reset state
		out_pad_o	= 32'h0;
		oen_padoe_o	= 32'h0;
		io_pad_driver	= 32'h0;
		io_pad_enable	= 32'h0;
		
		repeat(2)
			@(negedge ext_clk_pad_i);
			

		//data is being sent from gpio register via out_pad_o
		out_pad_o     = 32'h5555_AAAA;
		oen_padoe_o   = 32'hFFFF_FFFF;
		
		repeat(2)
			@(negedge ext_clk_pad_i);
			
		oen_padoe_o   = 32'h0000_0000;
		
			
		@(negedge ext_clk_pad_i);

		//send data via external io_pad 
		io_pad_driver   = 32'hA5A5_9999;
		io_pad_enable   = 32'hFFFF_FFFF;          
		
		repeat(2)
			@(negedge ext_clk_pad_i);
		
		//upper half input, lower half output
		io_pad_enable	= 32'd0;
		oen_padoe_o	= 32'h0000_FFFF; 
		out_pad_o	= 32'h0000_1234;
		
		io_pad_driver   = 32'hABCD_0000;
		io_pad_enable	= 32'hFFFF_0000;
	       
		repeat(2)
			@(negedge ext_clk_pad_i);

		#20 $finish;
		
	end

	initial
	begin
	        $dumpfile("io_interface_sim.vcd");
	        $dumpvars(0, io_interface_tb);
	end

endmodule
