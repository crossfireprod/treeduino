/*
 ***************************
 *     Treeduino 2011      *
 * Zach Cross & Jacob Ford *
 ***************************
 * 
 * Arduino Uno w/ ETHShield
 * Arduino IDE 1.5.4 on Ubuntu 13.10
 *
 * Most of the Ethernet related parts of the code were derived from the Web_Demo
 * Sketch of the Webduino library (MIT License) by Ben Combee.  
 * (It is an awesome library, great job!)
 * https://github.com/sirleech/Webduino
 *
 */

/* CHANGELOG
 * "b" After version number denotes that code revision is in progress and may not be functional.
 * 
 *  v1.0: 
 *    Core of 2011 Treeduino code is compiled.  It is heavily based off of Web_Demo Sketch.
 *      The sketch is being re-compliled by hand in an effort to keep the code as lean as possible.
 *      Updates to the Webduino Library to coincide with the Arduino Uno & IDE 022 also necesitate this. (Z)
 *
 *  v1.1:
 *    Treeduino specific changes begin.  Changes are based on Treeduino 2010 v1.9WORKING code. (Z)
 *    - "outputPins" method from 2010 is implemented.  This includes page and output formatting. (Z)
 *        + Analog Output Print is removed.
 *        + For loop only generates lines for relevant pins.
 *        + Outputs are named.
 *        + Page background is set.
 *    - Client is re-directed back to /form upon submit. (Z)
 *        + There are some lingering timeout issues.  Being attributed to network current (PSB Dorm Room).
 *          Expected to resolve itself when properly installed. (Z)
 *    - Digital Pins 2-7 set as OUTPUT in setup method. (Z)
 *    - Coherently formatted digital pin status print.  As seen when not on "/form" page. (Z)
 *    - Commented out Analog Pin Read in jsonCMD Method. (Z)
 *
 *  v1.2b:
 *   // -b Serial communication functionality is implemented. (Z)
 *   // -b Version information is printed over serial on startup. (Z)
 *      - EEPROM anything header file added to EEPROM Library. (Z)
 *      - Flick counter implemented.  Counter stored in 32 bit unsigned long variable. (Z)
 *        EEPROM writeAnything templates were added to EEPROM library.
 *        Sketch written to zero out EEPROM variable during testing. (Clear_flickCounter.pde)
 *
 *  v1.3b:
 *      - Twitter is implemented. (Z)
 *      - Serial communication scrapped. (Z)
 *
 *  v1.4:
 *      - Built off of version 1.2, Twitter & Serial Scrapped. (Z)
 *      - iFrame formatting changes have begun, approaching finalized version. (Z)
 *      - Version number is now invisibly printed (same color as background) in the web form.
 *      - Channels Mapped - See Chart Below. (Z)
 *      - Added Channel Test Sequence in Setup method. (Z)
 *
 * 
 *        NOTE: Be sure to indicate output pins in Setup method as well as when printing 
 *               radio buttons in outputPins method.  Failure to set pins as outputs will
 *               keep them from being able to put out enough current to fully open or close
 *               the transistors.
 *
 *  v1.5:
 *      - RGB Fade Channel Implemented.  Fade channel turns on ATTiny85 that takes care of fading between channels via software PWM. (Z)
 *          NOTE:  RGB Fade overrides the Red, Green, and Blue star channels.
 *
 *
 *       *Channel - Pin Mapping*
 *        | Pin   | Assignment|
 *        | 0     | RX        |
 *        | 1     | TX        |
 *        | 2     | Ch. 0     |
 *        | 3     | Ch. 1     |
 *        | 4     | Ch. 2     |
 *        | 5     | Ch. 3     |
 *        | 6     | Ch. 4     |
 *        | 7     | Red       |
 *        | 8     | Green     |
 *        | 9     | Blue      |
 *        | 10-13 | Ethernet  |
 *
 *
 *  v1.6:
 *      - Channels have been named!
 *      - Treeduino goes live in BETA.
 *
 *        *********Channel - Pin Mapping**********
 *        | Pin   | Assignment| Name             |
 *        | 0     | RX        |                  |
 *        | 1     | TX        |                  |
 *        | 2     | Ch. 0     | Tree White       |
 *        | 3     | Ch. 1     | Tree Rainbow     |
 *        | 4     | Ch. 2     | Banister White   |
 *        | 5     | Ch. 3     | Banister Rainbow |
 *        | 6     | Ch. 4     | Little Tree      |
 *        | 7     | Red       |                  |
 *        | 8     | Green     |                  |
 *        | 9     | Blue      |                  |
 *        | 10-13 | Ethernet  |                  |
 *
 *  v.17:
 *      - IFrame CSS & other formatting was added to polish site for launch.
 *         + See Radio Button generation section of code for majority of changes.
 *
 *      - Treeduino code revisions v1.5/6 may be compromised by accidental "save-overs."
 *
 *  v1.9:
 *      - 2013 Development Season Begins
 *      - Reset Flick Counter, moved starting EEPROM address from 32 to 64 for wear leveling.
 *
 *
 */
