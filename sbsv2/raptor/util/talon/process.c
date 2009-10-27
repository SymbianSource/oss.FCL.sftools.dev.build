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

#include "process.h"
#include "buffer.h"
#include <stdlib.h>
#include <string.h>
#include <poll.h>
#include <signal.h>
#include <errno.h>
#include <sys/wait.h>

#include "log.h"


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

void childsig(int sig)
{
	//wait(&stat_loc);
	DEBUG(("SIGCHLD\n"));
}

struct sigaction child_action;

proc *process_run(char executable[], char *args[], int timeout)
{
	proc *p = process_new();

	if (p == NULL)
		return NULL;

	char *text;
	int status;
	int stdout_p[2];
	int stderr_p[2];

	child_action.sa_handler = childsig;
	sigemptyset (&child_action.sa_mask);
	child_action.sa_flags = 0;
	sigaction (SIGCHLD, &child_action, NULL);
	
	pipe(stdout_p);
	pipe(stderr_p);

	pid_t child = fork();
	if (child == 0)
	{
		close(stdout_p[0]);
		dup2(stdout_p[1], 1);
		close(stdout_p[1]);
		
		close(stderr_p[0]);
		dup2(stderr_p[1], 2);
		close(stderr_p[1]);

		execvp(executable, args);
		exit(1);
	} else if (child == -1) {
		p->causeofdeath = PROC_SOMEODDDEATH;
		return p;
	}
	else
	{
		close(stdout_p[1]);
		close(stderr_p[1]);
		p->pid = child;
		DEBUG(("child running\n"));
	}

	struct pollfd pf[2];

	int pv;
	int have_status = 0;
	do
	{
		pf[0].fd = stdout_p[0];
		pf[1].fd = stderr_p[0];
		pf[0].events = POLLIN;
		pf[0].revents = 0;
		pf[1].events = POLLIN;
		pf[1].revents = 0;
		DEBUG(("polling\n"));
	       	pv = poll(pf, 2, timeout);
		DEBUG(("polled %d\n", pv));
		if (pv == -1)
		{
		       	if (errno == EAGAIN)
			{
				errno = 0;
				DEBUG(("errno: \n"));
				continue;
			} else {
				/* EINVAL - can't poll */
				process_free(&p);
				return NULL;
			}
		} else if (pv == 0 ) {
			/* timeout */
			DEBUG(("timeout: \n"));
			kill(p->pid, SIGTERM);
			p->causeofdeath = PROC_TIMEOUTDEATH;
			break;
		}
		
		if (pf[0].revents & POLLIN )
		{
			char *space = buffer_makespace(p->output, 1024);
			int nbytes = read(pf[0].fd, space, 1024);
			if (nbytes < 0)
				break;
			buffer_usespace(p->output, nbytes);
		}
		if (pf[1].revents & POLLIN )
		{
			char *space = buffer_makespace(p->output, 1024);
			int nbytes = read(pf[1].fd, space, 1024);
			if (nbytes < 0)
				break;
			buffer_usespace(p->output, nbytes);
		}
		if  (pf[0].revents & (POLLERR | POLLHUP | POLLNVAL))
		{
			DEBUG(("stdout: pollerr %d\n", pf[0].revents));
			break;
		}
		
		if (  pf[1].revents & (POLLERR | POLLHUP | POLLNVAL)) 
		{
			DEBUG(("stderr: pollerr %d\n", pf[1].revents));
			break;
		}
		DEBUG(("events: %d %d \n", pf[0].revents, pf[1].revents));
	}
	while (1);

	waitpid(p->pid, &status, 0);
	if (WIFEXITED(status))
	{
		p->causeofdeath = PROC_NORMALDEATH;
		p->returncode = WEXITSTATUS(status);
		DEBUG(("process exited normally \n"));
	} else {
		p->causeofdeath = PROC_SOMEODDDEATH;
		if (WIFSIGNALED(status))
			p->returncode = WTERMSIG(status);
		else
			p->returncode = 128;
		DEBUG(("process terminated \n"));
	}
	
	return p;
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
