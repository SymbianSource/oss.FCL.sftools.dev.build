/*
* Copyright (c) 2008-2009 Nokia Corporation and/or its subsidiary(-ies).
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
   ransleep.c: sleep for some time period specified in milliseconds
               optionally choose a random time up to the maximum time specified.

   Description: Useful for delays between retries and for perturbing the
	        start times of tools which might cause resource starvation 
		if they all execute at exactly the same time.
*/

#include "../config.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// OS specific headers
#ifdef HOST_WIN
#include <windows.h>
#else
#include <sys/types.h>
#include <sys/select.h>
#endif

int main(int argc, char *argv[])
{

	srand(getpid());
	int millisecs=0;

	if (argc != 2)
	{
		fprintf(stderr,"Must supply numeric argument - maximum milliseconds to sleep\n");
		exit(1);
	}

	millisecs = atoi(argv[1]);


	if (millisecs <= 0 )
	{
		fprintf(stderr,"Must supply numeric argument > 0 - maximum milliseconds to sleep\n");
		exit(1);
	}


	millisecs = rand() % millisecs;
	fprintf(stderr,"random sleep for %d milliseconds\n", millisecs);

	#ifndef HAS_MILLISECONDSLEEP
	struct timeval wtime;
	wtime.tv_sec=millisecs/1000;
	wtime.tv_usec=(millisecs % 1000) * 1000;

	select(0,NULL,NULL,
                  NULL, &wtime);
	#else
	Sleep(millisecs);
	#endif

	return 0;
}