char verNum[] = "Treeduino 2013 | v1.9";  // Saved to EEPROM in Setup method as well as printed invisibly (same color as background) in the web form.

// Ititialization Configuration //////////////////////////////////////////////////////////

/***LIBRARIES***/
  // Webduino
  #include "SPI.h"
  #include "Ethernet.h"
  #include "WebServer.h"

  // Flick Counter EEPROM Storage
  #include "EEPROM.h"
  #include "EEPROMAnything.h"
/***END Libraries***/

/***Flick Counter***/
  // 32bit number storage variable.  Range from 0 - 4,294,967,295.
  unsigned long flickCounter;
/***END Flick Counter***/

/***WEBDUINO REQ***/
  // no-cost stream operator as described at 
  // http://sundial.org/arduino/?page_id=119
  template<class T>
  inline Print &operator <<(Print &obj, T arg)
  { obj.print(arg); return obj; }
/**END WEBDUINO REQ***/

/***TCP/IP SETUP***/
  // MAC Address
  static uint8_t mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };

  // Local IP Address
  static uint8_t ip[] = { 192, 168, 1, 210 };

  // Set Location of I/OStatus Page.
  // (Append /form to prefix to alter I/O pin state.)
  #define PREFIX "/tree"

  // Port
  WebServer webserver(PREFIX, 80);
/***END TCP/IP SETUP***/

// Webserver (Must remain above Setup & Loop) //////////////////////////////////////////////

/***jsonCMD***/
void jsonCmd(WebServer &server, WebServer::ConnectionType type, char *url_tail, bool tail_complete)
{
  if (type == WebServer::POST)
  {
    server.httpFail();
    return;
  }

  //server.httpSuccess(false, "application/json");
  server.httpSuccess("application/json");
  
  if (type == WebServer::HEAD)
    return;

  int i;    
  server << "{ ";
  for (i = 0; i <= 10; ++i)
  {
    // ignore the pins we use to talk to the Ethernet chip
      if ( i == 10 ) {
        i = 14;
      }
    int val = digitalRead(i);
    server << "\"d" << i << "\": " << val << ", ";
  }

  /* Read Analog Pin Status
  for (i = 0; i <= 5; ++i)
  {
    int val = analogRead(i);
    server << "\"a" << i << "\": " << val;
    if (i != 5)
      server << ", ";
  } END Read Analog Pin Status */
  
  server << " }";
} /***END jsonCMD***/

