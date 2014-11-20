; clk_v3.asm: Displays seconds, minuts, and hours in HEX2 to HEX7
; We can set the time by flipping SW0 and using KEY.3, KEY.2, KEY.1
; to increment the Hours, Minutes, and Seconds.

$MODDE2

org 0000H
	ljmp myprogram
	
org 000BH
	ljmp ISR_timer0
	
BSEG
dayTime:   dbit 1

DSEG at 30H
count10ms: ds 1
seconds:   ds 1
minutes:   ds 1
hours:     ds 1

CSEG

; Look-up table for 7-segment displays
myLUT:
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H
    DB 092H, 082H, 0F8H, 080H, 090H
    DB 0FFH ; All segments off

XTAL           EQU 33333333
FREQ           EQU 100
TIMER0_RELOAD  EQU 65538-(XTAL/(12*FREQ))

ISR_Timer0:
	; Reload the timer
    mov TH0, #high(TIMER0_RELOAD)
    mov TL0, #low(TIMER0_RELOAD)
    
    ; Save used register into the stack
    push psw
    push acc
    push dph
    push dpl
    
    jb SWA.0, ISR_Timer0_L0 ; Setting up time.  Do not increment anything
    
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
    cjne A, #12H, NoDayChange
    cpl dayTime
NoDayChange:
    cjne A, #13H, ISR_Timer0_L0
    mov hours, #1
 
ISR_Timer0_L0:

	; Update the display.  This happens every 10 ms
	mov dptr, #myLUT
	
	lcall displayDayTime
	
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

Init_Timer0:	
	mov TMOD,  #00000001B ; GATE=0, C/T*=0, M1=0, M0=1: 16-bit timer
	clr TR0 ; Disable timer 0
	clr TF0
    mov TH0, #high(TIMER0_RELOAD)
    mov TL0, #low(TIMER0_RELOAD)
    setb TR0 ; Enable timer 0
    setb ET0 ; Enable timer 0 interrupt
    ret

myprogram:
	mov SP, #7FH
	mov LEDRA,#0
	mov LEDRB,#0
	mov LEDRC,#0
	mov LEDG,#0
	
	mov seconds, #59H
	mov minutes, #59H
	mov hours, #11H
	clr	daytime

	lcall Init_Timer0
    setb EA  ; Enable all interrupts

M0:
	jnb SWA.0, M0

	jb KEY.3, M1
    jnb KEY.3, $
    mov a, hours
	add a, #1
	da a
	mov hours, a
	cjne A, #12H, NoDayChange2
    cpl dayTime
NoDayChange2:
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
	ljmp M0
	
displayDayTime:
	jb dayTime, day
	mov HEX0, #08H
	ret
day:
	mov HEX0, #8CH
	ret
END
