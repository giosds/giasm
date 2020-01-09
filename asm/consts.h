! This file contains constants used along the program.
! No interaction is ever expected between the user and these values.
! The parameters the user is allowed to tweak (for debugging or usage) 
!	are grouped in usrPrms.h

!	######################################
! SYSTEM AND LIBRARY CALLS

_EXIT	   =	  1	
_GETCHAR   =	117	
_SPRINTF   =	121
_PRINTF	   =	127

 !	######################################
 ! OTHER CONSTANTS
 TRUE = 1
 FALSE = 0
 
 ZEROINT = 0
 _HUNDRED = 100
 
!	######################################
!	PROGRAM CONSTANTS

!	-----------------------------------------------------------------
!	SEQUENCES
_nSeq = 48											!	Number of variables in a generated uniform sequence
																! 	Should match the gaussian generator
																!	To be changed to obtain longer uniform sequences
																! 	DO NOT CHANGE: the formulas depend on it
																!			In case it is changed, halfStd has
																!			to be changed accordingly with the squared-root 
																!			formula in series.s


!	-----------------------------------------------------------------
!	MATH
  _pcFier = 10000								! DO NOT CHANGE, used to set drift and Std percentages
 
 
!	-----------------------------------------------------------------
!	LOOPS

 ! MONTECARLO
	!	The Montecarlo trajectories amount to H*L
	! Neither should exceed 16 bit unsigned
	! Neither should exceed 32 bit unsigned, when multiplied by m_gauss
 _hMcCount = 20
 _lMcCount = 50
 
 ! PLOT
 NOP1 = 1000	! Higher and lower parts of the waiting cycles for displaying Mc Plots
 NOP2 = 32000
 MAXMCPLT = 20	! Total number of Montecarlo plots to display  
 

  
.SECT .TEXT
.SECT .DATA
.SECT .BSS