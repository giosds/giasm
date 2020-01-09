! This file contains parameters that are allowed to be changed
!	for debugging or usage.

!	######################################
!	USER MODIFIABLE DATA

!	-----------------------------------------------------------------
!	FINANCIAL DATA

 _days = 252!45										! Length of the generated final sequence. Note: Tracer only supports up to 45.
_startPr = 10000										! The value of the asset at T0.	
																	!	Should be small enough to fit in a register when growing, 
																	!		big enough to get meaningful results when manipulating.
																	!		Multiple of 10.000 gets the drift right
																	!	Also used as the quotient of percent values
_bpDrift =  0!25										! Basis points; eg: 0.25% of 20000 basePct yelds 50 absolute
 _bpReqStd=100										! Basis points; eg: 0.100% of 20000 basePct yelds 200 absolute.
																	! The absolute value should be a multiple of 4 for a good mean calculation
_rateR = 200											! Rate of return - yearly, in basis points. 
																	! Eg: price in T252 = 30000; bpR = 200; basePct = 20000 -> return 1%
																	! Discount in T0: (30000*200)/20000=300
 _put = TRUE
 _strike = 10000
 _cap = 12000
 _floor = 8000
 

!	######################################
!	DEBUG AND PROGRAM
 
!	-----------------------------------------------------------------
! PLOTS
! Number of rows and columns
_nRows = 30
_nCols = 150 

!	-----------------------------------------------------------------
 _debug = FALSE										! TRUE if debug mode, FALSE otherwise
																		! If DEBUG, jumps over the user input with preset values
 _dbgSd1 = 50
 _dbgSd2 = 70
 _dbgSd3 = 90

 
.SECT .TEXT
.SECT .DATA

.SECT .BSS

! SEQUENCES
rndSeq1: .SPACE 2*_nSeq
rndSeq2: .SPACE 2*_nSeq
rndSeq3: .SPACE 2*_nSeq
rndSeq4: .SPACE 2*_nSeq

! GAUSSIAN VARIABLES
gaussSeq: .SPACE _days*2

! BROWNIAN MOTION
brownSeq: .SPACE _days*2
