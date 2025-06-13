/*
Main module bor Brain-ring/Jeopardy system;
 Bases on Olimexino-stm32 board
 Pin numbers are subject to change for logistic reasons
 version 0.2.2 (" interrupted buttons, transistor-governed sound, 7-digit LED")
 
 Functionality: basic input/output logic;
 supports up to 6 player buttons;
 
 TO DO: test this;
 
 TO DO: interactions with software on the laptop:
 - detecting if someone is reading our output; 50ms delay on println to overcome;
 - reading/converting/resending output over some protocol agreement
 
 Portability: Due to extended usage of external interrupts, atm it's limited to Maple boards.
 
 2012
 */

const int NP = 6; //number of players, <=6


const int PlayerButton[6] = {
  7,6,5,2,1,0}; //Array of player button pins // Note that D3 is LED2 and somehow it interferes with our work on the first run(((

const voidFuncPtr PlayerHandler[6] = {
  PlayerHandler1,PlayerHandler2,PlayerHandler3,PlayerHandler4,PlayerHandler5,PlayerHandler6};


const int PlayerLED[6] = {
  8,9,10,11,12,13}; //Array of player led pins

const int TimeLED = 4; // on if timer is on
const int FalseLED = 3;// on if false start 

const int Buzz = 24; // buzzer pin

const int ResetButton = 19;//button to reset all variables to default; 


const int TimerButton[3] = {
  32,30,16}; // launch 60s,20s,5s respectively
const voidFuncPtr TimeHandler[3] = {
  TimeHandler60,TimeHandler20,TimeHandler5};


int i = 0; //iteration variable

//LiquidCrystal lcd(35,33,31,29,27,25);//everything leads to ext headers
//                rs,e, d4,d5,d6,d7

const int Letters[14][7] = {
  {
    HIGH, HIGH, HIGH, HIGH, HIGH, HIGH, LOW                         }
  ,//0
  {
    LOW, HIGH, HIGH, LOW, LOW, LOW, LOW                         }
  ,//1
  {
    HIGH, HIGH, LOW, HIGH, HIGH, LOW, HIGH                         }
  ,//2
  {
    HIGH, HIGH, HIGH, HIGH, LOW, LOW, HIGH                         }
  ,//3
  {
    LOW, HIGH, HIGH, LOW, LOW, HIGH, HIGH                         }
  ,//4
  {
    HIGH, LOW, HIGH, HIGH, LOW, HIGH, HIGH                         }
  ,//5
  {
    HIGH, LOW, HIGH, HIGH, HIGH, HIGH, HIGH                         }
  ,//6
  {
    HIGH, HIGH, HIGH, LOW, LOW, LOW, LOW                         }
  ,//7
  {
    HIGH, HIGH, HIGH, HIGH, HIGH, HIGH, HIGH                         }
  ,//8
  {
    HIGH, HIGH, HIGH, HIGH, LOW, HIGH, HIGH                         }
  ,//9
  {
    HIGH, LOW, LOW, LOW, HIGH, HIGH, HIGH                         }
  ,//F
  {
    HIGH, LOW, LOW, HIGH, HIGH, HIGH, LOW                         }
  ,//C
  {
    HIGH, HIGH, HIGH, HIGH, LOW, LOW, LOW                         }
  ,//D
  {
    LOW, LOW, LOW, LOW, LOW, LOW, LOW                         }//empty
};

const int LetterPins[2][7]={
  {
    //   28,34,36                 
    34,28,33,35,37,36,25     
  }
  , //!! IMPORTANT! this must be changed!
  {
    17,15,29,27,31,18,26                        }
};


volatile int TimeTotal = 0; // time launched for in seconds
//int TimeLaunch = 0;// time when we launched the countdown

HardwareTimer TickTimer(1);//we use hardware timer for the global timing
HardwareTimer BuzzTimer(4);//the pwm timer to drive a buzzer;
HardwareTimer BuzzLockerTimer(2); // the timer to turn buzzer on and off;
volatile boolean Counting = false; //true if the timer is on
volatile boolean ButtonFree = true; // false if any player pressed a button and reset button is yet to be hit;


const int start = 1000; //frequencies
const int ten = 1500;
const int over = 500;
const int good = 750;
volatile int state=0; // state that describes the buttons pressed;
volatile int btn = -1; //the number of the pressed player button
/* 0 nothing
 1 player button, the exact number is a global variable
 2 time button, the exact number is a global variable
 3 time tick
 4 reset.
 */


