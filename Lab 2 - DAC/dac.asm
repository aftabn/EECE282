; dac.asm: uses a R-2R ladder DAC to generate a ramp 
$MODDE2 

org 0000H 
 	ljmp myprogram 

org 000BH
	ljmp ISR_timer0
	
org 002BH
	ljmp ISR_timer2	

BSEG
playing: dbit 1
channel: dbit 1
		
DSEG at 30H
count10ms: ds 1
wait200ms: ds 1
notes: ds 1
x:	 ds 2
y: 	 ds 2
bcd: ds 3
 	
CSEG

$include(HEXs.asm)
$include(LCD.asm)
 	
myLUT:
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H
    DB 092H, 082H, 0F8H, 080H, 090H
    DB 0FFH ; All segments off

BITVOLTAGE	  EQU 130
CLK           EQU 33333333
TIMER0_RELOAD EQU 65536-(CLK/1200)
NOTE_A5  EQU 63958
NOTE_B5  EQU 64130
NOTE_C6  EQU 64209
NOTE_D6  EQU 64354
NOTE_D6S EQU 64420
NOTE_E6  EQU 64483
NOTE_F6  EQU 64542
NOTE_G6  EQU 64650
NOTE_A6  EQU 64747
NOTE_B6  EQU 64833
NOTE_C7  EQU 64872
     	
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
	mov P0MOD, #00000011B
	setb P0.0
	
	lcall init_Timer
	lcall init_LCD
	setb EA
	
	;mov R3, #0 ; Initialize counter to zero 
;Loop:
	;mov P3, R3 
	;inc R3 
	;lcall delay100us

Loop:
	lcall binarySearch1
	mov LEDRA, P3
	lcall delay100us
	mov R6, P3
	
	lcall binarySearch2
	mov LEDG, P3
	lcall delay100us
	mov R7, P3
	
	lcall calculateVoltage
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
