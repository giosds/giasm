
.SECT .TEXT

!	-----------------------------------------------------------------
!	PRINT THE FIRST N PLOTS WITH DELAY
!	For every run in Montecarlo, checks 
!	if it must be printer. Inserts NOPs in order
!	to let the user see the plot.
!	Keeps count in a global variable.
!	Used in mtCarlo.s -> mcPart

prFrstPlt:	
	CMP (pltCntr), MAXMCPLT								! check counter. If it reaches constant, jmp to return
	JGE 3f
	CALL fullPlot

	MOV CX, NOP1	! First part of waiting cycle
1:PUSH CX
	MOV CX, NOP2	
2:XCHG AX, AX		! Insert NOP
	LOOP 2b
	POP CX
	LOOP 1b
	! Increase counter
	INC (pltCntr)
3:
	RET


!	-----------------------------------------------------------------
!	PRINT GEOMETRIC BROWNIAN MOTION
prGmb:
	PUSH (days)											! Length of sequence to the stack
	PUSH brownSeq										! Sequence 1a pointer to stack 4(BP) in called
	CALL prDecSeq
	ADD SP,4
	MOV AX,prDiv											! Msg to user
	CALL prnt_msg
	RET
	
!	-----------------------------------------------------------------
! PRINT GAUSSIAN SEQUENCE
prGaSeq:	
	PUSH (days)											! Length of sequence to the stack
	PUSH gaussSeq										! Sequence 1a pointer to stack 4(BP) in called
	CALL prSeq
	ADD SP,4
	MOV AX,prDiv											! Msg to user
	CALL prnt_msg
	RET

!	-----------------------------------------------------------------
! PRINT THE 4 SEQUENCES
! Alters AX
pr4Seq:
! PRINT FIRST SEQUENCE	
	
	PUSH (nUnif)											! Length of sequence 1b on the stack
	PUSH rndSeq1										! Sequence 1a pointer to stack 4(BP) in called
	CALL prSeq
	ADD SP,2
	MOV AX,prDiv											! Msg to user
	CALL prnt_msg
	
! PRINT SECOND SEQUENCE
	PUSH rndSeq2										! Sequence 1a pointer to stack 4(BP) in called
	CALL prSeq
	ADD SP,2
	MOV AX,prDiv											! Msg to user
	CALL prnt_msg
	
! PRINT THIRD SEQUENCE
	PUSH rndSeq3										! Sequence 1a pointer to stack 4(BP) in called
	CALL prSeq
	ADD SP,2
	MOV AX,prDiv											! Msg to user
	CALL prnt_msg

! PRINT COMBINED SEQUENCE
	PUSH rndSeq4										! Sequence 1a pointer to stack 4(BP) in called
	CALL prSeq
	ADD SP,4
	MOV AX,prDiv											! Msg to user
	CALL prnt_msg
	
	RET	

!	-----------------------------------------------------------------
! PRINT SEQUENCE
! EXPECTS number of chars , then sequence pointer on the stack
prSeq:	
	PUSH BP
	MOV BP,SP
	PUSH SI	
	
	MOV CX,6(BP)										! Get  total days
	MOV SI, 4(BP)										! Get position of prices
1:	
	MOV AX, (SI)										! Get a price
	ADD SI, 2
	PUSH AX
	PUSH prNum
	PUSH _PRINTF
	SYS
	ADD SP, 6
	LOOP 1b
	
	tst1:
	POP SI
	MOV SP,BP
	POP BP			
	RET

!	-----------------------------------------------------------------
! PRINT DECIMAL SEQUENCE
!	Same as above, but prints a decimal number
! EXPECTS number of chars , then sequence pointer on the stack
! ALTERS AX, CX, DX
prDecSeq:	
	PUSH BP
	MOV BP,SP
	PUSH SI	
	
	MOV CX,6(BP)										! Get  total days
	MOV SI, 4(BP)										! Get position of prices
	
1:	
	MOV AX, (SI)										! Get a price	
	CALL axdxDecN									! Produce a decimal string using AX. 
																	! result in dcmlBuf
	PUSH DX
	PUSH AX
	PUSH frmtDecN
	PUSH _PRINTF
	SYS
	
	ADD SP, 4
	ADD SI, 2												! Prepare for next price	
	LOOP 1b
	
	POP SI
	MOV SP,BP
	POP BP			
	RET	

!	-----------------------------------------------------------------
! DECIMAL NUMBER
!	Transforms an int number into a decimal number
! EXPECTS number in AX
! RETURNS values in AX, DX
axdxDecN:
	PUSH BP
	MOV BP,SP
	
	XOR DX,DX
	DIV (HUNDRED)
	
	MOV SP,BP
	POP BP
	RET

