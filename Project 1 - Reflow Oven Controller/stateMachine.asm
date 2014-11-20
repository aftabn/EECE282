$MODDE2

org 0001H
   ljmp MyProgram
   
org 000BH
	ljmp ISR_timer0

org 001BH ;ISR for timer 1
	ljmp ISR_timer1	
	
;org 002BH
	;ljmp ISR_timer2	
	
XTAL           EQU 33333333
FREQ_0         EQU 100
TIMER0_RELOAD  EQU 65536-(XTAL/(12*FREQ_0)) ;clock

FREQ_1 		   EQU 2000 ;lets face it 2000hz is irritating as hell, 1000hz is way less awful
TIMER1_RELOAD  EQU 65536-(FREQ/(12*2*FREQ_1)) ;buzz

FREQ   EQU 33333333
BAUD   EQU 115200
T2LOAD EQU 65536-(FREQ/(32*BAUD))

MISO   EQU  P0.0 
MOSI   EQU  P0.1 
SCLK   EQU  P0.2
CE_ADC EQU  P0.3

	DSEG at 30H
x:      		ds 4
y:      		ds 4
w:				ds 4
bcd:			ds 4
tempMin:		ds 1
tempSec: 		ds 1
bcdSTemp:		ds 3 ;Temp values to write to LCD screen
bcdSTime:		ds 3 ;Temp values to write to LCD screen
bcdRTemp:		ds 3 ;Temp values to write to LCD screen
bcdRTime:		ds 3 ;Temp values to write to LCD screen
bcdCTemp:		ds 3
bcdJTemp:		ds 3
currentTemp:  	ds 1
junctionTemp:	ds 1
soakTemp:  		ds 1
reflowTemp:  	ds 1
soakTime:  		ds 1
reflowTime:  	ds 1
op:     		ds 1
count10ms: 		ds 1
delaySPI:		ds 1 
sec:   			ds 1
min:   			ds 1
secAlarm: 		ds 1
minAlarm: 		ds 1

	BSEG
mf:      	dbit 1
started:	dbit 1
preSoak:   	dbit 1
soak:	 	dbit 1
preReflow: 	dbit 1
reflow:  	dbit 1
cooling: 	dbit 1
valChanged: dbit 1
secondPassed: dbit 1
Emergency:	dbit 1

CSEG

$include(LCDStates.asm)
$include(countdownAndClock.asm)
$include(tempAndSPI.asm)
$include(math32.asm)
$include(buzzerSubroutines.asm)

STemp_Str:
	DB 'ST=', 0
STime_Str:
	DB 'C  St=', 0
RTemp_Str:
	DB 'RT=', 0
RTime_Str:
	DB 'C  Rt=', 0			
Keep_Settings1_Str:
	DB 'Keep settings?  ', 0
Keep_Settings2_Str:
	DB 'KEY3=Yes KEY2=No', 0
Next_Line_Str:
	DB 'Next: KEY.3     ', 0
Start_Str:
	DB 'Start: KEY.3     ', 0
CurrentTemp_Str:
	DB 'To=', 0	
JunctionTemp_Str:
	DB '  Tj=', 0
soakTemp_Str:
	DB 'SoakTemp:   ', 0
soakTime_Str:
	DB 'SoakTime:   ', 0
reflowTemp_Str:
	DB 'ReflowTemp: ', 0
reflowTime_Str:
	DB 'ReflowTime: ', 0	
ErrorMessage1_Str:
	DB 'Value(s) entered', 0
ErrorMessage2_Str:
	DB 'out of range    ', 0
preSoakState_Str:
	DB 'Soak Preheat    ', 0
soakState_Str:
	DB 'Soaking         ', 0
preReflowState_Str:
	DB 'Reflow Preheat  ', 0
reflowState_Str:
	DB 'Reflowing       ', 0
coolingState_Str:
	DB 'Cooling         ', 0
Emergency1_Str:
	DB 'Emergency Stop  ', 0
Emergency2_Str:
	DB 'Button Pressed  ', 0
doneCoolingString1:
	DB 'Safe to touch   ', 0		
doneCoolingString2:
	DB 'board!!!!!!     ', 0
restart1_Str:
	DB 'Press KEY.3 to  ', 0
restart2_Str:	
	DB 'restart process ', 0
SelectProfile_Str:
	DB 'Select Profile: ', 0
