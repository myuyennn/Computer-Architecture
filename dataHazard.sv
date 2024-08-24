// MyUyen Nguyen
// myuyen
// April 21, 2023
// EE 469
// Lab 3 - Pipelining

// This module deals with data hazards that arise when pipelining a CPU

// Inputs:  1-bit clk, rst, MemWriteM, PCSrcD, PCSrcE,PCSrcM, PCSrcW, MemtoRegE, RegWriteW, RegWriteM, BranchTakenE,
// 			Match_1E_M, Match_2E_M, Match_1E_W, Match_2E_W, and Match_12D_E
// 		   32-bits WriteDataM, PCF, and ALUResultE
// Outputs: 1-bit ldrStallD, StallD, StallF, FlushD, FlushE, PCWrPendingF,
// 		  2-bits ForwardAE, and ForwardBE, and 32-bits InstrF and ReadData
module dataHazard (
	 input logic clk, rst,
	 input logic PCSrcD, PCSrcE, PCSrcM, PCSrcW,
	 input logic MemtoRegE, RegWriteW, RegWriteM, BranchTakenE,
	 input logic Match_1E_M, Match_2E_M, Match_1E_W, Match_2E_W, Match_12D_E,
	 output logic ldrStallD, StallD, StallF, FlushD, FlushE, PCWrPendingF,
	 output logic [1:0] ForwardAE, ForwardBE
);
	 
	 // Combinational logic dependent on inputs from arm.sv
	 always_comb begin
		 PCWrPendingF = PCSrcD | PCSrcE | PCSrcM;
		 ldrStallD    = Match_12D_E & MemtoRegE;
		 
		 // Stall is needed
		 StallF 	     = ldrStallD | PCWrPendingF;
		 StallD 	     = ldrStallD;
		 
		 // Branch is taken
		 FlushE 	     = ldrStallD | BranchTakenE;
		 FlushD 	     = PCWrPendingF | PCSrcW | BranchTakenE;
	 end
	 
	 // Depending on if data forwarding is needed
	 always_comb begin
		 if 	   (Match_1E_M & RegWriteM) ForwardAE = 2'b10;
		 else if (Match_1E_W & RegWriteW) ForwardAE = 2'b01;
		 else 									 ForwardAE = 2'b00;
	 end
	 
	 // Depending on if data forwarding is needed
	 always_comb begin
		 if 	   (Match_2E_M & RegWriteM) ForwardBE = 2'b10;
		 else if (Match_2E_W & RegWriteW) ForwardBE = 2'b01;
		 else 									 ForwardBE = 2'b00;
	 end
	 
endmodule 

	 