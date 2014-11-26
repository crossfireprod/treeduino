/*
 ***************************
 *     Treeduino 2011      *
 * Zach Cross & Jacob Ford *
 ***************************
 * 
 * Arduino Uno w/ ETHShield
 * Arduino IDE 022
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
 *      - Channels Mapped (Z)
 *      - Added Channel Test Sequence in Setup method. (Z)
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
 *        NOTE: Be sure to indicate output pins in Setup method as well as when printing 
 *               radio buttons in outputPins method.  Failure to set pins as outputs will
 *               keep them from being able to put out enough current to fully open or close
 *               the transistors.
 *
 */
char verNum[] = "Treeduino 2011 - v1.4";  // Saved to EEPROM in Setup method as well as printed invisibly (same color as background) in the web form.

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
  for (i = 0; i <= 9; ++i)
  {
    // ignore the pins we use to talk to the Ethernet chip
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
    "div.secret {color: #6699FF; font-size: 5px;}"
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
  char* strLightStrings[] = {"", "", "Ch. 0", "Ch. 1", "Ch. 2", "Ch. 3", "Ch. 4", "Red", "Green", "Blue"};
 
  server << "---- Light Strings ---<br>";
 
  for (i = 2; i <= 9; ++i)
  {
    
    if ( i == 7 ) {
      server << "----- Star Color -----<br>"; 
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

  // Analog Pin Readings could be/were printed here.  See version 1.0 for code.
  
  if (addControls)
    
    // Invisibly print Treeduino version number.
    server << "<div class='secret'>" << verNum << "</div>";
    
    // Submit Button
    server << "<input type='submit' value='Send to Tree'/></form><br>";
    
    // Print EEPROM Flick Counter Value
    server << "The scene has been set " << flickCounter << " times.";
    
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
    EEPROM_writeAnything(32, flickCounter);
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
        
        
            digitalWrite(pin, val);
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
  for (int i = 2; i <= 9; ++i)
    pinMode(i, OUTPUT);
  
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
  EEPROM_readAnything(32, flickCounter);
  
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
