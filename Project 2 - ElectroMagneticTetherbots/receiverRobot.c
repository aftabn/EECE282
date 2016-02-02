
//  receiverRobot.c
// (c) Team Mango
//
#include <stdio.h>
#include <stdlib.h>
#include <at89lp51rd2.h>
// ~C51~

//--Car movement predefined boundary values and data transmission values--//
#define CLK 22118400L
#define BAUD 115200L
#define BRG_VAL (0x100-(CLK/(32L*BAUD)))
#define ALIGN_ERROR_1 0.2
#define ALIGN_ERROR_2 0.1
#define ALIGN_ERROR_3 0.03
#define ALIGN_ERROR_4 0.0142
#define ALIGN_ERROR_5 0.009
#define FIXED_THRESHOLD_1 2.7
#define FIXED_THRESHOLD_2 0.65
#define FIXED_THRESHOLD_3 0.162
#define FIXED_THRESHOLD_4 0.061
#define FIXED_THRESHOLD_5 0.01892
#define THRESH_ERROR_1 0.25
#define THRESH_ERROR_2 0.09
#define THRESH_ERROR_3 0.02
#define THRESH_ERROR_4 0.018
#define THRESH_ERROR_5 0.009
#define CUTOFF 0.01

//----------------------------------------------------------------------//

//--Car movement logic variables and port assignments--//

volatile int LBkwd = 0; //LCW
volatile int LFwd = 0; //LCCW
volatile int RFwd = 0; //RCW
volatile int RBkwd = 0; //RCCW;
volatile int BRight = 0; //Tail lights
volatile int BLeft = 0;
volatile int FRight = 0; //Head Lights
volatile int FLeft = 0;
volatile float leftVolt, rightVolt;
volatile float threshold, threshError;
volatile float alignError, fixedAlignError;

volatile unsigned int command, parallelFlag, rotateFlag, i;
volatile unsigned int startFlag = 0;
//----------------------------------------------------//

unsigned char _c51_external_startup(void)
{
    // Configure ports as a bidirectional with internal pull-ups.
    P0M0=0;	P0M1=0;
    P1M0=0;	P1M1=0;
    P2M0=0;	P2M1=0;
    P3M0=0;	P3M1=0;
    AUXR=0B_0001_0001; // 1152 bytes of internal XDATA, P4.4 is a general purpose I/O
    P4M0=0;	P4M1=0;
    
    // Instead of using a timer to generate the clock for the serial
    // port, use the built-in baud rate generator.
    PCON|=0x80;
    SCON = 0x52;
    BDRCON=0;
    BRL=BRG_VAL;
    BDRCON=BRR|TBCK|RBCK|SPD;
    
    return 0;
}

void SPIWrite(unsigned char value)
{
    SPSTA&=(~SPIF); // Clear the SPIF flag in SPSTA
    SPDAT=value;
    while((SPSTA & SPIF)!=SPIF); //Wait for transmission to end
}

// Read 10 bits from the MCP3004 ADC converter
unsigned int GetADC(unsigned char channel)
{
    unsigned int adc;
    // initialize the SPI port to read the MCP3004 ADC attached to it.
    SPCON&=(~SPEN); // Disable SPI
    SPCON=MSTR|CPOL|CPHA|SPR1|SPR0|SSDIS;
    SPCON|=SPEN; // Enable SPI
    
    P1_4=0; // Activate the MCP3004 ADC.
    SPIWrite(channel|0x18);	// Send start bit, single/diff* bit, D2, D1, and D0 bits.
    for(adc=0; adc<10; adc++); // Wait for S/H to setup
    SPIWrite(0x55); // Read bits 9 down to 4
    adc=((SPDAT&0x3f)*0x100);
    SPIWrite(0x55);// Read bits 3 down to 0
    P1_4=1; // Deactivate the MCP3004 ADC.
    adc+=(SPDAT&0xf0); // SPDR contains the low part of the result.
    adc>>=4;
    
    return adc;
}
float voltage (unsigned char channel)
{
    return ( (GetADC(channel)*4.84)/1023.0 ); // VCC=4.84V (measured)
}
float absVal (float input)
{
    if (input > 0)
        return input;
    
    return (input*-1);
}

