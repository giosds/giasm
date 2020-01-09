! The getnum function returns a random value [0-7]
! Prints messages. User is asked to press key in order
! to generate one component of a random seed.
! Returns seed in AX

.SECT .TEXT			

! -------------------------------------------------------------------
! 	APPLY BARRIERS
!	Reads in a whole trajectory and applies two knock-out
!	barriers to it.
!	Optimization: the barriers could either be applied where 
!		the trajectory is made, or they could just be tested after plotPars. 
!		The Apply Barriers step simplifies
!		the code, which is thus more modular.
!
!	NOTE: The option doesnt die when knocked-out.
!		The underlying asset price freezes until expiration. 
!		This means that the present value of the payoff 
!		will be discounted considering the full period.
!	CALLED: after the gmb call.
!	EXPECTS: nothing - uses global variables for everything,
!		for consistency with functions related to this one
!	ALTERS: CX, AX

applBarr:
	PUSH BP
	MOV BP,SP
	PUSH SI

	MOV SI, brownSeq									! Put brownian sequence in SI
	MOV CX, (days)										! Length of the br. sequence
	
	MOV DX, (floor)										! Down and out level
	MOV AX, (cap)											! Up and out level
	
! LOOK FOR KNOCK OUTS
!	If the price reaches a barrier, enter the next loop.
!	Otherwise jump to return
1:CMP DX, (SI)
	JG 2f															! Knock out (down)
	CMP AX, (SI)
	JL 2f															! Knock out (up)
	ADD SI,2
	LOOP 1b	
	JMP 4f														! The loop completed without reaching barriers. Exit
! BARRIER REACHED
!	Continue the previous loop, copying
!	the last price (currently in (SI) ) until expiration
2:MOV DX, (SI)											! Store last price
3:MOV (SI), DX											! Copy last price to the sequence
	ADD SI, 2
	LOOP 3b
	MOV AX, DX
	MOV (lstBrPr), DX
4:
	POP SI
	MOV SP, BP
	POP BP
	RET
	

! -------------------------------------------------------------------
! 	GENERATE GEOMETRIC BROWNIAN MOTION
!	EXPECTS price on the stack (AX will be price)
!
!	LAST PRICE IS RETURNED IN AX and saved in lstBrPr
!	ALTERS CX, AX

gbm:
	PUSH BP
	MOV BP,SP
	PUSH DI
	PUSH SI
	PUSH BX
		
	MOV AX, 4(BP)										! Start price
	MOV CX,(days)										! Number of gaussians to generate
	XOR SI,SI
	
gbmLp:	
	MOV DI, gaussSeq(SI)							! Take the gaussian
	ADD DI, (drift)											! Add the drift
	CMP DI,0
	JG 1f															! If positive, branch
	NEG DI														! NEGATIVE CASE
	MOV BX, AX												! Save price	
	MUL DI														! Multiply price times (drift+random)
	DIV (basePct)											! Percentify the price movement
	NEG AX														! Restore negative sign
	ADD AX, BX												! Add the price movement to the price
	XOR DX, DX												! Reset DX
	JMP 2f
	
1:MOV BX, AX												! POSITIVE	CASE
	MUL DI														! Same as negative, without sign issues
	DIV (basePct)				
	ADD AX, BX				
	XOR DX, DX
	
	
2:MOV brownSeq(SI), AX							! Store value in brownian sequence, same position as in gaussian
	ADD SI,2													! Advance sequences pointer
	LOOP gbmLp											! Continue until days finish
	
	MOV (lstBrPr), AX
	POP BX
	POP SI
	POP DI
	MOV SP,BP
	POP BP			
	RET

!	-----------------------------------------------------------------
! GENERATE AND ADD A GAUSSIAN SEQUENCE
!	The number of gaussian numbers to generate is 
!	on the stack
!	Uses global variable gaussCount to keep track of current gaussian being written.

genGaSeq:
	PUSH BP
	MOV  BP,SP
	PUSH DI
	
	MOV CX, 4(BP)										! Get number of gaussians to generate
	XOR DI,DI													! Set gauss array to 0
