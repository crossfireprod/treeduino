int ledPin = 10;
int btnPin = 4;

int buttonState;             // the current reading from the input pin
int lastButtonState = LOW;   // the previous reading from the input pin

int mode = 0;

unsigned long previousMillis;

long lastDebounceTime = 0;  // the last time the output pin was toggled
long debounceDelay = 5;    // the debounce time; increase if the output flickers

void setup() {
 pinMode(ledPin, OUTPUT);
 pinMode(btnPin, INPUT);
} // END Setup

void loop() {
btnState();

 switch (mode) {
  case 0:
    analogWrite(ledPin, 0);
    break;
    
  case 1:
    flickerLED();
    break;

 } // END Switch Case Menu
} // END Loop


void btnState() {
// read the state of the switch into a local variable:
int reading = digitalRead(btnPin);

// check to see if you just pressed the button 
// (i.e. the input went from LOW to HIGH),  and you've waited 
// long enough since the last press to ignore any noise:

// If the switch changed, due to noise or pressing:
if (reading != lastButtonState) {
// reset the debouncing timer
lastDebounceTime = millis();
}

if ((millis() - lastDebounceTime) > debounceDelay) {
// whatever the reading is at, it's been there for longer
// than the debounce delay, so take it as the actual current state:
buttonState = reading;
}

 if (buttonState == HIGH) {
     mode += 1;
     
     if (mode > 1) {
       mode = 0;
     }
 } // END Mode Counter
 
// save the reading.  Next time through the loop,
// it'll be the lastButtonState:
lastButtonState = reading;

} // END btnState


void flickerLED() { 
  unsigned long currentMillis = millis();
  int interval = random(50,150);

  if (currentMillis - previousMillis > interval) {    
  //int pin = random(1, 3);
  previousMillis = currentMillis;  
  analogWrite(ledPin, random(80)+135);
  }

} // END flickerLED
