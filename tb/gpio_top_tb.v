module gpio_top_tb;
	
	reg pclk;
	reg preset;
	wire [31:0] prdata;
	reg [31:0] paddr;
	reg [31:0] pwdata;
	reg psel;
	reg penable;
	reg pwrite;
	reg [31:0] aux_in;
	wire irq;
	wire pready;
	wire [31:0] io_pad;
	reg ext_clk_pad_i;
	
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
	
	gpio_top	DUT	(	
				pclk,
				preset,
				prdata,
				paddr,
				pwdata,
				psel,
				penable,
				pwrite,
				aux_in,
				irq,
				pready,
				io_pad,
				ext_clk_pad_i
				);
					
	initial
		pclk = 1'b0;
		
	always #5 pclk = ~pclk;
	
	initial
		ext_clk_pad_i = 1'b0;
	
	always #20 ext_clk_pad_i = ~ext_clk_pad_i;
	
	task reset;
	begin
		@(negedge pclk);
		preset = 1'b1;
		#10 preset = 1'b0;
	end
	endtask
	
	task initialize;
	begin
		@(negedge pclk);
		psel = 1'b0;
		pwrite = 1'b0;
		penable = 1'b0;
		paddr = 32'h0;
		pwdata = 32'h0;
		aux_in = 32'h0;
	end
	endtask
	
	task aux_write(input [31:0]in);
	begin
		@(negedge pclk);
		aux_in = in;
	end
	endtask
	
	task apb_write(input [31:0]addr, input [31:0]in);
	begin
		@(negedge pclk);
		paddr = addr;		//select phase
		psel = 1'b1;
		pwrite = 1'b1;
		penable = 1'b0;
		pwdata = in;
		
		@(negedge pclk);
		penable = 1'b1;		//enable phase
		
		@(negedge pclk);	
		penable = 1'b0;		//toggle penable
		
		@(negedge pclk);
		psel = 1'b0;
		pwrite = 1'b0;
		penable = 1'b0;		//reset all signal states
		
	end
	endtask
	
	task apb_read(input [31:0]addr);
	begin
		@(negedge pclk);
		paddr = addr;
		psel = 1'b1;
		pwrite = 1'b0;
		penable = 1'b0;		//select phase
		
		@(negedge pclk);
		penable = 1'b1;		//enable phase
		
		@(negedge pclk);
		penable = 1'b0;		//toggle penable
		
		@(negedge pclk);
		psel = 1'b0;
		pwrite = 1'b0;
		penable = 1'b0;		//reset all signal states
	end
	endtask
	
	reg io_dir = 1'b1;
	reg [31:0]temp_reg = 32'dz;
	
	task send_to_io_pad(input [31:0]input_iopad);
	begin
		io_dir = 1'b0;
		temp_reg = input_iopad;
	end
	endtask
	
	task set_io_pad_output;
		io_dir = 1'b1;
	endtask	
	
	assign io_pad = ~io_dir?temp_reg:32'dz;
	
	initial
	begin
		initialize;
		reset;
		#10;
		
		//gpio as output
		apb_write(addr_rgpio_inte, 32'h0);
		apb_write(addr_rgpio_out, 32'h5a5a_5a5a);
		apb_write(addr_rgpio_oe, 32'hffff_ffff);
		set_io_pad_output;
		
		//gpio as input, sys clk
		apb_write(addr_rgpio_oe, 32'h0);
		apb_write(addr_rgpio_ctrl, 2'd0);
		apb_write(addr_rgpio_inte, 32'h0);
		apb_write(addr_rgpio_eclk, 32'h0);
		send_to_io_pad(32'h8b8b_b8b8);
		apb_read(addr_rgpio_in);
		
		//gpio as aux input
		aux_write(32'hbbbb_dddd);
		apb_write(addr_rgpio_aux, 32'hffff_ffff);
		apb_write(addr_rgpio_oe, 32'hffff_ffff);
		set_io_pad_output;
		apb_write(addr_rgpio_aux, 32'd0);		//reset aux so we can pass values in upcoming tasks
		
		//gpio as bi-directional io in sys clk
		apb_write(addr_rgpio_inte, 32'd0);
		apb_write(addr_rgpio_eclk, 32'd0);
		apb_write(addr_rgpio_out, 32'h1020_3040);	//alternating nibbles for output
		apb_write(addr_rgpio_oe, 32'hf0f0_f0f0);	//making sure you are setting only those nibbles to be output
		send_to_io_pad(32'hzfzf_zfzf);			//alternating nibbles are for inputs
		apb_read(addr_rgpio_in);
		
		//gpio as input in interrupt mode in sys clk
		send_to_io_pad(32'h0000_ffff);
		apb_write(addr_rgpio_oe, 32'd0);
		apb_write(addr_rgpio_ctrl, 2'd1);
		apb_write(addr_rgpio_inte, 32'hffff_ffff);
		apb_write(addr_rgpio_ptrig, 32'hffff_0000);
		apb_write(addr_rgpio_eclk, 32'd0);
		send_to_io_pad(32'h87654321);
		apb_read(addr_rgpio_ctrl_ints);
		wait(irq);
		apb_read(addr_rgpio_in);
		
		//gpio as input, ext clk
		apb_write(addr_rgpio_oe, 32'h0);
		apb_write(addr_rgpio_ctrl, 2'd0);
		apb_write(addr_rgpio_inte, 32'h0);
		apb_write(addr_rgpio_nec, 32'h0000_f0f0);
		apb_write(addr_rgpio_eclk, 32'h0000_ffff);
		send_to_io_pad(32'h1234_5678);
		apb_read(addr_rgpio_in);
		
		//gpio as input in interrupt mode in ext clk
		apb_write(addr_rgpio_oe, 32'd0);
		apb_write(addr_rgpio_inte, 32'hffff_ffff);
		apb_write(addr_rgpio_ptrig, 32'hffff_0000);
		apb_write(addr_rgpio_ints, 32'h0);
		apb_write(addr_rgpio_ctrl, 2'd1);
		apb_write(addr_rgpio_nec, 32'h0000_f0f0);
		apb_write(addr_rgpio_eclk, 32'h0000_ffff);
		send_to_io_pad(32'h87654321);
		apb_read(addr_rgpio_ctrl_ints);
		wait(irq);
		apb_read(addr_rgpio_in);
		apb_write(addr_rgpio_ints, 32'h0);
		apb_write(addr_rgpio_ctrl, 2'd0);
		set_io_pad_output;
		
		//gpio as bi-directional io in ext clk
		apb_write(addr_rgpio_inte, 32'd0);
		apb_write(addr_rgpio_out, 32'h1020_3040);	//alternating nibbles for output
		apb_write(addr_rgpio_oe, 32'hf0f0_f0f0);	//making sure you are setting only those nibbles to be output
		apb_write(addr_rgpio_nec, 32'h0f0f_f0f0);
		apb_write(addr_rgpio_eclk, 32'h0f0f_0f0f);
		set_io_pad_output;
		send_to_io_pad(32'hzfzf_zfzf);			//alternating nibbles are for inputs
		apb_read(addr_rgpio_in);
		
		#200 $finish;
	end

	initial
	begin
        	$dumpfile("gpio_top.vcd");
        	$dumpvars(0, gpio_top_tb);
    	end

endmodule
