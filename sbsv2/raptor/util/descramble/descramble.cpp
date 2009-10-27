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
 	descramble.cpp:

	Description
	-----------
	"descramble" is a program that buffers standard input until end of file
	and then copies the buffers to the standard output in such a way that
	if there are many copies of descramble running, each will be given an
	opportunity to write the complete contents of its buffers while the
	others wait.

	Purpose
	-------
	descramble is used to ensure that output from multiple concurrent processes
	is not interleaved.  It is useful in build systems such as GNU make with
	the -j switch, although it requires that makefiles are changed before it can
	work.

	Design
	------
	This program may be built on Linux or on Windows.  On both platforms the
	basic behavior is similar:
		1) Read standard input into buffers.  Allocate these dynamically
		   so that there is no limit.
		2) Wait on a named or system-wide semaphore.
		3) Output all the buffers to stdout.

	The name of the semaphore is a parameter and should be chosen so that multiple
	instances of the build system (or whatever process is running many tasks with
	descramble) cannot block each other.


	Special Considerations for Linux
	--------------------------------
	A named semaphore is a file in the filesystem.  It is not automatically removed
	when a process exits.  descramble provides a "stop" parameter to be run at the
	"end" of the build system (or other process) that will clean away this semaphore.


	Special Considerations for Windows
	----------------------------------
	The windows implementation is built with the MINGW toolchain.  On windows
	problems have been noticed that require a fairly complex timeout capability
	such that descramble will not wait "forever" for output from stdin.
	This solution currently uses a "kill thread" that will stop descramble if
	it is blocked in a read on stdio for more than the timeout period.

	The "kill thread" attempts to print as much of the input from stdin as has
	been read so far.  It scans this for XML characters and escapes them, finally
	printing its own XML-formatted error message with the escaped version of the
	input between <descramble> tags.




*/

#include <stdio.h>
#include <vector>
#include <ctype.h>

// what size chunks to allocate/read
const int BufferSize = 4096;
unsigned int globalreadcounter = 0;

// OS specific headers
#ifdef WIN32
#include <windows.h>
#include <tlhelp32.h>
#include <fcntl.h> /*  _O_BINARY */
#else
#include <stdlib.h>
#include <fcntl.h>
#include <semaphore.h>
#include <sys/types.h>
#include <signal.h>
#include <string.h>
#endif
#include <unistd.h>

#define DEFAULT_TIMEOUT (600000) // 10 minutes

#define GOOD_OUTPUT 1
#define BAD_OUTPUT 0

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


// readstate is a flag to indicate whether descramble is reading
// it's standard input.
// This allows the timeout thread on Windows to only cause the
// process to exit if there is an overdue read operation on the
// standard input.
int readstate=1;
int timeoutstate=0;

// The output semaphore.
sbs_semaphore sem;
#ifdef WIN32
	HANDLE bufferMutex;


	// Make all output handling binary
	unsigned int _CRT_fmode = _O_BINARY;


	DWORD killPIDTree = 0;
#else
	pid_t killPIDTree = 0;
#endif



// Where we store all the standard input.
std::vector<char*> buffers;
std::vector<int> bytesIn;


void error(const char *reason, char *SEM_NAME)
{
	fprintf(stderr, "<descrambler reason='%s' semaphore='%s' />\n", reason, SEM_NAME);
	exit(1);
}

#ifdef WIN32

void killProcess(DWORD pid)
{
	HANDLE proc = OpenProcess(PROCESS_TERMINATE,0,pid);
	if (proc)
	{
		TerminateProcess(proc, 1);
		//fprintf(stdout,"sent terminate to process=%d\n", pid);
		CloseHandle(proc);
	}
	else
	{
		//fprintf(stderr,"Can't open process=%d\n", pid);
	}
}

typedef struct {
	DWORD PID;
	DWORD PPID;
} proc;

