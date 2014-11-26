/*
 * Tree Controller 2010
 * Zach Cross & Jacob Ford
 *
 **********************************************************************************************
 *
 * CHANGELOG
 * v1.0 - Kinda Working
 * v1.1 - Working, basic on/off functionality
 * v1.2 - Uh....... I'm working on a counter, what did you change to make this 1.2?
 */
 
#include "Ethernet.h"
#include "WebServer.h"
#include <EEPROM.h>

// EEPROM Write Anything Functions
template <class T> int EEPROM_writeAnything(int ee, const T& value)
{
    const byte* p = (const byte*)(const void*)&value;
    int i;
    for (i = 0; i < sizeof(value); i++)
	  EEPROM.write(ee++, *p++);
    return i;
}

template <class T> int EEPROM_readAnything(int ee, T& value)
{
    byte* p = (byte*)(void*)&value;
    int i;
    for (i = 0; i < sizeof(value); i++)
	  *p++ = EEPROM.read(ee++);
    return i;
}
// END EEPROM Write Anything Functions


// no-cost stream operator as described at 
// http://sundial.org/arduino/?page_id=119
template<class T>
inline Print &operator <<(Print &obj, T arg)
{ obj.print(arg); return obj; }


// CHANGE THIS TO YOUR OWN UNIQUE VALUE
static uint8_t mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };

// CHANGE THIS TO MATCH YOUR HOST NETWORK
static uint8_t ip[] = { 192, 168, 1, 100 };

#define PREFIX "/tree"

int mainCounter;

WebServer webserver(PREFIX, 80);

// commands are functions that get called by the webserver framework
// they can read any posted data from client, and they output to server

void jsonCmd(WebServer &server, WebServer::ConnectionType type, char *url_tail, bool tail_complete)
{
  if (type == WebServer::POST)
  {
    server.httpFail();
    return;
  }

  server.httpSuccess(false, "application/json");
  
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
}

void outputPins(WebServer &server, WebServer::ConnectionType type, bool addControls = false)
{
  P(htmlHead) =
    "<html>"
    "<head>"
    "<style type=\"text/css\">"
    "BODY { font-family: sans-serif }"
    "H1 { font-size: 14pt; color: #FFFFFFF; text-decoration: none }"
    "P  { font-size: 10pt; }"
    "input  { text-align: center; }"
    "</style>"
    "</head>"
    "<body>";

  int i;
  server.httpSuccess();
  server.printP(htmlHead);

  if (addControls)
    server << "<form action='" PREFIX "/form' method='post'>";

  for (i = 2; i <= 3; ++i)
  {
    // ignore the pins we use to talk to the Ethernet chip
    int val = digitalRead(i);
    server << "String # " << i << ": ";
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

/* Analog Pin Read
  server << "</p><h1>Analog Pins</h1><p>";
  for (i = 0; i <= 5; ++i)
  {
    int val = analogRead(i);
    server << "Analog " << i << ": " << val << "<br/>";
  }

  server << "</p>";
  END Analog Pin Read */
  server << "<br/>";
  
  if (addControls)
    server << "<input type='submit' value='Send to Tree'/></form>";
    
// EEPROM Counter
 server << "<BR>";
 server << "The lights have been flicked ";
 server << mainCounter;
 server << " times.";

 mainCounter = mainCounter + 1;
 EEPROM_writeAnything(0, mainCounter);
// END EEPROM Counter

  server << "</body></html>";
}

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

    server.httpSeeOther(PREFIX "/form");
  }
  else
    outputPins(server, type, true);
}

void defaultCmd(WebServer &server, WebServer::ConnectionType type, char *url_tail, bool tail_complete)
{
  outputPins(server, type, false);  
}

void setup()
{
  // set pins 0-8 for digital output
  for (int i = 2; i <= 4; ++i)
    pinMode(i, OUTPUT);
  pinMode(4, OUTPUT);

  Ethernet.begin(mac, ip);
  webserver.begin();

  webserver.setDefaultCommand(&defaultCmd);
  webserver.addCommand("json", &jsonCmd);
  webserver.addCommand("form", &formCmd);
}

void loop()
{
  // process incoming connections one at a time forever
  webserver.processConnection();

  // if you wanted to do other work based on a connecton, it would go here
}

