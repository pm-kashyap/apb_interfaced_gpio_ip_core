`timescale 1ns/1ps

module gpio_register_tb;

    reg sys_clk;
    reg sys_rst;
    reg gpio_we;
    reg [31:0] gpio_addr;
    reg [31:0] gpio_dat_i;
    reg [31:0] aux_i;
    reg [31:0] in_pad_i;
    reg gpio_eclk;

    wire [31:0] gpio_dat_o;
    wire gpio_inta_o;
    wire [31:0] out_pad_o;
    wire [31:0] oen_padoe_o;
	
    gpio_register DUT (
			.sys_clk(sys_clk),
			.sys_rst(sys_rst),
			.gpio_we(gpio_we),
			.gpio_addr(gpio_addr),
			.gpio_dat_i(gpio_dat_i),
			.gpio_dat_o(gpio_dat_o),
			.gpio_inta_o(gpio_inta_o),
			.aux_i(aux_i),
			.in_pad_i(in_pad_i),
			.gpio_eclk(gpio_eclk),
			.out_pad_o(out_pad_o),
			.oen_padoe_o(oen_padoe_o)
			);

    initial sys_clk = 1'b0;
    always #5 sys_clk = ~sys_clk;
    
    initial gpio_eclk = 1'b0;
    always #20 gpio_eclk = ~gpio_eclk;

    initial 
    begin
	//resetting register module
        sys_rst     = 1'b1;
        gpio_we     = 1'b0;
        gpio_addr   = 32'h0;
        gpio_dat_i  = 32'h0;
        aux_i       = 32'h0;
        in_pad_i    = 32'hABABABAB; 		//input to test default case
        gpio_eclk   = 1'b0;
        
        #15;
        sys_rst     = 1'b0; 			//release reset
	@(negedge sys_clk);			//wait a cycle

        //basic writing operation test
        gpio_addr  = 32'h08; 			//select the output enable register
        gpio_dat_i = 32'hFFFF_FFFF;		//enable all lines
	gpio_we    = 1'b1;			//enable writing 
        
	@(negedge sys_clk);			//wait a cycle
        
		
        gpio_addr  = 32'h04;			//select gpio out register
        gpio_dat_i = 32'h1234_5678;		//write a value
        
        @(negedge sys_clk);				
		
	//reading output register contents
        gpio_addr  = 32'h04;			//still the same gpio out register
        gpio_we    = 1'b0; 			//turn off write enable for reading from output reg
		
        @(negedge sys_clk); 
        @(negedge sys_clk); 			//2 clk cycles, 1 to latch to dat_reg, another to send to output register
        
        // default case testing
        gpio_addr  = 32'h99; 			//random address to force case statement to default
        
        @(negedge sys_clk);
        @(negedge sys_clk); 			//2 cycle delay to let data be output

        //aux input testing
        aux_i      = 32'hAAAA_BBBB;		//random value to pass as aux input
        gpio_addr  = 32'h14;			//select aux register
        gpio_dat_i = 32'hFFFF_FFFF; 		//select aux line for all pins
        gpio_we    = 1'b1;				
        
        @(negedge sys_clk);
        gpio_we    = 1'b0;			//pull down to enable reading
        
        //external clock sample testing
        gpio_addr  = 32'h18;			//select control register
        gpio_dat_i = 32'h0000_0003; 		//make sure both bits of control register are high
        gpio_we    = 1'b1;			//write into control register
        @(negedge sys_clk);
        gpio_we    = 1'b0;			//read from control register

        in_pad_i   = 32'h0000_000F; 		//now this change will reflect at ext clk posedge
        
	@(negedge sys_clk);
	@(negedge sys_clk);

        //interrupt validation
        gpio_addr  = 32'h0c;			//select interrupt enable
        gpio_dat_i = 32'h0000_0001;		//enable interrupts only on the first bit
        gpio_we    = 1'b1;			//write into ie reg
        @(negedge sys_clk);
        
        gpio_addr  = 32'h10;			//select ptrig reg
        gpio_dat_i = 32'h0000_0001;		//enable ptrig inter on first bit
        @(negedge sys_clk);			//time delay to allow for ptrig reg to be written into
        gpio_we    = 1'b0;			//read from ptrig reg. wr en is already high from prev case
        @(negedge sys_clk);
	@(negedge sys_clk);

        //check if interrupt fires if some other bit is toggled
        in_pad_i   = 32'h0000_001F; 		//change the 4th bit from 0 to 1
        @(negedge sys_clk);
	@(negedge sys_clk);			//interrupt will not fire as 4th bit is masked
        
        //actually toggling 0th bit to see if interrupt is fired
        in_pad_i   = 32'h0000_001E; 		//keep 4th bit high, lower 0th bit
        @(negedge sys_clk);
	@(negedge sys_clk);                       	
        
        // Flip Bit 0 from 0 to 1! (This is our targeted positive-edge transition)
        in_pad_i   = 32'h0000_001F; 		//push 0th bit high to trigger interrupt
        @(negedge sys_clk);
	@(negedge sys_clk);			//interrupt should ideally fire
        
        //clear interrupt status reg
        gpio_addr  = 32'h1C;			//select int status reg
        gpio_dat_i = 32'h0000_0000; 		//overwrite value to signal completion of interrupt servicing
        gpio_we    = 1'b1;			//write to status reg
        @(negedge sys_clk);
        gpio_we    = 1'b0;
        
        #40;
        $finish;
    end

    initial 
    begin
        $dumpfile("gpio_sim.vcd");
        $dumpvars(0, gpio_register_tb);
    end

endmodule
