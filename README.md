# giasm
Assembly code - Exotic option simulation

THIS PROGRAM SIMULATES THE BEHAVIOR OF AN EXOTIC OPTION.

-----------------------------------------------------------------
PROGRAM:
THE PROGRAM ASKS THE USER WHETHER HE PREFERS TO BUY A PUT OR A CALL.
SUBSEQUENTLY, IT PRICES THE DERIVATIVE VIA MONTECARLO.	
A SIMULATED UNDERLYING ASSET TRAJECTORY IS COMPUTED AND SHOWN THE USER.
A PAYOFF IS CALCULATED AND THE USER IS FINALLY INFORMED OF THE OUTCOME OF HIS BET.

-----------------------------------------------------------------
OPTION BEHAVIOR:
THE OPTION PAYS THE DIFFERENCE BETWEEN THE UNDERLYING ASSET
AND THE STRIKE IF IT IS IN THE MONEY, ZERO OTHERWISE.
THERE ARE TWO KNOCK-OUT BARRIERS, A CAP AND A FLOOR: IF THE ASSET
REACHES A BARRIER, THE PRICE IS FIXED UNTIL EXPIRATION.

-----------------------------------------------------------------
PROGRAM DESCRIPTION:
Whenever possible, multiplications are done before divisions, in order 
	to contain remainder approximations.

The user helps generating 3 initial numbers by keeping the Enter key pressed 
	for a while (too small a time is not allowed).
The lowest binary digits of those initial numbers form the basis for new numbers.
Three different combinations of those basis are assembled to form 3 different numbers,
	which	are less predictable than the original ones.
These new numbers are 3 random seeds for 3 Linear Congruential Generators.
Three sequences are thus generated: they contain uniform pseudo-random variables.
The 3 sequences interact to generate one longer-period sequence (still uniforms).
	This one is used as a source of randomness for all the simulations.
Next: 48 uniform variables are used at a time to yeld an approximated gaussian-distributed 
	random variable, relying on the Central Limit theorem.
	The number 48 is a convenient number, it being: 2 squared, times 12.
	Still, it produces better gaussians than 12.
	12 is related to the uniform distribution standard deviation; 4 saves us a square-root computation, 
	which	would complicate matters in an environment where floating-point arithmetic is not available.
The gaussian variable is appropriately standardized and scaled (the values must fit in the registers) 
	and used to form a Geometric Brownian Motion for the prices of the asset.
Then barriers are applied, limiting the asset prices.
A payoff is computed, relative to a strike price.
Using Montecarlo, many payoffs are averaged and discounted to price the derivative.
Some of the asset trajectories are shown in an animated plot, in the text-based console.
Prices are scaled and matched to a row number. If the columns allowed are fewer than 
	the whole trajectory, the plot is split into as many parts as needed.
	The trajectory is rescaled for every example, so that each time the maximum and
	minimum values are placed on the upper and lower rows of the plot.
The strike price is shown as a heavy line: ======

-----------------------------------------------------------------
PARAMETERS FOR THE PROGRAM 

USER MODIFIABLE PARAMETERS [usrPrms.h] file:
The first section of the file contains the parameters that determine the
asset trajectory in time and the behavior of the derivative. The user can modify them.
_days: the number of days the simulation will cover. E.g. Tn = 252
_startPr: price of the asset in T0. It is also the basis for other transformations. 
				20000 performs better in divisions (smaller remainders), 10000 is nicer
_bpDrift: drift of the asset, expressed in basis points, relative to the prices of the GBM
_bpReqStd: the standard deviation which the simulator is required to generate for the asset
_put: whether the option is a put or a call
_strike: the strike price
_cap: the upper barrier
_floor: the lower barrier

DEBUG AND PROGRAM:
Parameters used for debugging and fine-tuning the program.
_nRows, _nCols: rows and columns to display the plot.
 _dbgSd1, _dbgSd2, _dbgSd3: random seeds used to bypass the user-generation section.

CONSTANTS [consts.h] file:
This file should need no modifications.
It is worth mentioning the LOOPS part. Two variables are used to overcome the 16-bit constraint
on the CX register.
_hMcCount * _lMcCount is the number of trajectories Montecarlo runs on.
NOP1 * NOP2 is the number of cycles the program skips between the demonstrative plots.

=================================================================
This file, [main.s], contains the main part of the program:
	- Computes some useful math initializations
	- If the debug flag is on, assigns values and skip parts
	Otherwise:
	- Requires the user to generate 3 numbers as time spans
	- Assembles the numbers into seeds
			the seeds are used to initialize the random sequences
			every sequence generation updates the seeds with the last generated element
	- Runs Montecarlo and stores the payoff
		Also plots the first MAXMCPLT sequences, inserting NOPs to let the user see them
	- Computes one last trajetory and plots it

-----------------------------------------------------------------
ASSEMBLE AS:
./as88 main prFuncs series genrand vars mtCarlo prTraj
