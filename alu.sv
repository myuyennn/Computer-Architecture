// MyUyen Nguyen
// myuyen
// April 7, 2023
// EE 469
// Lab 1 - Register File and ALU

// This module is an ALU that can perform any of several operations

// Inputs: 1-bit clk, 2-bit ALUControl, and 32-bit a and b
// Outputs: 4-bit ALUFlags and 32-bit Result
module alu (
	input logic [31:0] a, b,
	input logic [1:0] ALUControl,
	output logic [31:0] Result,
	output logic [3:0] ALUFlags
	);
	
	// Intermediate logic
	logic negative, zero, carryOut, overflow, carryTemp;
	logic signed [31:0] tempb;
	
	// Combinational logic depending on ALUControl
	always_comb begin
		case (ALUControl) 
			2'b00: begin // ADD
				tempb = 0;
				{carryTemp, Result} = a + b;
			end
			2'b01: begin // SUBTRACT
				tempb = ~b;
				{carryTemp, Result} = a + tempb + 1;
			end
			2'b10: begin // AND
				tempb = 0;
				carryTemp = 0; 
				Result = a & b;
			end
			2'b11: begin // OR
				tempb = 0;
				carryTemp = 0;
				Result = a | b;
			end
			default: begin
				tempb = 0;
				carryTemp = 0; 
				Result = 0;
			end
		endcase
	end
	
	// Boolean equations to compute outputs
	assign negative = Result[31];
	assign zero = (Result == 0);
	assign carryOut = !ALUControl[1] & carryTemp;
	assign overflow = !(ALUControl[0] ^ a[31] ^ b[31]) & (a[31] ^ Result[31]) & !ALUControl[1];
	assign ALUFlags = {negative, zero, carryOut, overflow};
	
endmodule 

module alu_testbench();

	logic [31:0] a, b;
	logic [1:0] ALUControl;
	logic [31:0] Result;
	logic [3:0] ALUFlags;
	logic [103:0] testVectors [1000:0];
	
	// Instantiating from alu.sv
	alu dut (.*);
	
	// Read in text-only file to test all cases
	initial begin
		$readmemh("alu.tv", testVectors);
		
		for (int i = 0; i < 20; i = i + 1) begin
			{ALUControl, a, b, Result, ALUFlags} = testVectors[i];
		end
		$stop;
	end
endmodule 