unsigned char rx_byte ( float min )
{
    unsigned char j;
    unsigned int val;
    unsigned int v;
    //Skip the start bit
    val=0;
    wait_one_and_half_bit_time();
    for(j=0; j<4; j++)
    {
        P0_7 = !P0_7; //for testing
        v=GetADC(0);
        val|=(v>min)?(0x01<<j):0x00;
        wait_bit_time();
    }
    return val;
}

//----------------------WAIT FUNCTIONS--------------------------//

void wait_bit_time(void)
{ //Waits for 200ms
    _asm
    ;For a 22.1184MHz crystal one machine cycle
    ;takes 12/22.1184MHz=0.5425347us
    mov R1, #140
L2:	mov R0, #255
L1:	djnz R0, L1
    djnz R1, L2
    ret
    _endasm;
}

void wait_one_and_half_bit_time(void)
{ //Waits for 300ms
    _asm
    ;For a 22.1184MHz crystal one machine cycle
    ;takes 12/22.1184MHz=0.5425347us
    mov R1, #210
L4:	mov R0, #255
L3:	djnz R0, L3
    djnz R1, L4
    ret
    _endasm;
}

void wait1s(void)
{
    _asm
    ;For a 22.1184MHz crystal one machine cycle
    ;takes 12/22.1184MHz=0.5425347us
    mov R2, #20
M3:	mov R1, #250
M2:	mov R0, #184
M1:	djnz R0, M1 ; 2 machine cycles-> 2*0.5425347us*184=200us
    djnz R1, M2 ; 200us*250=0.05s
    djnz R2, M3 ; 0.05s*20=1s
    ret
    _endasm;
}

void wait_time_rotate (void)
{
    wait1s();
    _asm
    ;For a 22.1184MHz crystal one machine cycle
    ;takes 12/22.1184MHz=0.5425347us
    mov R2, #8
B6:	mov R1, #250
B5:	mov R0, #184
B4:	djnz R0, B4 ; 2 machine cycles-> 2*0.5425347us*184=200us
    djnz R1, B5 ; 200us*250=0.05s
    djnz R2, B6 ; 0.05s*20=1s
    ret
    _endasm;
    
}

void waithalfs (void)
{
    _asm
    ;For a 22.1184MHz crystal one machine cycle
    ;takes 12/22.1184MHz=0.5425347us
    mov R2, #10
M6:	mov R1, #250
M5:	mov R0, #184
M4:	djnz R0, M4 ; 2 machine cycles-> 2*0.5425347us*184=200us
    djnz R1, M5 ; 200us*250=0.05s
    djnz R2, M6 ; 0.05s*20=1s
    ret
    _endasm;
}

void waitalmosthalfs (void)
{
    _asm
    ;For a 22.1184MHz crystal one machine cycle
    ;takes 12/22.1184MHz=0.5425347us
    mov R2, #15
M12:	mov R1, #250
M11:	mov R0, #184
M10: djnz R0, M10 ; 2 machine cycles-> 2*0.5425347us*184=200us
    djnz R1, M11 ; 200us*250=0.05s
    djnz R2, M12 ; 0.05s*5=250ms
    ret
    _endasm;
}

void waitalmostfulls (void)
{
    _asm
    ;For a 22.1184MHz crystal one machine cycle
    ;takes 12/22.1184MHz=0.5425347us
    mov R2, #19
M15:	mov R1, #250
M14:	mov R0, #184
M13: djnz R0, M13 ; 2 machine cycles-> 2*0.5425347us*184=200us
    djnz R1, M14 ; 200us*250=0.05s
    djnz R2, M15 ; 0.05s*5=500ms
    ret
    _endasm;
}

//---------------------------------------------------------//

//-------------Car Logic Functions-------------------------//

