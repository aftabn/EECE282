$NOLIST
;Note file for extra features

CSEG

lightDance:
	mov LEDRA, #0
	mov LEDRB, #0
	mov LEDRC, #0
	lcall wait
	mov LEDRA, #00000001B
	lcall wait
	mov LEDRA, #00000010B
	lcall wait
	mov LEDRA, #00000100B
	lcall wait
	mov LEDRA, #00001000B
	lcall wait
	mov LEDRA, #00010000B
	lcall wait
	mov LEDRA, #00100000B
	lcall wait
	mov LEDRA, #01000000B
	lcall wait
	mov LEDRA, #10000000B
	lcall wait
	mov LEDRA, #0
	mov LEDRB, #00000001B
	lcall wait
	mov LEDRB, #00000010B
	lcall wait
	mov LEDRB, #00000100B
	lcall wait
	mov LEDRB, #00001000B
	lcall wait
	mov LEDRB, #00010000B
	lcall wait
	mov LEDRB, #00100000B
	lcall wait
	mov LEDRB, #01000000B
	lcall wait
	mov LEDRB, #10000000B
	lcall wait
	mov LEDRB, #0
	mov LEDRC, #1
	lcall wait
	mov LEDRC, #2
	lcall wait
	mov LEDRC, #0
	ret

displayMeridian:
	jb meridian, night
	mov HEX0, #08H
	ret
night:
	mov HEX0, #8CH
	ret

displayMeridianAlarm:
	jb meridianAlarm, night2
	mov HEX0, #08H
	ret
night2:
	mov HEX0, #8CH
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
    
wait:
	mov R2, #2
W3: mov R1, #250
W2: mov R0, #250
W1: djnz R0, W1
	djnz R1, W2
	djnz R2, W3
	ret
    
alarmCheck:
    clr c
	mov a, meridian
	subb a, meridianAlarm
	jz hourCheck
	ret
hourCheck:
	clr c
	mov a, hours
	subb a, hourAlarm
	jz minCheck
	ret
minCheck:
	clr c
	mov a, minutes
	subb a, minAlarm
	jz secCheck
	ret
secCheck:
	clr c
	mov a, seconds
	subb a, secAlarm
	jz alarmSetCheck
	ret
alarmSetCheck:
	jb SWA.2, triggerAlarm
	ret
triggerAlarm:
	mov notes, #0
	mov wait200ms, #0
	setb TR2
waitForButton:
	lcall lightDance
	jb KEY.3, waitForButton
	jnb KEY.3, $
	clr TR2
	ret
END