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
* This programs tests the chompCommand function used by talon.
*/




#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>


#include "chomp.h"
#include "log.h"

char *positives[] =  { 
"c:\\apps\\talon.exe -c \"armcc -o barney.o\"", 
"c:\\apps\\sbs2112-capabilites\\bin\\talon.exe -c \"armcc -o barney.o\"", 
"\"c:\\apps and stuff\\talon.exe\" -c \"armcc -o barney.o\"", 
"\"c:\\apps-can-cause-crxxx\\talon.exe\" -c \"armcc -o barney.o\"", 
"c:\\bigspaces-\"   \"\\talon.exe -c \"armcc -o barney.o\"", 
"c:\\bigspaces2\"   \"\\talon.exe -c \"armcc -o barney.o\"", 
"c:\\apps\\talon.exe   -c   \"armcc -o barney.o\"", 
"c:\\\"apps\"\\talon.exe   -c   \"armcc -o barney.o\"", 
"c:\\\"ap ps\"\\talon.exe -c \"armcc -o barney.o\"", 
(char *)0
};

char *negatives[] =  { 
"c:\\apps\\talon.exe -c\"armcc -o barney.o\"", 
"c:\\apps and stuff\\talon.exe -c \"armcc -o barney.o\"", 
"c:\\apps\\talon.exe -c armcc -o barney.o", 
"c:\\apps\\talon.exe commandlist.tmp", 
(char *)0
};

char commandstr[]="armcc -o barney.o\"";

int main(int argc, char *argv[])
{
	int i;
	int errors = 0;
	/* loglevel = LOGDEBUG; /* useful to leave this here */

	for (i=0; positives[i] != (char *)0 ; i++)
	{
		char * c = chompCommand(positives[i]);
		if (!c)
		{
			fprintf(stdout,"error: test failed with NULL on: %s\n", positives[i]);
			errors++;
			continue;
		}

		if (strcmp(commandstr, c) != 0)
		{
			fprintf(stdout,"error: test failed with %s on: %s\n", c,positives[i]);
			errors++;
			continue;
		}
		fprintf(stdout,"ok: %s\n", positives[i]);
	}

	for (i=0; negatives[i] != (char *)0 ; i++)
	{
		char * c = chompCommand(negatives[i]);
		if (c)
		{
			fprintf(stdout,"error: negatice test failed with %s on: %s\n", c, negatives[i]);
			errors++;
			continue;
		}
		fprintf(stdout,"ok: negative: %s\n", negatives[i]);
	}

		
	fprintf(stdout,"TOTAL errors: %d\n", errors);
	return errors;
}
