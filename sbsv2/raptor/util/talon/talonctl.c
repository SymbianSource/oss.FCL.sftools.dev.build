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
*
*/




#include "sema.h"
#include "log.h"

#include <stdlib.h>

/* The output semaphore. */
sbs_semaphore talon_sem;

int main(int argc, char *argv[])
{
	char *buildid_str = getenv("TALON_BUILDID");

	if (!buildid_str)
	{
		error("error: TALON_BUILDID not set in environment\n");
		return 1;
	}

	if (argc != 2)
	{
		error("error: one argument required: start|stop\n");
		return 1;
	}

	talon_sem.name = buildid_str;
	talon_sem.timeout=0;

	if (strcasecmp("start", argv[1]) == 0)
	{
		sema_create(&talon_sem);
	}
	else if (strcasecmp("stop", argv[1]) == 0)
	{
		sema_destroy(&talon_sem);
	} else {
		error("error: argument must be: start|stop\n");
		return 1;
	}

	return 0;
}
