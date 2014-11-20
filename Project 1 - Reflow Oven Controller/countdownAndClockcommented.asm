$NOLIST

;//ISR for Timer Zero
;//Functions:
;//1a)Increments the elapsed time every second
;//1b)Decrements the countdown every second (provided it's in a state that requires a countdown)
;//2)Keeps the hex display cleared until user confirms the settings
;//3)Updates the hex every 10 ms once process has started
;//4)Performs the following checks every 10 ms:
;//     a)Start bit check: has the user confirmed the settings?
;//     b)State bit check: what state is the program currently in?
;//     c)Emergency stop check: has the user hit the kill button?
;//     d)Countdown check: has the countdown reached zero?
;//     e)Temperature check: has the oven reached the temp. input by the user?
;//     **Note: checks (d) and (e) are state dependent**

ISR_Timer0:
	; Reload the timer
    mov TH0, #high(TIMER0_RELOAD)
    mov TL0, #low(TIMER0_RELOAD)
    
    ; Save used register into the stack
    push psw
    push b
    push acc
    push dph
    push dpl
    
ISR_0:
	
	lcall EmergencyStop
	
	;Checks if a state needs to change
    lcall checkState
	
    ;Increment the counter and check if a second has passed	
    
    jb started, startClock
    mov HEX0, #0FFH
    mov HEX1, #0FFH
    mov HEX2, #0FFH
    mov HEX3, #0FFH
    mov HEX4, #0FFH
    mov HEX5, #0FFH
    mov HEX6, #0FFH
    mov HEX7, #0FFH
    ljmp ISR_end
     
startClock:  
	inc delaySPI
	mov a, delaySPI
	cjne a, #60, continueSeconds
	mov delaySPI, #0
	
	;Updates the LCD screen with temp values
    mov a, #0C0H
	lcall LCD_command
	mov dptr, #currentTemp_Str
	lcall writeString
	
	mov a, bcdCTemp+2
	lcall LCD_put
	mov a, bcdCTemp+1
	lcall LCD_put
	mov a, bcdCTemp+0
	lcall LCD_put
	mov a, #'C'
	lcall LCD_put
	
	mov dptr, #junctionTemp_Str
	lcall writeString
	
	mov a, bcdJTemp+2
	lcall LCD_put
	mov a, bcdJTemp+1
	lcall LCD_put
	mov a, bcdJTemp+0
	lcall LCD_put
	mov a, #'C'
	lcall LCD_put
	
	
	
continueSeconds:	
	;Waits until a seconds has passed  
	inc count10ms
    mov a, count10ms
    clr secondPassed
    cjne A, #100, ISR_Timer0_L0
    setb secondPassed
    mov count10ms, #0
	
	;Writes stuff to the SPI (Python)
	mov a, BCDCTemp+2
	lcall putchar
	mov a, BCDCTemp+1
	lcall putchar
	mov a, BCDCTemp+0
	lcall putchar
	mov a, #'\r'
	lcall putchar
	mov a, #'\n'
	lcall putchar
	
	;Elapsed time math
    mov a, sec
    add a, #1
    da a
    mov sec, a
    cjne A, #60H, ISR_Timer0_L0
    mov sec, #0
 
    mov a, min
    add a, #1
    da a
    mov min, a
    cjne A, #60H, ISR_Timer0_L0
    mov min, #0

ISR_Timer0_L0:

	; Update the display.  This happens every 10 ms
	mov dptr, #myLUT
	
	mov a, sec
	anl a, #0fH
	movc a, @a+dptr
	mov HEX4, a
	mov a, sec
	swap a
	anl a, #0fH
	movc a, @a+dptr
	mov HEX5, a

	mov a, min
	anl a, #0fH
	movc a, @a+dptr
	mov HEX6, a
	mov a, min
	swap a
	anl a, #0fH
	movc a, @a+dptr
	mov HEX7, a 

	jnb secondPassed, ISR_End
		
	jb soak, ISR_Timer_Countdown ;go to countdown
    jb reflow, ISR_Timer_Countdown
    
    mov HEX0, #0FFH
    mov HEX1, #0FFH
    mov HEX2, #0FFH
    mov HEX3, #0FFH
    
    sjmp ISR_End
       
ISR_Timer_Countdown:
    mov a, secAlarm
    anl a, #00FH
    cjne A, #0, regularSec ;can we subtract from lsb seconds?
    mov a, secAlarm ;nope, need to borrow
    anl a, #0F0H
    swap a
    cjne a, #0, borrowmsbSec ;can we borrow from msb seconds?
   	
   	;Called minAlarm but actually hundreds digit of seconds
   	mov a, minAlarm
    anl a, #00FH
    cjne A, #0, borrowLSBMin
    mov LEDRA, #0FFH ;celebrate with lights! COUNTER DONE
    sjmp displayCountdown
    
regularSec: ; -- -- -- ## case
 	mov a, secAlarm
	subb a, #1
	mov secAlarm, a
	sjmp displayCountdown

borrowmsbSec: ;-- -- #0 case
    subb a, #1
    orl a, #10010000B
    swap a
    mov secAlarm, a
    sjmp displayCountdown
        
borrowlsbMin: ;-- ## 00 case
	mov a, minAlarm
	subb a, #1
	mov minAlarm, a
	mov secAlarm, #99H
	sjmp displayCountdown

;-----------------------
displayCountdown:
	mov a, secAlarm
	anl a, #0fH
	movc a, @a+dptr
	mov HEX0, a
	mov a, secAlarm
	swap a
	anl a, #0fH
	movc a, @a+dptr
	mov HEX1, a
	mov a, minAlarm
	anl a, #0fh
	movc a, @a+dptr
	mov HEX2, a
	
