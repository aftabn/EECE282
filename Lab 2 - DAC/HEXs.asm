$NOLIST

CSEG

calculateVoltage:
	mov x+0, #low(BITVOLTAGE)
	mov x+1, #0
	mov y+1, #0
	
	jnb channel, V2		
V1:
	mov y+0, R6
	sjmp displayIt
V2:
	mov y+0, R7
	
displayIt:		
	lcall mul16
	lcall hex2bcd
	lcall display
	lcall songCheck	
	ret

songCheck:
	clr c
	jnb channel, S1		
S1:
	mov a, R6
	sjmp coninueSongLoad
S2:
	mov a, R7
coninueSongLoad:
	subb a, #11101110B
	jz alreadyRunning
	clr TR2
	clr playing
	ret
alreadyRunning:
	jnb playing, setSong
	ret	
setSong:
	mov notes, #0
	mov wait200ms, #0
	setb TR2
	setb playing
	ret
			
Display:
	mov dptr, #myLUT
	; Display Digit 0
    mov A, bcd+0
    anl a, #0fh
    movc A, @A+dptr
    mov HEX2, A
	; Display Digit 1
    mov A, bcd+0
    swap a
    anl a, #0fh
    movc A, @A+dptr
    mov HEX3, A
	; Display Digit 2
    mov A, bcd+1
    anl a, #0fh
    movc A, @A+dptr
    mov HEX4, A
	; Display Digit 3
    mov A, bcd+1
    swap a
    anl a, #0fh
    movc A, @A+dptr
    mov HEX5, A
	; Display Digit 4
    mov A, bcd+2
    anl a, #0fh
    movc A, @A+dptr
    mov HEX6, A
    ret

hex2bcd:
	push acc
	push psw
	push AR0
	
	clr a
	mov bcd+0, a ; Initialize BCD to 00-00-00 
	mov bcd+1, a
	mov bcd+2, a
	mov r0, #16  ; Loop counter.
	    
hex2bcd_L0:
	; Shift binary left	
	mov a, x+1
	mov c, acc.7 ; This way x remains unchanged!
	mov a, x+0
	rlc a
	mov x+0, a
	mov a, x+1
	rlc a
	mov x+1, a
    
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

	djnz r0, hex2bcd_L0

	pop AR0
	pop psw
	pop acc
	ret

;------------------------------------------------
; x = x * y
;------------------------------------------------
mul16:
	push acc
	push b
	push psw
	push AR0
	push AR1
		
	; R0 = x+0 * y+0
	; R1 = x+1 * y+0 + x+0 * y+1
	
	; Byte 0
	mov	a,x+0
	mov	b,y+0
	mul	ab		; x+0 * y+0
	mov	R0,a
	mov	R1,b
	
	; Byte 1
	mov	a,x+1
	mov	b,y+0
	mul	ab		; x+1 * y+0
	add	a,R1
	mov	R1,a
	clr	a
	addc a,b
	mov	R2,a
	
	mov	a,x+0
	mov	b,y+1
	mul	ab		; x+0 * y+1
	add	a,R1
	mov	R1,a
	
	mov	x+1,R1
	mov	x+0,R0

	pop AR1
	pop AR0
	pop psw
	pop b
	pop acc
	
	ret	
	
loadSymphony5:
	mov a, notes
	cjne a, #0, C_1
	mov RCAP2H,#high(NOTE_G6)
    mov RCAP2L,#low(NOTE_G6)
    ret 
C_1:
	cjne a, #1, C_2
	mov RCAP2H,#high(NOTE_G6)
    mov RCAP2L,#low(NOTE_G6)
    ret 
C_2:
	cjne a, #2, C_3
	mov RCAP2H,#0
    mov RCAP2L,#0
    ret 
C_3:
	cjne a, #3, C_4
	mov RCAP2H,#high(NOTE_G6)
    mov RCAP2L,#low(NOTE_G6)
    ret	 
C_4:
	cjne a, #4, C_5
	mov RCAP2H,#high(NOTE_G6)
    mov RCAP2L,#low(NOTE_G6)
    ret	 
C_5:
	cjne a, #5, C_6
	mov RCAP2H,#0
    mov RCAP2L,#0
    ret 
C_6:
	cjne a, #6, C_7
	mov RCAP2H,#high(NOTE_G6)
    mov RCAP2L,#low(NOTE_G6)
    ret	 
C_7:
	cjne a, #7, C_8
	mov RCAP2H,#high(NOTE_G6)
    mov RCAP2L,#low(NOTE_G6)
    ret	 
C_8:
	cjne a, #8, C_9
	mov RCAP2H,#0
    mov RCAP2L,#0
	ret
C_9:
	cjne a, #9, C_10
	mov RCAP2H,#high(NOTE_D6S)
    mov RCAP2L,#low(NOTE_D6S)
    ret 	
C_10:
	cjne a, #10, C_11
	mov RCAP2H,#high(NOTE_D6S)
    mov RCAP2L,#low(NOTE_D6S)
	ret
C_11:
	cjne a, #11, C_12
	mov RCAP2H,#high(NOTE_D6S)
    mov RCAP2L,#low(NOTE_D6S)
    ret 	
C_12:
	cjne a, #12, C_13
	mov RCAP2H,#0
    mov RCAP2L,#0	
	ret
C_13:
	cjne a, #13, C_14
	mov RCAP2H,#high(NOTE_F6)
    mov RCAP2L,#low(NOTE_F6)
    ret 
C_14:
	cjne a, #14, C_15
	mov RCAP2H,#high(NOTE_F6)
    mov RCAP2L,#low(NOTE_F6)
    ret 
C_15:
	cjne a, #15, C_16
	mov RCAP2H,#0
    mov RCAP2L,#0
    ret 
C_16:
	cjne a, #16, C_17
	mov RCAP2H,#high(NOTE_F6)
    mov RCAP2L,#low(NOTE_F6)
    ret	 
C_17:
	cjne a, #17, C_18
	mov RCAP2H,#high(NOTE_F6)
    mov RCAP2L,#low(NOTE_F6)
    ret	 
C_18:
	cjne a, #18, C_19
	mov RCAP2H,#0
    mov RCAP2L,#0
    ret 
C_19:
	cjne a, #19, C_20
	mov RCAP2H,#high(NOTE_F6)
    mov RCAP2L,#low(NOTE_F6)
    ret	 
C_20:
	cjne a, #20, C_21
	mov RCAP2H,#high(NOTE_F6)
    mov RCAP2L,#low(NOTE_F6)
    ret	 
C_21:
	cjne a, #21, C_22
	mov RCAP2H,#0
    mov RCAP2L,#0
	ret
C_22:
	cjne a, #22, C_23
	mov RCAP2H,#high(NOTE_D6)
    mov RCAP2L,#low(NOTE_D6)
    ret 	
C_23:
	cjne a, #23, C_24
	mov RCAP2H,#high(NOTE_D6)
    mov RCAP2L,#low(NOTE_D6)
	ret
C_24:
	cjne a, #24, C_25
	mov RCAP2H,#high(NOTE_D6)
    mov RCAP2L,#low(NOTE_D6)
    ret
C_25:
	mov RCAP2H,#0
    mov RCAP2L,#0
    ret 
    
$LIST	