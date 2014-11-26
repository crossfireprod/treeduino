int const LED1 = 0;
int const LED2 = 1;
int const LED3 = 2;
int const potPin = 3;


void setup() {
  pinMode(LED1, OUTPUT);
  pinMode(LED2, OUTPUT);
  pinMode(LED3, OUTPUT);
  pinMode(potPin, INPUT);
}

void loop() {
 int potValue = (analogRead(potPin) / 4);
 
 if (potValue < 5) {
   digitalWrite(LED3, LOW);
   flickerLED();
   
 } else if (potValue > 5 && potValue < 250) {
   digitalWrite(LED3, LOW);
   analogWrite(LED1, potValue);
   analogWrite(LED2, potValue);
   
 } else if (potValue > 250) {
   digitalWrite(LED3, HIGH);
   digitalWrite(LED1, LOW);
   digitalWrite(LED2, LOW);
 }
}

 void flickerLED() {
    
  analogWrite(LED1, random(80)+135);
//  millis(random(50,150));
  analogWrite(LED3, random(80)+135);
}
