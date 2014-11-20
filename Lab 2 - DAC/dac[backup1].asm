; dac.asm: uses a R-2R ladder DAC to generate a ramp 
$MODDE2 

org 0000H 
 	ljmp myprogram 
 	
DSEG at 30H
x:	 ds 2
y: 	 ds 2
bcd: ds 3
 	
CSEG

; 100 micro-second delay subroutine 
delay100us: 
	mov R1, #10 
L0: mov R0, #111 
L1: djnz R0, L1 ; 111*30ns*3=10us 
	djnz R1, L0 ; 10*10us=100us, approximately 
	ret 
 
myprogram: 
	mov SP, #7FH ; Set the stack pointer 
	mov LEDRA, #0 ; Turn off all LEDs 
	mov LEDRB, #0 
	mov LEDRC, #0 
	mov LEDG, #0 
	mov P3MOD, #11111111B ; Configure P3.0 to P3.7 as outputs 
	;mov R3, #0 ; Initialize counter to zero 
;Loop:
	;mov P3, R3 
	;inc R3 
	;lcall delay100us
Loop:
	lcall binarySearch1
	mov LEDRA, P3
	lcall delay100us
	lcall binarySearch2
	mov LEDG, P3
	lcall delay100us
	sjmp Loop  
	 
binarySearch1:
;clear stuff
	mov P3, #0
	;lcall delay100uS
;Start Conversion
	setb P3.7
	lcall delay100uS
	jnb P2.0, M1
	clr P3.7
M1: setb P3.6
	lcall delay100uS
	jnb P2.0, M2
	clr P3.6
M2: setb P3.5
	lcall delay100uS
	jnb P2.0, M3
	clr P3.5
M3: setb P3.4
	lcall delay100uS
	jnb P2.0, M4
	clr P3.4
M4: setb P3.3
	lcall delay100uS
	jnb P2.0, M5
	clr P3.3
M5: setb P3.2
	lcall delay100uS
	jnb P2.0, M6
	clr P3.2
M6: setb P3.1
	lcall delay100uS
	jnb P2.0, M7
	clr P3.1
M7: setb P3.0
	lcall delay100uS
	jnb P2.0, M8
	clr P3.0
M8: ret

binarySearch2:
;clear stuff
	mov P3, #0
	lcall delay100uS
;Start Conversion
	setb P3.7
	lcall delay100uS
	jnb P2.1, N1
	clr P3.7
N1: setb P3.6
	lcall delay100uS
	jnb P2.1, N2
	clr P3.6
N2: setb P3.5
	lcall delay100uS
	jnb P2.1, N3
	clr P3.5
N3: setb P3.4
	lcall delay100uS
	jnb P2.1, N4
	clr P3.4
N4: setb P3.3
	lcall delay100uS
	jnb P2.1, N5
	clr P3.3
N5: setb P3.2
	lcall delay100uS
	jnb P2.1, N6
	clr P3.2
N6: setb P3.1
	lcall delay100uS
	jnb P2.1, N7
	clr P3.1
N7: setb P3.0
	lcall delay100uS
	jnb P2.1, N8
	clr P3.0
N8: ret
													
 END 
