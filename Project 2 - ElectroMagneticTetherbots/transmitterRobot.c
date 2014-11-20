//This version has the standard transmitter functionality without 
//bluetooth implementation (still contains the bluetooth code though)

#include <stdio.h>
#include <at89lp51rd2.h>

#define CLK 22118400L
#define BAUD 115200L
#define BRG_VAL (0x100-(CLK/(32L*BAUD)))
#define TIMER0_RELOAD (65475) //(65536L-(CLK/(12L*FREQ))) //FREQ = 30100
#define TIMER1_RELOAD (65536 - 177) //177*.542535 = 100us which is the 
									//period of each bluetooth bit


volatile unsigned int val[30]; //array to store incoming bluetooth bits
volatile unsigned int count = 0; // variable to keep track of bluetooth bits
volatile unsigned char command; //stores the converted bluetooth command
volatile unsigned int LMotCCW, LMotCW, RMotCCW, RMotCW; //variables for 
volatile unsigned int button = 10; 
volatile unsigned int buttonPressed = 0; 
volatile unsigned int dataInc = 0; 
volatile unsigned int exitFlag = 0;
     
unsigned char _c51_external_startup(void)
{
	// Configure ports as a bidirectional with internal pull-ups.
	P0M0=0;	P0M1=0;
	P1M0=0;	P1M1=0;
	P2M0=0;	P2M1=0;
	P3M0=0;	P3M1=0;
	AUXR=0B_0001_0001; // 1152 bytes of internal XDATA, P4.4 is a general purpose I/O
	P4M0=0;	P4M1=0;
    //setbaud_timer2(TIMER_2_RELOAD); // Initialize serial port using timer 2
    
    PCON|=0x80;
	SCON = 0x52;
    BDRCON=0;
    BRL=BRG_VAL;
    BDRCON=BRR|TBCK|RBCK|SPD;
    
    //INITIALIZATION
	LMotCCW = 0;
    LMotCW = 0;
    RMotCCW = 0; 
    RMotCW = 0;	
	
	TR0=0; // Disable timer/counter 0
	TR1=0;
	TMOD=0B_00010001; // Autoreload timer 0
    TH0=RH0=TIMER0_RELOAD/0x100;
	TL0=RL0=TIMER0_RELOAD%0x100;
	TH1=RH1=TIMER1_RELOAD/0x100;
	TL1=RL1=TIMER1_RELOAD%0x100;
	IPH0 = 0B_00000010;
	IPL0 = 0B_00000010;
	ET0=1;
	ET1=1;
	TR0=1;
	TR1=1;
	EA=1;
	
    return 0;
}

void wait_bit_time(void)
{ //Waits for 11.068ms
	_asm
		mov R1, #80
	Z2:	mov R0, #255
	Z1:	djnz R0, Z1 
	    djnz R1, Z2
	    ret
    _endasm;
}

void wait_smaller_bit_time(void)
{ //Waits for 6.415 ms
	_asm	
		mov R1, #55
	Z5:	mov R0, #215
	Z4:	djnz R0, Z4 
	    djnz R1, Z5
	    ret
    _endasm;
}

void waitBluetoothTime (void)
{ //Waits for 271 us
	_asm	
		mov R1, #20
	L5:	mov R0, #25
	L4:	djnz R0, L4
	    djnz R1, L5
	    ret
    _endasm;
}

void wait50ms(void)
{
	_asm	
		;For a 22.1184MHz crystal one machine cycle 
		;takes 12/22.1184MHz=0.5425347us
		mov R2, #4
	J3:	mov R1, #90
	J2:	mov R0, #255
	J1:	djnz R0, J1 ; 2 machine cycles-> 2*0.5425347us*184=200us
	    djnz R1, J2 ; 200us*250=0.05s
	    djnz R2, J3
	    ret
    _endasm;
}

