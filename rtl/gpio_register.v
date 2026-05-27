module gpio_register (	input sys_clk,
			input sys_rst,
			input gpio_we,
			input [31:0] gpio_addr,
			input [31:0] gpio_dat_i,
			output reg [31:0] gpio_dat_o,
			output gpio_inta_o,
			input [31:0] aux_i,
			input [31:0] in_pad_i,
			input gpio_eclk,
			output [31:0] out_pad_o,
			output [31:0] oen_padoe_o
			);

	
	parameter addr_rgpio_in = 32'h00;
	parameter addr_rgpio_out = 32'h04;
	parameter addr_rgpio_oe = 32'h08;
	parameter addr_rgpio_inte = 32'h0c;
	parameter addr_rgpio_ptrig = 32'h10;
	parameter addr_rgpio_aux = 32'h14;
	parameter addr_rgpio_ctrl = 32'h18;
	parameter addr_rgpio_ints = 32'h1c;
	parameter addr_rgpio_eclk = 32'h20;
	parameter addr_rgpio_nec = 32'h24;
	
	parameter addr_rgpio_ctrl_inte = 0;
	parameter addr_rgpio_ctrl_ints = 1;
	
	reg [31:0] rgpio_in, rgpio_out, rgpio_oe, rgpio_inte, rgpio_ptrig, rgpio_aux, rgpio_ints, rgpio_eclk, rgpio_nec;
	reg [1:0]  rgpio_ctrl;
	
	reg [31:0] dat_reg;				//used to hold output, we use this to send to gpio_dat_o reg on posedge of sys clk
	
	wire [31:0] extclk_in;				//multiplexed inputs by ext clk
	reg [31:0] pextc_sampled, nextc_sampled;	//posedge and negedge ext clk sampled inputs
	
	//--------------------------------------
	
	//gpio ctrl logic block
	
	always @ (posedge sys_clk or posedge sys_rst)
		if(sys_rst == 1'b1)
			rgpio_ctrl <= 2'd0;
		else if( (gpio_addr == addr_rgpio_ctrl) && gpio_we == 1'b1 )					//if addr is of gpio ctrl reg and wr en is high
			rgpio_ctrl <= gpio_dat_i[1:0];								//assign lsb 2 bits of input stream to ctrl reg
		else if(rgpio_ctrl[addr_rgpio_ctrl_inte] == 1'b1)						//if interrupts enabled
			rgpio_ctrl[addr_rgpio_ctrl_ints] <= rgpio_ctrl[addr_rgpio_ctrl_ints] | gpio_inta_o;	//update status reg and keep it high until serviced
	
	//--------------------------------------
	
	//gpio out logic block
	
	always @ (posedge sys_clk or posedge sys_rst)
		if(sys_rst == 1'b1)
			rgpio_out <= 32'd0;
		else if( (gpio_addr == addr_rgpio_out) && gpio_we == 1'b1 )
			rgpio_out <= gpio_dat_i[31:0];
		else
			rgpio_out <= rgpio_out;
			
	//--------------------------------------
	
	//gpio output enable logic block
	
	always @ (posedge sys_clk or posedge sys_rst)
		if(sys_rst == 1'b1)
			rgpio_oe <= 32'd0;
		else if( (gpio_addr == addr_rgpio_oe) && gpio_we == 1'b1 )
			rgpio_oe <= gpio_dat_i[31:0];
		else
			rgpio_oe <= rgpio_oe;		//extra line added, if bug remove
			
	//--------------------------------------
	
	//gpio interrupt enable
	
	always @ (posedge sys_clk or posedge sys_rst)
		if(sys_rst == 1'b1)
			rgpio_inte <= 32'd0;
		else if( (gpio_addr == addr_rgpio_inte) && gpio_we == 1'b1 )
			rgpio_inte <= gpio_dat_i[31:0];
		else
			rgpio_inte <= rgpio_inte;
	
	//--------------------------------------
	
	//gpio posedge trigger register
	
	always @ (posedge sys_clk or posedge sys_rst)
		if(sys_rst == 1'b1)
			rgpio_ptrig <= 32'd0;
		else if( (gpio_addr == addr_rgpio_ptrig) && gpio_we == 1'b1 )
			rgpio_ptrig <= gpio_dat_i[31:0];
		else
			rgpio_ptrig <= rgpio_ptrig;
		
	//--------------------------------------
	
	//gpio aux register
	
	always @ (posedge sys_clk or posedge sys_rst)
		if(sys_rst == 1'b1)
			rgpio_aux <= 32'd0;
		else if( (gpio_addr == addr_rgpio_aux) && gpio_we == 1'b1 )
			rgpio_aux <= gpio_dat_i[31:0];
		else
			rgpio_aux <= rgpio_aux;
			
	//--------------------------------------
	
	//gpio ext clk register
	
	always @ (posedge sys_clk or posedge sys_rst)
		if(sys_rst == 1'b1)
			rgpio_eclk <= 32'd0;
		else if( (gpio_addr == addr_rgpio_eclk) && gpio_we == 1'b1 )
			rgpio_eclk <= gpio_dat_i[31:0];
		else
			rgpio_eclk <= rgpio_eclk;
		
	//--------------------------------------
	
	//neg edge ext clk register
	
	always @ (posedge sys_clk or posedge sys_rst)
		if(sys_rst == 1'b1)
			rgpio_nec <= 32'd0;
		else if( (gpio_addr == addr_rgpio_nec) && gpio_we == 1'b1)
			rgpio_nec <= gpio_dat_i[31:0];
		else
			rgpio_nec <= rgpio_nec;
			
	//--------------------------------------
	
	//sending input to gpio in reg
	
	wire [31:0] muxed_in;
	
	always @ (posedge sys_clk or posedge sys_rst)
		if(sys_rst == 1'b1)
			rgpio_in <= 32'd0;
		else
			rgpio_in <= muxed_in;
	
	assign muxed_in = (rgpio_eclk & extclk_in) | (~rgpio_eclk & in_pad_i);		//if ext clk reg high, then pass ext clk, if not, pass input from input pad
	
	assign extclk_in = (~rgpio_nec & pextc_sampled) | (rgpio_nec & nextc_sampled);	//if neg edge reg low, then pass posedge sampled input, if high, then pass negedge sampled input
	
	//--------------------------------------
	
	//posedge sampled input, note the use of ext clk here
	
	always @ (posedge gpio_eclk or posedge sys_rst)
		if(sys_rst == 1'b1)
			pextc_sampled <= 32'd0;
		else
			pextc_sampled <= in_pad_i;
	
	//negedge sampled input, note ext clk
	
	always @ (negedge gpio_eclk or posedge sys_rst)
		if(sys_rst == 1'b1)
			nextc_sampled <= 32'd0;
		else
			nextc_sampled <= in_pad_i;
	
	//--------------------------------------
	
	//passing register contents to intermediate signal
	
	always @ (*)
		case(gpio_addr)
			addr_rgpio_out: dat_reg = rgpio_out;
			addr_rgpio_oe: dat_reg = rgpio_oe;
			addr_rgpio_inte: dat_reg = rgpio_inte;
			addr_rgpio_ptrig: dat_reg = rgpio_ptrig;
			addr_rgpio_nec: dat_reg = rgpio_nec;
			addr_rgpio_eclk: dat_reg = rgpio_eclk;
			addr_rgpio_aux: dat_reg = rgpio_aux;
			addr_rgpio_ctrl:	begin
							dat_reg[1:0] = rgpio_ctrl;
							dat_reg[31:2] = 30'd0;
						end
			addr_rgpio_ints: dat_reg = rgpio_ints;
			default: dat_reg = rgpio_in;
		endcase
		
	//--------------------------------------
	
	//passing intermediate signal value to gpio output reg
	
	always @ (posedge sys_clk or posedge sys_rst)
		if(sys_rst == 1'b1)
			gpio_dat_o <= 32'd0;
		else
			gpio_dat_o <= dat_reg;

	//--------------------------------------
	
	//gpio interrupt status reg, wr and rd 
	
	always @ (posedge sys_clk or posedge sys_rst)
		if(sys_rst == 1'b1)
			rgpio_ints <= 32'd0;
		else if( (gpio_addr == addr_rgpio_ints) && gpio_we == 1'b1 )
			rgpio_ints <= gpio_dat_i;
		else if(rgpio_ctrl[addr_rgpio_ctrl_inte] == 1'b1)
			rgpio_ints <= (rgpio_ints | ((muxed_in ^ rgpio_in) & ~(muxed_in ^ rgpio_ptrig)) & rgpio_inte);
	
	//--------------------------------------
	
	assign gpio_inta_o = |rgpio_ints ? rgpio_ctrl[addr_rgpio_ctrl_inte] : 1'b0;		//gen interrupt req, note the use of the 'reduction or'	operator
	assign oen_padoe_o = rgpio_oe;								//output enables are the same as gpio output enable register bits
	assign out_pad_o = (rgpio_out & ~rgpio_aux) | (aux_i & rgpio_aux);			//generate gpio output as register output if no aux input, if aux input present, pass that as output
	
endmodule
