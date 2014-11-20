; sqrt16: this calculator reads a 16-bit number and gets it square root

$modde2

	CSEG at 0
	ljmp mycode

dseg at 30h
x:    ds 2
y:    ds 2
bcd:  ds 3

bseg
mf:   dbit 1

	CSEG
	
$include(math16.asm)

; Look-up table for 7-seg displays
myLUT:
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H        ; 0 TO 4
    DB 092H, 082H, 0F8H, 080H, 090H        ; 4 TO 9
    DB 088H, 083H, 0C6H, 0A1H, 086H, 08EH  ; A to F

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
    ret

Shift_Digits:
	mov R0, #4 ; shift left four bits
Shift_Digits_L0:
	clr c
	mov a, bcd+0
	rlc a
	mov bcd+0, a
	mov a, bcd+1
	rlc a
	mov bcd+1, a
	mov a, bcd+2
	rlc a
	mov bcd+2, a
	djnz R0, Shift_Digits_L0
	; R7 has the new bcd digit	
	mov a, R7
	orl a, bcd+0
	mov bcd+0, a
	; make the four most significant bits of bcd+2 zero
	mov a, bcd+2
	anl a, #0fH
	mov bcd+2, a
	ret

Wait50ms:
;33.33MHz, 1 clk per cycle: 0.03us
	mov R0, #30
L3: mov R1, #74
L2: mov R2, #250
L1: djnz R2, L1 ;3*250*0.03us=22.5us
    djnz R1, L2 ;74*22.5us=1.665ms
    djnz R0, L3 ;1.665ms*30=50ms
    ret

; Check if SW0 to SW15 are toggled up.  Returns the toggled switch in
; R7.  If the carry is not set, no toggling switches were detected.
ReadNumber:
	mov r4, SWA ; Read switches 0 to 7
	mov r5, SWB ; Read switches 8 to 15
	mov a, r4
	orl a, r5
	jz ReadNumber_no_number
	lcall Wait50ms ; debounce
	mov a, SWA
	clr c
	subb a, r4
	jnz ReadNumber_no_number ; it was a bounce
	mov a, SWB
	clr c
	subb a, r5
	jnz ReadNumber_no_number ; it was a bounce
	mov r7, #16 ; Loop counter
ReadNumber_L0:
	clr c
	mov a, r4
	rlc a
	mov r4, a
	mov a, r5
	rlc a
	mov r5, a
	jc ReadNumber_decode
	djnz r7, ReadNumber_L0
	sjmp ReadNumber_no_number	
ReadNumber_decode:
	dec r7
	setb c
ReadNumber_L1:
	mov a, SWA
	jnz ReadNumber_L1
ReadNumber_L2:
	mov a, SWB
	jnz ReadNumber_L2
	ret
ReadNumber_no_number:
	clr c
	ret
	
mycode:
	mov SP, #7FH
	clr a
	mov LEDRA, a
	mov LEDRB, a
	mov LEDRC, a
	mov LEDG, a
	mov bcd+0, a
	mov bcd+1, a
	mov bcd+2, a
	lcall Display

forever:
	; SW13 is the square root switch
	mov a, SWB ; Read switches 7 to 15
	jb acc.5, do_sqrt ; bit 7 is sw15, bit 6 is sw14, bit 5 is sw13, etc.
	lcall ReadNumber
	jnc forever
	
	mov a, r7 ; The number returned by 'ReadNumber' above must be < 10
	clr c
	subb a, #10
	jnc forever ; If the number keyed-in is larger than 10 discard it.
	
	; The number is less than 10.  Shift bcd one digit left with the new value.
	lcall Shift_Digits
	; Display the new bcd number
	lcall Display
	ljmp forever
	
do_sqrt:
	; The bcd variable has the number to sqrt.  Convert it to hex:
	lcall bcd2hex
	; Now x has the number in binary.  Compute the square root:
	lcall sqrt16
	; Now x has the square root of the number.  Convert to bcd
	lcall hex2bcd
	; Almost done.  We need to display the number first:
	lcall Display
	; Now wait for SW13 to go back to zero:
do_sqrt_loop:
	mov a, SWB
	jb acc.5, do_sqrt_loop
	; We are done.  Wait for another number:
	ljmp forever
	
end
