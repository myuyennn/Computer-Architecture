// MyUyen Nguyen
// myuyen
// April 21, 2023
// EE 469
// Lab 3 - Pipelining

// This module is a CPU with Pipelining that can perform various operations

// Inputs: 1-bit clk, rst, ldrStallD, StallD, StallF, FlushD, FlushE, PCWrPendingF,
// 		  2-bits ForwardAE, and ForwardBE, and 32-bits InstrF and ReadData
// Outputs: 1-bit MemWriteM, PCSrcD, PCSrcE,PCSrcM, PCSrcW, MemtoRegE, RegWriteW, RegWriteM, BranchTakenE,
// 			Match_1E_M, Match_2E_M, Match_1E_W, Match_2E_W, and Match_12D_E
// 		   32-bits WriteDataM, PCF, and ALUResultE

/* arm is the spotlight of the show and contains the bulk of the datapath and control logic. This module is split into two parts, the datapath and control. 
*/

// clk - system clock
// rst - system reset
// Instr - incoming 32 bit instruction from imem, contains opcode, condition, addresses and or immediates
// ReadData - data read out of the dmem
// WriteData - data to be written to the dmem
// MemWrite - write enable to allowed WriteData to overwrite an existing dmem word
// PC - the current program count value, goes to imem to fetch instruciton
// ALUResult - result of the ALU operation, sent as address to the dmem