void runCommand (unsigned int input)
{
    
    if (input == 0) //execute preset drive commands
        preset_drive ();
    
    else if (input == 4) //move closer (ie decrease "threshold")
    {
        if (threshold == FIXED_THRESHOLD_5)
        {
            threshold = FIXED_THRESHOLD_4;
            threshError = THRESH_ERROR_4;
            fixedAlignError = ALIGN_ERROR_4;
        }
        if (threshold == FIXED_THRESHOLD_4)
        {
            threshold = FIXED_THRESHOLD_3;
            threshError = THRESH_ERROR_3;
            fixedAlignError = ALIGN_ERROR_3;
        }
        else if (threshold == FIXED_THRESHOLD_3)
        {
            threshold = FIXED_THRESHOLD_2;
            threshError = THRESH_ERROR_2;
            fixedAlignError = ALIGN_ERROR_2;
        }
        else
        {
            threshold = FIXED_THRESHOLD_1;
            threshError = THRESH_ERROR_1;
            fixedAlignError = ALIGN_ERROR_1;
        }
    }
    
    else if (input == 5) //move farther (ie increase "threshold")
    {
        if (threshold == FIXED_THRESHOLD_1)
        {
            threshold = FIXED_THRESHOLD_2;
            threshError = THRESH_ERROR_2;
            fixedAlignError = ALIGN_ERROR_2;
        }
        else if (threshold == FIXED_THRESHOLD_2)
        {
           	threshold = FIXED_THRESHOLD_3;
           	threshError = THRESH_ERROR_3;
            fixedAlignError = ALIGN_ERROR_3;
        }
        else if (threshold == FIXED_THRESHOLD_3)
        {
           	threshold = FIXED_THRESHOLD_4;
           	threshError = THRESH_ERROR_4;
            fixedAlignError = ALIGN_ERROR_4;
        }
        else
        {
           	threshold = FIXED_THRESHOLD_5;
           	threshError = THRESH_ERROR_5;
            fixedAlignError = ALIGN_ERROR_5;
        }
        
    }
    
    else if (input == 6) //turn 180 left
    {
        rotate_left ();
        
        {
            //stuck waiting for next command
            if (voltage(0) < CUTOFF && voltage(1) < CUTOFF)
            {
                
                while (voltage(0) < CUTOFF);
                command = rx_byte(CUTOFF);
                //must send rotate instruction to ;eave while loop
                if (command == 6 || command == 7)
                    rotateFlag = 1;
            }
        }
        
        if (command == 6)
            rotate_left ();
        else
            rotate_right ();
    }
    
    else if (input == 7) //turn 180 right
    {
        rotate_right ();
        
        while (rotateFlag == 0)
        {
            
            if (voltage(0) < CUTOFF && voltage(1) < CUTOFF)
            {
                while (voltage(0) < CUTOFF);
                command = rx_byte(CUTOFF);
                if (command == 6 || command == 7)
                    rotateFlag = 1;
            }
        }
        
        if (command == 6)
            rotate_left ();
        
        else
            rotate_right ();
    }
    
    else if (input == 8) //parallel park
    {
        parallel_park ();
        
        //Stay parked until we get the command again
        while (parallelFlag == 0)
        {
            
            if (voltage(0) < CUTOFF && voltage(1) < CUTOFF)
            {
                
                while (voltage(0) < CUTOFF);
                command = rx_byte(CUTOFF);
                if (command == 8)
                    parallelFlag = 1;
            }
            
        }
        
        reverse_parallel_park ();
    }
    
    else if (input == 10)
        left_turn_blinker ();
    
    else if (input == 11)
        right_turn_blinker ();
}

