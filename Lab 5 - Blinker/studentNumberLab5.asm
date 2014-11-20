; studentNumberLab5.asm : displays student number on LED Displays
$MODDE2

org 0000H
	LJMP myprogram
	
;For a 33.33 MHz one clock cycle takes 30ns
WaitHalfSec:
	MOV R2, #90
L3:	MOV R1, #250
L2: MOV R0, #250
L1: DJNZ R0, L1 ; 3 machine cycles -> 3*30ns*250=22.5us
	DJNZ R1, L2 ; 22.5us*250=5.6235ms
	DJNZ R2, L3 ; 5.625ms*90=0.5s (approximately)
	ret

myprogram:
	MOV SP, #7FH
	MOV LEDRA, #0
	MOV LEDRB, #0
	MOV LEDRC, #0
	MOV LEDG, #0

M0:
	MOV 91H, #7FH
	MOV 92H, #7FH
	MOV 93H, #7FH
	MOV 94H, #7FH
	MOV 8EH, #7FH
	MOV 8FH, #7FH
	MOV 96H, #7FH
	MOV 97H, #7FH
	LCALL WaitHalfSec
	
	MOV 97H, #79H
	LCALL WaitHalfSec
	
	MOV 96H, #00H
	LCALL WaitHalfSec
	
	MOV 8FH, #12H
	LCALL WaitHalfSec
	
	MOV 8EH, #78H
	LCALL WaitHalfSec
	
	MOV 94H, #79H
	LCALL WaitHalfSec
	
	MOV 93H, #79H
	LCALL WaitHalfSec
	
	MOV 92H, #24H
	LCALL WaitHalfSec
	
	MOV 91H, #12H
	LCALL WaitHalfSec
	LCALL WaitHalfSec
	LCALL WaitHalfSec
	LCALL WaitHalfSec
	
	SJMP M0

END