module arm (
    input  logic        clk, rst,
	 input  logic 			ldrStallD, StallD, StallF, FlushD, FlushE, PCWrPendingF, // extra added inputs and outputs
	 input  logic [1:0]  ForwardAE, ForwardBE,												// are going to or coming from
    input  logic [31:0] InstrF,																	// the dataHazard module
    input  logic [31:0] ReadData,
    output logic [31:0] WriteDataM, 
    output logic [31:0] PCF, ALUResultE,
    output logic        MemWriteM, PCSrcD, PCSrcE,PCSrcM, PCSrcW,
	 output logic 			MemtoRegE, RegWriteW, RegWriteM, BranchTakenE,
	 output logic 			Match_1E_M, Match_2E_M, Match_1E_W, Match_2E_W, Match_12D_E
);

    // datapath buses and signals
    logic [31:0] PCPrime, PCPlus4F, PCPlus8D, PCOption; // pc signals
    logic [ 3:0] RA1D, RA2D;                  // regfile input addresses
    logic [31:0] RD1D, RD2D;                  // raw regfile outputs
    logic [ 3:0] ALUFlags;                  // alu combinational flag outputs
    logic [31:0] ExtImm, SrcAE, SrcBE;        // immediate and alu inputs 
    logic [31:0] Result;                    // computed or fetched value to be written into regfile or pc
	 logic [3:0] FlagsPrime;
	 logic FlagWrite;
		
    // control signals
    logic MemtoRegD, ALUSrcD, RegWriteD, BranchD, NoWrite, 
			 MemWriteD, FlagWriteD, CondEx, RegW, FlagW; // Added PCS, NoWrite, RegW, and FlagW
    logic [1:0] RegSrcD, ImmSrcD, ALUControlD;
	 
	 // Decode (include some control signals above from Lab 2)
	 logic [3:0] WA3D;
	 logic [31:0] InstrD;
	 
	 // Execute stage signals
	 logic RegWriteE, MemWriteE, BranchE, ALUSrcE, FlagWriteE, CondExE;
	 logic [1:0] ALUControlE;
	 logic [3:0] WA3E, CondE, FlagsE, RA1E, RA2E;
	 logic [31:0] ExtImmE, RD1E, RD2E, WriteDataE, RDTemp1D, RDTemp2D;
	 
	 // Memory stage signals
	 logic MemtoRegM;
	 logic [3:0] WA3M;
	 logic [31:0] ALUResultM, ALUOutM;
	 
	 // Writeback stage signals
	 logic MemtoRegW;
	 logic [3:0] WA3W;
	 logic [31:0] ALUOutW, ResultW, ReadDataW;

    /* The datapath consists of a PC as well as a series of muxes to make decisions about which data words to pass forward and operate on. It is 
    ** noticeably missing the register file and alu, which you will fill in using the modules made in lab 1. To correctly match up signals to the 
    ** ports of the register file and alu take some time to study and understand the logic and flow of the datapath.
    */
    //-------------------------------------------------------------------------------
    //                                      DATAPATH
    //-------------------------------------------------------------------------------

	 assign PCOption  = PCSrcW ? ResultW : PCPlus4F;
    assign PCPrime   = BranchTakenE ? ALUResultE : PCOption;  // mux, use either default or newly computed value
    assign PCPlus4F  = PCF + 'd4;                  			// default value to access next instruction
    assign PCPlus8D  = PCPlus4F;             // value read when reading from reg[15]]
    
	 // update the PC, at rst initialize to 0
    always_ff @(posedge clk) begin
        if 		 (rst) 	 PCF <= '0;
		  else if (StallF) PCF <= PCF;		// When we cannot go back in time to forward data
        else     			 PCF <= PCPrime;	// stall the whole program
    end
	 
	 always_ff @(posedge clk) begin
		  if 		 (rst | FlushD) InstrD <= '0; // Clear out signal if branching
		  else if (StallD)		 InstrD <= InstrD; // When data forwarding is not an option
		  else 	  					 InstrD <= InstrF;
	 end

    // determine the register addresses based on control signals
    // RegSrc[0] is set if doing a branch instruction
    // RefSrc[1] is set when doing memory instructions
    assign RA1D = RegSrcD[0] ? 4'd15         : InstrD[19:16];
    assign RA2D = RegSrcD[1] ? InstrD[15:12] : InstrD[ 3: 0];

    // two muxes, put together into an always_comb for clarity
    // determines which set of instruction bits are used for the immediate
    always_comb begin
        if      (ImmSrcD == 'b00) ExtImm = {{24{InstrD[7]}},InstrD[7:0]};          // 8 bit immediate - reg operations
        else if (ImmSrcD == 'b01) ExtImm = {20'b0, InstrD[11:0]};                  // 12 bit immediate - mem operations
        else                      ExtImm = {{6{InstrD[23]}}, InstrD[23:0], 2'b00}; // 24 bit immediate - branch operation
    end
	 
	 // Instantiated register file from lab 1 to processor
    reg_file u_reg_file (
        .clk       (~clk), 
        .wr_en     (RegWriteW),
        .write_data(ResultW),
        .write_addr(WA3W),
        .read_addr1(RA1D), 
        .read_addr2(RA2D),
        .read_data1(RD1D), 
        .read_data2(RD2D)
    );
	 
	 // Signals sent to dataHazard and determine if data forwarding is necessary
	 always_comb begin
		 Match_1E_M   = (RA1E == WA3M);
		 Match_1E_W   = (RA1E == WA3W);
		 Match_2E_M   = (RA2E == WA3M);
		 Match_2E_W   = (RA2E == WA3W);
		 Match_12D_E  = (RA1D == WA3E) | (RA2D == WA3E);
	 end
	 
	 // Instantiated dataHazard module to designated ports
	 dataHazard DH 	(
		  .clk			(clk),
		  .rst		   (rst),
		  .PCSrcD		(PCSrcD),
		  .PCSrcE		(PCSrcE),
		  .PCSrcM		(PCSrcM),
		  .PCSrcW		(PCSrcW),
		  .BranchTakenE(BranchTakenE),
		  .MemtoRegE	(MemtoRegE),
		  .RegWriteW	(RegWriteW),
		  .RegWriteM	(RegWriteM),
		  .Match_1E_M	(Match_1E_M),
		  .Match_2E_M	(Match_2E_M),
		  .Match_1E_W	(Match_1E_W),
		  .Match_2E_W	(Match_2E_W),
		  .Match_12D_E (Match_12D_E),
		  .ldrStallD	(ldrStallD),
		  .StallD		(StallD),
		  .StallF		(StallF),
		  .FlushD		(FlushD),
		  .FlushE		(FlushE),
		  .PCWrPendingF(PCWrPendingF),
		  .ForwardAE	(ForwardAE),
		  .ForwardBE	(ForwardBE)
	 );
	 
	 // Combinational logic to determine SrcAE (dependent on dataHazard)
	 always_comb begin
		 if 		(ForwardAE == 2'b00) SrcAE = RD1E;
		 else if (ForwardAE == 2'b10) SrcAE = ALUResultM;
		 else 							   SrcAE = ResultW;
	 end
	 
	 // Combinational logic to determine SrcBE and WriteDataE (dependent on dataHazard)
	 always_comb begin
		 if (ForwardBE == 2'b00) begin
			 SrcBE = ALUSrcE ? ExtImmE : RD2E;
			 WriteDataE = RD2E;
		 end
		 else if (ForwardBE == 2'b10) begin
			 SrcBE = ALUSrcE ? ExtImmE : ALUResultM;
			 WriteDataE = ALUResultM;
		 end
		 else begin
			 SrcBE = ALUSrcE ? ExtImmE : ResultW;
			 WriteDataE = ResultW;
		 end
	 end
	 
	 // Saving address to write to
	 assign WA3D = InstrD[15:12];
	 
	 // if branching, substitute the 15th regfile register file to PCF
	 assign RDTemp1D = (RA1D == 'd15) ? PCPlus8D : RD1D;
	 assign RDTemp2D = (RA2D == 'd15) ? PCPlus8D : RD2D;
	 
	 // Execute stage pipeline
	 always_ff @(posedge clk) begin
		  
		  MemtoRegE <= MemtoRegD;
		  ALUControlE <= ALUControlD;
		  ALUSrcE <= ALUSrcD;
		  FlagWriteE <= FlagWriteD;
		  CondE <= InstrD[31:28];
		  ExtImmE <= ExtImm;
		  RA1E <= RA1D;
		  RA2E <= RA2D;
		  RD1E <= RDTemp1D;
		  RD2E <= RDTemp2D;
		  WA3E <= WA3D;
		  
		  // Flush all signals responsible for write and branching
		  if (rst | FlushE) begin
				PCSrcE <= 0; 
				RegWriteE <= 0;
				MemWriteE <= 0;
				BranchE <= 0;
		  end
		  else begin
				PCSrcE <= PCSrcD;
				RegWriteE <= RegWriteD;
				MemWriteE <= MemWriteD;
				BranchE <= BranchD;
		  end
	 end
	 
	 // Logic to predict if branch will be taken
	 assign BranchTakenE = BranchE & CondExE;
	 
	 // Memory stage pipeline
	 always_ff @(posedge clk) begin
		  if (rst) begin
				PCSrcM <= 0;
				RegWriteM <= 0;
				MemtoRegM <= 0;
				MemWriteM <= 0;
				
				WA3M <= '0;
				ALUResultM <= '0;
				ALUOutM <= '0;
				WriteDataM <= '0;
		  end
		  else begin
				PCSrcM <= PCSrcE & CondExE;
				RegWriteM <= RegWriteE & CondExE;
				MemtoRegM <= MemtoRegE;
				MemWriteM <= MemWriteE & CondExE;
				
				WA3M <= WA3E;
				ALUResultM <= ALUResultE;
				ALUOutM <= ALUResultE;
				WriteDataM <= WriteDataE;
		  end
	 end
	 
	 // Writeback stage pipeline
	 always_ff @(posedge clk) begin
		  if (rst) begin
				PCSrcW <= 0;
				RegWriteW <= 0;
				MemtoRegW <= 0;
				
				WA3W <= '0;
				ALUOutW <= '0;
				ResultW <= '0;
				ReadDataW <= '0;
		  end
		  else begin
				PCSrcW <= PCSrcM;
				RegWriteW <= RegWriteM;
				MemtoRegW <= MemtoRegM;
				
				WA3W <= WA3M;
				ALUOutW <= ALUOutM;
				ResultW <= MemtoRegW ? ReadDataW : ALUOutW;
				ReadDataW <= ReadData;
		  end
	 end
	 
    // Instantiated ALU from lab 1 to the correct ports in processor
    alu u_alu (
        .a          (SrcAE), 
        .b          (SrcBE),
        .ALUControl (ALUControlE),
        .Result     (ALUResultE),
        .ALUFlags   (ALUFlags)
    );
	 
    // determine the result to run back to PC or the register file based on whether we used a memory instruction
    // assign Result = MemtoReg ? ReadData : ALUResult;    // determine whether final writeback result is from dmemory or alu
	
    /* The control conists of a large decoder, which evaluates the top bits of the instruction and produces the control bits 
    ** which become the select bits and write enables of the system. The write enables (RegWrite, MemWrite and PCSrc) are 
    ** especially important because they are representative of your processors current state. 
    */
    //-------------------------------------------------------------------------------
    //                                      CONTROL
    //-------------------------------------------------------------------------------
    
	 // Always assign ALUFlags to FlagsPrime (FlagsPrime then MIGHT save to FlagsE below)
	 assign FlagsPrime = ALUFlags;
	 
	 // Sequential Logic to update FlagsPrime to ALUFlags
	 always_ff @(posedge clk)
	 begin	
		if 	  (rst) 			FlagsE <= 4'b0000;
		else if (FlagWriteE) FlagsE <= FlagsPrime; // Only update FlagsPrime when doing CMP
	 end
	 
	 always_comb 
	 begin
		if (InstrD[31:28] == 4'b1110) CondEx = 0; // Checks if instruction is 
		else 									CondEx = 1;	// conditional (4 MSB)
	 end	
	 
	  // Logic to update CondExE (dependent on FlagsPrime)
	 always_comb 
	 begin
		case (CondE)
			4'b0000: CondExE = FlagsE[2]; // Equal (EQ)
			4'b0001: CondExE = ~FlagsE[2]; // Not equal (NE)
			4'b1010: CondExE = (~(FlagsE[3] ^ FlagsE[0])); // Signed greater than or equal (GE)
			4'b1100: CondExE = (~FlagsE[2]) & (~(FlagsE[3] ^ FlagsE[0])); // Signed greater then (GT)
			4'b1101: CondExE = FlagsE[2] | (FlagsE[3] ^ FlagsE[0]); // Signed less than or equal (LE) 
			4'b1011: CondExE = (FlagsE[3] ^ FlagsE[0]); // Signed less than (LT)
			4'b1110: CondExE = 1;
			default: CondExE = 0;
		endcase
	 end
	 
//	 // Added CMP functionality and modified branch section to perform
	 // both conditional and unconditional branching
    always_comb 
	 begin
		  
        casez (InstrD[27:20])

            // ADD (Imm or Reg)
            8'b00?_0100_0 : begin   // note that we use wildcard "?" in bit 25. That bit decides whether we use immediate or reg, but regardless we add
                PCSrcD    = 0;
                MemtoRegD = 0; 
                MemWriteD = 0; 
                ALUSrcD   = InstrD[25]; // may use immediate
                RegWriteD = 1;
                RegSrcD   = 'b00;
                ImmSrcD   = 'b00; 
                ALUControlD = 'b00;
					 FlagWriteD = 0;
					 BranchD = 0;
					 RegW = 1;
					 NoWrite = 0;
            end
            // SUB (Imm or Reg)
            8'b00?_0010_0 : begin   // note that we use wildcard "?" in bit 25. That bit decides whether we use immediate or reg, but regardless we sub
                PCSrcD    = 0; 
                MemtoRegD = 0; 
                MemWriteD = 0; 
                ALUSrcD   = InstrD[25]; // may use immediate
                RegWriteD = 1;
                RegSrcD   = 'b00;
                ImmSrcD   = 'b00; 
                ALUControlD = 'b01;
					 FlagWriteD = 0;
					 BranchD = 0;
					 RegW = 1;
					 NoWrite = 0;
            end

            // AND
            8'b000_0000_0 : begin
                PCSrcD    = 0; 
                MemtoRegD = 0; 
                MemWriteD = 0; 
                ALUSrcD   = 0; 
                RegWriteD = 1;
                RegSrcD   = 'b00;
                ImmSrcD   = 'b00;    // doesn't matter
                ALUControlD = 'b10;  
					 FlagWriteD = 0;
					 BranchD = 0;
					 RegW = 1;
					 NoWrite = 0;
            end

            // ORR
            8'b000_1100_0 : begin
                PCSrcD    = 0;
                MemtoRegD = 0; 
                MemWriteD = 0; 
                ALUSrcD   = 0; 
                RegWriteD = 1;
                RegSrcD   = 'b00;
                ImmSrcD   = 'b00;    // doesn't matter
                ALUControlD = 'b11;
					 FlagWriteD = 0;
					 BranchD = 0;
					 RegW = 1;
					 NoWrite = 0;
            end

            // LDR
            8'b010_1100_1 : begin
                PCSrcD    = 0;
                MemtoRegD = 1; 
                MemWriteD = 0; 
                ALUSrcD   = 1;
                RegWriteD = 1;
                RegSrcD   = 'b10;    // msb doesn't matter
                ImmSrcD   = 'b01; 
                ALUControlD = 'b00;  // do an add
					 FlagWriteD = 0;
					 BranchD = 0;
					 RegW = 1;
					 NoWrite = 0;
            end

            // STR
            8'b010_1100_0 : begin
                PCSrcD    = 0;
                MemtoRegD = 0; // doesn't matter
                MemWriteD = 1; 
                ALUSrcD   = 1;
                RegWriteD = 0;
                RegSrcD   = 'b10;    // msb doesn't matter
                ImmSrcD   = 'b01; 
                ALUControlD = 'b00;  // do an add
					 FlagWriteD = 0;
					 BranchD = 0;
					 RegW = 0;
					 NoWrite = 0;
            end

            // B
            8'b1010_???? : begin
					if (CondEx & CondExE) begin // Conditional branch and condition is met
                    PCSrcD    = 0; 
                    MemtoRegD = 0;
                    MemWriteD = 0; 
                    ALUSrcD   = 1;
                    RegWriteD = RegW & !NoWrite & CondEx;
                    RegSrcD   = 'b01;
                    ImmSrcD   = 'b10; 
                    ALUControlD = 'b00;  // do an add
						  FlagWriteD = 0;
						  BranchD = 1;
						  RegW = 0;
						  NoWrite = 0;
					end
					else if (CondEx & !CondExE) begin // Conditional branch but condition is
                    PCSrcD    = 0; 			   // not met
                    MemtoRegD = 0;
                    MemWriteD = 0; 
                    ALUSrcD   = 1;
                    RegWriteD = RegW & !NoWrite & CondEx;
                    RegSrcD   = 'b01;
                    ImmSrcD   = 'b10; 
                    ALUControlD = 'b00;  // do an add
						  FlagWriteD = 0;
						  BranchD = 1;
						  RegW = 0;
						  NoWrite = 0;
					end
					else begin		// Unconditional branching
						  PCSrcD    = 0; 
                    MemtoRegD = 0;
                    MemWriteD = 0; 
                    ALUSrcD   = 1;
                    RegWriteD = RegW & !NoWrite & CondEx;
                    RegSrcD   = 'b01;
                    ImmSrcD   = 'b10; 
                    ALUControlD = 'b00;  // do an add
						  FlagWriteD = 0;
						  BranchD = 1;
						  RegW = 0;
						  NoWrite = 0;
					end
            end
				
				// CMP (Nearly identical to SUB)
            8'b00?_0010_1 : begin
                PCSrcD    = 0; 
                MemtoRegD = 0; 
                MemWriteD = 0; 
                ALUSrcD   = InstrD[25]; // may use immediate
                RegWriteD = 1;
                RegSrcD   = 'b00;
                ImmSrcD   = 'b00; 
                ALUControlD = 'b01;
					 FlagWriteD = 1;
					 BranchD = 0;
					 RegW = 1;
					 NoWrite = 1;
            end

			default: begin
					 PCSrcD    = 0; 
					 MemtoRegD = 0; // doesn't matter
					 MemWriteD = 0; 
					 ALUSrcD   = 0;
				    RegWriteD = 0;
					 RegSrcD   = 'b00;
					 ImmSrcD   = 'b00; 
					 ALUControlD = 'b00;  // do an add
					 FlagWriteD = 0;
					 BranchD = 0;
					 RegW = 0;
					 NoWrite = 0;
			end
        endcase
    end

endmodule 
