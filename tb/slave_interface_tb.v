module slave_interface_tb;
	reg pclk, preset, psel, penable, pwrite, gpio_inta_o;
	reg [31:0] pwdata, gpio_dat_o;
	reg [3:0] paddr;
	wire pready, irq, sys_clk, sys_rst, gpio_we;
	wire [3:0] gpio_addr;
	wire [31:0] prdata, gpio_dat_i;
	
	slave_interface DUT (	.pclk(pclk),
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
				.gpio_inta_o(gpio_inta_o)	);
				
	initial
	begin
		pclk = 1'b0;
		psel = 1'b0;
		penable = 1'b0;
		pwrite = 1'b0;
	end
	
	always #5 pclk = ~pclk;

    always @ (posedge pclk) 
	begin
	
	if(preset == 1'b1)
		gpio_dat_o <= 32'd0;
	
        else if(gpio_we == 1'b1) 
	begin
            gpio_dat_o <= gpio_dat_i;
        end
    end
	
	initial
	begin
	
		//-------------------write cycle-----------------------
		
		preset = 1'b1;
		#10 preset = 1'b0;
		
		@(negedge pclk);
			paddr = 4'd2;
			pwrite = 1'b1;
			pwdata = 32'd17;
			psel = 1'b1;
		
		@(negedge pclk);
			penable = 1'b1;
			
		@(negedge pclk);
			while(pready == 1'b0)
				@(negedge pclk);
		
			penable = 1'b0;
			psel = 1'b0;

		//--------------------read cycle-----------------------
		
		@(negedge pclk);
		    paddr = 4'd2;
		    pwrite = 1'b0;
		    psel = 1'b1;
		
		@(negedge pclk);
		    penable = 1'b1;

		@(negedge pclk);
			while(pready == 1'b0)
				@(negedge pclk);
	
			penable = 1'b0;
			psel = 1'b0;
			
		//-------------------------------------------------------
		
		#100 $finish;
		
	end
		
	initial 
	begin
		$dumpfile("apb_slave.vcd"); 
		$dumpvars(0, slave_interface_tb);
	end
	
endmodule
