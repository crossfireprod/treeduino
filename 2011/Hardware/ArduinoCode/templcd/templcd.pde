#include <LiquidCrystal.h>
#include <OneWire.h>
#include <DallasTemperature.h>

// initialize the library with the numbers of the LCD interface pins
LiquidCrystal lcd(12, 11, 5, 4, 3, 2);

// Define OneWire Bus pin.
#define ONE_WIRE_BUS 7

// Setup a oneWire instance to communicate with any OneWire devices (not just Maxim/Dallas temperature ICs)
OneWire oneWire(ONE_WIRE_BUS);

// Pass our oneWire reference to Dallas Temperature. 
DallasTemperature sensors(&oneWire);

void setup() { 
  lcd.begin(16, 2);
  sensors.begin();
  
    lcd.setCursor(0, 0);
  lcd.print("Fridge: ");
  
  //
  
  lcd.setCursor(13, 0);
  lcd.print((char)223);
  lcd.print("F");
  
  //
  //
  
  lcd.setCursor(0, 1);
  lcd.print("Freeze: ");
  
   
  lcd.setCursor(13, 1);
  lcd.print((char)223);
  lcd.print("F");

}

void loop() {
  
  sensors.requestTemperatures();
  
  lcd.setCursor(7, 0);
  lcd.println(sensors.getTempFByIndex(0));
  
  lcd.setCursor(7, 1);
  lcd.println(sensors.getTempFByIndex(1));
 
}

