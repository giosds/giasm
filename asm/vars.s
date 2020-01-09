.SECT .TEXT
!	-----------------------------------------------------------------
!	INITIALIZE VARIABLES
!	Alters AX, CX, DX

initVars:										
	! PERFORMS SOME NEEDED CALCULATIONS ON THE PARAMETERS	

	! Required Standard Deviation, as a base value
	XOR DX, DX
	MOV AX, (basePct)
	DIV (pcFier)
	MUL (bpReqStd)
	MOV (reqStd), AX	
	
	! Normalizer-mean calculated (in accordance with the 48 summation formula)	
	XOR DX, DX
	MOV AX, (reqStd)
	SHR AX,1												! Divide by 4
	SHR AX,1
	MUL (nUnif)											! Multiply by 48
	MOV (mean), AX
		
	! Drift, as a base value
	XOR DX, DX
	MOV AX, (basePct)
	DIV (pcFier)
	MUL (bpDrift)
	MOV (drift), AX

	!Half of required standard deviation, base value
	!	(in accordance with the 48 summation)
	MOV AX, (reqStd)
	SHR AX,1	
	MOV (halfStd), AX
	
	! rateR, as a base value
	XOR DX, DX
	MOV AX, (basePct)
	DIV (pcFier)
	MUL (bpRateR)
	MOV (rateR), AX
	
	RET
	
!	-----------------------------------------------------------------
	.SECT .DATA

!	-----------------------------------------------------------------
! MISCELLANEOUS
	debug: .WORD _debug							! 1 if debug mode, 0 otherwise
	HUNDRED: .WORD _HUNDRED		! 100

!	-----------------------------------------------------------------
!	MONTECARLO
hMcCount: .WORD _hMcCount				! 100
lMcCount: .WORD _lMcCount					! 100		 100 * 100 = 10k runs
pltCntr: .WORD ZEROINT	! 0 Counter of Montecarlo plots displayed

!	-----------------------------------------------------------------
! FINANCIAL DATA
!	By using the percentifier, the basis point values are made independent respect the 
!	base price of the asset.

	days: .WORD _days								! 252 Number of time steps
	startPr: .WORD _startPr							! 20000 Starting price of the asset
	
	! DevStd and Average are expressed as a percentage multiplied by
	! the base number
	basePct: .WORD _startPr						! 20000	Used to get percent values

	pcFier: .WORD _pcFier							! 10000		 Used to transform drift, std, r
	bpDrift: .WORD _bpDrift						! 25				 Relative - basis points
	bpReqStd: .WORD _bpReqStd			! 100 daily stdev of the asset - basis points
	bpRateR: .WORD _rateR						! 200 Rate of return - year, in basis points. 
	
	strike: .WORD _strike								!	20000 Strike price of the asset for the option
	redStrk: .WORD ZEROINT	
	cap: .WORD _cap
	floor: .WORD _floor
	
	put: .WORD _put	! TRUE	Boolean. The option behaves like a put if True, as a call if False
	
	mcPayOff: .WORD 0
	dscPayOff: .WORD 0

!	-----------------------------------------------------------------
! GAUSSIANS
	m_gauss:	.WORD	32362					! For the combined sequence, LCG
	nUnif: .WORD _nSeq	! 48						! Number of uniforms to sum up

!	-----------------------------------------------------------------
! BROWNIAN MOTION
	lstBrPr:  .WORD 0									!Last brownian price computed
	lstMinPr:  .WORD 0									!Minimum brownian price computed
	lstMaxPr:  .WORD 0								!Maximum brownian price computed
	

!	-----------------------------------------------------------------
! UNIFORMS
! a, c, m  coefficients of LCG are stored into vectors: for each index into them,
! a different combination of parameters is chosen 

	a:	.SPACE  2				
	c:	.SPACE  2		
	m:	.SPACE	2
	aVec:	.WORD 157, 146, 142
	cVec:	.WORD 0, 0, 0
	mVec: .WORD 32363, 31727, 31657

!	######################################
!	MESSAGES AND RELATED PARAMETERS
 
!	-----------------------------------------------------------------
! PLOT
!	----> prTraj.s
	maxStrSp:	.WORD 46							! Space taken by the maxStr and minStr
	minStrSp: .WORD 20								! on the plot borders
	nRows:  .WORD _nRows						! 30	 Rows and columns of the plot area
	nCols:  .WORD _nCols							! 100
	voidStr:	.SPACE 1000							! For the frame 
	maxStr1: .ASCIZ "\n+ %d.%02d  $ MAX VALUE"
	maxStr2: .ASCIZ " %d.%02d  $ AT EXPIRATION + \n"
	minStr1: .ASCIZ "\n+ %d.%02d  $ MIN VALUE"

