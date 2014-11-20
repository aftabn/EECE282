$NOLIST
;Note file for extra features

CSEG

;SR to cycle though symphony #5 starting
changeNote:
	push acc
	push psw
;First check which note sequence it's on
noteCheck:
	mov a, #noteCount
	
	equalCheck a, #0
	equalCheck a, #1
	equalCheck a, #2
	equalCheck a, #6
	equalCheck a, #7
	equalCheck a, #8
	equalCheck a, #12
	equalCheck a, #13
	equalCheck a, #14
	jb equal, NoteG6
	
	equalCheck a, #3
	equalCheck a, #4
	equalCheck a, #5
	equalCheck a, #9
	equalCheck a, #10
	equalCheck a, #11
	equalCheck a, #15
	equalCheck a, #16
	equalCheck a, #17
	jb equal, NoteZero
	
	equalCheck a, #18
	equalCheck a, #19
	equalCheck a, #20
	equalCheck a, #21
	equalCheck a, #22
	equalCheck a, #23
	equalCheck a, #24
	equalCheck a, #25
	equalCheck a, #26
	jb equal, NoteD6S
	sjmp endSequenceCheck
	
NoteG6:
	mov RCAP2H,#high(NOTE_G6)
    mov RCAP2L,#low(NOTE_G6)
	sjmp endSequenceCheck
NoteZero:
	mov RCAP2H,#0
    mov RCAP2L,#0
	sjmp endSequenceCheck
NoteD6S:
	mov RCAP2H,#high(NOTE_D6S)
    mov RCAP2L,#low(NOTE_D6S)
	sjmp endSequenceCheck
NoteD6:
	mov RCAP2H,#high(NOTE_D6)
    mov RCAP2L,#low(NOTE_D6)
	sjmp endSequenceCheck	
NoteF6:
	mov RCAP2H,#high(NOTE_F6)
    mov RCAP2L,#low(NOTE_F6)
	sjmp endSequenceCheck
	
endSequenceCheck:
    inc a
	cjne a, #27, doneReload
	mov a, #0
doneReload:
	mov noteCount, a
	clr equal
	pop psw
	pop acc
ret
 
;Macro to check if two numbers are equal	
equalCheck MAC
	push acc
	push psw
	clr equals
	clr c
	mov a, #%0
	subb a, #%1
	jnz doneEqualCheck
	setb equal
doneEqualCheck:
	pop psw
	pop acc
ENDMAC
	
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
	jz triggerAlarm
	ret
triggerAlarm:
	setb TR2
waitForButton:
	jb KEY.3, waitForButton
	jnb KEY.3, $
	clr TR2
	ret
END