void react (float dLeft, float dRight)
{
    int i = 0;
    
    alignError = absVal(dLeft-dRight);
    
    command = 0;
    
    //Case 1: receiver car is facing the transmitter head on
    if (alignError <= fixedAlignError)
    {
        //Case 1.1: car is too far away from tranmitter
        if (dLeft < threshold-threshError && dRight < threshold-threshError)
        {
            //car moves forwards
            LFwd = 1;
            LBkwd = 0;
            RFwd = 1;
            RBkwd = 0;
            //headlights turn on
            FRight = 1;
            FLeft = 1;
            BRight = 0;
            BLeft = 0;
            
        }
        //Case 1.2: car is too close to transmitter
        else if (dLeft > threshold+threshError && dRight > threshold+threshError)
        {
            //car moves backwards
            LFwd = 0;
            LBkwd = 1;
            RFwd = 0;
            RBkwd = 1;
            //reverse lights turn on
            FRight = 0;
            FLeft = 0;
            BRight = 1;
            BLeft = 1;
            
        }
        //Case 1.3: car is at the correct distance from transmitter
        else
        {
            //car remains stationary
            LFwd = 0;
            LBkwd = 0;
            RFwd = 0;
            RBkwd = 0;
            //all lights turn on
            FRight = 1;
            FLeft = 1;
            BRight = 1;
            BLeft = 1;
            
            //car checks for start bit (logic 0) to signal keypad commands or change in transmitter position
            while (1)
            {
                //transmitter changes position, exit while loop and respond accordingly
                if (absVal(voltage(0)-voltage(1)) > fixedAlignError)
                    break;
                //transmitter changes position, exit while loop and respond accordingly
                if (voltage(0) > threshold-threshError && voltage(0) < threshold+threshError)
                    break;
                //transmitter changes position, exit while loop and respond accordingly
                if (voltage(1) > threshold-threshError && voltage(1) < threshold+threshError)
                    break;
                //transmitter sends start bit, trip startFlag to prompt bit bang data reading
                if (voltage(0) < CUTOFF && voltage(1) < CUTOFF)
                {
                    //start bit received
                    startFlag = 1;
                    break;
                }
            }
            
            if (startFlag == 1)
            {   //read keypad command being sent via transmitter using bit bang
                while (voltage(0) < CUTOFF);
                command = rx_byte(CUTOFF);
                startFlag = 0;
                //execute the sent command
                runCommand(command);
            }
        }
    }
    
    //Case 2: Car not facing transmitter, must turn to face it before Case 1 movment possible
    else
    {
        //Case 2.1: left inductor too close to transmitter inductor
        if (dLeft > threshold)
        {
            //Case 2.1.1: left too close, right too far or equal
            if (dRight <= threshold)
            {
                //car rotates to the left by turning left motor in backwards direction
                LFwd = 0;
                LBkwd = 1;
                RFwd = 0;
                RBkwd = 0;
                //reverse lights turn on
                FRight = 0;
                FLeft = 0;
                BRight = 1;
                BLeft = 1;
            }
            
            //Case 2.1.2: both left and right inductors too close to transmitter inductor but their signal strengths aren't equal
            else
            {
                if (dLeft < dRight) //Case 2.1.2.a: right inductor is closer than left inductor
                {
                    //car rotates to the right by turning the right motor in backwards direction
                    LFwd = 0;
                    LBkwd = 0;
                    RFwd = 0;
                    RBkwd = 1;
                    //reverse lights turn on
                    FRight = 0;
                    FLeft = 0;
                    BRight = 1;
                    BLeft = 1;
                }
                
                //Case 2.1.2.b:left inductor is closer than right inductor
                else
                {
                    //car rotates to the left by turning the left motor in backwards direction
                    LFwd = 0;
                    LBkwd = 1;
                    RFwd = 0;
                    RBkwd = 0;
                    //reverse lights turn on
                    FRight = 0;
                    FLeft = 0;
                    BRight = 1;
                    BLeft = 1;
                }
            }
        }
        
        //Case 2.2: right inductor is too close to transmitter, left is either too far away or at the correct distance
        else if (dRight > threshold+threshError)
        {
            //car rotates right by turning right motor in backwards direction
            LFwd = 0;
            LBkwd = 0;
            RFwd = 0;
            RBkwd = 1;
            //reverse lights turn on
            FRight = 0;
            FLeft = 0;
            BRight = 1;
            BLeft = 1;
        }
        
        //Case 2.3: left inductor is too far away, right is either too far away or at the correct distance
        else if (dLeft < threshold-threshError)
        {
            //Case 2.3.1: right inductor is at the correct distance
            if (dRight == threshold)
            {
                //car rotates to the right by turning left motor in forwards direction
                LFwd = 1;
                LBkwd = 0;
                RFwd = 0;
                RBkwd = 0;
                //right turning light turns on
                FRight = 1;
                FLeft = 0;
                BRight = 0;
                BLeft = 0;
            }
            
            //Case 2.3.2: both inductors too far away from transmitter inductor
            else
            {
                //Case 2.3.2.a: left inductor is further away than right inductor
                if (dLeft < dRight)
                {
                    //car rotates to the right by turning left motor in forwards direction
                    LFwd = 1;
                    LBkwd = 0;
                    RFwd = 0;
                    RBkwd = 0;
                    //right turning light turns on
                    FRight = 1;
                    FLeft = 0;
                    BRight = 0;
                    BLeft = 0;
                }
                
                //Case 2.3.2.b: right inductor is further away than left inductor
                else
                {
                    //car rotates to the left by turning right motor in forwards direction
                    LFwd = 0;
                    LBkwd = 0;
                    RFwd = 1;
                    RBkwd = 0;
                    //left turning light turns on
                    FRight = 0;
                    FLeft = 1;
                    BRight = 0;
                    BLeft = 0;
                }
                
            }
        }
        
        //Case 2.4: left inductor is at correct distance and right inductor is too far away
        else
        {
            //car rotates to the left by turning right motor in forwards direction
            LFwd = 0;
            LBkwd = 0;
            RFwd = 1;
            RBkwd = 0;
            //left turning light turns on
            FRight = 0;
            FLeft = 1;
            BRight = 0;
            BLeft = 0;	
        }
    }
    
    //Motor and light port assignment
    P2_0 = LFwd;
    P2_1 = LBkwd;
    P2_2 = RBkwd;
    P2_3 = RFwd;
    P3_4 = BRight;
    P3_5 = BLeft;
    P3_6 = FRight;
    P3_7 = FLeft;
    
}
//--------Keypad Command Functions-------//

