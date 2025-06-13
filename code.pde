/*
Main module bor Brain-ring/Jeopardy system;
 Bases on Olimexino-stm32 board
 Pin numbers are subject to change for logistic reasons
 version 0.0.1
 
 Functionality: basic input/output logic;
 supports up to 6 player buttons;
 
 TO DO: LCD;
 TO DO: Buzzer;
 TO DO: interactions with software on the laptop:
 - detecting if someone is reading our output; 50ms delay on println to overcome;
 - reading/converting/resending output over some protocol agreementl
 
 Portability: Any Arduino/Maple compatible board with, eventually, some charlieplexing/reducing number of players/making LCD 4-bit; 
 hardware timer, afaik, is not portable;
 2012
 */

const int NP = 6; //number of players, <=6


const int PlayerButton[6] = {
  0,1,2,12,4,5}; //Array of player button pins // Note that D3 is LED2 and somehow it interferes with our work on the first run(((
const int PlayerLED[6] = {
  6,7,8,9,10,11}; //Array of player led pins

const int TimeLED = BOARD_LED_PIN; // on if timer is on
const int FalseLED = 3;// on if false start //can use 14, but let's use the second LED

const int Buzz = 24; // buzzer pin//yet to be used

const int ResetButton = 19;//button to reset all variable to default; 
const int TimerButton[3] = {
  16,17,18}; // launch 60s,20s,5s respectively

const int Trust = 500;//block timer buttons for Trust ms after one of them pressed;
//sort of software debouncing plus avoids long presses
int i = 0; //iteration variable


volatile int TimeTotal = 0; // time launched for in seconds
int TimeLaunch = 0;// time when we launched the countdown

volatile int secs = 0; //Decreased on the hardware timer interrupt;
HardwareTimer timer(1);//we use hardware timer; This is not directly portable to Arduino

volatile boolean Counting = false; //true if the timer is on
boolean Buzzing = false; //might be not necessary
boolean ButtonFree = true; // false if any player pressed a button and reset button is yet to be hit;

void setup(){
  //not yet needed;
  establishContact();

  for (i=0;i<NP;i++){
    pinMode(PlayerButton[i],INPUT_PULLUP);//setting all buttons to input pull-up mode; HIGH reading stand for unpressed;
    pinMode(PlayerLED[i],OUTPUT);
  }

  for (i=0;i<3;i++){
    pinMode(TimerButton[i],INPUT_PULLUP);
  }

  pinMode(ResetButton,INPUT_PULLUP); 
  pinMode(TimeLED,OUTPUT);//evident part

  pinMode(FalseLED,OUTPUT);

  pinMode(Buzz, OUTPUT);
  ResetAll();//resetting all output channels;

  timer.pause();
  timer.setPeriod(1000*1000);//period of 1 second 
  timer.setChannel1Mode(TIMER_OUTPUT_COMPARE);
  timer.setCompare(TIMER_CH1, 0 );  // Interrupt 1 count after each update
  timer.attachCompare1Interrupt(tick);


}
void loop(){



  for (i=0;i<NP;i++){//asking all player buttons
    if((digitalRead(PlayerButton[i])==LOW) && ButtonFree){
      ButtonFree = false; //not accepting other button hits
      if (!Counting){
        digitalWrite(FalseLED,HIGH); // if it was before the time, then light up false start LED
      } 
      else { //do nothing atm. stub for buzzer, maybe
      }//endifelse
      digitalWrite(TimeLED,LOW); // in any way, timer will need to be restarted;
      Counting = false; //timer is off
      timer.pause();
      digitalWrite(PlayerLED[i],HIGH); //who pressed?
      SerialUSB.println("pressed");
      SerialUSB.println(i+1);
    } //endif
  }//endfor

  for (i=0;i<3;i++){//asking timer buttons
    if ((digitalRead(TimerButton[i])==LOW) && (ButtonFree) && ((!Counting) || (millis()-TimeLaunch>Trust))){
      //      Button is pressed and players didn't press and (either not counting  or the timer button is no longer locked)

      TimeTotal = TimeToLaunch(2-i); //first button stands for 60s
      timer.pause();
      timer.refresh();
      TimeLaunch = millis();
      timer.resume();

      digitalWrite(TimeLED,HIGH);
      Counting = true;
      SerialUSB.println("Time is up.");

    }//endif
  }//endfor

  if (digitalRead(ResetButton)==LOW){
    ResetAll(); //reset button;
  }


  //working with timer Looks like we will use hardware timers; see for examples on the site;

}//endloop

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

  digitalWrite(Buzz,LOW);

  Counting = false;
  Buzzing = false;
  ButtonFree = true;

  timer.pause();
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


void tick(){
  TimeTotal--;
  if (Counting){
    switch (TimeTotal){
    case 0: 
      Counting = false; 
      SerialUSB.println(millis()-TimeLaunch);
      timer.pause();
      digitalWrite(TimeLED,LOW); //time is over

      break;
    case 10: 
      donothing(); //stub for buzzer. Note, maybe break is not needed;
    default:   
      SerialUSB.println(TimeTotal);
      break; //stub for LCD  
    }//endswitch
  }//endif
}

void donothing(){
}















