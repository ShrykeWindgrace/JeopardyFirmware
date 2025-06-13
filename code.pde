/*
Main module bor Brain-ring/Jeopardy system;
 Bases on Olimexino-stm32 board
 Pin numbers are subject to change for logistic reasons
 version 0.1.2 ("interrupted buttons, buzzer, LCD")
 
 Functionality: basic input/output logic;
 supports up to 6 player buttons;
 
 TO DO: test this;
 
 TO DO: interactions with software on the laptop:
 - detecting if someone is reading our output; 50ms delay on println to overcome;
 - reading/converting/resending output over some protocol agreementl
 
 Portability: Due to extended usage of external interrupts, atm it's limited to Maple boards.
 
 2012
 */
#include <LiquidCrystal.h> //required for easy lcd usage
 
const int NP = 6; //number of players, <=6


const int PlayerButton[6] = {
  0,1,2,4,5,6}; //Array of player button pins // Note that D3 is LED2 and somehow it interferes with our work on the first run(((

const voidFuncPtr PlayerHandler[6] = {
  PlayerHandler1,PlayerHandler2,PlayerHandler3,PlayerHandler4,PlayerHandler5,PlayerHandler6};

const uint16 PlayerButtonLogic[6]={
  1u,2u,4u,8u,16u,32u};

const int PlayerLED[6] = {
  15,16,17,18,19,20}; //Array of player led pins

const int TimeLED = BOARD_LED_PIN; //=13; on if timer is on
const int FalseLED = 3;// on if false start //can use 14, but let's use the second LED

const int Buzz = 24; // buzzer pin

const int ResetButton = 10;//button to reset all variables to default; 
const int ResetButtonLogic = 512u;

const int TimerButton[3] = {
  7,8,9}; // launch 60s,20s,5s respectively
const voidFuncPtr TimeHandler[3] = {
  TimeHandler60,TimeHandler20,TimeHandler5};
const int TimerButtonLogic[3] = {
  64u,128u,256u};

int i = 0; //iteration variable

LiquidCrystal lcd(25,27,29,31,33,35);//everything leads to ext headers
//                rs,e, d4,d5,d6,d7
   
volatile int TimeTotal = 0; // time launched for in seconds
//int TimeLaunch = 0;// time when we launched the countdown

HardwareTimer TickTimer(1);//we use hardware timer for the global timing
HardwareTimer BuzzTimer(4);//the pwm timer to drive a buzzer;
HardwareTimer BuzzLockerTimer(2); // the timer to turn buzzer on and off;
volatile boolean Counting = false; //true if the timer is on
volatile boolean ButtonFree = true; // false if any player pressed a button and reset button is yet to be hit;

const int TimeTickLogic = 1024u;

//const int freq[5] = {};
const int start = 1000; //frequencies
const int ten = 1500;
const int over = 500;
const int good = 750;
volatile uint16 state=0; // state that describes the buttons pressed;
/* first six bits correspond to player buttons; 0 to represent UNPRESSED;
 next three bits correspond to "launch time" buttons; 0 to represent UNPRESSED; 60s, 20s, 5s respectively
 512u correspond to reset button. we need to include it here, because reset now operates with lcd, and it has
 delays
 1024u stands for time ticks. same as above, we need delays
 */