void wait200ms(void)
{
	_asm	
		mov R2, #16
	N3:	mov R1, #90
	N2:	mov R0, #255
	N1:	djnz R0, N1 
	    djnz R1, N2
	    djnz R2, N3
	    ret
    _endasm;
}
void debounce(void)
{ //Waits for 75 ms
	_asm	
		mov R2, #6
	L3:	mov R1, #90
	L2:	mov R0, #255
	L1:	djnz R0, L1
	    djnz R1, L2
	    djnz R2, L3
	    ret
    _endasm;
}    

/************************* buttonScan ****************************
* Scans each row of the keypad to check if a button was pressed. *
* If a button is pressed, the buttonPressed flag is set and      *
* scanning is halted until the appropriate command has finished. *
*****************************************************************/
void buttonScan (void)
{
//scan row 1 first

	P2_3 = 0; //ROW 1
	P2_4 = 1; //ROW 2
	P2_5 = 1; //ROW 3
	P2_6 = 1; //ROW 4
	
	if (P2_0 == 0 && buttonPressed == 0)  {    //COLUMN 1 BUTTON 1
		button = 1;
		buttonPressed = 1;
		return;
	}
	else if (P2_1 == 0 && buttonPressed == 0) { //COLUMN 2 BUTTON 2
		button = 2;
		buttonPressed = 1;
		return;
	}
	else if(P2_2 == 0 && buttonPressed == 0) { //COLUMN 3 BUTTON 3
		button = 3;
		buttonPressed = 1;
		return;
	}
	
	//Bluetooth segment to exit the this loop early if a start bit is
	//read on the appropriate port
	if (dataInc == 1)
	{
		button = 16;
		buttonPressed = 0;
		return;
	}

//scan row 2 			
	P2_3 = 1;
	P2_4 = 0;
	P2_5 = 1;
	P2_6 = 1;
    
	if (P2_0 == 0 && buttonPressed == 0)  {    //COLUMN 1 BUTTON 4
		button = 4;
		buttonPressed = 1;
		return;
	}
	else if (P2_1 == 0 && buttonPressed == 0) { //COLUMN 2 BUTTON 5
		button = 5;
		buttonPressed = 1;
		return;
	}
	else if(P2_2 == 0 && buttonPressed == 0) { //COLUMN 3 BUTTON 6
		button = 6;
		buttonPressed = 1;
		return;
	}	
	
	//Bluetooth segment to exit the this loop early if a start bit is
	//read on the appropriate port
	if (dataInc == 1)
	{
		button = 16;
		buttonPressed = 0;
		return;
	}	

//scan row 3	
	P2_3 = 1;
	P2_4 = 1;
	P2_5 = 0;
	P2_6 = 1;
	
	if (P2_0 == 0 && buttonPressed == 0)  {    //COLUMN 1 BUTTON 7
		button = 7;
		buttonPressed = 1;
		return;
	}
	else if (P2_1 == 0 && buttonPressed == 0) { //COLUMN 2 BUTTON 8
		button = 8;
		buttonPressed = 1;
		return;
	}
	else if(P2_2 == 0 && buttonPressed == 0) { //COLUMN 3 BUTTON 9
		button = 9;
		buttonPressed = 1;
		return;
	}
	
	//Bluetooth segment to exit the this loop early if a start bit is
	//read on the appropriate port
	if (dataInc == 1)
	{
		button = 16;
		buttonPressed = 0;
		return;
	}
	
//scan row 4		
	P2_3 = 1;
	P2_4 = 1;
	P2_5 = 1;
	P2_6 = 0;
	
	if (P2_0 == 0 && buttonPressed == 0)  {    //COLUMN 1 BUTTON *
		button = 10;
		buttonPressed = 1;
		return;
	}
	else if (P2_1 == 0 && buttonPressed == 0) { //COLUMN 2 BUTTON 0
		button = 0;
		buttonPressed = 1;
		return;
	}
	else if(P2_2 == 0 && buttonPressed == 0) { //COLUMN 3 BUTTON #
		button = 11;
		buttonPressed = 1;
		return;
	}
	else
	{
		button = 16;
		buttonPressed = 0;
		return;
	}	
}

