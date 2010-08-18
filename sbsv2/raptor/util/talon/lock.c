/*
* Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
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
* Test program for grabbing and releasing the talon output semaphore.
*/




#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdarg.h>

#include "sema.h"
#include "buffer.h"
#include "../config.h"

/* The output semaphore. */
sbs_semaphore talon_sem;

#define TALON_ATTEMPT_STRMAX 32
#define RECIPETAG_STRMAX 2048
#define STATUS_STRMAX 100

#define TALONDELIMITER '|'
#define VARNAMEMAX 100
#define VARVALMAX 1024


#include "log.h"

#ifdef HAS_MSVCRT
/* Make all output handling binary */
unsigned int _CRT_fmode = _O_BINARY;
#endif

double getseconds(void)
{
	struct timeval tp;
	gettimeofday(&tp, NULL);

	return (double)tp.tv_sec + ((double)tp.tv_usec)/1000000.0L;
}

void talon_setenv(char name[], char val[])
{
#if defined(HAS_GETENVIRONMENTVARIABLE)
	SetEnvironmentVariableA(name,val); 
#elif defined(HAS_GETENV)
	setenv(name,val, 1);
#else
#	error "Need a function for setting environment variables"
#endif
}


#define TALON_MAXENV 4096
char * talon_getenv(char name[])
{
#if defined(HAS_SETENV)
	char *val = getenv(name);
	char *dest = NULL;
	
	if (val)
	{
		dest = malloc(strlen(val) + 1);
		if (dest)
		{
			strcpy(dest,val);
		}
	}
	return dest;
#elif defined(HAS_SETENVIRONMENTVARIABLE)
	char *val = malloc(TALON_MAXENV);
	if (0 != GetEnvironmentVariableA(name,val,TALON_MAXENV-1))
		return val;
	else
		return NULL;
#else
#	error "Need a function for setting environment variables"
#endif
}



int main(int argc, char *argv[])
{
	/* find the argument to -c then strip the talon related front section */

	char *recipe = NULL;
	int talon_returncode = 0;

	/* Now take settings from the environment (having potentially modified it) */	
	if (talon_getenv("TALON_DEBUG"))
		loglevel=LOGDEBUG;
	

	int enverrors = 0;

	char *buildid = talon_getenv("TALON_BUILDID");
	if (!buildid)
	{
		error("error: %s", "TALON_BUILDID not set in environment\n");
		enverrors++;	
	}

        talon_sem.name = buildid;
        talon_sem.timeout = 999999990;


	

	int x;
	debug("debug: %s", "WAITING ON SEMAPHORE\n");
	x = sema_wait(&talon_sem);
	if (x == 0)
	{
		debug("debug: %s", "SEMAPHORE OBTAINED\n");
		getchar();
		sema_release(&talon_sem);
		debug("debug: %s", "SEMAPHORE RELEASED\n");
	}
}
