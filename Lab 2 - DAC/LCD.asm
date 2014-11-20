$NOLIST

CSEG
  
goToChannel2:
	ljmp Channel2
	 
goToDo_Nothing:
	ljmp do_nothing

goToAll_done:
	ljmp all_done
			 
ISR_Timer0:
	push psw
    push acc
    push dph
    push dpl
	; Reload the timer
    mov TH0, #high(TIMER0_RELOAD)
    mov TL0, #low(TIMER0_RELOAD)
    
    inc wait200ms
    mov a, wait200ms
    cjne A, #16, continueChannelSelect
    mov wait200ms, #0
    
    mov a, notes
    inc a
    mov notes, a
    cjne A, #26, continueChannelSelect
    mov notes, #0
    
continueChannelSelect:    
    ;jb KEY.3, goToDo_Nothing
    
    ;inc count10ms
    ;mov a, count10ms
    ;cjne A, #100, goToAll_Done
    ;mov count10ms, #0

    cpl P0.1
	jb SWA.0, GoToChannel2
		
Channel1:
	clr channel
	mov a, #80H
	lcall LCD_command

	mov a, #'C'
	lcall LCD_put
	mov a, #'H'
	lcall LCD_put
	mov a, #'A'
	lcall LCD_put
	mov a, #'N'
	lcall LCD_put
	mov a, #'N'
	lcall LCD_put
	mov a, #'E'
	lcall LCD_put
	mov a, #'L'
	lcall LCD_put
	mov a, #' '
	lcall LCD_put
	mov a, #'1'
	lcall LCD_put
	mov a, #'/'
	lcall LCD_put
	mov a, #'G'
	lcall LCD_put
	mov a, #'R'
	lcall LCD_put
	mov a, #'E'
	lcall LCD_put
	mov a, #'E'
	lcall LCD_put
	mov a, #'N'
	lcall LCD_put
	
	mov a, #0C0H
	lcall LCD_command
	
	mov a, #'V'
	lcall LCD_put
	mov a, #'1'
	lcall LCD_put
	mov a, #' '
	lcall LCD_put
	mov a, #'I'
	lcall LCD_put
	mov a, #'S'
	lcall LCD_put
	mov a, #' '
	lcall LCD_put
	mov a, #'R'
	lcall LCD_put
	mov a, #'O'
	lcall LCD_put
	mov a, #'U'
	lcall LCD_put
	mov a, #'G'
	lcall LCD_put
	mov a, #'H'
	lcall LCD_put
	mov a, #'L'
	lcall LCD_put
	mov a, #'Y'
	lcall LCD_put
	mov a, #':'
	lcall LCD_put
	ljmp all_done
	
Channel2:
	setb channel
	mov a, #80H
	lcall LCD_command

	mov a, #'C'
	lcall LCD_put
	mov a, #'H'
	lcall LCD_put
	mov a, #'A'
	lcall LCD_put
	mov a, #'N'
	lcall LCD_put
	mov a, #'N'
	lcall LCD_put
	mov a, #'E'
	lcall LCD_put
	mov a, #'L'
	lcall LCD_put
	mov a, #' '
	lcall LCD_put
	mov a, #'2'
	lcall LCD_put
	mov a, #'/'
	lcall LCD_put
	mov a, #'R'
	lcall LCD_put
	mov a, #'E'
	lcall LCD_put
	mov a, #'D'
	lcall LCD_put
	mov a, #' '
	lcall LCD_put
	mov a, #' '
	lcall LCD_put
	
	mov a, #0C0H
	lcall LCD_command
	
	mov a, #'V'
	lcall LCD_put
	mov a, #'2'
	lcall LCD_put
	mov a, #' '
	lcall LCD_put
	mov a, #'I'
	lcall LCD_put
	mov a, #'S'
	lcall LCD_put
	mov a, #' '
	lcall LCD_put
	mov a, #'R'
	lcall LCD_put
	mov a, #'O'
	lcall LCD_put
	mov a, #'U'
	lcall LCD_put
	mov a, #'G'
	lcall LCD_put
	mov a, #'H'
	lcall LCD_put
	mov a, #'L'
	lcall LCD_put
	mov a, #'Y'
	lcall LCD_put
	mov a, #':'
	lcall LCD_put		
all_done:
	lcall loadSymphony5
	pop dpl
	pop dph
	pop acc
	pop psw 			
Do_nothing:
	reti

ISR_timer2:
	clr TF2
	cpl P0.0
	reti 
	
Init_Timer:
	;Timer 0	
	mov TMOD,  #00010001B ; GATE=0, C/T*=0, M1=0, M0=1: 16-bit timer
	clr TR0 ; Disable timer 0
	clr TF0
    mov TH0, #high(TIMER0_RELOAD)
    mov TL0, #low(TIMER0_RELOAD)
    setb TR0 ; Enable timer 0
    setb ET0
    
    ;Timer 2
    setb PT2
    mov T2CON, #00H ; Autoreload is enabled, work as a timer
    clr TR2
    clr TF2
    ; Set up timer 2 to interrupt every 10ms
    mov RCAP2H,#high(TIMER0_RELOAD)
    mov RCAP2L,#low(TIMER0_RELOAD)
    setb ET2
    ret
    	  
Wait40us:
	mov R0, #149
X1: 
	nop
	nop
	nop
	nop
	nop
	nop
	djnz R0, X1 ; 9 machine cycles-> 9*30ns*149=40us
    ret
    
LCD_command:
	mov	LCD_DATA, A
	clr	LCD_RS
	nop
	nop
	setb LCD_EN ; Enable pulse should be at least 230 ns
	nop
	nop
	nop
	nop
	nop
	nop
	clr	LCD_EN
	ljmp Wait40us

LCD_put:
	mov	LCD_DATA, A
	setb LCD_RS
	nop
	nop
	setb LCD_EN ; Enable pulse should be at least 230 ns
	nop
	nop
	nop
	nop
	nop
	nop
	clr	LCD_EN
	ljmp Wait40us
    
init_LCD:    
    ; Turn LCD on, and wait a bit.
    setb LCD_ON
    clr LCD_EN  ; Default state of enable must be zero
    lcall Wait40us
    
    mov LCD_MOD, #0xff ; Use LCD_DATA as output port
    clr LCD_RW ;  Only writing to the LCD in this code.
	
	mov a, #0ch ; Display on command
	lcall LCD_command
	mov a, #38H ; 8-bits interface, 2 lines, 5x7 characters
	lcall LCD_command
	mov a, #01H ; Clear screen (Warning, very slow command!)
	lcall LCD_command
    
    ; Delay loop needed for 'clear screen' command above (1.6ms at least!)
   	mov R1, #40
    
Clr_loop:	
	lcall Wait40us
	djnz R1, Clr_loop
	ret
	
$LIST
