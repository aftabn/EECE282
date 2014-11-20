$modde2
	CSEG at 0
	ljmp MyProgram
dseg at 30h
x:    ds 3
bcd:  ds 4
	CSEG
	
myLUT:
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H        
    DB 092H, 082H, 0F8H, 080H, 090H
    
hex2bcd:
	push acc
	push psw
	push AR0
	
	clr a
	mov bcd+0, a
	mov bcd+1, a
	mov bcd+2, a
	mov bcd+3, a
	mov r0, #24 
hex2bcd_L0:
	; Shift binary left
	mov a, x+2
	mov c, acc.7 ; This way x remains unchanged!
	mov a, x+0
	rlc a
	mov x+0, a
	mov a, x+1
	rlc a
	mov x+1, a
	mov a, x+2
	rlc a
	mov x+2, a
    
	; Perform bcd + bcd + carry using BCD arithmetic
	mov a, bcd+0
	addc a, bcd+0
	da a
	mov bcd+0, a
	mov a, bcd+1
	addc a, bcd+1
	da a
	mov bcd+1, a
	mov a, bcd+2
	addc a, bcd+2
	da a
	mov bcd+2, a
	mov a, bcd+3
	addc a, bcd+3
	da a
	mov bcd+3, a
	djnz r0, hex2bcd_L0
	pop AR0
	pop psw
	pop acc
	ret
	
; On the DE2-8052, with a 33.33MHz clock, one cycle takes 30ns
Wait1s:
	mov R2, #88
L3: mov R1, #250
L2: mov R0, #250
L1: jb TF0, incrementReg	
	djnz R0, L1 ; 3 machine cycles-> 3*30ns*250=22.5us
	djnz R1, L2 ; 22.5us*250=5.625ms
	djnz R2, L3 ; 5.625ms*180=1s (approximately)
	ret
	
incrementReg:
	inc x+2
	clr TF0
	sjmp L1
	
;Initializes timer/counter 0 as a 16-bit counter
InitTimer0:
	clr TR0 ; Stop timer 0
	mov a, #11110000B ; Clear the bits of timer 0
	anl a,TMOD
	orl a, #00000101B ; Set timer 0 as 16-bit counter
	mov TMOD, a
	ret
	
MyProgram:
	mov SP, #7FH
	clr a
	mov LEDRA, a
	mov LEDRB, a
	mov LEDRC, a
	mov LEDG, a
	mov bcd+0, a
	mov bcd+1, a
	mov bcd+2, a
	mov bcd+3, a
	lcall display
	
getFreq:
	mov x+0, a
	mov x+1, a
	mov x+2, a
	;lcall clearDisplay
	; Configure T0 as an input (original 8051 only).
	; Not needed but harmless in the DE2-8052
	setb T0
	; 1) Set up the counter to count pulses from T0
	lcall InitTimer0
	; Stop counter 0
	clr TR0
	; 2) Reset the counter
	mov TL0, #0
	mov TH0, #0
	; 3) Start counting
	setb TR0
	; 4) Wait one second
	lcall Wait1s
	; 5) Stop counter 0, TH0-TL0 has the frequency!
	clr TR0
	mov x+0, TL0
	mov x+1, TH0
	lcall hex2bcd
	lcall display
	sjmp getFreq
Display:
	mov dptr, #myLUT
	; Display Digit 0
    mov A, bcd+0
    anl a, #0fh
    movc A, @A+dptr
    mov HEX0, A
	; Display Digit 1
    mov A, bcd+0
    swap a
    anl a, #0fh
    movc A, @A+dptr
    mov HEX1, A
	; Display Digit 2
    mov A, bcd+1
    anl a, #0fh
    movc A, @A+dptr
    mov HEX2, A
	; Display Digit 3
    mov A, bcd+1
    swap a
    anl a, #0fh
    movc A, @A+dptr
    mov HEX3, A
	; Display Digit 4
    mov A, bcd+2
    anl a, #0fh
    movc A, @A+dptr
    mov HEX4, A
	; Display Digit 5
    mov A, bcd+2
    swap a
    anl a, #0fh
    movc A, @A+dptr
    mov HEX5, A
    ; Display Digit 6
    mov A, bcd+3
    anl a, #0fh
    movc A, @A+dptr
    mov HEX6, A
    
    lcall ReplaceZeroes
    ret
    
ReplaceZeroes:
Digit6:
	mov a, bcd+3
	anl a, #1111B
	jnz displayNumber
	mov HEX6, #7FH
Digit5:
	mov a, bcd+2
	anl a, #11110000B
	jnz displayNumber
	mov HEX5, #7FH
Digit4:
	mov a, bcd+2
	anl a, #1111B
	jnz displayNumber
	mov HEX4, #7FH	
Digit3:
	mov a, bcd+1
	anl a, #11110000B
	jnz displayNumber
	mov HEX3, #7FH
Digit2:
	mov a, bcd+1
	anl a, #1111B
	jnz displayNumber
	mov HEX2, #7FH		
Digit1:
	mov a, bcd+0
	anl a, #11110000B
	jnz displayNumber
	mov HEX1, #7FH
displayNumber:
	ret
end