1:PUSH CX													! Save loop state. Will change in genGausN
	MOV (gaussCount),DI							! Update counter of generated gaussians
	CALL genGausN										! Generate one gaussian variable
	ADD DI,2													! Increment destination
	POP CX														! Retrieve loop state
	LOOP 1b

	POP DI
	MOV  SP,BP
	POP BP
	RET
	
!	-----------------------------------------------------------------
! GENERATE AND ADD A GAUSSIAN NUMBER
genGausN:
	PUSH BP
	MOV  BP,SP
	PUSH SI												! Save SI state

! GENERATE THE 3 UNIFORM SEQUENCES
	CALL genSeqs	
	
! GENERATE THE COMBINED SEQUENCE
	CALL genCmbA							
	
! GENERATE GAUSSIAN
	PUSH (nUnif)										! Number of uniforms to sum up for one gaussian
	CALL uni2gaus
	ADD SP, 2
test0:
	POP SI
	MOV  SP,BP
	POP BP
	RET
	
	 
!	-----------------------------------------------------------------
!	GENERATE 3 LINEAR CONGRUENTIAL SEQUENCES
!	GIVEN LENGTH, POINTER, SEEDS

genSeqs:
	PUSH BP
	MOV  BP,SP
	PUSH DI												! Save DI state
	PUSH SI
	
! GENERATE FIRST SEQUENCE (Jumping)
	PUSH 0												! First combination of parameters
	CALL updPars									! Assign parameters to a, c, m
	ADD SP,2											! Clean up the stack from parameter index
	PUSH _nSeq									! Length of sequence 1a on the stack
	PUSH rndSeq1								! Sequence 1a pointer to stack 4(BP) in called
	PUSH (seed1)									! Seed 1 to stack
	CALL rndLp										! Returns result in AX
	MOV (seed1),AX								! Update seed to last rand element
	ADD SP, 6										! Clean up the stack from sequence data
	
! GENERATE SECOND SEQUENCE
	PUSH 2												! Second combination of parameters
	CALL updPars						
	ADD SP,2								
	PUSH _nSeq						
	PUSH rndSeq2					
	PUSH (seed2)						
	CALL rndLp
	MOV (seed2),AX					
	ADD SP,6		

! GENERATE THIRD SEQUENCE
	PUSH 4									
	CALL updPars						
	ADD SP,2								
	PUSH _nSeq						
	PUSH rndSeq3					
	PUSH (seed3)						
	CALL rndLp
	MOV (seed3),AX					
	ADD SP,6
	
	POP SI												! Retrieve DI state
	POP DI									
	MOV BP,SP
	POP BP
	RET
	

! -------------------------------------------------------------------
!	UPDATE PARAMETERS
! a, c, m get updated to a different combination
!	finds the parameter index on the stack
! ALTERS AX
updPars:
	PUSH BP
	MOV BP,SP
	PUSH SI
	
	MOV SI,4(BP)
	MOV AX, aVec(SI)
	MOV (a),AX
	MOV AX, cVec(SI)
	MOV (c),AX
	MOV AX, mVec(SI)
	MOV (m),AX
	
	POP SI
	MOV SP, BP
	POP BP
	RET


!	-----------------------------------------------------------------
!	GENERATE SEQUENCE FROM SEED
!	ALTERS AX, DX, CX
rndLp:			
	PUSH BP
	MOV  BP,SP
	PUSH DI
	
	MOV AX, 4(BP)										! Get seed
	MOV DI, 6(BP)											! Get sequence pointer
	MOV CX, 8(BP)										! Initialize counter

! (a*[seed])+0 mod m
nxtRnd:
	MUL (a)									
	ADD AX, (c)
	DIV (m)
	MOV AX, DX
	MOV (DI),DX											! Store number in rndSeq
	ADD DI,2													! Increment pointer to stored rand vars
	LOOP nxtRnd
	
	POP DI
	MOV  SP,BP
	POP BP
	RET


!	-----------------------------------------------------------------
! COMBINE 3 SEQUENCES AND GENERATE
! NEW ONE WITH LONGER PERIOD	
! ALTERS CX, DX
genCmbA:		
	PUSH BP
	MOV  BP,SP
	PUSH DI													! Save register states
	PUSH SI
	PUSH BX
	
	MOV CX, (nUnif)										! From _nSeq-1 to 0
	XOR DI, DI												! Make sure the sequence pointers start from 0
	XOR SI,SI
	
