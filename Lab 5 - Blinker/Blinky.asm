; Blinky.asm : blinks LEDR0 of the DE2-8052 each second.
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
	CPL LEDRA.0
	LCALL WaitHalfSec
	SJMP M0

END