Profiles_Str:
	DB 'SW 1 2 0(Custom)', 0

myLUT:
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H        ; 0 TO 4
    DB 092H, 082H, 0F8H, 080H, 090H 
    DB 0FFH

MyProgram:
	mov sp, #7FH
	mov LEDRA,#0
	mov LEDRB,#0
	mov LEDRC,#0
	mov LEDG,#0
	
	orl P0MOD, #00111000b ; make all CEs outputs
	mov P2MOD, #00001111B ; P2.0...2.3 are outputs! Lots of buzzers!!!!!!
	mov P3MOD, #10001111B
	setb P2.0
	setb P2.1
	setb P2.2
	setb P2.3
	clr P3.0
	clr P3.1
	clr P3.2
	clr P3.3
	clr P3.7

	mov sec, #00H
	mov min, #00H

	mov secAlarm, #00H
	mov minAlarm, #00H 
    
	mov currentTemp, #0
	mov soakTemp, #120
	mov soakTime, #90
	mov reflowTemp, #210
	mov reflowTime, #35
	
	clr preSoak
	clr soak
	clr preReflow
	clr reflow
	clr cooling
	clr started
	clr Emergency
	
	lcall LCD_init
	setb CE_ADC
	lcall INIT_SPI
    lcall InitSerialPort
    lcall init_Timers
    
    setb EA
    
initializationState:
	asciiConvert(soakTemp, bcdSTemp+2, bcdSTemp+1, bcdSTemp+0)
	asciiConvert(soakTime, bcdSTime+2, bcdSTime+1, bcdSTime+0)
	asciiConvert(reflowTemp, bcdRTemp+2, bcdRTemp+1, bcdRTemp+0)
	asciiConvert(reflowTime, bcdRtime+2, bcdRtime+1, bcdRtime+0)
	
	
	lcall initialLCD_Message ;display initial message
	
	mov a, #80H
	lcall LCD_command
	mov dptr, #Keep_Settings1_str
	lcall writeString
	
	mov a, #0C0H
	lcall LCD_command
	mov dptr, #Keep_Settings2_str
	lcall writeString
	

getUserInput_L0:
	jnb KEY.3, keepSettings
	jnb KEY.2, selectProfile
	clr a
	mov bcd+0, a
	mov bcd+1, a
	sjmp getUserInput_L0
	
keepSettings:
	lcall LCD_init
	lcall initialLCD_Message
	setb P2.0 
	lcall wait1s
	clr P2.0 
	clr a
	mov bcd+0, a
	mov bcd+1, a
	ljmp loadPreSoakState


;==========================USER INPUT ===============================
; This section of code is where the user has the option to choose
; between 2 default settings or their own custom settings.
; If the user chooses custom, they must enter values for each of the
; 4 variables. If any of the variables are out of range of their max
; allowed settings, they are rounded down and the user is notified.
;====================================================================

;---------------------------------------------------------
; selectProfile:
; Continuous loop until the user chooses a profile with
; the appropriate switch
;---------------------------------------------------------
selectProfile:
	mov a, #80H
	lcall LCD_command
	mov dptr, #SelectProfile_Str
	lcall writeString
	
	mov a, #0C0H
	lcall LCD_command
	mov dptr, #Profiles_Str
	lcall writeString
	jb SWA.0, debounceSWA0
	jb SWA.1, loadProfile1 ;this is the original default profile
	jb SWA.2, loadProfile2
	sjmp selectProfile

loadProfile1: ;Use original values here
	mov soakTemp, #120
	mov soakTime, #90
	mov reflowTemp, #210
	mov reflowTime, #35
	ljmp initializationState 

loadProfile2: ;custom profile found online
	mov soakTemp, #150
	mov soakTime, #120
	mov reflowTemp, #210
	mov reflowTime, #40
	ljmp initializationState 

debounceSWA0:
  	jnb SWA.0, rewriteSoakTemp
  	sjmp debounceSWA0
  	