/***outputPins***/
void outputPins(WebServer &server, WebServer::ConnectionType type, bool addControls = false)
{
  P(htmlHead) =
    "<html>"
    "<head>"
    "<style type=\"text/css\">"
    "BODY { font-family: sans-serif; text-align: center; background: #6699FF; }"
    "H1 { font-size: 14pt; color: #FFFFFFF; text-decoration: none; }"
    "P  { font-size: 10pt; }"
    "div.radiobuttons  { text-align: right; width: 250px;}"
    "div.secret {color: #6699FF; font-size: 8px;}"
    "div.flickcounter {color: #FFFFFF; font-size: 11pt;}"
    "div.instructions {color: #FFFFFF; font-size: 9pt;}"
    "hr {height: 1px; color: #FFFFFF; background-color: #FFFFFF; border-width: 0px; margin: 3px;}"
    "</style>"
    "</head>"
    "<body>";

  int i;
  server.httpSuccess();
  server.printP(htmlHead);

  if (addControls)
    server << "<form action='" PREFIX "/form' method='post'>";
    
    server << "<div class='radiobuttons'>";

  // Array of labels for each digital output.  0 and 1 (TX/RX) are not used and must remain blank.
  char* strLightStrings[] = {"", "", "Big Tree White", "Big Tree Rainbow", "Small Left Tree", "Window Accent", "Small Right Tree", "Star Red", "Star Green", "Star Blue", "", "", "", "", "Star Rainbowifier"};
 
  for (i = 2; i <= 9; ++i)
  {
        
    if ( i == 10 ) { // Insert note explaining Star Rainbowifier
      server << "<div class='instructions'>Mix colors &#x25b2; <b>or</b> activate The Rainbowifier &#x25bc;.</div>";
    }
    
    if ( i == 10 ) { // Skip over Ethernet Shield pins.
        i = 14;
    }

    if ( i == 7 ) {  // Insert Break before star control section.
      server << "<hr/>"; 
    }
    
    int val = digitalRead(i);
    
    server << strLightStrings[i];
    if (addControls) // Generate & Print Radio Buttons
    {
      char pinName[5];
      pinName[0] = 'd';
      itoa(i, pinName + 1, 10);
      server.radioButton(pinName, "1", "On", val);
      server << " ";
      server.radioButton(pinName, "0", "Off", !val);
    }
    else // Print Pin Status
      server << (val ? ": HIGH" : ": LOW");
      server << ("<br>");
    }
  
  server << "</div>";
  server << "<div class='lower'>";

  // Analog Pin Readings could be / were printed here.  See version 1.0 for code.
  
  if (addControls)
    
    // Invisibly print Treeduino version number.
    server << "<div class='secret'>" << verNum << "</div>";
    
    // Submit Button
    server << "<input type='submit' value='Send to Tree'/></form><br>";
    
    // Print EEPROM Flick Counter Value
    server << "<div class='flickcounter'>The scene has been set " << flickCounter << " times.</div>";
    
    // Closing HTML Tags
    server << "</div></body></html>";
}

/***formCmd***/
void formCmd(WebServer &server, WebServer::ConnectionType type, char *url_tail, bool tail_complete)
{
  if (type == WebServer::POST)
  {
    
    /***EEPROM flickCounter Write***/
    flickCounter += 1;
    EEPROM_writeAnything(64, flickCounter);
    /***END EEPROM flickCounter Write***/
    
    bool repeat;
    char name[16], value[16];
    do
    {
      repeat = server.readPOSTparam(name, 16, value, 16);
      if (name[0] == 'd')
      {
        int pin = strtoul(name + 1, NULL, 10);
        int val = strtoul(value, NULL, 10);
        
        if ( pin == 14 && val == 1 ) {
          digitalWrite(7, LOW);
          digitalWrite(8, LOW);
          digitalWrite(9, LOW);
          
          digitalWrite(14, HIGH);
          
        } else {
            digitalWrite(pin, val);
          }
      }
    } while (repeat);
    
    //Re-directs client back to /form upon submit.
    server.httpSeeOther(PREFIX "/form");
  }
  else
    outputPins(server, type, true);
} /***END formCmd***/

/***defaultCmd***/
void defaultCmd(WebServer &server, WebServer::ConnectionType type, char *url_tail, bool tail_complete)
{
  outputPins(server, type, false);  
} /***END defaultCmd***/

// Setup & Loop //////////////////////////////////////////////////////////

/***SETUP***/
void setup()
{
  // Set pins unused by the Ethernet Shield or for Serial Communication as digital outputs.
  for (int i = 2; i <= 14; ++i) {
        if ( i == 10 ) {
          i = 14;
        }
    pinMode(i, OUTPUT); }
    
  
  // Channel Test Sequence
  for (int i = 2; i <= 9; ++i) {
   digitalWrite(i, HIGH);
   delay(50);

   if ( i == 9) {
       for (int i = 2; i <= 9; ++i) {
        digitalWrite(i, LOW);
       }
         delay(250);
            for (int i = 2; i <= 9; ++i) {
            digitalWrite(i, HIGH);
            }
              delay(750);
                for (int i = 2; i <= 9; ++i) {
                digitalWrite(i, LOW);
                }
    }
   } // END Channel Test Sequence
  
  // Grab last flickCounter value from EEPROM.
  EEPROM_readAnything(64, flickCounter);
  
  // Write version number to EEPROM for safekeeping / recovery later.
  EEPROM_writeAnything(0, verNum);

  // Setup webserver
  Ethernet.begin(mac, ip);
  webserver.begin();

  webserver.setDefaultCommand(&defaultCmd);
  webserver.addCommand("json", &jsonCmd);
  webserver.addCommand("form", &formCmd);
   
} /***END SETUP***/

/***LOOP***/
void loop()
{ 
  // process incoming connections one at a time forever
  webserver.processConnection();

} /***END LOOP***/


 
