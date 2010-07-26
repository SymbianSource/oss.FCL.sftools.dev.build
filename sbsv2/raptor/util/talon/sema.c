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

// OS specific headers
#ifdef WIN32
#include <windows.h>
#include <tlhelp32.h>
#else
#include <semaphore.h>
#include <sys/types.h>
#include <signal.h>
#include <fcntl.h>
#include <time.h>
#endif

#include <unistd.h>


void sema_create(sbs_semaphore *s)
{
#ifdef WIN32
	s->handle = CreateSemaphore(NULL, 1, 1, s->name);
	if (s->handle)
		CloseHandle(s->handle);
	else
		error("unable to create semaphore %s", s->name);
#else
	s->handle = sem_open(s->name, O_CREAT | O_EXCL, 0644, 1);
	
  	if (s->handle == SEM_FAILED)
	{
		sem_close(s->handle);
	  	error("unable to create semaphore %s", s->name);
	}
	sem_close(s->handle);
#endif
}

void sema_destroy(sbs_semaphore *s)
{
	#ifdef WIN32
		/* can't destroy a windows semaphore... */
	#else
  		if (sem_unlink(s->name) != 0)
		  	error("unable to unlink semaphore", s->name);
	#endif
}


int sema_wait(sbs_semaphore *s)
{
	/* try and open the semaphore now */
        #ifdef WIN32
		s->handle = CreateSemaphore(NULL, 1, 1, s->name);
		if (!s->handle)
		{
			error("unable to open semaphore %s", s->name);
			return -2;
		}
        #else
		struct timespec tmout;
		
		s->handle = sem_open(s->name, 0);
	
	  	if (s->handle == SEM_FAILED)
		{
    			sem_close(s->handle);
      			error("unable to open semaphore %s\n", s->name);
			return -2;
    		}
	#endif
    
    /* wait for the semaphore to be free [timeout if it takes too long] */
 	int timedOutFlag = 0;
	int semcount = 0;
	#ifdef WIN32
 		timedOutFlag = (WaitForSingleObject(s->handle, s->timeout) != WAIT_OBJECT_0);
	#else

		sem_getvalue(s->handle, &semcount);
      		debug("sema: count before wait: %d\n", semcount);
      		debug("sema: timeout: %d\n", s->timeout);

	        if (clock_gettime(CLOCK_REALTIME, &tmout) == -1)
		{
               		error("sema: clock_gettime failed - can't do timed wait");
			return -1;
		}

		tmout.tv_sec += (s->timeout / 1000);
		tmout.tv_nsec += (s->timeout % 1000) * 1000;
		timedOutFlag = sem_timedwait(s->handle, &tmout); 
		/* roughly speaking the return value indicates timeouts. It also indicated
		 * signals.  We are glossing over this for the moment since it isn't really
		 * interesting in this application 
		 * */
	#endif

	return timedOutFlag;
}


void  sema_release(sbs_semaphore *s)
{
	/* release the semaphore */
	#ifdef WIN32
		ReleaseSemaphore(s->handle, 1, NULL);
	#else
	   	sem_post(s->handle);
	#endif
	
	   /* clean up */
	#ifdef WIN32
		CloseHandle(s->handle);
	#else
	   	sem_close(s->handle);
	#endif
}