;---------------------------------------------------------
; rewrite_______:
; A loop that rewrites the selected variable and updates 
; the LCD display so the user has visual confirmation of 
; their choice
;---------------------------------------------------------  	
rewriteSoakTemp:
	mov a, #80H
	lcall LCD_command
	mov dptr, #Next_Line_Str
	lcall writeString
	
	mov a, #0C0H
	lcall LCD_command
	mov dptr, #soakTemp_Str
	lcall writeString
	
	mov a, bcdSTemp+2
	lcall LCD_put
	mov a, bcdSTemp+1
	lcall LCD_put
	mov a, bcdSTemp+0
	lcall LCD_put
	mov a, #'C'
	lcall LCD_put
	
	;Jump to next input
	jnb KEY.3, rewriteSoakTimeDebounce 
	lcall readNumber
	jnc rewriteSoakTemp
	lcall shift_digits
	BCD_Dump(bcdSTemp+2,bcdSTemp+1,bcdSTemp+0)
	
	ljmp rewriteSoakTemp

rewriteSoakTimeDebounce:
	jnb KEY.3, rewriteSoakTimeDebounce
	clr a
	mov bcd+0, a
	mov bcd+1, a
rewriteSoakTime:
	mov a, #80H
	lcall LCD_command
	mov dptr, #Next_Line_Str
	lcall writeString
	
	mov a, #0C0H
	lcall LCD_command
	mov dptr, #soakTime_Str
	lcall writeString
	
	mov a, bcdSTime+2
	lcall LCD_put
	mov a, bcdSTime+1
	lcall LCD_put
	mov a, bcdSTime+0
	lcall LCD_put
	mov a, #'s'
	lcall LCD_put
	
	jnb KEY.3, rewriteReflowTempDebounce ;Jump to next input
	lcall readNumber
	jnc rewriteSoakTime
	lcall shift_digits
	BCD_Dump(bcdSTime+2,bcdSTime+1,bcdSTime+0)
	
	ljmp rewriteSoakTime

rewriteReflowTempDebounce:
	jnb KEY.3, rewriteReflowTempDebounce
	clr a
	mov bcd+0, a
	mov bcd+1, a
rewriteReflowTemp:
	mov a, #80H
	lcall LCD_command
	mov dptr, #Next_Line_Str
	lcall writeString
	
	mov a, #0C0H
	lcall LCD_command
	mov dptr, #reflowTemp_Str
	lcall writeString
	
	mov a, bcdRTemp+2
	lcall LCD_put
	mov a, bcdRTemp+1
	lcall LCD_put
	mov a, bcdRTemp+0
	lcall LCD_put
	mov a, #'C'
	lcall LCD_put
	
	jnb KEY.3, rewriteReflowTimeDebounce ;Jump to next input
	lcall readNumber
	jnc rewriteReflowTemp
	lcall shift_digits
	BCD_Dump(bcdRTemp+2,bcdRTemp+1,bcdRTemp+0)
	
	ljmp rewriteReflowTemp

rewriteReflowTimeDebounce:
	jnb KEY.3, rewriteReflowTimeDebounce
	clr a
	mov bcd+0, a
	mov bcd+1, a
rewriteReflowTime:
	mov a, #80H
	lcall LCD_command
	mov dptr, #Start_Str
	lcall writeString
	
	mov a, #0C0H
	lcall LCD_command
	mov dptr, #reflowTime_Str
	lcall writeString
	
	mov a, bcdRTime+2
	lcall LCD_put
	mov a, bcdRTime+1
	lcall LCD_put
	mov a, bcdRTime+0
	lcall LCD_put
	mov a, #'s'
	lcall LCD_put
	
	jnb KEY.3, checkValueDebounce ;Jump to next input
	lcall readNumber
	jnc rewriteReflowTime
	lcall shift_digits
	BCD_Dump(bcdRTime+2,bcdRTime+1,bcdRTime+0)
	
	ljmp rewriteReflowTime
		
;---------------------------------------------------------
; checkValue:
; This calls the checkSTemp within LCDStates.asm and verifies
; or corrects the values that were entered by the user
;---------------------------------------------------------
checkValueDebounce:
	jnb KEY.3, checkValueDebounce
checkValue:
	lcall checkSTemp
	jb valChanged, displayErrorMessage
	sjmp displayCorrectedValues
displayErrorMessage:
	mov a, #80H
	lcall LCD_command
	mov dptr, #ErrorMessage1_Str
	lcall writeString
	
	mov a, #0C0H
	lcall LCD_command
	mov dptr, #ErrorMessage2_Str
	lcall writeString
		
	lcall wait1s
	lcall wait1s
	