void rotate_left (void)
{   //turn 180 left
    
    rotateFlag = 0;
    
    P2_0 = 0; //LFwd
    P2_1 = 1; //LBkwd
    P2_2 = 0; //RBkwd
    P2_3 = 1; //RFwd
    
    wait_time_rotate ();
    //wait1s();
    //waithalfs();
    
    P2_0 = 0; //LBkwd
    P2_1 = 0; //LFwd
    P2_2 = 0; //RFwd
    P2_3 = 0; //RBkwd
    
}

//turn 180 right
void rotate_right (void)
{
    rotateFlag = 0;
    P2_0 = 1; //LFwd
    P2_1 = 0; //LBkwd
    P2_2 = 1; //RBkwd
    P2_3 = 0; //RFwd
    wait_time_rotate ();
    P2_0 = 0; //LFwd
    P2_1 = 0; //LBkwd
    P2_2 = 0; //RBkwd
    P2_3 = 0; //RFwd
    
}

//parallel park

void parallel_park (void)
{
    parallelFlag = 0;
    
    P2_0 = 0; //LFwd   GET INTO POSITION
    P2_1 = 1; //LBkwd
    P2_2 = 0; //RBkwd
    P2_3 = 0; //RFwd
    waitalmosthalfs();
    P2_0 = 0; //LFwd   MOVE BACK
    P2_1 = 1; //LBkwd
    P2_2 = 1; //RBkwd
    P2_3 = 0; //RFwd
    waitalmostfulls();
    P2_0 = 0; //LFwd  CORRECT POSITION
    P2_1 = 0; //LBkwd
    P2_2 = 1; //RBkwd
    P2_3 = 0; //RFwd
    waitalmosthalfs();
    
    P2_0 = 0; //LFwd  STOP
    P2_1 = 0; //LBkwd
    P2_2 = 0; //RBkwd
    P2_3 = 0; //RFwd
}

void reverse_parallel_park (void)
{
    P2_0 = 1; //LFwd  forward
    P2_1 = 0; //LBkwd
    P2_2 = 0; //RBkwd
    P2_3 = 1; //RFwd
    
    waithalfs();
    
    P2_0 = 0; //LFwd  turn left
    P2_1 = 1; //LBkwd
    P2_2 = 0; //RBkwd
    P2_3 = 1; //RFwd
    
    waithalfs();
    
    P2_0 = 1; //LFwd  forward
    P2_1 = 0; //LBkwd
    P2_2 = 0; //RBkwd
    P2_3 = 1; //RFwd
    
    waitalmosthalfs();
    wait_bit_time();
    wait_bit_time();
    wait_bit_time();
    
    P2_0 = 1; //LFwd  right
    P2_1 = 0; //LBkwd
    P2_2 = 1; //RBkwd
    P2_3 = 1; //RFwd
    
    waithalfs();
    wait_bit_time();
    wait_bit_time();
    wait_one_and_half_bit_time();
    wait_one_and_half_bit_time();
    
    P2_0 = 0; //LFwd  STOP
    P2_1 = 0; //LBkwd
    P2_2 = 0; //RBkwd
    P2_3 = 0; //RFwd
    
}

