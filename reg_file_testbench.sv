// MyUyen Nguyen
// myuyen
// April 7, 2023
// EE 469
// Lab 1 - Register File and ALU

// This module is the testbench to test reg_file making sure that write data shows
// up one cycle after it was given, but read would happen instantaneously

// Logics are the inputs and outputs from reg_file
module reg_file_testbench();

		parameter data_width = 32;
		parameter addr_width = 4;
	
		logic clk, we;
		logic [data_width - 1:0] wr_data;
		logic [addr_width - 1:0] wr_addr;
		logic [addr_width - 1:0] read_addr1, read_addr2;
		logic [data_width - 1:0] read_data1, read_data2;
		
		// Instantiating reg_file to get tested
		reg_file dut (.*);
		
		// Clock period
		parameter clock_period = 100;
		
		// Clock setup
		initial begin
			clk <= 0;
			forever #(clock_period /2) clk <= ~clk;
					
		end //initial
		
		initial begin
			// 1 @(posedge clk) represents one clock cycle, wr_data, wr_addr, and read_datas
			// are inputs of that clock cycle. If no inputs is declared before @(posedge clk),
			// the inputs remain the same from last clock cycle
			we<=1; wr_data<=32'd0; wr_addr<=4'd0; read_addr1<=4'd0; 	@(posedge clk);
					 read_addr2<=4'd0;
					 
					 wr_data<=32'd1; wr_addr<=4'd1; read_addr1<=4'd1; 	@(posedge clk);
					 read_addr2<=4'd0;
					 
																						@(posedge clk);
					 
					 wr_data<=32'd2; wr_addr<=4'd2; read_addr1<=4'd0; 	@(posedge clk);
					 read_addr2<=4'd1;
					 
					 wr_data<=32'd3; wr_addr<=4'd3; read_addr1<=4'd2; 	@(posedge clk);
					 read_addr2<=4'd2;
					 
					 wr_data<=32'd4; wr_addr<=4'd4; read_addr1<=4'd3; 	@(posedge clk);
					 read_addr2<=4'd3;
					 
					 wr_data<=32'd5; wr_addr<=4'd5; read_addr1<=4'd0; 	@(posedge clk);
					 read_addr2<=4'd0;
					 
					 wr_data<=32'd6; wr_addr<=4'd6; read_addr1<=4'd2; 	@(posedge clk);
					 read_addr2<=4'd3;
					 
					 wr_data<=32'd7; wr_addr<=4'd7; read_addr1<=4'd5; 	@(posedge clk);
					 read_addr2<=4'd6;
					 
					 wr_data<=32'd8; wr_addr<=4'd8; read_addr1<=4'd7; 	@(posedge clk);
					 read_addr2<=4'd7;
					 
					 wr_data<=32'd9; wr_addr<=4'd9; read_addr1<=4'd8; 	@(posedge clk);
					 read_addr2<=4'd7;
					 
					 wr_data<=32'd10; wr_addr<=4'd10; read_addr1<=4'd9; 	@(posedge clk);
					 read_addr2<=4'd9;
					 
					 wr_data<=32'd11; wr_addr<=4'd11; read_addr1<=4'd10; 	@(posedge clk);
					 read_addr2<=4'd10;
					 
			we<=0; wr_data<=32'd9; wr_addr<=4'd9; read_addr1<=4'd8; 	@(posedge clk);
					 read_addr2<=4'd8;
					 
					 wr_data<=32'd10; wr_addr<=4'd10; read_addr1<=4'd9; 	@(posedge clk);
					 read_addr2<=4'd9;
					 
					 wr_data<=32'd4; wr_addr<=4'd15; read_addr1<=4'd11; 	@(posedge clk);
					 read_addr2<=4'd11;
					 
					 wr_data<=32'd15; wr_addr<=4'd7; read_addr1<=4'd15; 	@(posedge clk);
					 read_addr2<=4'd12;
					 
					 wr_data<=32'd23; wr_addr<=4'd3; read_addr1<=4'd3; 	@(posedge clk);
					 read_addr2<=4'd6;
					 
					 wr_data<=32'd30; wr_addr<=4'd2; read_addr1<=4'd7; 	@(posedge clk);
					 read_addr2<=4'd8;
					 
					 wr_data<=32'd11; wr_addr<=4'd6; read_addr1<=4'd4; 	@(posedge clk);
					 read_addr2<=4'd5;
					 
					 wr_data<=32'd1; wr_addr<=4'd0; read_addr1<=4'd3; 	@(posedge clk);
					 read_addr2<=4'd9;
			$stop; //end simulation							
							
		end //initial
		
endmodule 