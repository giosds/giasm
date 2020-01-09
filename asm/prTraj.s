!	PRINTS ASSET PRICE TRAJECTORIES

.SECT .TEXT

!	-----------------------------------------------------------------
! DRAWS A FULL PLOT AREA
! Draws a partial plot area [_nCols] long.
! 	Continues drawing until the accumulated prtFrm
!	is bigger than [_days], then draws the last part
!	with the difference
!	SI accumulates the pointer position, in terms of days
!	
!	
fullPlot:
	PUSH BP
	MOV BP,SP
	PUSH SI
	PUSH DI
	PUSH BX	
	MOV SI, 0
	MOV DI, 0
	MOV BX, (days)									! For comparison
	
! GET THE OPTIMAL PARAMETERS FOR PLOTTING
	PUSH brownSeq									! Push the brownian sequence
	PUSH (days)										! Push the length of the sequence
	PUSH _nRows									! Push the number of rows of the plot
	CALL plotPars										! Get the optimal parameters for plotting
																	! Shrink in AX, Shift in DX, max in CX
	ADD SP, 6
	
	MOV (lstMinPr), DX								! Copy min and maxin global variable 
	MOV (lstMaxPr), CX							! Used for the plot frame in prPlot
	
! GET THE PLOTTABLE VALUES
	! The next functions require on the stack:
	! min price, shrink, days, price sequence, axis sequence
	PUSH DX
	PUSH AX
	PUSH (days)
	PUSH brownSeq
	PUSH redPrSeq
	CALL redPric										! Reduce prices to axis values
	ADD SP, 6											! Make place for the STRIKE parmeters
	PUSH 1													! Strike is only 1 number
	PUSH strike
	PUSH redStrk						
	CALL redPric										! Reduce strike price to axis values
	ADD SP,10
	
1:
	MOV SI, DI											! Prepare next frame
	ADD DI, _nCols
	CMP DI, BX
	JGE 2f													! If DI > days, draw the remaining part and exit
	PUSH redPrSeq
	PUSH _nCols										! Otherwise draw a full col-length frame
	PUSH SI												! Starting day
	CALL partPlot										! Draw a plot frame
	ADD SP, 6

	JMP 1b	
	
	2:															! draw the remaining part and exit
	SUB BX, SI	
	PUSH redPrSeq		
	PUSH BX					
	PUSH SI												! Starting day
	CALL partPlot										! Draw a plot frame
	ADD SP, 6
	
	POP BX
	POP DI
	POP SI
	MOV SP,BP
	POP BP		
	RET

!	-----------------------------------------------------------------
!	TRANSFORMS THE PRICES TO PLOTTABLE VALUES
!	Subtracts the minimum value, then divides by the shrink factor
!	EXPECTS: red. price seq. address, displacement, shrink, 
!		price sequence length,price sequence address on the stack
!	ALTERS CX

redPric:
	PUSH BP
	MOV BP,SP
	PUSH SI
	PUSH DI
	PUSH BX
	
	
	MOV SI, 6(BP)
	MOV DI, 4(BP)
	MOV BX,0

	CMP 10(BP),0										! If all the prices are equal, modify shrink and displacement.
	JNE 1f													! Otherwise, continue
	MOV AX, 12(BP)
	MOV 10(BP), AX
	MOV 12(BP), 0
	
	
1:	MOV CX, 8(BP)								! Set loop to number of days
	
2:XOR DX,DX
	MOV AX, (BX)(SI)								! Get number from prices sequence
	SUB AX, 12(BP)									! Shift it by displacement
	DIV 10(BP)											! Divide by shrink
	
	MOV (BX)(DI), AX
	ADD BX,2
	LOOP 2b
	
	POP BX
	POP DI
	POP SI
	MOV SP,BP
	POP BP		
	RET


!	-----------------------------------------------------------------
! COMPUTES OPTIMAL PARAMETERS FOR PLOTTING
!	The SHRINK factor is the resolution of the plot. It divides the
!		price value.
!	The SHIFT parameter is the lowest value. It is subtracted from the
!		price to center the plot.
! RETURNS: 
!		SHRINK factor in AX, 
!		SHIFT factor in DX (also the min price), max price in CX
! EXPECTS: 
!		brownian sequence pointer, sequence length,  
!		number of rows on the stack
! ALTERS: AX, DX, CX
!
plotPars:
	PUSH BP
	MOV BP,SP
	PUSH SI

	MOV SI, 8(BP)										! Put brownian sequence pointer in SI
	MOV CX, 6(BP)									! Length of the br. sequence
	
	MOV DX, 32767									! Keeps the minimum value found in the sequence
	MOV AX, 0											! Keeps the maximum value found in the sequence
	