/************** tx_byte ******************
* Transmits data to the receiever car by * 
* turning on and off the magnetic field  *
* to simulate a logic 1 or 0.            *
*****************************************/

void tx_byte ( unsigned int val )  //bit bang data sent
{
	unsigned char j; 
	//Send the start bit
	ET0=0;
	printf("Starting transmission\n");
	wait_bit_time(); //send PRELIMINARY start bit (logic 0)
	ET0 = 1;
	wait_smaller_bit_time(); //send start bit (logic 1)
	for (j=0; j<4; j++)
	{
		ET0=val&(0x01<<j)?1:0;
		if (ET0 == 1)
			wait_smaller_bit_time();
		else 
			wait_bit_time();
	}
	ET0=1;
}

//BLUETOOTH FUNCTION
/************** React *******************
*Responds to the input received over    * 
*bluetooth by controlling the motors    *
*driving the transmitter robot          *
****************************************/

void react(unsigned char input)
{
	if (input == 'w')
	{
		LMotCCW = 1;
        LMotCW = 0;     //car moves forward
        RMotCCW = 0;
        RMotCW = 1;
        wait50ms();
    }
    else if (input == 's')
    {
    	LMotCCW = 0;
        LMotCW = 1;     //car moves backwards
        RMotCCW = 1;
        RMotCW = 0;
        wait50ms();  
    }
    else if (input == 'a')
    {
    	LMotCCW = 0; //car moves left
        LMotCW = 0;
        RMotCCW = 0;
        RMotCW = 1;
        wait50ms();
        
    }
    else if (input == 'd')
    {
    	LMotCCW = 1;
        LMotCW = 0; //car moves right
        RMotCCW = 0; //NOTE: might turn too fast with both motors on
        RMotCW = 0;
        wait50ms();
    }
    else
    {
    	LMotCCW = 0;
        LMotCW = 0; //car moves nowhere
        RMotCCW = 0; 
        RMotCW = 0;
    }  
    
}


/******************* transmitterCommands ********************
* - Keypad buttons are now mapped differently since the 	*
* transmitter has entered the manual drive state		    *
* - State is entered by pressing '0' on the keypad          *
************************************************************/

void transmitterCommands()
{
	//Tells the robot to blink twice to notify the user
	//that the transmitter robot is in manual drive mode
	tx_byte(button);
	debounce();
	
	//Clears the button so there is no infinite command response
	button = 16;
	
	//Transmitter robot stays in this state until the user pressed '0'
	//AKA flag exitFlag must be set to exit
	while (exitFlag == 0)
	{
		//Tells the robot to blink to notify the user that the
		//transmitter robot has exited manual drive mode 
		if (button == 0)
		{
			tx_byte(button);
	   		debounce();
			exitFlag = 1;
		}	
		
		//Moves the transmitter robot forward while '5' is held down
		else if (button == 5)
		{
			P3_5 = 0; 
	        P3_6 = 1;     //car moves forwards
	        P4_3 = 1;
	        P3_7 = 0;
	        wait_bit_time();
	        buttonPressed = 0;
	    }
	    
	    //Moves the transmitter robot backward while '8' is held down
	    else if (button ==  8)
	    {
	    	P3_5 = 1; 
	        P3_6 = 0;     //car moves backwards
	        P4_3 = 0;
	        P3_7 = 1;
	        wait_bit_time();
	        buttonPressed = 0;   
		}
		
		//Turns the transmitter robot left while '7' is held down
		else if (button == 7)
		{
			P3_5 = 0; 
	        P3_6 = 0;     //car turns left
	        P4_3 = 1;
	        P3_7 = 0;
	        wait_bit_time();
	        buttonPressed = 0;
	    }
	    
	    //Turns the transmitter robot right while '9' is held down
	    else if (button == 9)
	    {
	    	P3_5 = 0; 
	        P3_6 = 1;     //car turns right
	        P4_3 = 0;
	        P3_7 = 0;
	        wait_bit_time();
	        buttonPressed = 0;
	    }
	    
	    //Commands the robot to travel a fixed path and then wait for
	    //the next button
	    else if (button == 11)
	    {
	    	P3_5 = 1;
	        P3_6 = 0;     //car moves backwards
	        P4_3 = 0;
	        P3_7 = 1;
	        wait200ms();	
	        
	        P3_5 = 0;
	        P3_6 = 1;     //car moves forwards
	        P4_3 = 1;
	        P3_7 = 0;
	        wait200ms();	
	        
	        P3_5 = 0;
	        P3_6 = 0;     //stops the motors
	        P4_3 = 0;
	        P3_7 = 0;
	        
	        buttonPressed = 0;
	    }    
	    
	    //No button scanned means the robot will wait for the next input
	    else
	    {
	    	P3_5 = 0; //All motors off 
	        P3_6 = 0;
	        P4_3 = 0;
	        P3_7 = 0;
	        buttonPressed = 0; //Allows the robot to scan for the next button
	    } 
	    button = 16; //Clears the button so no infinite loop   
	}    
}	    	    		

