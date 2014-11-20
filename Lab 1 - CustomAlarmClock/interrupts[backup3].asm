$MODDE2

org 0000H
	ljmp myprogram
	
org 000BH
	ljmp ISR_timer0
	
org 001BH
	ljmp ISR_timer1

org 002BH
	ljmp ISR_timer2
	
BSEG
meridian:     dbit 1
meridianAlarm: dbit 1

DSEG at 30H
count10ms: ds 1
seconds:   ds 1
minutes:   ds 1
hours:     ds 1
secAlarm:  ds 1
minAlarm:  ds 1
hourAlarm: ds 1

CSEG

; Look-up table for 7-segment displays
myLUT:
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H
    DB 092H, 082H, 0F8H, 080H, 090H
    DB 0FFH ; All segments off

CLK           EQU 33333333
FREQ           EQU 100
B_FREQ 		   EQU 2000
TIMER0_RELOAD  EQU 65536-(CLK/(12*FREQ))
TIMER2_RELOAD  EQU 65536-(CLK/(12*2*B_FREQ))

ISR_Timer0:
	; Reload the timer
    mov TH0, #high(TIMER0_RELOAD)
    mov TL0, #low(TIMER0_RELOAD)
    
    ; Save used register into the stack
    push psw
    push acc
    push dph
    push dpl
    
    cpl P0.1
    
    jb SWA.0, ISR_Timer0_L0 ; Setting up time.  Do not increment anything
    jb SWA.1, ISR_Timer0_L0 ; Setting up alarm. Ain't gon' increment shit
    
    ;Check if clock time matches alarm time
    ;lcall AlarmCheck
    
    ; Increment the counter and check if a second has passed
    inc count10ms
    mov a, count10ms
    cjne A, #100, ISR_Timer0_L0
    mov count10ms, #0
    
    mov a, seconds
    add a, #1
    da a
    mov seconds, a
    cjne A, #60H, ISR_Timer0_L0
    mov seconds, #0
	
    mov a, minutes
    add a, #1
    da a
    mov minutes, a
    cjne A, #60H, ISR_Timer0_L0
    mov minutes, #0
	
    mov a, hours
    add a, #1
    da a
    mov hours, a
    cjne A, #12H, NoMeridianChange1
    cpl meridian
NoMeridianChange1:
    cjne A, #13H, ISR_Timer0_L0
    mov hours, #1
    
ISR_Timer0_L0:
	; Update the display.  This happens every 10 ms
	mov dptr, #myLUT
	
	lcall displayMeridian
	
	mov a, seconds
	anl a, #0fH
	movc a, @a+dptr
	mov HEX2, a
	mov a, seconds
	swap a
	anl a, #0fH
	movc a, @a+dptr
	mov HEX3, a
	
	mov a, minutes
	anl a, #0fH
	movc a, @a+dptr
	mov HEX4, a
	mov a, minutes
	swap a
	anl a, #0fH
	movc a, @a+dptr
	mov HEX5, a

	mov a, hours
	anl a, #0fH
	movc a, @a+dptr
	mov HEX6, a
	mov a, hours
	jb acc.4, ISR_Timer0_L1
	mov a, #0A0H
ISR_Timer0_L1:
	swap a
	anl a, #0fH
	movc a, @a+dptr
	mov HEX7, a

	; Restore used registers
	pop dpl
	pop dph
	pop acc
	pop psw    
	reti

ISR_Timer1:
	; Reload the timer
    mov a, minutes
    add a, #1
    da a
    mov TH1, #high(TIMER0_RELOAD)
    mov TL1, #low(TIMER0_RELOAD)
    
    ; Save used register into the stack
    push psw
    push acc
    push dph
    push dpl

    ; Increment the counter and check if a second has passed
    inc count10ms
    mov a, count10ms
    cjne A, #100, ISR_Timer1_L0
    mov count10ms, #0
    
    mov a, seconds
    add a, #1
    da a
    mov seconds, a
    cjne A, #60H, ISR_Timer1_L0
    mov seconds, #0

    mov a, minutes
    add a, #1
    da a
    mov minutes, a
    cjne A, #60H, ISR_Timer1_L0
    mov minutes, #0

    mov a, hours
    add a, #1
    da a
    mov hours, a
    cjne A, #12H, NoMeridianChange2
    cpl meridian
NoMeridianChange2:
    cjne A, #13H, ISR_Timer1_L0
    mov hours, #1
 