ISR_End:
	; Restore used registers
	pop dpl
	pop dph
	pop acc
	pop b
	pop psw    
	reti
	
init_Timers:	
	;TIMER 0 (USED FOR CLOCK/DISPLAY/STATE CHANGE CHECKS)
	mov TMOD,  #00010001B ; GATE=0, C/T*=0, M1=0, M0=1: 16-bit timer
	clr TR0 
	clr TF0
    mov TH0, #high(TIMER0_RELOAD)
    mov TL0, #low(TIMER0_RELOAD)
    setb TR0
    setb ET0
    
    ;TIMER 1 (USED FOR BUZZERS)
    mov TMOD,  #00010001B ; GATE=0, C/T*=0, M1=0, M0=1: 16-bit timer
	clr TR1
	clr TF1
    mov TH1, #high(TIMER1_RELOAD)
    mov TL1, #low(TIMER1_RELOAD)
    setb TR1
    
    ret	

;//Emergency Stop
;//FUNCTION:
;//Checks if kill switch, key1, has been pressed. If it has,
;//Emergency bit is set.

EmergencyStop:
	jb KEY.1, FalseAlarm  
	setb Emergency
FalseAlarm:
	ret

;//Check State
;//FUNCTION:
;//Checks each state bit to determine what state the 
;//program is currently in. Then performs the checks
;//corresponding to the current state.

checkState:
	jb preSoak, preSoakTempCheck
	jb soak, soakTimeAndTempCheck
	jb preReflow, preReflowTempCheck
	jb reflow, reflowTimeAndTempCheck
	jb cooling, coolingCheck
	ret

;HEATING UP TO SOAK TEMP

;//Presoak Temp Check
;//FUNCTION:
;//Called during the presoak state. Checks if oven temperature is
;//within 20 degrees of soak temp set by user. Shuts off oven once 
;//said temperature has been reached to avoid overshooting the mark.

preSoakTempCheck:
	setb P3.7
	setb P3.0
	clr c
	mov a, soakTemp
	subb a, #20
	subb a, currentTemp
	jc changeToSoak
	ret
changeToSoak:	
	clr preSoak
	ret

;THIS CONTROLS OVEN TEMP AND CHECKS IF THE TIME IS UP FOR
;THE SOAK STATE
;//Soak Time and Temp Check
;//FUNCTION:
;//Called during soak state. Checks if countdown has reached zero while monitoring
;//the temperature to ensure it remains at the soak temperature specified by the user.
;//If the temperature falls 20 degrees below the set value, oven is turned on.
;//If the temperature rises 20 degrees above the set value, oven is turned off.

soakTimeAndTempCheck:
	clr c
	mov a, soakTemp
	subb a, #20
	subb a, currentTemp 
	jc soakTempOff
	sjmp checkSoakTempLow
soakTempOff:
	clr P3.7
	clr P3.0	

checkSoakTempLow:
	clr c
	mov a, soakTemp
	subb a, #20
	subb a, currentTemp
	jnc soakTempOn
	sjmp checkSoakTime
soakTempOn:
	setb P3.7
	setb P3.0
		
checkSoakTime:		
	mov a, minAlarm
	cjne a, #0, stayInSoak
	
	mov a, secAlarm
	cjne a, #0, stayInSoak
	
	clr soak
	ret
stayInSoak:
	ret
	
;HEATING UP TO REFLOW TEMP

;//PreReflow Temp Check
;//FUNCTION:
;//Called during the prereflow state. Checks if oven temperature is
;//within 10 degrees of soak temp set by user. Shuts off oven once
;//said temperature has been reached to avoid overshooting the mark.

preReflowTempCheck:
	setb P3.7
	setb P3.0
	
	clr c
	mov a, reflowTemp
	subb a, #10
	subb a, currentTemp
	jc changeToReflow
	ret
changeToReflow:	
	clr preReflow
	ret

;THIS CHECKS IF WE HAVE REACHED THE REQUIRED REFLOW
;TEMPERATURE SET BY THE USER	

;//Reflow Time and Temp Check
;//FUNCTION:
;//Called during reflow state. Checks if countdown has reached zero while monitoring
;//the temperature to ensure it remains at the reflow temperature specified by the user.
;//If the temperature falls 10 degrees below the set value, oven is turned on.
;//If the temperature rises 10 degrees above the set value, oven is turned off.

reflowTimeAndTempCheck:
	clr c
	mov a, reflowTemp
	subb a, #10
	subb a, currentTemp 
	jc reflowTempOff
	sjmp checkReflowTempLow
reflowTempOff:
	clr P3.7
	clr P3.0	

checkReflowTempLow:
	clr c
	mov a, reflowTemp
	subb a, #10
	subb a, currentTemp
	jnc reflowTempOn
	sjmp checkReflowTime
reflowTempOn:
	setb P3.7
	setb P3.0

checkReflowTime:	
	mov a, minAlarm
	cjne a, #0, stayInReflow
	mov a, secAlarm
	cjne a, #0, stayInReflow
	
	clr reflow
	ret
stayInReflow:
	ret

;//Cooling Check
;//FUNCTION:
;//Turns off oven and then checks if oven temperature to see
;//if it has reached a safe 40 degrees. Once this temperature 
;//has been reached, program exits cooling stage and reflow
;//process is complete.

coolingCheck:
	clr P3.7
	clr P3.0
	clr c 
	mov a, currentTemp
	subb a, #40
	jc doneCooling 
	ret
doneCooling:
	clr cooling	
	clr started	
	ret
	
$LIST