void left_turn_blinker (void)
{
    int i;
    
    for (i = 0; i < 3; i++)
    {
        P3_4 = 0; //BRight
        P3_5 = 1; //BLeft
        P3_6 = 0; //FRight
        P3_7 = 1; //FLeft
        waithalfs();
        P3_4 = 0; //BRight
        P3_5 = 0; //BLeft
        P3_6 = 0; //FRight
        P3_7 = 0; //FLeft
        waithalfs();
    }
}

void right_turn_blinker (void)
{
    int i;
    
    for (i = 0; i < 3; i++)
    {
        P3_4 = 1; //BRight
        P3_5 = 0; //BLeft
        P3_6 = 1; //FRight
        P3_7 = 0; //FLeft
        waithalfs();
        P3_4 = 0; //BRight
        P3_5 = 0; //BLeft
        P3_6 = 0; //FRight
        P3_7 = 0; //FLeft
        waithalfs();
    }
}

void preset_drive (void)
{
    P3_4 = 1; //BRight
    P3_5 = 1; //BLeft
    P3_6 = 1; //FRight
    P3_7 = 1; //FLeft
    waithalfs();
    P3_4 = 0; //BRight
    P3_5 = 0; //BLeft
    P3_6 = 0; //FRight
    P3_7 = 0; //FLeft
    waithalfs();
    P3_4 = 1; //BRight
    P3_5 = 1; //BLeft
    P3_6 = 1; //FRight
    P3_7 = 1; //FLeft
    waithalfs();
    P3_4 = 0; //BRight
    P3_5 = 0; //BLeft
    P3_6 = 0; //FRight
    P3_7 = 0; //FLeft
    waithalfs();
}
//---------------------------------------------------------//



//---------------Keypad Command Functions------------------//

void rotate_left (void)
{   //turn 180 left
    
    rotateFlag = 0;
    
    P2_0 = 0; //LFwd
    P2_1 = 1; //LBkwd
    P2_2 = 0; //RBkwd
    P2_3 = 1; //RFwd
    
    wait_time_rotate ();
    //wait1s();
    //waithalfs();
    
    P2_0 = 0; //LBkwd
    P2_1 = 0; //LFwd
    P2_2 = 0; //RFwd
    P2_3 = 0; //RBkwd
    
}

//turn 180 right
void rotate_right (void)
{
    rotateFlag = 0;
    P2_0 = 1; //LFwd
    P2_1 = 0; //LBkwd
    P2_2 = 1; //RBkwd
    P2_3 = 0; //RFwd
    wait_time_rotate ();
    P2_0 = 0; //LFwd
    P2_1 = 0; //LBkwd
    P2_2 = 0; //RBkwd
    P2_3 = 0; //RFwd
    
}

//parallel park

void parallel_park (void)
{
    parallelFlag = 0;
    
    P2_0 = 0; //LFwd   GET INTO POSITION
    P2_1 = 1; //LBkwd
    P2_2 = 0; //RBkwd
    P2_3 = 0; //RFwd
    waitalmosthalfs();
    P2_0 = 0; //LFwd   MOVE BACK
    P2_1 = 1; //LBkwd
    P2_2 = 1; //RBkwd
    P2_3 = 0; //RFwd
    waitalmostfulls();
    P2_0 = 0; //LFwd  CORRECT POSITION
    P2_1 = 0; //LBkwd
    P2_2 = 1; //RBkwd
    P2_3 = 0; //RFwd
    waitalmosthalfs();
    
    P2_0 = 0; //LFwd  STOP
    P2_1 = 0; //LBkwd
    P2_2 = 0; //RBkwd
    P2_3 = 0; //RFwd
}

