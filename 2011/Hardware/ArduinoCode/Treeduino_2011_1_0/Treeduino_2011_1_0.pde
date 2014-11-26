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
 * sketch of the Webduino library (MIT License) by Ben Combee.  
 * (It is an awesome library, great job!)
 * https://github.com/sirleech/Webduino
 *
 */

/* CHANGELOG
 *
 *  v1.0: 
 *    - Core of 2011 Treeduino code is compiled.  It is heavily based off of Treeduino 2010 v1.9WORKING.
 *      The sketch is being re-compliled by hand in an effort to keep the code as lean as possible.
 *      Updates to the Webduino Library to coincide with the Arduino Uno & IDE 022 also necesitate this.
 *      (Z)
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

  for (i = 0; i <= 5; ++i)
  {
    int val = analogRead(i);
    server << "\"a" << i << "\": " << val;
    if (i != 5)
      server << ", ";
  }
  
  server << " }";
} /***END jsonCMD***/

/***outputPins***/
void outputPins(WebServer &server, WebServer::ConnectionType type, bool addControls = false)
{
  P(htmlHead) =
    "<html>"
    "<head>"
    "<title>Arduino Web Server</title>"
    "<style type=\"text/css\">"
    "BODY { font-family: sans-serif }"
    "H1 { font-size: 14pt; text-decoration: underline }"
    "P  { font-size: 10pt; }"
    "</style>"
    "</head>"
    "<body>";

  int i;
  server.httpSuccess();
  server.printP(htmlHead);

  if (addControls)
    server << "<form action='" PREFIX "/form' method='post'>";

  server << "<h1>Digital Pins</h1><p>";

  for (i = 0; i <= 9; ++i)
  {
    // ignore the pins we use to talk to the Ethernet chip
    int val = digitalRead(i);
    server << "Digital " << i << ": ";
    if (addControls)
    {
      char pinName[4];
      pinName[0] = 'd';
      itoa(i, pinName + 1, 10);
      server.radioButton(pinName, "1", "On", val);
      server << " ";
      server.radioButton(pinName, "0", "Off", !val);
    }
    else
      server << (val ? "HIGH" : "LOW");

    server << "<br/>";
  }

  server << "</p><h1>Analog Pins</h1><p>";
  for (i = 0; i <= 5; ++i)
  {
    int val = analogRead(i);
    server << "Analog " << i << ": " << val << "<br/>";
  }

  server << "</p>";

  if (addControls)
    server << "<input type='submit' value='Submit'/></form>";

  server << "</body></html>";
} /***END outputPins***/

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
    
    server.httpSeeOther(PREFIX "");
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
  // set pins 0-8 for digital input
  for (int i = 0; i <= 9; ++i)
    pinMode(i, INPUT);
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
