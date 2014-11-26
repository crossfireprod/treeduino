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
 *  v1.1b:
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
 */

// Ititialization Configuration //////////////////////////////////////////////////////////

/***LIBRARIES***/
// Webduino
#include "SPI.h"
#include "Ethernet.h"
#include "WebServer.h"
/***END Libraries***/


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
    
    // Closing HTML Tags
    server << "</div></body></html>";
}

/***formCmd***/
void formCmd(WebServer &server, WebServer::ConnectionType type, char *url_tail, bool tail_complete)
{
  if (type == WebServer::POST)
  {
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

  // if you wanted to do other work based on a connecton, it would go here
} /***END LOOP***/
