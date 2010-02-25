/*
* Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
* All rights reserved.
* This component and the accompanying materials are made available
* under the terms of the License "Eclipse Public License v1.0"
* which accompanies this distribution, and is available
* at the URL "http://www.eclipse.org/legal/epl-v10.html".
*
* Initial Contributors:
* Nokia Corporation - initial contribution.
*
* Contributors:
*
* Description: 
*
*/

/*
   Get rid of the path to talon from a commandline string on windows find the 
   -c (if it's there) and step past it to after the quote on the first command:

   "g:\program files\talon\talon.exe" -c "gcc -c . . ."
                                          ^------ Returns a pointer to here

   Take care of the possibilty that there might be spaces in the command
   if it is quoted.

   A state-machine is flexible but not all that easy to write.  Should investigate
   the possiblity of using the Ragel state machine generator perhaps.

*/
#define CH_START 0 	/* start state */
#define CH_PRE 1	/* spaces before executable name */
#define CH_EXQUOTE 2    /* part of the executable name, outside quotes */
#define CH_INQUOTE 3	/* part of the executable name, in a quoted region */
#define CH_POST 4	/* spaces after executable name */
#define CH_MINUS 5	/* start of -c option */
#define CH_C 6		/* end of -c option */
#define CH_PRECOMMAND 7 /* spaces before shell commands */
#define CH_COMMAND 8	/* first character of shell command */
#define CH_ERR 9	/* Error! */

#include "log.h"
#include "chomp.h"

char * chompCommand(char command[])
{
	char *result = command;
	int state = CH_START;

	while (state != CH_COMMAND && state != CH_ERR)
	{
		DEBUG(("startstate: %d, char %c ",state, *result));
		switch (*result)
		{
			case ' ':
				switch (state)
				{
					case CH_START:
					case CH_PRE:
						state = CH_PRE;
						break;
					case CH_EXQUOTE:
						state = CH_POST;
						break;
					case CH_INQUOTE:
						break;
					case CH_POST:
						break;
					case CH_MINUS:
						state = CH_C;
						break;
					case CH_C:
						state = CH_PRECOMMAND;
						break;
					case CH_PRECOMMAND:
						break;
					default:
						state = CH_ERR;
						break;
				}
			break;
			case 'c':
				switch (state)
				{
					case CH_START:
					case CH_PRE:
						state = CH_EXQUOTE;
						break;
					case CH_EXQUOTE:
					case CH_INQUOTE:
						break;
					case CH_POST:
						state = CH_ERR;
						break;
					case CH_MINUS:
						state = CH_C;
						break;
					case CH_C:
					case CH_PRECOMMAND:
					default:
						state = CH_ERR;
						break;
				}
			break;
			case '-':
				switch (state)
				{
					case CH_START:
					case CH_PRE:
						state = CH_EXQUOTE;
						break;
					case CH_EXQUOTE:
					case CH_INQUOTE:
						break;
					case CH_POST:
						state = CH_MINUS;
						break;
					case CH_MINUS:
					case CH_C:
					case CH_PRECOMMAND:
					default:
						state = CH_ERR;
						break;
				}
			break;
			case '"':
				switch (state)
				{
					case CH_START:
					case CH_PRE:
					case CH_EXQUOTE:
						state = CH_INQUOTE;
						break;
					case CH_INQUOTE:
						state = CH_EXQUOTE;
						break;
					case CH_POST:
					case CH_MINUS:
					case CH_C:
						state = CH_ERR;
						break;
					case CH_PRECOMMAND:
						state = CH_COMMAND;
						break;
					default:
						state = CH_ERR;
						break;
				}

			break;
			default:
				switch (state)
				{
					case CH_START:
					case CH_PRE:
						state = CH_EXQUOTE;
						break;
					case CH_INQUOTE:
					case CH_EXQUOTE:
						break;
					default:
						state = CH_ERR;
						break;
				}
			break;
		}
		DEBUG(("endstate: %d\n",state));
		result ++;
		
	}

	if (state == CH_ERR)
		return (char *)0;

	return result;
}