displayCorrectedValues:	
	lcall initialLCD_Message ;display initial message
	
	lcall wait1s
	lcall wait1s
	lcall wait1s
	
	lcall LCD_init
	lcall reloadUserVariables
	sjmp loadPreSoakState
			
;======================= STATE MACHINE ============================
; This section of code is responsible for running each state which
; means calculating and updating temperature and time variables
; depending on the which state the program is in. 
; State transitions of the main program will occur when the current 
; state bit is cleared
;==================================================================

;------------------------------------------------------------------
; load____State:
; - Displays the new message for the state being entered 
; - If in soak/reflow, loads the countdown timer with the 
; 	timer variable
; - Beeps the appropriate # of times depending on the state
;------------------------------------------------------------------
;------------------------------------------------------------------
; ____State:
; - Calculates the temperature
; - If in soak/reflow, updates the LCD with the countdown variables
; - Checks if current state bit has been cleared (state transition)
;------------------------------------------------------------------
loadPreSoakState:
	lcall LCD_init
	
	mov a, #80H
	lcall LCD_command
	mov dptr, #preSoakState_Str
	lcall writeString
	
	lcall shortBeep
	setb P3.1
	setb preSoak
	setb started
preSoakState:
	mov b, #0  ; Read channel 0
	lcall Read_ADC_Channel
	lcall calculateRoomTemp
	
	;Updates the room temperature
	mov junctionTemp, x+0
	asciiConvert(junctionTemp, BCDJTemp+2,BCDJTemp+1,BCDJTemp+0)
	
	lcall Opamp
	lcall addingtemps
	
	;Updates the oven temperature
	mov currentTemp, x+0
	asciiConvert(currentTemp, BCDCTemp+2,BCDCTemp+1,BCDCTemp+0)
	
	mov LEDRA, #00000001B
	
	jb emergency, preSoakToEmergency

	jnb preSoak, loadSoakState
	ljmp preSoakState	
preSoakToEmergency:
	ljmp EmergencyState

loadSoakState:
	clr P3.1
	lcall LCD_init
	lcall shortBeep
	mov a, #80H
	lcall LCD_command
	mov dptr, #SoakState_Str
	lcall writeString
	
	BCDReverseDump(bcdSTime+2,bcdSTime+1,bcdSTime+0)
	lcall bcd2hex
	mov secAlarm, bcd+0
	mov minAlarm, bcd+1

	setb P3.2
	setb soak
soakState:
	mov b, #0  ; Read channel 0
	lcall Read_ADC_Channel
	lcall calculateRoomTemp
	
	;Updates the room temperature
	mov junctionTemp, x+0
	asciiConvert(junctionTemp, BCDJTemp+2,BCDJTemp+1,BCDJTemp+0)
	
	lcall Opamp
	lcall addingtemps
	
	;Updates the oven temperature
	mov currentTemp, x+0
	asciiConvert(currentTemp, BCDCTemp+2,BCDCTemp+1,BCDCTemp+0)

	mov LEDRA, #00000010B
	
	jb emergency, soakToEmergency
	
	jnb soak, loadPreReflowState
	ljmp soakState	
soakToEmergency:
	ljmp EmergencyState


loadPreReflowState:
	clr P3.2
	lcall LCD_init
	lcall shortBeep
	
	mov a, #80H
	lcall LCD_command
	mov dptr, #preReflowState_Str
	lcall writeString
	
	setb P3.1
	setb preReflow
preReflowState:
	mov b, #0  ; Read channel 0
	lcall Read_ADC_Channel
	lcall calculateRoomTemp
	
	;Updates the room temperature
	mov junctionTemp, x+0
	asciiConvert(junctionTemp, BCDJTemp+2,BCDJTemp+1,BCDJTemp+0)
	
	lcall Opamp
	lcall addingtemps
	
	;Updates the oven temperature
	mov currentTemp, x+0
	asciiConvert(currentTemp, BCDCTemp+2,BCDCTemp+1,BCDCTemp+0)

	mov LEDRA, #00000100B
	
	jb Emergency, preReflowToEmergency
	
	jnb preReflow, loadReflowState
	ljmp preReflowState	
preReflowToEmergency:
	ljmp EmergencyState

	