1:CMP DX, (SI)
	JLE 2f													! If min value is smaller than current value, continue on 2
	MOV DX, (SI)										! Otherwise, set min value
2:CMP AX, (SI)
	JGE 3f													! If max value is greater than current value, continue on 3
	MOV AX, (SI)										! Otherwise, set max value
3:
	ADD SI,2
	LOOP 1b	

	PUSH AX												! Save max and min values
	PUSH DX
	SUB AX, DX											! Get range
! SHRINK FACTOR in AX
	XOR DX, DX											! Clean DX for division
	DEC 4(BP) 
	DIV 4(BP)												! Divide by rows number to get the SHRINK factor

! SHIFT PARAMETER IS DX, being DX the minimum value
	POP DX
! MAX VALUE in CX
	POP CX
	
	POP SI
	MOV SP,BP
	POP BP		
	RET


!	-----------------------------------------------------------------
! DRAWS A PARTIAL PLOT AREA
!
! EXPECTS source sequence pointer, sequence length, sequence on the stack
partPlot:
	PUSH BP
	MOV BP,SP
	PUSH BX

	PUSH 6(BP)											! Length of the sequence to draw (excluding newlines)
	CALL voidPlt										! Build an empty plot area
																	! Optimization: could be computed just once, in fullPlot
	! 6(BP) still on the stack, used by the next function
	CALL cpVoid										! Copy the void plot area to the trajectory plot area
	
	! 6(BP) still on the stack, used by the next function
	MOV BX, 4(BP)									! Get the offset of the days for the next plot (number of days already plotted)
	SHL BX,1												! Double the offset - the days need be converted to WORD
	ADD BX, 8(BP)									! Add the starting sequence pointer (redPrSeq)
	PUSH BX												! Push the new pointer for the prices on the stack
	PUSH  (redStrk)									! Push the strike
	CALL addDots										! Add dots to the plot area
	ADD SP,6												! Clean up: BX and 6(BP)
	CALL prPlot											! Print the plotted area

	POP BX
	MOV SP,BP
	POP BP		
	RET
	
	
!	-----------------------------------------------------------------
! BUILDS AN EMPTY PLOT AREA
!
! EXPECTS number of cols on the stack
! ALTERS AX, DX
voidPlt:	
	PUSH BP
	MOV BP,SP
	PUSH DI
	PUSH BX
	
	MOV DI, voidMat	
	MOV DX, _nRows
	MOV BX, 4(BP)									! Number of columns to draw 
1:MOV CX, BX											! Number of columns to draw 
	! FILL A ROW WITH NULLS
	MOVB AL," "											! Fill value
	REPNZ STOSB									! space fill until CX==0
	MOVB AL,"\n"										! Place a newline at the end
	STOSB													! =
	DEC DX												! Move to next row
	LOOPNZ 1b
	MOVB AL, 0
	STOSB													! Signal string ending
	
	POP BX
	POP DI
	MOV SP,BP
	POP BP		
	RET
	
!	-----------------------------------------------------------------
! COPY AN EMPTY PLOT AREA IN trjPlot
!
! EXPECTS number of cols on the stack
cpVoid:
	PUSH BP
	MOV BP,SP
	PUSH SI
	PUSH DI
	PUSH BX

	MOV SI, voidMat
	MOV DI, trjPlot
	! Copy the rows*cols + nrows (the newlines)+1 end string
	MOV AX, _nRows
	MOV BX, 4(BP)									! Number of cols
	INC BX													! Make space for newline
	MUL BX
	INC AX													! Line ending will also be copied
	MOV CX, AX
	REPNZ MOVSB
	
	!MOV AX,0
	!MOVSB
	
	POP BX
	POP DI
	POP SI
	MOV SP,BP
	POP BP		
	RET
	
!	-----------------------------------------------------------------
! ADDS THE DOTS TO THE PLOT AREA
! ADDS STRIKE PRICE, BARRIERS
! 
! EXPECTS sequence length, sequence pointer, reduced strike on the stack
! ALTERS AX, DX
addDots:
	PUSH BP
	MOV BP,SP
	PUSH BX
	PUSH DI
	PUSH SI
	
	XOR SI, SI
	XOR DI, DI
	MOV CX, 8(BP)									! Get sequence length
	PUSH CX												! Get days + 1 and push it on the stack --> LOCAL VARIABLE -8(BP)
	INC -8(BP)											! =

1:
! DOTS:
! The memory location of a dot is:
!	Location of row (from the axis-price sequence) +  col (the current in the cycle)
!	Price is _nRows-price, to let the plot start on the lower border
!	price*(row_length+1) + col, where +1 refers to the newline
! STRIKE AND BARRIERS:
!	Same as above, but the price comes from the appropriate global variable

