module aux_interface	(
			input clk,
			input rst,
			input [31:0] aux_in,
			output reg [31:0] aux_i
			);
						
	always @ (posedge clk or posedge rst)
	begin
		if(rst == 1'b1)
			aux_i <= 32'd0;
		else
			aux_i <= aux_in;
	end
	
endmodule
