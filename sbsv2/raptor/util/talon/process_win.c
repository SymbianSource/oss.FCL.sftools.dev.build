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



#include <unistd.h>

#include "talon_process.h"
#include "buffer.h"
#include <errno.h>

#include <windows.h> 
#include <tchar.h>
#include <stdio.h> 
//#include <strsafe.h>


#include "log.h"

#define RETURN(x) { retval=x; goto cleanup; }
#define CLEANUP() cleanup:

#define READSIZE 4096

typedef struct ReadOpStruct {
	HANDLE semaphore;
	HANDLE thread;
	DWORD timeout;
	DWORD error;
	HANDLE file;
	BOOL success;
	char *space;
	DWORD nbytes;
	int id;
	struct ReadOpStruct *next;
} ReadOp;

typedef struct {
	ReadOp *first;
	ReadOp *last;
	HANDLE semaphore;
} ReadOpQ;

proc *process_new(void)
{
	proc *p = malloc(sizeof(proc));
	p->output = buffer_new();
	if (!p->output)
	{
		free(p);
		return  NULL;
	}
	p->starttime = 0;
	p->endtime = 0;
	p->returncode = 1;
	p->pid = 0;
	p->causeofdeath = PROC_NORMALDEATH;

	return p;
}

#define TALONMAXERRSTR 1024

void printlasterror(void)
{
	LPTSTR msg;
	DWORD err = GetLastError();
	char buf[1024];

	msg=buf;
	
	DEBUG(("error %d\n",err));
	FormatMessage( FORMAT_MESSAGE_ALLOCATE_BUFFER |
	  FORMAT_MESSAGE_FROM_SYSTEM |
	  FORMAT_MESSAGE_IGNORE_INSERTS, 
	  NULL, 		// lpSource
	  err, 	// dwMessageId,
	  0,
	  //MAKELANGID(LANG_NEUTRAL,SUBLANG_DEFAULT), 			// dwLanguageId,
	  msg,
	  0,
	  NULL
	);

	DEBUG(("%s\n",msg));
	//LocalFree(msg);
}

typedef struct 
{
	HANDLE read, write;
} tl_stream;


/* Because windows is d**b, there is no way to avoid blocking on an anonymous
 * pipe.  We can't use CancelIO  to stop reads since that's only in newer
 * versions of Win***ws.  So what we are left with is putting the read operation
 * into a thread, timing out in the main body and ignoring this thread if we
 * feel we have to.
 * */


DWORD readpipe_thread(void *param)
{
	ReadOpQ *io_ops = (ReadOpQ *)param;
	ReadOp *iopipe_op;
	/* have our own buffer since we don't want to risk that the
	 * caller's buffer might have disappeared by the time
	 * our readfile unblocks.
	 */

	while (1)
	{
		DWORD  waitres = WaitForSingleObject(io_ops->semaphore, INFINITE);
		iopipe_op = io_ops->last;

		DEBUG(("readpipe_thread: pre-ReadFile%d: %d \n", iopipe_op->id, iopipe_op->nbytes));
		iopipe_op->success = ReadFile(iopipe_op->file, iopipe_op->space, iopipe_op->nbytes, &iopipe_op->nbytes, NULL);
		iopipe_op->error = GetLastError();
		
		DEBUG(("readpipe_thread: post-ReadFile%d: %d read, err %d\n", iopipe_op->id, iopipe_op->nbytes,iopipe_op->error));
		ReleaseSemaphore(iopipe_op->semaphore, 1, NULL);
	}
}

