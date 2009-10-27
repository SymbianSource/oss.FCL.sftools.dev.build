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




/*
 * Process.h
 */


#ifndef _TALONPROCESS_H_
#define _TALONPROCESS_H_

#include <sys/types.h>
#include "buffer.h"

typedef pid_t proc_handle;

#define PROC_NORMALDEATH 0
#define PROC_TIMEOUTDEATH 1
#define PROC_SOMEODDDEATH 2
#define PROC_PIPECREATE 3
#define PROC_STARTPROC 4


typedef struct 
{
	proc_handle pid;
	unsigned int starttime;
	unsigned int endtime;
	int returncode;
	unsigned int causeofdeath;
	buffer *output;
} proc;

proc *process_run(char executable[], char *args[], int timeout);
void process_free(proc **pp);
	
#endif
