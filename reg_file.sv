// MyUyen Nguyen
// myuyen
// April 7, 2023
// EE 469
// Lab 1 - Register File and ALU

// This module is a register file of size 16 x 32 to store 32-bit data

// Inputs: 1-bit clk and we, 32-bit wr_data, 4-bit wr_addr, read_addr1, read_addr2
// Outputs: 32-bit read_data1 and read_data2
module reg_file #(parameter data_width = 32, addr_width = 4)
	(input logic clk, we,
	 input logic [data_width - 1:0] wr_data,
	 input logic [addr_width - 1:0] wr_addr,
	 input logic [addr_width - 1:0] read_addr1, read_addr2,
	 output logic [data_width - 1:0] read_data1, read_data2);
	
	// Initializing array to store data
	logic [data_width - 1:0] reg_array [2**addr_width - 1:0];
	
	// Sequential Logic (DFFs)
	always_ff @(posedge clk) begin
		if (we)
			reg_array[wr_addr] <= wr_data;
	end 
	
	// read_datas are asynchronous
	assign read_data1 = reg_array[read_addr1]; 
	assign read_data2 = reg_array[read_addr2];
	
endmodule
		