void killProcessTreeRecursively(DWORD PPID, DWORD thisPID, std::vector<proc *> &processtree)
{
	int idx;

	for (idx=0; idx < processtree.size(); idx++)
	{
		if (processtree[idx]->PID != thisPID &&  processtree[idx]->PPID  == PPID)
		{
			killProcessTreeRecursively(processtree[idx]->PID, thisPID, processtree);
			//fprintf(stderr,"Found descendant =%d\n",processtree[idx]->PID );
		}
	}

	killProcess(PPID);
}

int killProcessTree(DWORD PPID)
{
	HANDLE hSnapShot;
	DWORD thisProcID=0;
	BOOL ok;
	PROCESSENTRY32 pe;
	std::vector<proc *> processtree;

	thisProcID = GetCurrentProcessId();

	hSnapShot=CreateToolhelp32Snapshot( TH32CS_SNAPPROCESS, 0 );

	// Put all this process information into an array;
	ok = Process32First(hSnapShot, &pe);
	while (ok)
	{
		if ( pe.th32ProcessID != thisProcID)
		{
			proc *p = new proc;
			p->PID = pe.th32ProcessID;
			p->PPID = pe.th32ParentProcessID;
			processtree.push_back(p);
			//fprintf(stderr,"Found process =%d\n", pe.th32ProcessID );
		}

		ok = Process32Next(hSnapShot, &pe);
	}

	killProcessTreeRecursively(PPID, thisProcID, processtree);

	CloseHandle(hSnapShot);

	//fprintf(stderr,"Ending killproc\n", PPID);

	return 0;
}

#endif

void createDescrambleSemaphore(sbs_semaphore *s)
{
#ifdef WIN32
	s->handle = CreateSemaphore(NULL, 1, 1, s->name);
	if (s->handle)
		CloseHandle(s->handle);
	else
		error("unable to create semaphore", s->name);
#else
	s->handle = sem_open(s->name, O_CREAT | O_EXCL, 0644, 1);

  	if (s->handle == SEM_FAILED)
	{
		sem_close(s->handle);
	  	error("unable to create semaphore", s->name);
	}
	sem_close(s->handle);
#endif
}

void destroyDescrambleSemaphore(sbs_semaphore *s)
{
	#ifdef WIN32
		/* can't destroy a windows semaphore... */
	#else
  		if (sem_unlink(s->name) != 0)
		  	error("unable to unlink semaphore", s->name);
	#endif
}


int waitForOutput(sbs_semaphore *s)
{
	/* try and open the semaphore now */
        #ifdef WIN32
		s->handle = CreateSemaphore(NULL, 1, 1, s->name);
		if (!s->handle)
			error("unable to open semaphore", s->name);
        #else
		s->handle = sem_open(s->name, 0);

	  	if (s->handle == SEM_FAILED)
		{
    			sem_close(s->handle);
      			error("unable to open semaphore", s->name);
    		}
	#endif

    /* wait for the semaphore to be free [timeout after 60 seconds] */
 	int timedOutFlag = 0;
	#ifdef WIN32
 		timedOutFlag = (WaitForSingleObject(s->handle, s->timeout) != WAIT_OBJECT_0);
	#else
		sem_wait(s->handle);
	#endif

	return timedOutFlag;
}


void  releaseOutput(sbs_semaphore *s)
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