ISR_Timer1_L0:
	; Update the display.  This happens every 10 ms
	mov dptr, #myLUT
	
	lcall displayMeridianAlarm
	
	mov a, secAlarm
	anl a, #0fH
	movc a, @a+dptr
	mov HEX2, a
	mov a, secAlarm
	swap a
	anl a, #0fH
	movc a, @a+dptr
	mov HEX3, a
	
	mov a, minAlarm
	anl a, #0fH
	movc a, @a+dptr
	mov HEX4, a
	mov a, minAlarm
	swap a
	anl a, #0fH
	movc a, @a+dptr
	mov HEX5, a
	
	mov a, hourAlarm
	anl a, #0fH
	movc a, @a+dptr
	mov HEX6, a
	mov a, hourAlarm
	jb acc.4, ISR_Timer1_L1
	mov a, #0A0H
ISR_Timer1_L1:
	swap a
	anl a, #0fH
	movc a, @a+dptr
	mov HEX7, a

	; Restore used registers
	pop dpl
	pop dph
	pop acc
	pop psw    
	reti

ISR_timer2:
	clr TF2
	cpl P0.0
	reti 
	
Init_Timers:
	;Timer 0	
	mov TMOD,  #00010001B ; GATE=0, C/T*=0, M1=0, M0=1: 16-bit timer
	clr TR0 ; Disable timer 0
	clr TF0
    mov TH0, #high(TIMER0_RELOAD)
    mov TL0, #low(TIMER0_RELOAD)
    setb TR0 ; Enable timer 0
    setb ET0 ; Enable timer 0 interrupt
    
    ;Timer 1
    clr TR1 ; Disable timer 1
	clr TF1
    mov TH1, #high(TIMER0_RELOAD)
    mov TL1, #low(TIMER0_RELOAD)
    setb ET1 ; Enable timer 1 interrupt
    
    setb PT2
    mov T2CON, #00H ; Autoreload is enabled, work as a timer
    clr TR2
    clr TF2
    ; Set up timer 2 to interrupt every 10ms
    mov RCAP2H,#high(TIMER2_RELOAD)
    mov RCAP2L,#low(TIMER2_RELOAD)
    setb ET2
    ret

myprogram:
	mov SP, #7FH
	mov LEDRA,#0
	mov LEDRB,#0
	mov LEDRC,#0
	mov LEDG,#0
	mov P0MOD, #00000011B
	setb P0.0
	
	mov seconds, #00H
	mov minutes, #00H
	mov hours, #08H
	clr	meridian
	
	mov secAlarm, #00H
	mov minAlarm, #00H
	mov hourAlarm, #08H
	clr	meridianAlarm
	

	lcall Init_Timers
    setb EA  ; Enable all interrupts

Choice:
	lcall alarmCheck
	jb SWA.0, M0
	jb SWA.1, Alarm
	sjmp Choice
	
; Setting the clock	
M0:	
	jb KEY.3, M1
    jnb KEY.3, $
    mov a, hours
	add a, #1
	da a
	mov hours, a
	cjne A, #12H, NoMeridianChange3
    cpl meridian
NoMeridianChange3:
    cjne A, #13H, M1
    mov hours, #1

M1:	
	jb KEY.2, M2
    jnb KEY.2, $
    mov a, minutes
	add a, #1
	da a
	mov minutes, a
    cjne A, #60H, M2
    mov minutes, #0

M2:	
	jb KEY.1, M3
	jnb KEY.1, $
	mov a, seconds
	add a, #1
	da a
	mov seconds, a
    cjne A, #60H, M3
    mov seconds, #0

M3:	
	jnb SWA.0, Choice
	ljmp M0

; Alarm mode
	
Alarm:
	lcall setAlarmTime
N0:
	jb KEY.3, N1
    jnb KEY.3, $
    mov a, hourAlarm
	add a, #1
	da a
	mov hourAlarm, a
	cjne A, #12H, NoMeridianChange4
    cpl meridianAlarm
NoMeridianChange4:
    cjne A, #13H, N1
    mov hourAlarm, #1

N1:	
	jb KEY.2, N2
    jnb KEY.2, $
    mov a, minAlarm
	add a, #1
	da a
	mov minAlarm, a
    cjne A, #60H, N2
    mov minAlarm, #0

N2:	
	jb KEY.1, N3
	jnb KEY.1, $
	mov a, secAlarm
	add a, #1
	da a
	mov secAlarm, a
    cjne A, #60H, N3
    mov secAlarm, #0

N3:	
	jnb SWA.1, restoreTime
	ljmp N0

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
	
setAlarmTime:
	clr TR0
	setb TR1
	ret
	
restoreTime:
	clr TR1
	setb TR0
	ljmp Choice
	
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
