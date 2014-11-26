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
 *  v1.2b: (Z)
 *   // -b Serial communication functionality is implemented.
 *   // -b Version information is printed over serial on startup.
 *          + Issues with Serial reliability.  Arduino sometimes floods serial port, causing IDE to freeze.
 *          + Experimenting in ver1.2TwitterFork to replace the functionality that the Serial interface was to provide.
 *
 *      - EEPROM anything header file added to EEPROM Library.
 *      - Flick counter implemented.  Counter stored in 32 bit unsigned long variable.
 *        EEPROM writeAnything templates were added to EEPROM library.
 *        Sketch written to zero out EEPROM variable during testing. (Clear_flickCounter.pde)
 *
 *  v1.2TwitterFork: (Z)
 *      - Serial communication functionality scrapped.
 *      - Experimenting with the implemantation of a Tweeting Treeduino.
 *          + Current plan is to tweet flickCounter.
 *
 *  v1.3:
 *      - Twitter is fully implemented. (Z)
 *      - Serial.print has been scrapped. (Z)
 *     
 * 
 */
char verNum[] = "v1.3";

// Ititialization Configuration //////////////////////////////////////////////////////////

/***LIBRARIES***/
  // Webduino
  #include "SPI.h"
  #include "Ethernet.h"
  #include "WebServer.h"

  // Flick Counter EEPROM Storage
  #include "EEPROM.h"
  #include "EEPROMAnything.h"
  
  // Twitter
    // Check IDE Version to ensure compatibility
  #if defined(ARDUINO) && ARDUINO > 18   // Arduino 0019 or later
  #include <SPI.h>
  #endif
  // #include <Ethernet.h> (Already included by webduino.)
  #include <EthernetDNS.h>
  #include <Twitter.h>
/***END Libraries***/

/***Twitter Setup***/
  // Token to Tweet (get it from http://arduino-tweet.appspot.com/)
  Twitter twitter("404949676-kaUHGD45Wfxmw4VBwhaeoHHs8hLvHBJlSWtNGJEY");
  
  // Library of possible Tweets
    // rebootTweet - Published once during setup.
    char rebootTweet[140] = "3I Just got rebooted, things should be runnning smoothly now.";
    
    // axFlicksTweet - Published as each milestone is hit.  Determined by select case statement
    char a100FlicksTweet[140] = "The first hundred scenes have BETA been set, keep em coming!";
    char a500FlicksTweet[140] = "BETA 500";
    char a1000FlicksTweet[140] = "BETA 1000";
    char a2000FlicksTweet[140] = " ";
    char a3000FlicksTweet[140] = " ";
    char a4000FlicksTweet[140] = " ";
    char a5000FlicksTweet[140] = " ";
    char a7500FlicksTweet[140] = " ";
    char a10000FlicksTweet[140] = " ";
    char a15000FlicksTweet[140] = " ";
    char a20000FlicksTweet[140] = " ";
    char a25000FlicksTweet[140] = " ";
    char a30000FlicksTweet[140] = " ";
    
/***END Twitter Setup***/

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
    "div.radiobuttons  { text-align: right; width: 250px; padding: 8px;}"
    "</style>"
    "</head>"
    "<body>";

  int i;
  server.httpSuccess();
  server.printP(htmlHead);

  if (addControls)
    server << "<form action='" PREFIX "/form' method='post'>";
    
    server << "<div class='radiobuttons'>";

  // For loop generates a line for each control pin.
  for (i = 2; i <= 7; ++i)
  {
    int val = digitalRead(i);
    
    // Array of labels for each digital output.  0 and 1 (TX/RX) are not used and must stay blank.
    char* strLightStrings[] = {"", "", "White Lights", "Colored Lights", "Star", "Blue", "Green", "Red"};
    
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
  
  server << "<br/>";
  
  if (addControls)
    
    // Flick Counter was printed here.  Not yet implemented in 2011 code.
    
    // Submit Button
    server << "<input type='submit' value='Send to Tree'/></form><br><br>";
    
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
    
    tweetFlicksMilestone();
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
  // set pins 2-7 for digital OUTPUT
  for (int i = 2; i <= 7; ++i)
    pinMode(i, OUTPUT);
  pinMode(9, OUTPUT);
  
  // Grab last flickCounter value from EEPROM.
  EEPROM_readAnything(32, flickCounter);
  
  // Write version number to EEPROM.
  EEPROM_readAnything(0, verNum);

  // Setup webserver
  Ethernet.begin(mac, ip);
  webserver.begin();
  
  // Depends on Ethernet being initialized, and therefore must remain after.
  twitter.post(rebootTweet);

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

/***tweetFlicksMilestone***/
void tweetFlicksMilestone() {
  switch (flickCounter) {
   case 100:
    twitter.post(a100FlicksTweet);
    break;
 
   case 500:
    twitter.post(a500FlicksTweet);
    break;
  
   case 1000:
    twitter.post(a1000FlicksTweet);
    break;
  
   case 2000:
    twitter.post(a2000FlicksTweet);
    break;

   case 3000:
    twitter.post(a3000FlicksTweet);
    break;
 
   case 4000:
    twitter.post(a4000FlicksTweet);
    break;
 
   case 5000:
    twitter.post(a5000FlicksTweet);
    break;

   case 7500:
    twitter.post(a7500FlicksTweet);
    break;

   case 10000:
    twitter.post(a10000FlicksTweet);
    break;
  
   case 15000:
    twitter.post(a15000FlicksTweet);
    break;
 
   case 20000:
    twitter.post(a20000FlicksTweet);
    break;

   case 25000:
    twitter.post(a25000FlicksTweet);
    break;
 
   case 30000:
    twitter.post(a30000FlicksTweet);
    break;
  }
} /***END tweetFlicksMilestone***/
