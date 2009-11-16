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




#ifndef _SEMA_H_
#define _SEMA_H_

#ifdef WIN32
#include <windows.h>
#include <tlhelp32.h>
#else
#include <semaphore.h>
#include <sys/types.h>
#endif



typedef struct
{
	char *name;
	#ifdef WIN32
	HANDLE handle;
	#else
	sem_t *handle;
	#endif
	unsigned int timeout;
} sbs_semaphore;


void sema_create(sbs_semaphore *s);
void sema_destroy(sbs_semaphore *s);
int sema_wait(sbs_semaphore *s);
void  sema_release(sbs_semaphore *s);
int sema_wait(sbs_semaphore *s);

#endif
