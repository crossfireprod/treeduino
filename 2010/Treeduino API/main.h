#include <string>
#include <termios.h>

using namespace std;

#ifndef MAIN_H
#define MAIN_H

class terminal {
public:
	static char getch	()						;
	static char getch	(string chars)			;
	static char getch	(const char *chars)		;
	static void getSequence	(string sequence)		;
	static void getSequence	(const char *sequence)	;
	static bool ready	()						;
private:
	static struct	termios		oldt, newt		;
	static void		getReady	()				;
	static void		set			()				;
	static void		reset		()				;
	static char		getOneChar	()				;
	static bool		is_ready						;
}												;

/* Old and new terminals */
struct termios terminal::oldt, terminal::newt;

/* Ready? */
bool terminal::is_ready = false;

/* Returns if the terminal is ready. */
bool terminal::ready()
{
	return is_ready;
}

/* Prepare the terminals */
void terminal::getReady()
{
	// Get the stdin attributes into the old terminal.
	tcgetattr( STDIN_FILENO, &oldt );
	// Copy the old terminal over to the new terminal.
	newt = oldt;
	/* set the old terminal's options like so: c_lflag = c_lflag & ~( ICANON | ECHO ).
	 This actually sets the terminal to receive a character. */
	newt.c_lflag &= ~( ICANON | ECHO );
	// We're ready, so set the ready flag to true.
	is_ready = true;
}

/* Set the terminal */
void terminal::set()
{
	// Set the terminal's attributes with the modified terminal.
	tcsetattr( STDIN_FILENO, TCSANOW, &newt );
}

/* reset the terminal */
void terminal::reset()
{
	// Set the terminal's attributes with the terminal in memory.
	tcsetattr( STDIN_FILENO, TCSANOW, &oldt );
}

/* Get one character. This should not be called directly; it's private anyway. */
char terminal::getOneChar()
{
	// getchar() returns an int, so cast it to a char.
	return static_cast <char> ( getchar() );
}

/* Get any one character. Call this one. */
char terminal::getch()
{
	// Make the char that we actually will get.
	char ch;
	// If we're not ready, please make us ready.
	if( !ready() )
		getReady();
	// set the terminal attributes.
	set();
	// Get a character.
	ch = getOneChar();
	// reset the terminal attributes.
	reset();
	// Return the character we got.
	return ch;
}

/* Get any character in chars, ignoring any other input. */
char terminal::getch(string chars)
{
	// Make the char that we actually will get.
	char ch;
	// If we're not ready, please make us ready.
	if( !ready() )
		getReady();
	// set the terminal attributes.
	set();
	// While the first occurence of the character isn't found, get another char.
	while( chars.find_first_of( ch ) == string::npos )
		ch = getOneChar();
	// reset the terminal attributes.
	reset();
	// Return the character we got.
	return ch;
}

/* Overloaded */
char terminal::getch(const char *chars)
{
	// Make chars a string to be more friendly.
	return getch( string( chars ) );
}

/* Get a sequence, ignoring any other input. */
void terminal::getSequence(string sequence)
{
	// Make an iterator to the beginning of the sequence.
	string::iterator it = sequence.begin();
	// Make the char that we actually will get.
	char ch;
	// If we're not ready, please make us ready.
	if( !ready() )
		getReady();
	// set the terminal attributes.
	set();
	// While the iterator (the position in the string) is not equal to the end of the sequence...
	while( it != sequence.end() )
	{
		// Get a character. Say the sequence is "dog" and we just got "d". The iterator is at "d" currently.
		ch = getOneChar();
		// If the character is equal to the current position in the string, increment the iterator. Now the iterator is at "o".
		if( ch == *it )
			it++;
		// Otherwise, restart the sequence. The iterator would be back at "d".
		else
			it = sequence.begin();
	}
	// reset the terminal attributes.
	reset();
}

/* Overloaded */
void terminal::getSequence(const char *sequence)
{
	// Make sequence a string.
	getSequence( string( sequence ) );
}

#endif // MAIN_H