cmbLp:															! Sum/subtract 3 sequences
	XOR DX,DX												! Reset register
	
	MOV AX,rndSeq1(SI)
	MOV BX,rndSeq2(SI)
	ADD AX, BX
	ADC DX,0
	
	MOV BX,rndSeq3(SI)
	ADD AX,BX							
	ADC DX,0
	DIV (m_gauss)	
						! If second number was to be subtracted (to be tested):
						!cmbLp:										
							!MOV DX,0
							!MOV AX,rndSeq1(SI)
							!MOV BX,rndSeq2(SI)
							!SUB AX,BX					
							!JS negative									! Handle negative case below
							!! positive
							!MOV BX,rndSeq3(SI)
							!ADD AX,BX				
							!DIV (m_gauss)							! Just divide the result. 
							!JMP store									
							!negative:										! Twos complement on 32 bits
							!CWD
							!NOT AX
							!ADD AX,1
							!NOT DX
							!ADC DX,0
							!DIV (m_gauss)	
	MOV rndSeq4(SI),DX											! Store number in rndSeq4			
	ADD SI,2
	LOOP cmbLp
	
	!MOV SI,0
	
	POP BX
	POP SI
	POP DI																	! Retrieve DI state
	MOV  SP,BP
	POP BP
	RET


!	-----------------------------------------------------------------
!	TRANSFORM A BATCH OF UNIFORMS 
!	TO A GAUSSIAN RANDOM VARIABLE
!
!	GENERAL FORMULA to get
!	mean req_avg, standard deviation req_std,
!   having n numbers from a Uniform [0-m]
!	
!	req_std*    [sum(...n..)-m/2]/(sqrt(n*m**2/12))  + req_avg
!
!	FORMULA with n=48, m approaching 16 bit.
!	Starting price of asset (range under 16 bit) startPr: 20,000
!	Standard deviation = 1% of Starting price = 200; req_std = 300; req_avg = 0
!	---> (200*sum(...48...)/2)/m_gauss -12*200 + 0
!	--->(100*sum(...48...))/m_gauss -2400
!	
!	Requires additions resulting up to 32 bits, multiplications 32*16 bits
!	EXPECTS the number of uniforms (48)on the stack
!	ALTERS AX, CX, DX

uni2gaus:
	PUSH BP
	MOV  BP,SP
	PUSH BX												! Save register states
	PUSH SI
	PUSH DI
	
	MOV CX, 4(BP)									! Get batch length
	XOR AX,AX											! Initialize lower bits of Total
	XOR DX,DX											! Initialize higher bits of Total
	XOR SI,SI												! Start the 48 uniforms counter

! SUM UP THE 48 NUMBERS	
sumLp:														! SUM UP THE 48 NUMBERS
	MOV BX,rndSeq4(SI)							! Fetch new number	
	ADD AX,BX											! Add new number to lower bits of total
	ADC DX,0												! If AX+BX generates carry, add it to DX
	ADD SI,2												! Point to next number
	LOOP sumLp										! Repeat until number of elements is 0

! MULTIPLY THE SUM BY HALF STD
	MOV CX, DX										! Save Old Higher part of N
	MUL (halfStd)										! Multiply the Lower part of N times halfStd
	MOV BX, DX											! Save New Higher of Low
	XCHG AX, CX										! Now CX contains the New Lower of Lower. AX contains Old Higher
	MUL (halfStd)										! Multiply Old Higher times halfStd
	ADD AX, BX											! Add New Higher of Low to New Low of Higher
																	! 32bit * 16 bit: no carry to Higher of Higher

	MOV DX, AX											! High part result
	MOV AX, CX											! Low part result
	
	DIV (m_gauss)										! If m_gauss is big enough, the result will fit in AX
	SUB AX, (mean)									! Subtract the mean	
	
	MOV DI, (gaussCount)
	MOV gaussSeq(DI), AX						! Store	
	
	POP DI
	POP SI
	POP BX													! Restore BX state
	MOV BP,SP
	POP BP
	RET


