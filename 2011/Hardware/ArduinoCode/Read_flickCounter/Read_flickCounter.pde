/*
 * Treeduino FlickCounter Read
 *
 * Reads value from defined area in EEPROM.
 *
 */
 
// Flick Counter EEPROM Storage Libraries
#include "EEPROM.h"
#include "EEPROMAnything.h"
 
unsigned long flickCounter;

void setup() {
  // Read value from specified location into 32bit long.
  EEPROM_readAnything(32, flickCounter);

  Serial.begin(9600);
  Serial.print("flickCounter = ");
  Serial.print(flickCounter);
}

void loop() {
  
}
