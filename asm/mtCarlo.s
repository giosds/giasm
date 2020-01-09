!	THIS MODULE HANDLES THE CREATION OF A SET OF SIMULATED PRICE TRAJECTORIES
!	AND CALCULATES THE AVERAGE PAYOFF.
!

.SECT .TEXT				

!	-----------------------------------------------------------------
!	GENERATES A TRAJECTORY. PRINTS: 
!		the 3 base uniform sequences;
!		the derived uniform sequence; the Gaussian sequence;
!		the brownian motion.

runEpr:	
	PUSH BP
	
	CALL trjctry			
	
	! PRINT
	CALL pr4Seq							!	THE LAST RUN OF UNIFORM SEQUENCES
														!	genfuncs.s	
	CALL prGaSeq						!	GAUSSIANS
														!	genfuncs.s
	CALL prGmb							! BROWNIAN MOTION
														!	genfuncs.s
	POP BP
	RET

!	-----------------------------------------------------------------
! GENERATES MANY TRAJECTORIES 
! COMPUTES AVERAGE AND PRESENT VALUE
! Yelds a mean value - the fair price
! A high number of trajectories (> 16 bit) is achieved 
! by running 2 loops
!
! EXPECTS the number of runs to be pushed on the stack:
! 	2int < 16 bit. The number of runs is their product.
! RETURNS the average Mc Price in AX

runMc:
	
	PUSH BP
	MOV BP, SP
	dbg3:
	MOV CX, 6(BP)						! Set higher counter
	PUSH 4(BP)								! Pass lower counter to function
	
	XOR AX,AX								! Resets the accumulator
	XOR DX, DX	

1:													! OUTER LOOP STARTS HERE
	PUSH CX									! Save higher counter	
	PUSH AX									! Save last cumulated values - lower word
	PUSH DX									! Save last cumulated values - higher word
	
	CALL mcPart

	! CUMULATE THE PRICES
	POP DX										! Last cumulated values, higher word
	POP BX										! Last cumulated values, lower word, go in BX
	ADD AX, BX								! Add the last generated price to the cumulated values
	ADC DX, 0								! Add carry if needed
	
	POP CX										! Retrieve higher counter
	LOOP 1b									! CONTINUE OUTER LOOP

	! AVERAGE THE AVERAGES
	DIV 6(BP)									! Divide by higher loop length to get the mean	
	MOV (mcPayOff), AX				! Save the Montecarlo average value
	MOV SP, BP
	POP BP
	RET

!	-----------------------------------------------------------------
mcPart:
	PUSH BP
	MOV BP, SP
	

	MOV CX, 10(BP)						! Set CX to lower counter. 
														! Finds the counter value on the stack before: 
														! 3 saved values, the function address and the bp address
	XOR AX,AX								! Resets the accumulator
	XOR DX, DX
	
1:	
	dbg4:
	PUSH CX									! Save loop counter before next functions
	PUSH AX									! Save last cumulated values - lower word
	PUSH DX									! Save last cumulated values - higher word
	
	CALL trjctry								! BUILD A TRAJECTORY
	CALL prFrstPlt							! Plot one of the first trajectories

	CALL payOff 							! Must find last price in (lstBrPr). Returns payoff in AX
	
	! CUMULATE THE PAYOFFS
	dbg5:											
	POP DX										! Last cumulated values, higher word
	POP BX										! Last cumulated values, lower word, go in BX
	ADD AX, BX								! Add the last generated price to the cumulated values
	ADC DX, 0								! Add carry if needed
	
	dbg6:
	POP CX
	LOOP 1b
	
	! AVERAGE THE PAYOFFS
	DIV 10(BP)								! Divide by lower loop length to get the mean
	MOV SP, BP
	POP BP
	RET

!	-----------------------------------------------------------------
!	GENERATE A COMPLETE PRICE TRAJECTORY
!	Stored in brownSeq
!	TODO: barriers
!	RETURNS: AX, the last day price
trjctry:											
! GENERATE A GAUSSIAN SEQUENCE

	PUSH (days)							! Push length of sequence
	CALL genGaSeq						! series2.s
	ADD SP, 2								! Clean up stack	
	
! GENERATE BROWNIAN MOTION
	PUSH (startPr)
	CALL gbm								! series.s
	ADD SP, 2								! Clean up stack
!	APPLY BARRIERS
	CALL applBarr
	RET
	
!	-----------------------------------------------------------------
!	GENERATE A PAYOFF
!	
! 	EXPECTS: (lstBrPr) in memory, the last price of the sequence
!	RETURNS: AX, the payoff
!	ALTERS AX, DX
payOff:
	PUSH BP
	MOV BP, SP
	
	MOV AX, (lstBrPr)
	MOV DX, (strike)
	CMP (put),TRUE
	JNE 1f
	XCHG AX, DX
1:SUB AX, DX
	JNS 2f	
	XOR AX, AX
2:
	MOV SP, BP
	POP BP
	RET
	


	
!	-----------------------------------------------------------------
!	DISCOUNT A PRICE	
!	Uses the full period, base rate of return, rateR.
!	
!	RETURNS: AX, the discounted price
! 	EXPECTS: AX, the future payoff. (days)
!	ALTERS AX, DX
dscnt:
															! The price is in AX
	XOR DX,DX
	MOV BX, AX									! Save price for later
	MUL (rateR)									! Multiply price by return - could use AX-DX
	DIV (basePct)								! Percentify the price movement - AX is enough
	SUB BX, AX									! Subtract the discount from the price
															! Always >= 0
	MOV AX, BX									! Price back to AX
	RET

.SECT .DATA
.SECT .BSS				