.ALIGN 2

!	-----------------------------------------------------------------
! INPUT
!	---->genrand.s
	lp_chaos: .WORD 3
	n_chars: .WORD 2								! At least n_chars pressed before exiting the read loop
	bck_chars: .WORD 2							! If user exits too early, decrease counter by bck_chars

!	-----------------------------------------------------------------
! OUTPUT
!	---->genrand.s, prFuncs.s
	k_push:	.ASCIZ "KEEP PUSHING!!!!!!"
	prompt_ms: .ASCIZ "a.Press ENTER for a few seconds (count to 10)\nb.Press any other key\nc.Press ENTER again, once"
	prNum: .ASCIZ "%d " 
	clear: .ASCIZ "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"
	frmtDecN: .ASCIZ "%d.%02d "
	
!	---->main.s
	prDiv: .ASCIZ "\n-------------------------------------------------------------------\n"
	step: .ASCIZ "\n=====================\nSTILL %d TO GO\n" 
	
!	-----------------------------------------------------------------	
! MESSAGES
	msg1: .ASCIZ "2) NOW: CREATE CHAOS!!\nCharge your generator by pressing [ENTER... - ANY KEY - ENTER] 3 times\n"
	msg2: .ASCIZ "*******************************************\n*                                         *  \n* WELCOME TO THE BARRIER OPTION SIMULATOR * \n*                                         *  \n*******************************************\n"
	msg3: .ASCIZ "\n\n1) Choose the option type\n2) Generate randomness\n3) Wait for Montecarlo pricing\n4) See if you gain or loose\n\n\nBuy a CALL or a PUT "
	msg4: .ASCIZ "on an asset where:\nR (Basis Points): %d\nDRIFT (Basis Points): %d\nSTANDARD DEVIATION (Basis Points): %d\nSTRIKE PRICE: %d\nCAP: %d\nFLOOR: %d\n\n"
	msg5: .ASCIZ "These parameters are modifiable in the source code. Rows and columns of the plot can also be set. \nPress ENTER to continue..."
	msg6: .ASCIZ "\n\n1) Please, CHOOSE YOUR OPTION. Enter [p] (lowercase) for a PUT, any other character for a CALL. Then press ENTER.\nType:  "
	msg6p: .ASCIZ "You own a PUT option! \nPress ENTER..."
	msg6c: .ASCIZ "You own a CALL option! \n3) Now, run Montecarlo\n\nPress ENTER..."
	msg7: .ASCIZ "\n\n\nThe estimated payoff of your derivative is %d.%02d$ in a year\nNow it costs you %d.%02d$\n\n4) Now, see what happens to the underlying asset in the next year:\n\nPress ENTER..."
	msg8: .ASCIZ "\n\n\n(See how a trajectory is made)\nThe next 4 sequences are uniform distributions. They will be used to generate a single gaussian random variable\n\nPress ENTER...\n"
	msg9: .ASCIZ  "\n\n\n(See how a trajectory is made)\nThat way, a sequence of gaussians is built\n\nPress ENTER...\n"
	msg10: .ASCIZ  "\n\n\nTHESE ARE YOUR ASSET PRICES:\n\nPress ENTER...\n"
	msg11: .ASCIZ  "\n\n\nTHIS IS THE PLOT OF THE PERIOD:\n\nPress ENTER...\n"
	msg12a: .ASCIZ  "\n\n\nTHIS IS YOUR GAIN:\n\n>>>   %d.%02d$  <<<Press ENTER to exit the program...\n"
	msg12b: .ASCIZ  "\n\n\nTHIS IS YOUR LOSS:\n\n>>>   %d.%02d$  <<<\nPress ENTER to exit the program...\n"
	
	

.ALIGN 2

.SECT .BSS 

!	-----------------------------------------------------------------
! FINANCIAL DATA

	halfStd: .SPACE 2!  100							! To use in computation of gaussian, precomputed element
	mean: .SPACE 2	! 2400							! reqStd*48/4
	drift: .SPACE 2! 50										! Base daily drift of asset: 0.25%*basePct = 50
	reqStd: .SPACE 2! 										! Daily standard deviation of asset: 1%*basePct = 200
	
	rateR: .SPACE 2! 50									! Base rate of return
!	-----------------------------------------------------------------
! RANDOMNESS GENERATION

	gaussCount: .SPACE 2								! Where to put next gaussian

	chaos3:  .SPACE 2										! Seed components
	chaos2:  .SPACE 2		
	chaos1:  .SPACE 2		

	seed1:	.SPACE  2										! seeds obtained by reordering components
	seed2:	.SPACE  2		
	seed3:	.SPACE	2

	

