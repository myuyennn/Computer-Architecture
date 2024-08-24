// MyUyen Nguyen
// myuyen
// April 7, 2023
// EE 469
// Lab 1 - Register File and ALU

// This module is the testbench for the alu making sure that operations match
// ALUControl and the correct ALUFlags are raised

// Logics are the inputs and outputs from alu
module alu_testbench();
	
	logic clk;
	logic [31:0] a, b;
	logic [1:0] ALUControl;
	logic [31:0] result;
	logic [3:0] ALUFlags;
	logic [103:0] testVectors [1000:0];
	
	// Instantiating from alu.sv
	alu dut (.*);
	
	// Clock setup
	parameter clock_period = 100;
	
	initial begin
		clk <= 0;
		forever #(clock_period /2) clk <= ~clk;
					
	end //initial
	
	// Read in text-only file to test all cases
	initial begin
		$readmemh("alu.tv", testVectors);
		for (int i = 0; i < 17; i++) begin
			{ALUControl, a, b, ALUFlags} = testVectors[i]; @(posedge clk);
		end
		$stop;
	end
endmodule 