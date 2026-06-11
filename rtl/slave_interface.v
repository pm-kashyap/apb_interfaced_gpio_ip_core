module slave_interface	(	input pclk,
				input preset,
				input psel,
				input penable,
				input pwrite,
				output pready,
				input [31:0] pwdata,
				input [31:0] paddr,
				output reg [31:0] prdata,
				output irq,
				output sys_clk,
				output sys_rst,
				output reg gpio_we,
				output [31:0] gpio_addr,
				output reg [31:0] gpio_dat_i,
				input [31:0] gpio_dat_o,
				input gpio_inta_o
			);

	
	parameter idle = 2'd0;
	parameter setup = 2'd1;
	parameter enable = 2'd2;
	
	reg [1:0] pres, next;
	
	assign irq = gpio_inta_o;
	assign gpio_addr = paddr;
	assign sys_rst = preset;
	assign sys_clk = pclk;
	
	assign pready = ( (pres == enable) || (pres == idle && preset == 1'b1) ) ? 1'b1: 1'b0;
	
	always @ (posedge pclk or posedge preset)
	begin
		if (preset == 1'b1)
			pres <= idle;
		else
			pres <= next;
	end
	
	always @ (*)
	begin
		case(pres)
			idle:	begin
					if(psel == 1'b1 && penable == 1'b0)
						next = setup;
					else
						next = idle;
				end
			
			setup:	begin
					if(psel == 1'b1 && penable == 1'b1)
						next = enable;
					else if(psel == 1'b1 && penable == 1'b0)
						next = setup;
					else
						next = idle;
				end
				
			enable:	begin
					if(psel == 1'b1)
						next = setup;
					else
						next = idle;
				end
			
			default: next = idle;	
		endcase
	end
	
	
	always @ (*)
	begin
		if(pres == enable && pwrite == 1'b1)
		begin
			gpio_dat_i = pwdata;
			gpio_we = 1'b1;
			prdata = 32'd0;
		end
		
		else if(pres == enable && pwrite == 1'b0)
		begin
			gpio_dat_i = 32'd0;
			gpio_we = 1'b0;
			prdata = gpio_dat_o;
		end
		
		else
		begin
			gpio_dat_i = 32'd0;
			gpio_we = 1'b0;
			prdata = 32'd0;
		end
	end
	
endmodule
	
