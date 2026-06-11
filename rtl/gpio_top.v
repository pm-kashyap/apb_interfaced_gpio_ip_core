module gpio_top	(	
		input pclk,
		input preset,
		output [31:0] prdata,
		input [31:0] paddr,
		input [31:0] pwdata,
		input psel,
		input penable,
		input pwrite,
		input [31:0] aux_in,
		output irq,
		output pready,
		inout [31:0] io_pad,
		input ext_clk_pad_i
		);
					
	wire [31:0] in_pad_i;
	wire gpio_we;
	wire [31:0] gpio_addr;
	wire [31:0] gpio_dat_i;
	wire [31:0] gpio_dat_o;
	wire [31:0] out_pad_o;
	wire [31:0] oen_padoe_o;
	wire gpio_inta_o;
	wire sys_clk;
	wire sys_rst;
	wire [31:0] aux_i;
	wire ext_clk_to_gpio_eclk;
	
	slave_interface slv_intf	(	
					.pclk(pclk),
					.preset(preset),
					.psel(psel),
					.penable(penable),
					.pwrite(pwrite),
					.pready(pready),
					.pwdata(pwdata),
					.paddr(paddr),
					.prdata(prdata),
					.irq(irq),
					.sys_clk(sys_clk),
					.sys_rst(sys_rst),
					.gpio_we(gpio_we),
					.gpio_addr(gpio_addr),
					.gpio_dat_i(gpio_dat_i),
					.gpio_dat_o(gpio_dat_o),
					.gpio_inta_o(gpio_inta_o)
					);
	
	
	aux_interface	aux_intf	(	
					.clk(sys_clk),
					.rst(sys_rst),
					.aux_in(aux_in),
					.aux_i(aux_i)
					);
					
	
	gpio_register 	gpio_reg 	(	
					.sys_clk(sys_clk),
					.sys_rst(sys_rst),
					.gpio_we(gpio_we),
					.gpio_addr(gpio_addr),
					.gpio_dat_i(gpio_dat_i),
					.gpio_dat_o(gpio_dat_o),
					.gpio_inta_o(gpio_inta_o),
					.aux_i(aux_i),
					.in_pad_i(in_pad_i),
					.gpio_eclk(ext_clk_to_gpio_eclk),
					.out_pad_o(out_pad_o),
					.oen_padoe_o(oen_padoe_o)
					);
							
					
	io_interface	io_intf		(
					.ext_clk_pad_i(ext_clk_pad_i),
					.out_pad_o(out_pad_o), 
					.oen_padoe_o(oen_padoe_o),
					.in_pad_i(in_pad_i),
					.io_pad(io_pad),
					.gpio_eclk(ext_clk_to_gpio_eclk)
					);
	
endmodule