proc *process_run(char executable[], char *args[], int timeout)
{
	proc *retval = NULL;
	char *text;
	int status;
	tl_stream stdout_p;
	tl_stream stdin_p;
	SECURITY_ATTRIBUTES saAttr; 
	PROCESS_INFORMATION pi;
	STARTUPINFO si;
	BOOL createproc_success = FALSE; 
	BOOL timedout = FALSE; 
	TCHAR *commandline = NULL;

	proc *p = process_new();

	if (p == NULL)
		return NULL;

	/* Make sure pipe handles are inherited */
	saAttr.nLength = sizeof(SECURITY_ATTRIBUTES); 
	saAttr.bInheritHandle = TRUE; 
	saAttr.lpSecurityDescriptor = NULL; 
	
	p->causeofdeath = PROC_PIPECREATE;

	DEBUG(("making pipes \n"));
	/* Child's Stdout */
	if ( ! CreatePipe(&stdout_p.read, &stdout_p.write, &saAttr, 1) ) 
	{
		printlasterror();
		RETURN(p);
	}
	DEBUG(("stdout done \n"));
	
	/* read handle to the pipe for STDOUT is not inherited */
	if ( ! SetHandleInformation(stdout_p.read, HANDLE_FLAG_INHERIT, 0) )
	{
		printlasterror();
		RETURN(p); 
	}
	DEBUG(("stdout noinherit \n"));
	
	/* a pipe for the child process's STDIN */
	if ( ! CreatePipe(&stdin_p.read, &stdin_p.write, &saAttr, 0) ) 
	{
		printlasterror();
		RETURN(p); 
	}
	DEBUG(("stdin done \n"));
	
	/*  write handle to the pipe for STDIN not inherited */
	if ( ! SetHandleInformation(stdin_p.read, HANDLE_FLAG_INHERIT, 0) )
	{
		printlasterror();
		RETURN(p); 
	}
	DEBUG(("pipes done \n"));
	
	
	p->causeofdeath = PROC_START;

	ZeroMemory( &si, sizeof(STARTUPINFO) );
	ZeroMemory( &pi, sizeof(PROCESS_INFORMATION) );
	
	si.cb = sizeof(STARTUPINFO); 
	si.hStdError = stdout_p.write;
	si.hStdOutput = stdout_p.write;
	/*
	  Rather than use the stdin pipe, which would be
       		  si.hStdInput = stdin_p.read;
	  Pass on talon's own standard input to the child process
	  This helps with programs like xcopy which demand that
	  they are attached to a console and not just any type of
	  input file.
	 */
	si.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
	si.dwFlags |= STARTF_USESTDHANDLES;

	
	DEBUG(("pre commandline \n"));
	/* create the commandline string */
	int len = 0;
	int i = 0;
	while (args[i] != NULL)
	{
		len += strlen(args[i++]) + 1;
	}
	len+=2;

	commandline = malloc(len*2);
	if (! commandline) 
		RETURN(p);
	commandline[0] = '\0';

	i = 0;
	while (args[i] != NULL)
	{
		strcat(commandline, args[i]);
		strcat(commandline, " ");
		i++;
	}


	/* Get the read thread ready to go before creating
	 * the process.
	 */
	ReadOpQ *ropq  = malloc(sizeof(ReadOpQ));

	ropq->first=NULL;
	ropq->last=NULL;
	ropq->semaphore = CreateSemaphore(NULL, 0, 1, NULL);
	DEBUG(("Creating read thread. \n"));

	DWORD readpipe_threadid;
	HANDLE h_readpipe_thread = CreateThread(NULL, 8192, (LPTHREAD_START_ROUTINE) readpipe_thread, (void*)ropq, 0, &readpipe_threadid);

	/* ready to run the process */
 
	DEBUG(("process commandline:\n%s \n", commandline));
	DEBUG(("\n"));
	createproc_success = CreateProcess(executable, 
	   commandline,     // command line 
	   NULL,          // process security attributes 
	   NULL,          // primary thread security attributes 
	   TRUE,          // handles are inherited 
	   0,             // creation flags 
	   NULL,          // use parent's environment 
	   NULL,          // use parent's current directory 
	   &si,  // STARTUPINFO pointer 
	   &pi);  // receives PROCESS_INFORMATION 

	if (! createproc_success)
	{
		DEBUG(("Createprocess failed. \n"));
		p->causeofdeath = PROC_SOMEODDDEATH;
		RETURN(p);
	}

	int have_status = 0;


	DEBUG(("Closing Handles. \n"));
	if (!CloseHandle(stdout_p.write)) 
		RETURN(p);
	if (!CloseHandle(stdin_p.read)) 
		RETURN(p);

	DEBUG(("Closed Handles. \n"));


	static int id=0;
	do
	{
		char *space = buffer_makespace(p->output, READSIZE);

		DWORD waitres;
		ReadOp *iopipe_op = malloc(sizeof(ReadOp));
		iopipe_op->semaphore = CreateSemaphore(NULL, 0, 1, NULL);
		iopipe_op->thread =  h_readpipe_thread;
		iopipe_op->timeout = timeout;
		iopipe_op->file = stdout_p.read;
		iopipe_op->space = malloc(READSIZE);
		iopipe_op->id = id++;
		iopipe_op->nbytes = READSIZE;
		iopipe_op->next = NULL;

		if (!ropq->first)
		{
			ropq->first = iopipe_op;
			ropq->last = iopipe_op;
		} else {
			ropq->last->next = iopipe_op;
			ropq->last = iopipe_op;
		}

		ReleaseSemaphore(ropq->semaphore, 1, NULL);

		DEBUG(("waiting for read %d\n", timeout));
		waitres = WaitForSingleObject(iopipe_op->semaphore, timeout);
		DEBUG(("read wait finished result= %d\n", waitres));

		if (waitres != WAIT_OBJECT_0)
		{
			DEBUG(("timeout \n"));
			timedout = TRUE;
			break;
		}
		else
		{
			DEBUG(("read signalled: nbytes: %d \n", iopipe_op->nbytes));
			if (iopipe_op->nbytes <= 0)
			{
				break;
			}
			memcpy(space, iopipe_op->space, iopipe_op->nbytes);	
			buffer_usespace(p->output, iopipe_op->nbytes);	
			DEBUG(("buffer took on nbytes: %d \n", iopipe_op->nbytes));
		}
	}
	while (1);

	if (timedout == FALSE) 
	{
		DEBUG(("Wait for process exit\n"));
		// Wait until child process exits.
		WaitForSingleObject(pi.hProcess, INFINITE);
		DEBUG(("Process exited\n"));

		DWORD exitcode;

		if (GetExitCodeProcess(pi.hProcess, &exitcode))
		{
			p->causeofdeath = PROC_NORMALDEATH;
			p->returncode = exitcode;
			DEBUG(("process exited normally = %d:\n", p->returncode));
			RETURN(p);	
		} else {
			p->causeofdeath = PROC_SOMEODDDEATH;
			p->returncode = 128;
			DEBUG(("process terminated \n"));
			RETURN(p);	
		}
	} else {
		TerminateProcess(pi.hProcess,1);
		p->causeofdeath = PROC_TIMEOUTDEATH;
		p->returncode = 128;
		DEBUG(("process timedout \n"));
		RETURN(p);	
	}

	/* Clean up the read operation queue 
	ReadOp *r = ropq.first;
	do
	{
		CloseHandle(r->semaphore);
		free(r->space);
		free(r);
		r = r->next;
	} while (r != NULL); */

	CLEANUP();
	if (retval == NULL)
	{
		if (p)
			process_free(&p);
	}
	if (commandline)
		free(commandline);
	
	return retval;
}

void process_free(proc **pp)
{
	if (!pp)
		return;
	if (! *pp)
		return;

	if ((*pp)->output)
		buffer_free(&((*pp)->output));
	
	free(*pp);

	*pp = NULL;
}
