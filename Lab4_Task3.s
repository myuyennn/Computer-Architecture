// MyUyen Nguyen
// myuyen
// May 19, 2023
// EE 469
// Lab 4 - Assembly Programming

// This programs implements the floating-point addition algorithm 

.global _start
_start:
	
	MOVW R0, #0x0000			// Initialize float 1
	MOVT R0, #0x3F01			
	MOVW R1, #0xFFB0			// Initialize float 2
	MOVT R1, #0x477F			
	
	// STEP 1					// Mask and shift down exponents
	MOVW R11, #0x0000			// Initialize mask for exponent
	MOVT R11, #0x7F80			
	AND R2, R0, R11				// AND R0 with 0111 1111 1000 to mask exponent of float 1 and store in R2
	LSR R2, R2, #23				// Shift down 23 bits to only exponent bits
	
	AND R3, R1, R11				// AND R1 with 0111 1111 1000 to mask exponent of float 2 and store in R3
	LSR R3, R3, #23				// Shift down 23 bits to only exponent bits
	
	// STEP 2					// Mask fractions and append leading 1's to form mantissas
	MOVW R11, #0xFFFF			// Initialize mask for fraction
	MOVT R11, #0x007F			
	AND R4, R0, R11				// AND R0 with 0000 0000 0111 1111 1111 1111 1111 1111 to mask fraction of float 1
	AND R5, R1, R11				// AND R1 with 0000 0000 0111 1111 1111 1111 1111 1111 to mask fraction of float 2
	
	MOVW R11, #0x0000			// Initialize mask to append leading 1 to mantissa
	MOVT R11, #0x0080			
	ORR R4, R4, R11				// OR with 0000 0000 1000..0 to append leading 1 to mantissa
	ORR R5, R5, R11				// OR with 0000 0000 1000..0 to append leading 1 to mantissa
	
	// STEP 3					// Compare exponents, and set result to be the larger exponent
	CMP R2, R3					// Compare the exponents
	MOVGT R6, R2				// If float 1 exponent is greater
	MOVLE R6, R3				// If float 2 exponent is greater
	
	// STEP 4					// Right shift mantissa of smaller number by the difference b/t exponents to align mantissas
	CMP R2, R3					// Compare the exponents
	MOVGT R7, R5				// If float 1 exponent is > float 2 exponent, store float 2 mantissa in R7
	MOVLE R7, R4				// If float 1 exponent is <= float 2 exponent, store float 1 mantissa in R7
	
	CMP R2, R3
	SUBGT R8, R2, R3			// Store the difference b/t exponents in R8
	SUBLE R8, R3, R2
	LSR R7, R7, R8				// Shift the smaller mantissa by the difference that was stored in R8
	
	// STEP 5
	CMP R2, R3
	ADDGT R9, R4, R7			// Sum the mantissas
	ADDLE R9, R5, R7
	
	// STEP 6					// Normalize the result if needed
	MOVW R11, #0x0000			// Initalize threshold
	MOVT R11, #0x0100			
	CMP R9, R11					// Compare result (R9) with threshold
	ADDGT R6, R6, #1 			// If result is > threshold, increment exponent by 1
	LSRGT R9, R9, #1			// And right shift mantissa by 1
	
	// STEP 7					// Round by truncation
	MOVW R11, #0xFFFF			// Initialize mask to truncate extra bits
	MOVT R11, #0x00FF			
	AND R9, R9, R11				// Truncate excess bits
	
	// STEP 8					// Strip off leading 1 off resulting mantissa, and merge sign, exponent, and fraction bits
	MOVW R11, #0x0000			// Initialize mask to restore sign bit (should always be 0 since dealing with positive numbers only)
	MOVT R11, #0x0000			
	ORR R10, R0, R11			// Restore sign bit and store in R10 (result)
	
	MOVW R11, #0x0000			// Initialize mask to clear exponent and fraction bits
	MOVT R11, #0x8000			
	AND R10, R10, R11			// Clear exponent and fraction bits that was float 1
	
	LSL R12, R6, #23			// Left shift exponent (R6) by 23 places and store in R12
	ORR R10, R10, R12			// ORR shifted exponent bits with R10 to merge exponent to result
	
	MOVW R11, #0xFFFF			// Initialize mask to strip leading 1 off mantissa
	MOVT R11, #0x007F					
	AND R9, R9, R11				// Strip leading 1 off mantissa
	
	ORR R10, R10, R9			// Merge mantissa into result by ORRing
	
	
	