void setup(){
  //not yet needed;
  //establishContact();

  lcd.begin(16,2);
  lcd.clear();
  
  for (i=0;i<NP;i++){
    pinMode(PlayerButton[i],INPUT_PULLUP);//setting all buttons to input pull-up mode; HIGH reading stand for unpressed;
    attachInterrupt(PlayerButton[i],PlayerHandler[i],FALLING); //we attach the corresponding interrupts
    pinMode(PlayerLED[i],OUTPUT);
  }

  for (i=0;i<3;i++){
    pinMode(TimerButton[i],INPUT_PULLUP);
    attachInterrupt(TimerButton[i], TimeHandler[i], FALLING);//we attach the corresponding interrupts
  }

  pinMode(ResetButton,INPUT_PULLUP); 
  attachInterrupt(ResetButton, ResetHandler, FALLING);

  pinMode(TimeLED,OUTPUT);//evident part
  pinMode(FalseLED,OUTPUT);

  pinMode(Buzz, PWM);
  ResetAll();//resetting all output channels;

  TickTimer.pause();
  TickTimer.setPeriod(1000*1000);//period of 1 second 
  TickTimer.setChannel1Mode(TIMER_OUTPUT_COMPARE);
  TickTimer.setCompare(TIMER_CH1, 0 );  // Interrupt 0 count after each update
  TickTimer.attachCompare1Interrupt(TickHandler);

  BuzzLockerTimer.pause();
  //BuzzLockerTimer.setPrescaleFactor(1);
  //BuzzLockerTimer.setOverflow(2*1000*1000);//period of 1 second plus something else, anyway, we don't need that
  BuzzLockerTimer.setPeriod(2*1000000);
  BuzzLockerTimer.setChannel1Mode(TIMER_OUTPUT_COMPARE);
  BuzzLockerTimer.setCompare(TIMER_CH1, 1000000 );  // Interrupt 1000000 count after each update
  BuzzLockerTimer.attachCompare1Interrupt(BuzzTick);


  BuzzTimer.pause();
  BuzzTimer.setPrescaleFactor(72);  // microseconds
  BuzzTimer.setMode(TIMER_CH4,TIMER_PWM);

}
void loop(){

  while(state==0){
  }//meaning, wait for input;

  if (state&ResetButtonLogic>0){//reset button
    ResetAll();
  }else{
  if (state&TimeTickLogic>0){//time tick
    TimeTick();}else{
  if ((state&63u)>0){//pressed a player button
    for(i=0;i<NP;i++){
      if (state|PlayerButtonLogic[i]>0){
	    lcd.clear();
		lcd.setCursor(0,0);
        if (!Counting){
          tone(over); 
          digitalWrite(FalseLED, HIGH);
		  lcd.print("FALSESTART");
        }
        else{
          tone(good);
		  lcd.print("FIRST TO PRESS");
        }
		lcd.setCursor(0,1);
		lcd.print("TABLE "+(i+1));
        Counting=false;
        TickTimer.pause();
        digitalWrite(TimeLED,LOW);
        digitalWrite(PlayerLED[i],HIGH);
        digitalWrite(TimeLED,LOW);
      }//end if player
    }//endfor
  }//end if 63
  else{//time button pressed
    if (!Counting){
      TickTimer.pause();
      TickTimer.refresh();
      TickTimer.resume();
      tone(start);
      Counting = true;
	  lcd.clear();
	  lcd.print("TIME REMAINING");

    }
    state = 0; // allowing to go listening again; in case of counting, this just ignores the triggers from those buttons
  }//endelse if 63
}//endglobal else
}







}//endloop
// freq in Hz    duration in ms
void tone( int freq) {
  BuzzTimer.pause();
  BuzzLockerTimer.pause();
  //pinMode(Buzz,PWM);
  //BuzzTimer.setPrescaleFactor(72);  // microseconds
  BuzzTimer.setOverflow(1000000/freq);
  //BuzzTimer.setMode(TIMER_CH4,TIMER_PWM);
  BuzzTimer.setCompare(TIMER_CH4,1000000/freq/2);
  //BuzzTimer.setCount(0);      // probaby doesn't matter
  BuzzTimer.refresh(); // start it up
  BuzzLockerTimer.refresh();
  BuzzTimer.resume();
  BuzzLockerTimer.resume();
}
//not yet needed

void establishContact() {
  while (SerialUSB.available() <= 0) {
    SerialUSB.println(BOARD_BUTTON_PIN);   // send an initial string
    delay(300);
  }
}


void ResetAll(){
  for (i=0;i<NP;i++){
    digitalWrite(PlayerLED[i],LOW);
  }//endfor

  digitalWrite(TimeLED,LOW);

  digitalWrite(FalseLED,LOW);

  pwmWrite(Buzz,0); //???

  Counting = false;
  //Buzzing = false;
  ButtonFree = true;

  BuzzLockerTimer.pause();
  TickTimer.pause();
  BuzzTimer.pause();
  state =0;
  
  lcd.clear();
}//endresetall

int TimeToLaunch(int var){
  if ((var>=0)&&(var<3)){
    return (25*i*i+5*i+10)/2+1;
  }
  else{
    return 1000; //Meaning WTF?
  }
  /*
  easy to check the table
   0-> 5000
   1-> 20000
   2-> 60000
   else->1000
   */
}


void TimeTick(){
  TimeTotal--;
  if (Counting){
    switch (TimeTotal){
    case 0: 
      Counting = false; 
      tone(over);
      //SerialUSB.println(millis()-TimeLaunch);
      TickTimer.pause();
      digitalWrite(TimeLED,LOW); //time is over
      state=0;
	  lcd.clear();
	  lcd.print("TIME IS OVER!");
      break;
    case 10: 
      tone(ten);
      
    default:   
      //SerialUSB.println(TimeTotal);
	  lcd.setCursor(0,1);
	  lcd.print(TimeTotal+" seconds");
      break; //stub for LCD  
    }//endswitch
  }//endif
}

void donothing(){
}

//Handlers for player buttons
void PlayerHandler1(){
  state |= PlayerButtonLogic[0]; // rise the corresponding bit
}

void PlayerHandler2(){
  state |= PlayerButtonLogic[1];
}

void PlayerHandler3(){
  state |= PlayerButtonLogic[2];
}

void PlayerHandler4(){
  state |= PlayerButtonLogic[3];
}

void PlayerHandler5(){
  state |= PlayerButtonLogic[4];
}

void PlayerHandler6(){
  state |= PlayerButtonLogic[5];
}

//handlers for corresponding time buttons;

void TimeHandler60(){
  state |= TimerButtonLogic[0];
  TimeTotal = 61;
}

void TimeHandler20(){
  state |= TimerButtonLogic[1];
  TimeTotal = 21;
}

void TimeHandler5(){
  state |= TimerButtonLogic[2];
  TimeTotal = 6;
}

void BuzzTick(){
  pwmWrite(Buzz, 0);
  BuzzTimer.pause();
  BuzzLockerTimer.pause();
}

void ResetHandler(){
  state |= ResetButtonLogic;
}

void TickHandler(){
  state |= TimeTickLogic;
}






