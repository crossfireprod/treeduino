/*
The purpose of this code is to allow the Arduino to use the 
generic serial output of vixen lights to control 5 channels of LEDs. 
Author: Matthew Strange
Created: 14 October 2010

*/

// Output
int Chan1 = 2;  // red LED,   connected to digital pin 5
int Chan2 = 3;  // green LED, connected to digital pin 6
int Chan3 = 4;  // red LED,  connected to digital pin 9
int Chan4 = 5;  // green LED,  connected to digital pin 10
int Chan5 = 6;  // red LED,  connected to digital pin 11

int i = 0;     // Loop counter
int incomingByte[7];   // array to store the 7 values from the serial port

//setup the pins/ inputs & outputs
void setup()
{
  Serial.begin(9600);        // set up Serial at 9600 bps

  pinMode(Chan1, OUTPUT);   // sets the pins as output
  pinMode(Chan2, OUTPUT);
  pinMode(Chan3, OUTPUT);
  pinMode(Chan4, OUTPUT);
  pinMode(Chan5, OUTPUT);
}

void loop()
{  // 7 channels are coming in to the Arduino
   if (Serial.available() >= 7) {
    // read the oldest byte in the serial buffer:
    for (int i=0; i<8; i++) {
      // read each byte
      incomingByte[i] = Serial.read();
    }
    
    analogWrite(Chan1, incomingByte[0]);   // Write current values to LED pins
    analogWrite(Chan2, incomingByte[1]);   // Write current values to LED pins
    analogWrite(Chan3, incomingByte[2]);   // Write current values to LED pins
    analogWrite(Chan4, incomingByte[3]);   // Write current values to LED pins
    analogWrite(Chan5, incomingByte[4]);   // Write current values to LED pins
   }
}
