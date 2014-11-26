#include <iostream>
#include <iomanip>
#include <csignal>
#include <string>
#include <cstring>
#include <sstream>
#include <curl/curl.h>
#include <curl/easy.h>

#include "main.h"

using namespace std;

CURL *curl = NULL;
static bool go = true, insanity = false;

struct memory {
	char *memory;
	size_t size;
};

void sig(int) {
	cout << "Signal caught, exiting." << endl;
	go = insanity = false;
	if( curl ) {
		curl_easy_cleanup( curl );
	}
}

void *myrealloc(void *ptr, size_t size)
{
	/* There might be a realloc() out there that doesn't like reallocing
     NULL pointers, so we take care of it here */
	if( ptr )
		return realloc( ptr, size );
	else
		return malloc( size );
}

size_t write_memory_callback(void *ptr, size_t size, size_t nmemb, void *data)
{
	size_t realsize = size * nmemb;
	struct memory *mem = (memory *)data;
	
	mem->memory = (char *)myrealloc( mem->memory, mem->size + realsize + 1 );
	if ( mem->memory ) {
		memmove( &( mem->memory[mem->size] ), ptr, realsize );
		mem->size += realsize;
		mem->memory[mem->size] = '\0';
	}
	return realsize;
}

int main (int argc, char * const argv[]) {
	// Initialization
    const char url[] = "http://netstore.webhop.org:3223/tree/form";
	const char useragent[] = "treepocalypse/1.0.0 by integ3r";
	bool white = false, colored = false, star = false;
	memory chunk;
	
	// Set up the chunk
	chunk.memory = NULL;
	chunk.size = 0;
	
	// Set up cURL
	curl_global_init( CURL_GLOBAL_ALL );
	atexit( curl_global_cleanup );
	curl = curl_easy_init();
	if( !curl ) {
		cerr << "Error initializing CURL instance." << endl;
		return 1;
	}
	
	// Set up a signal handler for CTRL+C
	signal( SIGINT, sig );
	
	// cURL options
	curl_easy_setopt( curl, CURLOPT_URL, url );
	curl_easy_setopt( curl, CURLOPT_WRITEFUNCTION, write_memory_callback );
	curl_easy_setopt( curl, CURLOPT_WRITEDATA, &chunk );
	curl_easy_setopt( curl, CURLOPT_USERAGENT, useragent );
	curl_easy_setopt( curl, CURLOPT_FOLLOWLOCATION, false );
	curl_easy_setopt( curl, CURLOPT_NOPROGRESS, true );
	curl_easy_setopt( curl, CURLOPT_AUTOREFERER, true );
	curl_easy_setopt( curl, CURLOPT_POST, true );
	
	// Initial message
	cout << useragent << endl;
	cout << "Press 'w' for white lights, 'c' for colored lights, or 's' for the star." << endl;
	cout << "To enable insanity mode, press 'i'" << endl;
	
	// Let's do it!
	while( go ) {
		if( !insanity ) {
			// Make a stringstream and a CURLcode
			ostringstream str;
			CURLcode cc;
			
			// Wait for a character
			char c = terminal::getch( "wWcCsSiI" );
			
			// Decide what to do
			if( c == 'w' ) {
				white = true;
			}
			else if( c == 'W' ) {
				white = false;
			}
			else if( c == 'c' ) {
				colored = true;
			}
			else if( c == 'C' ) {
				colored = false;
			}
			else if( c == 's' ) {
				star = true;
			}
			else if( c == 'S' ) {
				star = false;
			}
			else if( (char)toupper( c ) == 'I' ) {
				cout << "Insanity mode enabled." << endl;
				insanity = true;
			}
			
			// Output a wait message
			cout << "Wait..." << flush;
			
			// Build the querystring for the Arduino
			str << noboolalpha << "d2=" << white << "&d3=" << colored << "&d4=" << star;
			
			// Set the POST data
			curl_easy_setopt( curl, CURLOPT_COPYPOSTFIELDS, str.str().c_str() );
			
			// Tell the Arduino what to do
			cc = curl_easy_perform( curl );
			
			// Output what we just did
			cout << " White: " << ( white ? "On" : "Off" ) << " | Colored: " << ( colored ? "On" : "Off" ) << " | Star: " << ( star ? "On" : "Off" ) << endl;
			
			// Free the chunk
			if( chunk.memory ) {
				free( chunk.memory );
				chunk.memory = NULL;
				chunk.size = 0;
			}
			
			// Error handling
			if( cc != CURLE_OK ) {
				cout << "cURL Error: " << curl_easy_strerror( cc ) << endl;
			}
		}
		else {
			while( 1 ) {
				// Set up vars
				ostringstream str;
				CURLcode cc;
				
				// Set white, colored, and star with even/odd random stuff
				white = rand() % 2 == 0;
				colored = rand() % 2 == 0;
				star = rand() % 2 == 0;
				
				// Output a wait message
				cout << "Wait..." << flush;
				
				// Build the querystring
				str << noboolalpha << "d2=" << white << "&d3=" << colored << "&d4=" << star;
				
				// Set the POST data
				curl_easy_setopt( curl, CURLOPT_COPYPOSTFIELDS, str.str().c_str() );
				
				// Tell the Arduino what to do
				cc = curl_easy_perform( curl );
				
				// Output what we just did
				cout << " White: " << ( white ? "On" : "Off" ) << " | Colored: " << ( colored ? "On" : "Off" ) << " | Star: " << ( star ? "On" : "Off" ) << endl;
				
				// Free the chunk
				if( chunk.memory ) {
					free( chunk.memory );
					chunk.memory = NULL;
					chunk.size = 0;
				}
				
				// Error handling
				if( cc != CURLE_OK ) {
					cout << "cURL Error: " << curl_easy_strerror( cc ) << endl;
				}				
			}
		}
	}
}