! DRAW STRIKE
	MOV BX, 4(BP)									! Get the row of the strike price
	MOV AX, _nRows
	SUB AX,BX											! Reduced price (in sequence pointer+SI) to AX, in reverse order	
	MUL -8(BP)											! -8(BP) is the local variable for [days+1]
																	! Now AX contains memory location of row														
	MOV BX,AX											! Location of row goes to BX for Register index displacement	
	MOVB trjPlot(BX)(DI), "="					! Place a hyphen in  trjPlot where row = strike, column DI

! DRAW DOT
! COLUMN IS IN DI
! GET ROW IN AX

	MOV BX, 6(BP)									! Move sequence pointer from stack to BX	
	MOV AX, _nRows-1							! dont want max rows
	SUB AX,(BX)(SI)									! Reduced price (in sequence pointer+SI) to AX, in reverse order	
	
! GET MEMORY LOCATION OF ROW according to formula above
	MUL -8(BP)											! -8(BP) is the local variable for [days+1]
																	! Now AX contains memory location of row														
	MOV BX,AX											! Location of row goes to BX for Register index displacement	
	MOVB trjPlot(BX)(DI), "|"					! Place a dot in  trjPlot where row = price, column DI
	INC DI													! Next column
	ADD SI,2												! Next pointer for price sequence
	LOOP 1b												! Plot one more column	
	
	ADD SP,2
	POP SI
	POP DI
	POP BX
	MOV SP,BP
	POP BP		
	RET


!	-----------------------------------------------------------------
! PRINTS THE PLOT AREA
!	Prints the plotstring and 2 strings as divisors with high and low prices
!	For the frame, finds the minimum, maximum, last prices of the 
!		brownian sequence in lstMinPr, lstMaxPr, lstBrPr
!
! ALTERS AX, DX
prPlot:
	PUSH BP
	MOV BP,SP
	PUSH DI

! TOP SEPARATOR
	MOV DI, voidStr
	MOVB AL, "\n"
	STOSB
	MOVB AL, "#"										! Print a separator nCols times
	MOV CX, (nCols)
	REPNZ STOSB
	MOVB AL, "\n"
	STOSB
	MOVB AL, 0											! End the string
	STOSB						
	
	PUSH voidStr
	PUSH _PRINTF
	SYS
	ADD SP, 4	

! TOP LEFT
	MOV AX,(lstMaxPr)
	CALL axdxDecN
	PUSH DX
	PUSH AX
	PUSH maxStr1
	PUSH _PRINTF
	SYS
	ADD SP, 8
	
! TOP CENTER
	MOVB AL, "-"
	MOV DI, voidStr
	MOV CX, (nCols)							
	SUB CX, (maxStrSp)							! If there is space enough to add hyphens, add as many as the columns,
	JNS 1f													! subtracting the start and end strings. Otherwise, repeat 0 times
	XOR CX, CX
1:REPNZ STOSB
	MOVB AL, 0											! End the string
	STOSB						

	PUSH voidStr
	PUSH _PRINTF
	SYS
	ADD SP, 4
	
! TOP RIGHT
	MOV AX,(lstBrPr)
	CALL axdxDecN
	PUSH DX
	PUSH AX
	PUSH maxStr2
	PUSH _PRINTF
	SYS
	ADD SP, 8
	
! PLOT THE TRAJECTORY
	PUSH trjPlot
	PUSH _PRINTF
	SYS
	ADD SP, 4
	
! BOTTOM LEFT
	MOV AX,(lstMinPr)
	CALL axdxDecN
	PUSH DX
	PUSH AX
	PUSH minStr1
	PUSH _PRINTF
	SYS
	ADD SP, 8

! BOTTOM CENTER
	MOVB AL, '-'
	MOV DI, voidStr
	MOV CX, (nCols)
	SUB CX, (minStrSp)									! If there is space enough to add hyphens, add as many as the columns,
	JNS 1f															! subtracting the start and end strings. Otherwise, repeat 0 times
	XOR CX, CX
1:REPNZ STOSB
	MOVB AL, "+"
	STOSB
	MOVB AL, "\n"
	STOSB
	MOVB AL, 0													! End the string
	STOSB						
	
	PUSH voidStr
	PUSH _PRINTF
	SYS
	ADD SP, 4
	
	POP DI
	MOV SP,BP
	POP BP			
	RET
	

.SECT .DATA

.SECT .BSS	
redPrSeq: .SPACE _days*2
voidMat: .SPACE _nRows*_nCols+_nRows+1
.ALIGN 2
trjPlot: .SPACE  _nRows*_nCols+_nRows+1
.ALIGN 2
topBfr: .SPACE 1000
botBfr: .SPACE 1000