void reverse_parallel_park (void)
{
    P2_0 = 1; //LFwd  forward
    P2_1 = 0; //LBkwd
    P2_2 = 0; //RBkwd
    P2_3 = 1; //RFwd
    
    waithalfs();
    
    P2_0 = 0; //LFwd  turn left
    P2_1 = 1; //LBkwd
    P2_2 = 0; //RBkwd
    P2_3 = 1; //RFwd
    
    waithalfs();
    
    P2_0 = 1; //LFwd  forward
    P2_1 = 0; //LBkwd
    P2_2 = 0; //RBkwd
    P2_3 = 1; //RFwd
    
    waitalmosthalfs();
    wait_bit_time();
    wait_bit_time();
    wait_bit_time();
    
    P2_0 = 1; //LFwd  right
    P2_1 = 0; //LBkwd
    P2_2 = 1; //RBkwd
    P2_3 = 1; //RFwd
    
    waithalfs();
    wait_bit_time();
    wait_bit_time();
    wait_one_and_half_bit_time();
    wait_one_and_half_bit_time();
    
    P2_0 = 0; //LFwd  STOP
    P2_1 = 0; //LBkwd
    P2_2 = 0; //RBkwd
    P2_3 = 0; //RFwd
    
}

void left_turn_blinker (void)
{
    int i;
    
    for (i = 0; i < 3; i++)
    {
        P3_4 = 0; //BRight
        P3_5 = 1; //BLeft
        P3_6 = 0; //FRight
        P3_7 = 1; //FLeft
        waithalfs();
        P3_4 = 0; //BRight
        P3_5 = 0; //BLeft
        P3_6 = 0; //FRight
        P3_7 = 0; //FLeft
        waithalfs();
    }
}

void right_turn_blinker (void)
{
    int i;
    
    for (i = 0; i < 3; i++)
    {
        P3_4 = 1; //BRight
        P3_5 = 0; //BLeft
        P3_6 = 1; //FRight
        P3_7 = 0; //FLeft
        waithalfs();
        P3_4 = 0; //BRight
        P3_5 = 0; //BLeft
        P3_6 = 0; //FRight
        P3_7 = 0; //FLeft
        waithalfs();
    }
}

void preset_drive (void)
{
    P3_4 = 1; //BRight
    P3_5 = 1; //BLeft
    P3_6 = 1; //FRight
    P3_7 = 1; //FLeft
    waithalfs();
    P3_4 = 0; //BRight
    P3_5 = 0; //BLeft
    P3_6 = 0; //FRight
    P3_7 = 0; //FLeft
    waithalfs();
    P3_4 = 1; //BRight
    P3_5 = 1; //BLeft
    P3_6 = 1; //FRight
    P3_7 = 1; //FLeft
    waithalfs();
    P3_4 = 0; //BRight
    P3_5 = 0; //BLeft
    P3_6 = 0; //FRight
    P3_7 = 0; //FLeft
    waithalfs();
}
//---------------------------------------------------------//

//         LP51B    MCP3004
//---------------------------
// MISO  -  P1.5  - pin 10
// SCK   -  P1.6  - pin 11
// MOSI  -  P1.7  - pin 9
// CE*   -  P1.4  - pin 8.
// 4.8V  -  VCC   - pins 13, 14
// 0V    -  GND   - pins 7, 12
// CH0   -        - pin 1
// CH1   -        - pin 2
// CH2   -        - pin 3
// CH3   -        - pin 4

void main (void)
{
    P2_0 = 0; //LFwd
    P2_1 = 0; //LBkwd
    P2_2 = 0; //RBkwd
    P2_3 = 0; //RFwd
    P3_4 = 0; //BRight
    P3_5 = 0; //BLeft
    P3_6 = 0; //FRight
    P3_7 = 0; //FLeft
    
    threshold = FIXED_THRESHOLD_1;
    threshError = THRESH_ERROR_1;
    fixedAlignError = ALIGN_ERROR_1;
    
    while(1)
    {
        leftVolt = voltage(0);
        rightVolt = voltage(1);
        //printf("V0=%4.5f ", leftVolt);
        //printf("V1=%4.5f ", rightVolt);
        //printf("\n");
        
        //Standard vehicle response
        react(leftVolt, rightVolt);
    }
    
}

