int ledPin = 0;
int btnPin = 4;
int mode = 0;

void setup() {
 pinMode(ledPin, OUTPUT);
 pinMode(btnPin, INPUT);
 
 randomSeed(analogRead(3));

}

void loop() {
btnState();

if (mode == 0) {
digitalWrite(ledPin, LOW);

} else if (mode == 1) {
flickerLED();

} else if (mode == 2) {
digitalWrite(ledPin, HIGH);  
}
  
}

void btnState() {
int pinState = digitalRead(btnPin);

 if (pinState == HIGH) {
   if (mode == 2) {
     mode = 0;
   } else {
   mode += 1;
   }
 } 
}

void flickerLED() {
  int pin = random(1, 3);
    
  analogWrite(pin, random(80)+135);
  millis(random(50,150));
}