void writeBuffers(int goodoutput)
{
	/* write stdin buffers to stdout. If the output comes
	   from a partially-complete command then make sure that there
	   is no malformed xml inside by escaping it. */
	char *escaped_output=NULL;

	#ifdef WIN32
		DWORD dwWaitResult = WaitForSingleObject(
		            bufferMutex,
		            INFINITE);
	#endif

	for (int i = 0; i < buffers.size(); i++)
	{
		int bytes_out;
		char *outbuf;

		if (goodoutput != GOOD_OUTPUT)
		{
			if (!escaped_output)
				escaped_output = new char[BufferSize*4];

			if (!escaped_output)
				error("No memory for escaped outputbuffer.",sem.name);

			char *buf = buffers[i];
			bytes_out = 0;
			for (int idx=0; idx < bytesIn[i]; idx++)
			{
				switch (buf[idx])
				{
					case '&':
						escaped_output[bytes_out++]='&';
						escaped_output[bytes_out++]='a';
						escaped_output[bytes_out++]='m';
						escaped_output[bytes_out++]='p';
						escaped_output[bytes_out++]=';';
						break;
					case '<':
						escaped_output[bytes_out++]='&';
						escaped_output[bytes_out++]='l';
						escaped_output[bytes_out++]='t';
						escaped_output[bytes_out++]=';';
						break;
					case '>':
						escaped_output[bytes_out++]='&';
						escaped_output[bytes_out++]='g';
						escaped_output[bytes_out++]='t';
						escaped_output[bytes_out++]=';';
						break;
					default:
						if (!iscntrl(buf[idx]) || buf[idx] == '\n' || buf[idx] == '\r')
							escaped_output[bytes_out++]=buf[idx];
						break;
				}

			}

			outbuf = escaped_output;

		} else {
			outbuf = buffers[i];
			bytes_out = bytesIn[i];
		}
		fwrite(outbuf, 1, bytes_out, stdout);
	}
	#ifdef WIN32
		ReleaseMutex(bufferMutex);
	#endif

	if (escaped_output)
		delete escaped_output;
	fflush(stdout);
}

#ifdef WIN32
/*
 A Thread that kills this process if it is "stuck" in a read operation
 for longer than the timeout period.

 There are some race conditions here that don't matter. e.g. globalreadcounter
 is not protected.  This might result in an "unfair" timeout but we don't care
 because the timeout should be pretty long and anything that's even nearly
 a timeout deserves to be timed out.

 Additionally, if the timeout is so quick that this function starts before the first
 ever read has happened then there would be a premature timeout.  This is not likely
 so we also dont' care - the timeout has a minimum value which is more than long
 enough (500msec) to deal with that.

*/
DWORD descrambleKillerThread(void * param)
{

	sbs_semaphore *s;
	unsigned int stored_globalreadcounter;
	s = (sbs_semaphore *)param;

	fflush(stderr);
	//fprintf(stdout, " timeout=%u sem_name='%s' \n", s->timeout, s->name);

	do
	{
		stored_globalreadcounter = globalreadcounter;
		Sleep(s->timeout);
	}
	while (globalreadcounter != stored_globalreadcounter);

	if (waitForOutput(s) != 0)
	{
		fprintf(stdout, "<descrambler reason='semaphore wait exceeded %ums timeout' semaphore='%s' />\n", s->timeout, s->name);
		ExitProcess(3);
	}

	if (readstate)
	{
		fprintf(stdout, "<descrambler reason='command output read exceeded %ums timeout' semaphore='%s'>\n", s->timeout, s->name);
		writeBuffers(BAD_OUTPUT);
		fprintf(stdout, "</descrambler>\n");
		fflush(stdout);
		if (killPIDTree != 0)
			killProcessTree(killPIDTree); // Make sure peers and parents all die. Nasty
		ExitProcess(2);
	}
	else
	{
		writeBuffers(GOOD_OUTPUT);
	}

	// Don't release the semaphore in case the main thread
	// gets it and tries to write the output.

	// Input process finished while we were waiting
	// for the semaphore so a false alarm.
	fflush(stdout);
	ExitProcess(0);
}
#endif


