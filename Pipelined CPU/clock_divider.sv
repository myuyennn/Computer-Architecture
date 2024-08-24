// MyUyen Nguyen & Jonathan So
// myuyen & jso888
// November 4, 2022
// EE 271
// Lab 3 - Finite State Machines

// This module implements a slower clock so that when the program
// gets uploaded to FPGA, the clock cycles are slow enough for us
// to test our input values accurately

// Overall inputs and outputs to the clock_divider module are listed below:
// Inputs: 1-bit clock
// Output: 32-bit divided_clocks
module clock_divider (clock, divided_clocks);
	
	input logic clock;
	output logic [31:0] divided_clocks = 32'b0;

	always_ff @(posedge clock) begin
		divided_clocks <= divided_clocks + 1;
   end

endmodule

// Testbench for clock_divider module. Simulates a test input clock signal
// for the clock_divider module. Allows one to check correct divided time
// through ModelSim
module clock_divider_testbench ();
	
	// logic to simulate
	logic clock;
	logic [31:0] divided_clocks;
	
	// Instantiates clock_divider
	clock_divider dut (.clock, .divided_clocks);
	
	parameter clock_period = 100;
	
	initial begin
		divided_clocks <= 0;
		forever #(clock_period / 2) clock <= ~clock;
	end
	
	integer i;
	initial begin
	
		for(i = 0; i < 100; i++) begin
			@(posedge clock);
		end
		$stop;
	end
endmodule