!	-----------------------------------------------------------------
! PRINTS INFORMATION ON PARAMETERS
! All the parameters are pushed on the stack
! and printed
! The values are divided by 100
! ALTERS AX, DX
prInfo1:
	PUSH BP
	MOV BP,SP
	
	PUSH msg2
	PUSH _PRINTF
	SYS
	PUSH msg3
	PUSH _PRINTF
	SYS
	MOV AX, (floor)
	DIV (HUNDRED)
	PUSH AX
	MOV AX, (cap)
	DIV (HUNDRED)
	PUSH AX
	MOV AX, (strike)
	DIV (HUNDRED)
	PUSH AX
	PUSH (reqStd)
	PUSH (drift)
	PUSH (rateR)
	PUSH msg4
	PUSH _PRINTF
	SYS
	PUSH msg5
	PUSH _PRINTF
	SYS
	
	MOV SP,BP
	POP BP
	RET

!	-----------------------------------------------------------------
! ASK PUT
! Asks the user if he wants a put (p)
! ALTERS AX
askPut:
	PUSH BP
	MOV BP,SP
	
	! PRINT REQUEST
	PUSH msg6
	PUSH _PRINTF
	SYS

	! GET ANSWER
	PUSH _GETCHAR
	SYS								
	CMPB AL,'p'				
	JNE 1f								
	MOV (put), TRUE										! It is a PUT
	MOV AX, msg6p
	JMP 2f
1:MOV (put), FALSE										! It is a CALL
	MOV AX, msg6c
2:PUSH AX
	PUSH _PRINTF
	SYS
	
	MOV SP,BP
	POP BP
	RET

!	-----------------------------------------------------------------
! TELL THE COST
!	Tells the user the discounted, average Montecarlo price
! 	of the option
prInfo2:
	PUSH BP
	MOV BP,SP
	
	MOV AX, (dscPayOff)
	CALL axdxDecN
	PUSH DX
	PUSH AX
	MOV AX,  (mcPayOff)
	CALL axdxDecN
	PUSH DX
	PUSH AX
	PUSH msg7
	PUSH _PRINTF
	SYS
	
	
	MOV SP,BP
	POP BP
	RET

!	-----------------------------------------------------------------
! EXPLAIN THE UNIFORMS
prInfo3:
	PUSH BP
	MOV BP,SP
	PUSH msg8
	PUSH _PRINTF
	SYS	
	MOV SP,BP
	POP BP
	RET

!	-----------------------------------------------------------------
! EXPLAIN THE GAUSSIANS
prInfo4:
	PUSH BP
	MOV BP,SP
	PUSH msg9
	PUSH _PRINTF
	SYS	
	MOV SP,BP
	POP BP
	RET

!	-----------------------------------------------------------------
! EXPLAIN THE UNIFORMS
prInfo5:
	PUSH BP
	MOV BP,SP
	PUSH msg10
	PUSH _PRINTF
	SYS	
	MOV SP,BP
	POP BP
	RET

!	-----------------------------------------------------------------
! SHOW THE TRAJECTORY
prInfo6:
	PUSH BP
	MOV BP,SP
	PUSH msg11
	PUSH _PRINTF
	SYS	
	MOV SP,BP
	POP BP
	RET

!	-----------------------------------------------------------------
! 	TELL THE OUTCOME
!	Subtracts the previously computed discounted
!	Montecarlo payoff from the new payoff
!
!	EXPECTS payOff in AX
tellOutc:
	PUSH BP
	MOV BP,SP
	SUB AX, (dscPayOff)
	JS 1f
	PUSH AX
	CALL axdxDecN
	PUSH DX
	PUSH AX
	PUSH msg12a
	JMP 2f
1:NEG AX
	PUSH AX
	CALL axdxDecN
	PUSH DX
	PUSH AX
	PUSH msg12b
	
2:PUSH _PRINTF
	SYS	
	MOV SP,BP
	POP BP
	RET
	
!	-----------------------------------------------------------------
! PRINT A TEXT AND POSSIBLY A NUMBER
! Requires string pointer in AX, number in DX
prnt_msg:
	PUSH BP
	MOV BP,SP
	PUSH DX
	PUSH AX
	PUSH _PRINTF
	SYS
	MOV SP,BP
	POP BP
	RET

!	-----------------------------------------------------------------
! WAITS FOR KEYPRESS
pause:								
	PUSH BP
	MOV BP,SP
	PUSH _GETCHAR
	SYS
	MOV SP,BP
	POP BP
	RET

!	-----------------------------------------------------------------
!	INSERTS NEW LINES TO CLEAR THE SCREEN
cls:										!
	PUSH BP
	MOV BP,SP
	PUSH clear
	PUSH _PRINTF
	SYS
	MOV SP,BP
	POP BP
	RET
	