loadReflowState:
	clr P3.1
	lcall LCD_init
	lcall shortBeep
	
	mov a, #80H
	lcall LCD_command
	mov dptr, #reflowState_Str
	lcall writeString
	
	mov a, #0
	mov tempMin, a
	mov tempSec, a
	mov x+0, reflowTime
	mov x+1, a
	lcall convertToMinutes
	mov secAlarm, tempSec
	mov minAlarm, tempMin
	clr P3.2
	setb reflow
reflowState:
	mov b, #0  ; Read channel 0
	lcall Read_ADC_Channel
	lcall calculateRoomTemp
	
	;Updates the room temperature
	mov junctionTemp, x+0
	asciiConvert(junctionTemp, BCDJTemp+2,BCDJTemp+1,BCDJTemp+0)
	
	lcall Opamp
	lcall addingtemps
	
	;Updates the oven temperature
	mov currentTemp, x+0
	asciiConvert(currentTemp, BCDCTemp+2,BCDCTemp+1,BCDCTemp+0)

	
	mov LEDRA, #00001000B
	
	jb Emergency, reflowToEmergency
	
	jnb reflow, loadCoolingState
	ljmp reflowState	
reflowToEmergency:
	ljmp EmergencyState
	

loadCoolingState:
	clr P3.2
	lcall LCD_init
	lcall longBeep
	
	mov a, #80H
	lcall LCD_command
	mov dptr, #coolingState_Str
	lcall writeString	
	
	setb P3.3
	setb cooling
coolingState:
	mov b, #0  ; Read channel 0
	lcall Read_ADC_Channel
	lcall calculateRoomTemp
	
	;Updates the room temperature
	mov junctionTemp, x+0
	asciiConvert(junctionTemp, BCDJTemp+2,BCDJTemp+1,BCDJTemp+0)
	
	lcall Opamp
	lcall addingtemps
	
	;Updates the oven temperature
	mov currentTemp, x+0
	asciiConvert(currentTemp, BCDCTemp+2,BCDCTemp+1,BCDCTemp+0)

	mov LEDRA, #00010000B
	
	jnb cooling, doneCoolingState
	ljmp coolingState

doneCoolingState:	
	setb P3.0
	setb P3.1
	setb P3.2
	setb P3.3
	lcall LCD_init

	mov a, #80H
	lcall LCD_command
	mov dptr, #doneCoolingString1
	lcall writeString
	
	mov a, #0C0H
	lcall LCD_command
	mov dptr, #doneCoolingString2
	lcall writeString
	
	lcall shortBeep	
	lcall shortBeep
	lcall shortBeep
	lcall shortBeep
	lcall shortBeep
	lcall shortBeep
	
	lcall wait1s
    lcall wait1s
    
    lcall LCD_init
    
    mov a, #80H
	lcall LCD_command
	mov dptr, #Restart1_Str
	lcall writeString
	
	mov a, #0C0H
	lcall LCD_command
	mov dptr, #Restart2_Str
	lcall writeString
	
restartLoop1:
	jnb KEY.3, restartProgram1
	sjmp restartLoop1
	
restartProgram1:
	ljmp myProgram

;------------------------------------------------------------------
; EmergencyState:
; This state can be entered from any of the soak or reflow states
; through the use of KEY.1
; The user then has the option of restarting the program with KEY.3
;------------------------------------------------------------------
EmergencyState:
	clr started
	
	lcall LCD_init
	
	mov a, #80H
	lcall LCD_command
	mov dptr, #Emergency1_Str
	lcall writeString
	
	mov a, #0C0H
	lcall LCD_command
	mov dptr, #Emergency2_Str
	lcall writeString
	
	mov HEX0, #0FFH
    mov HEX1, #0FFH
    mov HEX2, #0FFH
    mov HEX3, #0FFH
    mov HEX4, #0FFH
    mov HEX5, #0FFH
    mov HEX6, #0FFH
    mov HEX7, #0FFH
    
    lcall wait1s
    lcall wait1s
    
    lcall LCD_init
    
    mov a, #80H
	lcall LCD_command
	mov dptr, #Restart1_Str
	lcall writeString
	
	mov a, #0C0H
	lcall LCD_command
	mov dptr, #Restart2_Str
	lcall writeString
	
restartLoop2:
	jnb KEY.3, restartProgram2
	sjmp restartLoop2
	
restartProgram2:
	ljmp myProgram		
	
END	