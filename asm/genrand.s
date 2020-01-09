! THIS MODULE GENERATES RANDOMNESS
! The getnum function returns a random value [0-7]
! Prints messages. User is asked to press key in order
! to generate one component of a random seed.
! Returns seed in AX

.SECT .TEXT		
			
!	-----------------------------------------------------------------
! BUILD SEEDS
! Builds 3 random seeds using the 3 components
! Seeds vary between [0, 4367]
getSeeds:						
										
	PUSH BP
	MOV  BP,SP											
		
	PUSH (chaos1)									! Compute seed 1
	PUSH (chaos2)
	PUSH (chaos3)
	CALL getSeed
	MOV (seed1), AX								! Store seed1 in memory
	
	PUSH (chaos3)									! Compute seed 2
	PUSH (chaos1)
	PUSH (chaos2)
	CALL getSeed
	MOV (seed2), AX								! Store seed2 in memory
	
	PUSH (chaos2)									! Compute seed 3
	PUSH (chaos3)
	PUSH (chaos1)
	CALL getSeed
	MOV (seed3), AX								! Store seed3 in memory
	
! PRINT SEEDS
	MOV AX, step
	MOV DX,(seed1)
	CALL prnt_msg
	MOV AX, step
	MOV DX,(seed2)
	CALL prnt_msg
	MOV AX, step
	MOV DX,(seed3)
	CALL prnt_msg
	
	MOV SP,BP					
	POP BP
	RET

!	-----------------------------------------------------------------
!	ASK USER TO GENERATE 3 NUMBERS
get3nums:

	PUSH BP
	MOV  BP,SP		
	PUSH BX
	PUSH DI
	
	
	MOV AX,msg1										! Msg to user
	CALL prnt_msg
	MOV BX,0
	MOV CX, (lp_chaos)							! Times the input is asked
	MOV DI,chaos3									! 3rd seed component

1:MOV AX, step										!Msg to user
	MOV DX,CX											!	 Num value for print (loop n. CX)
	CALL prnt_msg
	CALL getNum										! Get random seed: prompt msg to user
																	! 		collects input, returns rnd seed [0,9]
																	! 		uses BX to generate seed (seed accumulator)										
	STOS														! Store seed in AX to DI variable, then increment DI
	MOV BX,0												! Reset seed accumulator
	LOOP 1b												! More input asked for

	POP DI													! Reset state
	POP BX
	MOV SP,BP					
	POP BP
	RET

getNum:								
	PUSH BP
	MOV  BP,SP					
	PUSH BX												! Save state
	
	MOV AX, prompt_ms							! Print message
	CALL prnt_msg									! =
	CALL pause											! Wait
	PUSH _GETCHAR								! =
	CALL  cls												! Clear screen (azzera AL)
	
1:																! Enter-reading loop
	INC BX													! Increment counter
	SYS														! Get char 
	CMPB AL,'\n'				
	JE 1b														! If Enter, continues loop.
	
rd:SYS														! Clears possible extra chars
	CMPB AL,'\n'										! =
	JNE rd													! =
	
	CMP BX, (n_chars)								! If not Enter, tries to exit loop: if BX below n_chars stays in, otherwise exits loop
	JLE k_psh												! If below threshold: prints message, decreases counter, loops back to 1
	CALL  cls												! Exit conditions satisfied:  exit getNum function
	AND BX, 0XF										! Only keeps the last 4 bits, yelding mod 16
	
	MOV AX,BX											! Return value in register AX

																	! Reset state
	POP BX
	MOV SP,BP											! Clear stack
	POP BP
	RET
!	-----------------------------------------------------------------
! PRINTS "KEEP PUSHING" if release is too quick
k_psh:
	PUSH BP						
	MOV BP,SP
	SUB BX, (bck_chars)							! Decrements counter
	PUSH k_push				! Prints 'keep pushing'
	PUSH _PRINTF
	SYS
	PUSH _GETCHAR
	SYS	
	CALL  cls
	MOV SP,BP
	POP BP
	JMP 1b													! Back to loop


!	-----------------------------------------------------------------
!	GET ONE SEED OUT OF THREE
!	KEYPRESS COMPONENTS
!	components: number after AND (0-15)

getSeed:													! needs 3 components on the stack, returns
																	! seed in AX
	PUSH BP
	MOV BP,SP	
	
! ADD AND SHIFT 
! Equivalent to: n1*16*16+n2*16+n3
	MOVB CL,4					
	MOV AX, 4(BP)									! Use 1st seed component
	SHL AX, CL					
	ADD AX, 6(BP)									! Use 2nd seed component
	SHL AX, CL
	ADD AX, 8(BP)									! Use 3rd seed component
	MOV SP,BP
	POP BP
	RET 6													! Clean up the stack






