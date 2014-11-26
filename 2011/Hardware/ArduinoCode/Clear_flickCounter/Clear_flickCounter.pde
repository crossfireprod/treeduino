/*
 * Treeduino FlickCounter Reset
 *
 * Zeros out value in defined area of EEPROM.
 *
 * ONLY TO BE USED DURING TESTING.  ONCE OVERWRITTEN, VALUE CANNOT BE RETRIEVED.
 *
 */
 
// Flick Counter EEPROM Storage Libraries
#include "EEPROM.h"
#include "EEPROMAnything.h"
 
unsigned long flickCounter;

void setup() {
  // Value to be written to EEPROM
  flickCounter = 0;
  
  // Write Set Value.
  EEPROM_writeAnything(32, flickCounter);
}

void loop() {  
}
