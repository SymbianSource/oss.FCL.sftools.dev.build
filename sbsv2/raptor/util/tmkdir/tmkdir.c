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
* Program for making directory hierarchies
*
*/

#include <stdio.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <string.h>
#include <errno.h>
#include "log.h"
#include "../config.h"



int mkpath(char *path)
{
	int pathlen;
	char *pathend;
	char *p;
	int ret = 255;

	
	pathlen=strlen(path);
	pathend = path + pathlen;

	p = path;

	// Find the first level at which we *can* make a directory
	// go down one level at a time until we make something that works
	DEBUG(("down: %s\n", path));
	while ( 0 != mkdir(path, 0777))
	{
		//  ENOENT means that the parent directory doesn't exist so it's ok
		//  any other error is not ok and means that we must give up
		if (errno != ENOENT)
			return 1;	

		p = strrchr(path,'/');
		if (!p)
			break;
		*p = '\0';
	}

	// So we found the point at which a pre-existing tree starts
	do
	{
		p = index(path, '\0');
		if (p >= pathend)
		{
			ret = 0;
			break;
		}

		*p = '/';
		DEBUG(("up: %s\n", path));
	}
	while  (0 == mkdir(path, 0777));
	
	return ret;
}

int main(int argc, char *argv[])
{
	int i;

	//loglevel=LOGDEBUG;
	for (i=1; i < argc; i++)
	{
		if ( 0 != mkpath(argv[i]))
			return 255;
	}

	return 0;
}

