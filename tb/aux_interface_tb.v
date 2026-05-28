`timescale 1ns/1ps

module aux_interface_tb;
	reg clk, rst;
	reg [31:0] aux_in;
	wire [31:0] aux_i;
	
	aux_interface DUT (	.clk(clk),
				.rst(rst),
				.aux_in(aux_in),
				.aux_i(aux_i)
			);
	
	initial clk = 1'b0;
	always #5 clk = ~clk;
	
	initial
	begin
		rst = 1'b0;
		aux_in = 32'd0;
		
		@(negedge clk);
			rst = 1'b1;
		@(negedge clk);
			rst = 1'b0;
		
		@(negedge clk);
		@(negedge clk);
			aux_in = 32'habab_abab;
			
		@(negedge clk);
		@(negedge clk);
			aux_in = 32'heffe_feef;
		
		#40 $finish;
	end
	
	initial 
	begin
		$dumpfile("aux_sim.vcd");
		$dumpvars(0, aux_interface_tb);
	end
	
endmodule