void setup(){
  //not yet needed;
  //establishContact();

  //lcd.begin(16,2);
  //lcd.clear();
  int j=0;
  for (i=0;i<7;i++){
    for (j=0;j<2;j++){
      pinMode(LetterPins[j][i],OUTPUT);
      digitalWrite(LetterPins[j][i],LOW);
    }
  }


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
  //lcd.print("Welcome!");

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

  //establishContact();
  //  for(i=0;i<7;i++){
  //    digitalWrite(LetterPins[0][i],LOW);
  //    //delay(1500);
  //  }
  //  ShowLetter(1,13);
  //  digitalWrite(14,HIGH);
  //  delay(2500);
  //  for(i=0;i<7;i++){
  //    digitalWrite(LetterPins[0][i],HIGH);
  //    delay(1500);
  //  }
}
void loop(){

  while(state==0){
  }//meaning, wait for input;

  switch(state){
  case 1: //player button

    // SerialUSB.print("pressed");
    // SerialUSB.println(btn);
    //lcd.clear();
    //lcd.setCursor(0,0);
    if (!Counting){
      tone(over); 
      digitalWrite(FalseLED, HIGH);
      //lcd.print("FALSESTART");
      ShowLetter(0, 10);
    }
    else{
      tone(good);
      //lcd.print("FIRST TO PRESS");
      ShowLetter(0,13);
    }
    //lcd.setCursor(0,1);
    //lcd.print("TABLE ");
    //lcd.print(6-btn);
    ShowLetter(1, 6-btn);
    Counting=false;
    TickTimer.pause();
    digitalWrite(TimeLED,LOW);
    digitalWrite(PlayerLED[btn],HIGH);


    break;

  case 2: //timer button
    if (!Counting&&ButtonFree){
      TickTimer.pause();
      TickTimer.refresh();
      TickTimer.resume();
      tone(start);
      Counting = true;
      //ButtonFree = true;
      digitalWrite(TimeLED,HIGH);
      //lcd.clear();
      //lcd.print("TIME REMAINING");
      // SerialUSB.println(TimeTotal);
    }
    break;
  case 3: 
    TimeTick(); //interrupt from tick timer
    if (Counting){
      //    SerialUSB.println(TimeTotal);
    }
    break;
  case 4: //reset button
    ResetAll();
    //  SerialUSB.println("reset");
    break;

  default: 
    state=0;//jic
  }
  state = 0;//allows to run further

}//endloop


// freq in Hz    duration in ms
void tone( int freq) {
  BuzzTimer.pause();
  BuzzLockerTimer.pause();
  BuzzTimer.setOverflow(1000000/freq);

  BuzzTimer.setCompare(TIMER_CH4,1000000/freq/2);
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

  BuzzLockerTimer.pause();
  TickTimer.pause();
  BuzzTimer.pause();
  state = 0;
  btn = -1;
  //lcd.clear();
  ShowLetter(0,11);
  ShowLetter(1,12);
  ButtonFree = true;
}//endresetall



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
      //lcd.clear();
      //lcd.print("TIME IS OVER!");
      ShowLetter(0,12);
      ShowLetter(1,11);
      break;
    case 10: 
      tone(ten);

    default:   
      //SerialUSB.println(TimeTotal);
      //lcd.setCursor(0,1);
      //lcd.print(TimeTotal);
      //lcd.print(" seconds");
      ShowLetter(0,TimeTotal/10);
      ShowLetter(1,TimeTotal%10);
      break;  
    }//endswitch
  }//endif
}

void donothing(){
}

//Handlers for player buttons
void PlayerHandler1(){
  if (ButtonFree){
    state = 1;
    btn = 0;
    ButtonFree = false;
  }
}

void PlayerHandler2(){
  if (ButtonFree){
    state = 1;
    btn = 1;
    ButtonFree = false;
  }
}

void PlayerHandler3(){
  if (ButtonFree){
    state = 1;
    btn = 2;
    ButtonFree = false;
  }
}

void PlayerHandler4(){
  if (ButtonFree){
    state = 1;
    btn = 3;
    ButtonFree = false;
  }
}

void PlayerHandler5(){
  if (ButtonFree){
    state = 1;
    btn = 4;
    ButtonFree = false;
  }
}

void PlayerHandler6(){
  if (ButtonFree){
    state = 1;
    btn = 5;
    ButtonFree = false;
  }
}

//handlers for corresponding time buttons;

void TimeHandler60(){
  if (!Counting&&ButtonFree){
    state = 2;
    TimeTotal = 60;
  }
}

void TimeHandler20(){
  if (!Counting&&ButtonFree){
    state = 2;
    TimeTotal = 20;
  }
}

void TimeHandler5(){
  if (!Counting&&ButtonFree){
    state = 2;
    TimeTotal = 5;
  }
}

void BuzzTick(){
  pwmWrite(Buzz, 0);
  BuzzTimer.pause();
  BuzzLockerTimer.pause();
}

void ResetHandler(){
  state = 4;
}

void TickHandler(){
  state = 3;
}




void ShowLetter(int pos, int c){
  if ((pos>=0)&&(pos<=1)&&(c>=0)&&(c<=13)){
    for (int j=0;j<7;j++)
      digitalWrite(LetterPins[pos][j],Letters[c][j]);
  }
}
