/******************** squareWave (ISR 0) **********************
* - Creates two 15kHz square wave for the purpose of 		  *
* generating a magnetic field from the transmitting inductor. *
* - This interrupt always has priority so that there is a 	  *
* constant and steady magnetic field produced.				  *
**************************************************************/

void squareWave (void) interrupt 1
{
	P1_3 = P1_0;
	P1_0 = !P1_0;
}

/******************* sampleBits (ISR 1) **********************
* - Dual purpose of sampling the data sent over bluetooth	 *
* or for scanning the keypad if the the bluetooth start flag *
* was not set.												 *
* - Bluetooth took priority for boolean checks since timing  *
* is cruicial to read the correct data.						 *	
*************************************************************/
void sampleBits (void) interrupt 3 
{  
	if (dataInc == 1)
	{
		val[count] = P0_2;
		count++;
	}
	
	else if (buttonPressed == 0)	
		buttonScan();	
}

/***************************** main *****************************
* - Makes calls to the bluetooth react() whenever any command   *
* is sent to robot (via keypad or bluetooth start bit) 			*									 
* - Bluetooth is run regardless since timing is crucial and the *
* entire block of code takes a minimal amount of time to run.   *
* - If the user presses button '0', the transmitter enters 		*
* manual drive mode, otherwise a standard command is sent 		*
* by enabling and disabling ISR 0.								*
****************************************************************/

void main(void)
{
	printf( "Starting Transmitter\r\n" );
	
	TR0=0;
	TR1=0;
	TMOD=0B_00010001; // 16-bit timer modes
	ET0=1;
	ET1=1;
	TR0=1;
	TR1=1;
	EA=1;
	
	while (1)
	{
		int i;
		for (i = 0; i < 30; i++)
			val[i] = 0;
		count = 0;
		command = 0;	
    
    //Waits for a start bit or for a button press
		while (P0_2 == 1 && buttonPressed == 0);
		
	//Sets start bit flag and stores all received data	
		dataInc = 1;
		waitBluetoothTime();
		dataInc = 0;
	
	//Converts the data to an ascii command	
		command += val[6];
		command <<= 1;
		command += val[5];
		command <<= 1;
		command += val[4];
		command <<= 1;
		command += val[3];
		command <<= 1;
		command += val[2];
		command <<= 1;
		command += val[1];
		command <<= 1;
		command += val[0];
		
	//Responds to command	
		react(command);
    
    //Checks if a button was pressed on the keypad
	   	if (buttonPressed == 1)
	   	{
	   	//Manual drive case
	   		if (button == 0)
	   		{
	   			exitFlag = 0;
	   			transmitterCommands();
	   		}
	   	//Standard command case	
	   		else 
	   		{
	   			tx_byte(button);
	   			debounce();
	   		}
		//Clears the flag so scanning can continue        
	   		buttonPressed = 0;	
	   	}				
	}	
}	