int main(int argc, char *argv[])
{
	char usage[]="usage: %s [-t timeout_millisecs] [ -k kill_PID_tree_on_fail  ] buildID [start | stop]\nwhere timeout_millisecs >= 500\n";
	int opt_res;
	char options[]="t:k:";

	sem.timeout = DEFAULT_TIMEOUT;


	opt_res = getopt(argc, argv, options);

	while (opt_res != -1 )
	{
		switch (opt_res)
		{
			case 'k':
				if (!optarg)
				{
					fprintf(stderr, "PID argument required for 'kill PID tree on fail' option\n");
					fprintf(stderr, usage, argv[0]);
					exit(1);
				}

				killPIDTree = atol(optarg);
				if (killPIDTree == 0)
				{
					fprintf(stderr, usage, argv[0]);
					fprintf(stderr, "kill PID tree on fail must be > 0: %u\n", killPIDTree);
					exit(1);
				}
				break;
			case 't':
				if (!optarg)
				{
					fprintf(stderr, "timeout argument required for timeout option\n");
					fprintf(stderr, usage, argv[0]);
					exit(1);
				}

				sem.timeout = atoi(optarg);
				if (sem.timeout < 500)
				{
					fprintf(stderr, usage, argv[0]);
					fprintf(stderr, "timeout was too low: %u\n", sem.timeout);
					exit(1);
				}
				break;
			case '?':
			default:
				fprintf(stderr, usage, argv[0]);
				fprintf(stderr, "Unknown option. %s\n", opterr);
				exit(1);
				break;
		}

	opt_res = getopt(argc, argv, options);
	}

	if (optind >= argc)
	{
		fprintf(stderr, usage, argv[0]);
		fprintf(stderr, "Missing buildID\n");
		exit(1);
	}

	sem.name = argv[optind];

	if (optind + 1 < argc)
	{
		optind++;

		if (strncmp(argv[optind], "stop",4) == 0)
			destroyDescrambleSemaphore(&sem);
		else if (strncmp(argv[optind],"start",5) == 0)
			createDescrambleSemaphore(&sem);
		else
		{
			fprintf(stderr, usage, argv[0]);
			fprintf(stderr, "Unknown argument:: %s\n", argv[optind]);
			exit(1);
		}

		exit(0);
	}

	#ifdef WIN32

		HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);

		bufferMutex = CreateMutex(NULL, FALSE, NULL);

		/*
		HANDLE WINAPI CreateThread(
		  __in_opt   LPSECURITY_ATTRIBUTES lpThreadAttributes,
		  __in       SIZE_T dwStackSize,
		  __in       LPTHREAD_START_ROUTINE lpStartAddress,
		  __in_opt   LPVOID lpParameter,
		  __in       DWORD dwCreationFlags,
		  __out_opt  LPDWORD lpThreadId
		); */

		DWORD killerThreadId;
		HANDLE hKillerThread;

		hKillerThread = CreateThread(NULL, 4096, (LPTHREAD_START_ROUTINE) descrambleKillerThread, (void*)&sem, 0, &killerThreadId);
	#endif

	/* read all of my stdin into buffers */
	int bytesRead = 0;
	int bufferIndex = 0;
	do
	{
		char *buffer = new char[BufferSize];
		if (buffer == NULL)
			error("not enough memory for buffer", sem.name);


		// Add an empty buffer in advance so that if there is a timeout
		// the partial command result can be gathered.
		#ifdef WIN32
			DWORD dwWaitResult = WaitForSingleObject(
			            bufferMutex,
			            INFINITE);
		#endif

		buffers.push_back(buffer);
		bytesIn.push_back(0);
		int *counter = &bytesIn[bufferIndex];


		#ifdef WIN32
			ReleaseMutex(bufferMutex);
		#endif
		// Empty buffer added.

		char c = fgetc(stdin);

		//fprintf(stderr, "counter %d buffersize %d\n", *counter, BufferSize);
		do
		{
			if (c == EOF)
				break;
			// escape unprintable characters that might make logs unparsable.
			if (iscntrl(c) && !isspace(c))
				c = '_';

			buffer[*counter] = c;

			*counter += 1;
			if (*counter >= BufferSize)
				break;

			c = fgetc(stdin);
			globalreadcounter = ++globalreadcounter % 65535*4;
		}
		while (c != EOF);

		//fprintf(stderr, "## %d bytesin %d\n", bufferIndex, *counter);
		bufferIndex++;
	}
	while (!feof(stdin) && !timeoutstate);
	readstate = 0; //  Tell the killerthread that it can back off.

	int timedout;

	timedout = waitForOutput(&sem);


 	if (timedout)
 		error("timed out waiting for semaphore", sem.name);
 	else
 	{
		writeBuffers(1);
	}

	releaseOutput(&sem);

 	/* let the OS free the buffer memory */
	exit(0);
}


