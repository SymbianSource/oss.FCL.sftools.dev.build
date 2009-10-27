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




#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdarg.h>

#include "talon_process.h"
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

void prependattributes(buffer *b, char *attributes)
{
	char recipetag[RECIPETAG_STRMAX];
	char *rt;
	char envvarname[VARNAMEMAX];
	char *att;
	
	
        strcpy(recipetag, "<recipe ");
	rt = recipetag + 8;

	att = attributes;
	while (*att != '\0' && rt < &recipetag[RECIPETAG_STRMAX-1])
	{
		if ( *att == '$' )
		{
			int e;
			char *v;
			/* insert the value of an environent variable */
			att++;
			e = 0;	
			do {
				envvarname[e++] = *att;
				att++;
			} while ( e < (VARNAMEMAX-1) && (isalnum(*att) || *att == '_'));
			envvarname[e] = '\0';
/* DEBUG(("envvarname: %s\n", envvarname)); */
			v = talon_getenv(envvarname);
			if (v)
			{
				/* DEBUG(("     value: %s\n", v)); */
				char *oldv=v;
				while (*v != '\0' && rt < &recipetag[RECIPETAG_STRMAX-1])
				{
					*rt = *v;
					rt++; v++;
				}
				free(oldv);
			}
		} else {
			*rt = *att;
			rt++; att++;
		}
	}

	char *finish = ">\n<![CDATA[\n";
	
	while (*finish != '\0' && rt < &recipetag[RECIPETAG_STRMAX-1])
	{
		*rt = *finish;
		*rt++; finish++;
	}

	*rt = '\0';

        buffer_prepend(b, recipetag, strlen(recipetag));
}

/* read a recipe string from a temporary file.
 *
 * We only expect to do this for very long command lines on
 * Windows. So allocate the maximum size for CreateProcess on
 * Win32 (32768 bytes) and error if the file is longer than that. 
 *
 */
char *read_recipe_from_file(const char *filename)
{
	FILE *fp = fopen(filename, "r");

	if (!fp)
	{
		error("talon: error: could not read '%s'\n", filename);
		return NULL;
	}

	int max_length = 32768;
	char *recipe = (char*)malloc(max_length);

	if (!recipe)
	{
		error("talon: error: could not allocate memory to read '%s'\n", filename);
		return NULL;
	}
	int position = 0;

	/* read the file one character at a time */
	int c;
	while ((c = getc(fp)) != EOF)
	{
		switch (c)
		{
			case '\r':
			case '\n':
				/* ignore newlines */
				break;

			case '"':
				/* double quotes have to be escaped so they aren't lost later */
				if (position < max_length)
					recipe[position++] = '\\';
				if (position < max_length)
					recipe[position++] = c;
				break;

			default:
				if (position < max_length)
					recipe[position++] = c;
				break;
		}
	}
	fclose(fp);

	/* add a terminating \0 */
	if (position < max_length)
		recipe[position] = '\0';
	else
	{
		error("talon: error: command longer than 32768 in '%s'\n", filename);
		return NULL;
	}
	return recipe;
}

int main(int argc, char *argv[])
{
	/* find the argument to -c then strip the talon related front section */

	char *recipe = NULL;
	int talon_returncode = 0;

#ifdef HAS_GETCOMMANDLINE
	char *commandline= GetCommandLine();
	DEBUG(("talon: commandline: %s\n", commandline));
	/*
	 * The command line should be either,
	 * talon -c "some shell commands"
	 * or
	 * talon shell_script_file
	 *
	 * talon could be an absolute path and may have a .exe extension.
	 */
	recipe = strstr(commandline, "-c");
	if (recipe)
	{
		/* there was a -c so extract the quoted commands */

		while (*recipe != '"' && *recipe != '\0')
			recipe++;

		if (*recipe != '"')    /* we found -c but no following quote */
		{
			error("talon: error: unquoted recipe in shell call '%s'\n", commandline);
			return 1;
		}
		recipe++;
		
		int recipelen = strlen(recipe);
		if (recipelen > 0 && recipe[recipelen - 1] == '"')
			recipe[recipelen - 1] = '\0'; /* remove trailing quote */
	}
	else
	{
		/* there was no -c so extract the argument as a filename */

		recipe = strstr(commandline, "talon");
		if (recipe)
		{
			/* find the first space */
			while (!isspace(*recipe) && *recipe != '\0')
				recipe++;
			/* skip past the spaces */
			while (isspace(*recipe))
				recipe++;

			recipe = read_recipe_from_file(recipe);

			if (!recipe)
			{
			    error("talon: error: bad script file in shell call '%s'\n", commandline);
				return 1;
			}
		}
		else
		{
			error("talon: error: no 'talon' in shell call '%s'\n", commandline);
			return 1;
		}
	}
#else
	/*
	 * The command line should be either,
	 * talon -c "some shell commands"
	 * or
	 * talon shell_script_file
	 *
	 * talon could be an absolute path and may have a .exe extension.
	 */
	switch (argc)
	{
		case 2:
			recipe = read_recipe_from_file(argv[1]);
			break;
		case 3:
			if (strcmp("-c", argv[1]) != 0)
			{
				error("talon: error: %s\n", "usage is 'talon -c command' or 'talon script_filename'");
				return 1;
			}
			recipe = argv[2];
			break;
		default:
			error("talon: error: %s\n", "usage is 'talon -c command' or 'talon script_filename'");
			return 1;
	}
#endif

	/* did we get a recipe at all? */
	if (!recipe)
	{
		error("talon: error: %s", "no recipe supplied to the shell.\n");
		return 1;
	}

	/* remove any leading white space on the recipe */
	while (isspace(*recipe))
		recipe++;

	/* turn debugging on? */
	char *debugstr=talon_getenv("TALON_DEBUG");

	if (debugstr)
	{
		loglevel=LOGDEBUG;
		free(debugstr); debugstr=NULL;
	}

	DEBUG(("talon: recipe: %s\n", recipe));

	
	char varname[VARNAMEMAX];
	char varval[VARVALMAX];
	int dotagging = 0; 
	int force_descramble_off = 0;

	char  *rp = recipe;
	if (*rp == TALONDELIMITER) {
		dotagging = 1; 

		/* there are some talon-specific settings 
		 * in the command which must be stripped */
		rp++;
		char *out = varname;
		char *stopout = varname + VARNAMEMAX - 1;
		DEBUG(("talon: parameters found\n"));
		while (*rp != '\0')
		{
			
			switch (*rp) {
				case  '=':
					*out = '\0';
					DEBUG(("talon: varname: %s\n",varname));
					out = varval;
					stopout = varval + VARVALMAX - 1;
					break;
				case ';':
					*out = '\0';
					DEBUG(("talon: varval: %s\n",varval));
					talon_setenv(varname, varval);
					out = varname;
					stopout = varname + VARNAMEMAX - 1;
					break;
				default:	
					*out = *rp;
					if (out < stopout)
						out++;
					break;
			}

			if (*rp == TALONDELIMITER)
			{
				rp++;
				break;
			}
			
			rp++;
		}
	} else {
		/* This is probably a $(shell) statement 
 		 * in make so no descrambling needed and 
 		 * tags are definitely not wanted as they 
 		 * would corrupt the expected output*/
		force_descramble_off = 1; 
	}


	/* Now take settings from the environment (having potentially modified it) */	
	if (talon_getenv("TALON_DEBUG"))
		loglevel=LOGDEBUG;
	

	int enverrors = 0;

	char *shell = talon_getenv("TALON_SHELL");
	if (!shell)
	{
		error("error: %s", "TALON_SHELL not set in environment\n");
		enverrors++;	
	}

	int timeout = -1;
	char *timeout_str = talon_getenv("TALON_TIMEOUT");
	if (timeout_str)
	{
		timeout = atoi(timeout_str);
		free(timeout_str); timeout_str = NULL;
	}

	char *buildid = talon_getenv("TALON_BUILDID");
	if (!buildid)
	{
		error("error: %s", "TALON_BUILDID not set in environment\n");
		enverrors++;	
	}

	char *attributes = talon_getenv("TALON_RECIPEATTRIBUTES");
	if (!attributes)
	{
		error("error: %s", "TALON_RECIPEATTRIBUTES not set in environment\n");
		enverrors++;
	}


	int max_retries = 0;
	char *retries_str = talon_getenv("TALON_RETRIES");
	if (retries_str)
	{
		max_retries = atoi(retries_str);
		free(retries_str); retries_str = NULL;
	}	


	int descramble = 0;
	if (! force_descramble_off )
	{
		char *descramblestr = talon_getenv("TALON_DESCRAMBLE");
		if (descramblestr)
		{
			if (*descramblestr == '0')
				descramble = 0;
			else
				descramble = 1;
		
			free(descramblestr); descramblestr = NULL;
		}
	}



	/* Talon can look in a flags variable to alter it's behaviour */
	int force_success = 0;
	char *flags_str = talon_getenv("TALON_FLAGS");
	if (flags_str)
	{
		int c;
		for (c=0; flags_str[c] !=0; c++)
			flags_str[c] = tolower(flags_str[c]);

		if (strstr(flags_str, "forcesuccess"))
			force_success = 1;

		/* don't put <recipe> or <CDATA<[[ tags around the output. e.g. if it's XML already*/
		if (strstr(flags_str, "rawoutput"))
		{
			dotagging = 0;
		}

		free(flags_str); flags_str = NULL;
	}	

	/* Talon subprocesses need to have the "correct" shell variable set. */
	talon_setenv("SHELL", shell); 

	/* we have allowed some errors to build up so that the user
	 * can see all of them before we stop and force the user 
	 * to fix them
	 */
	if (enverrors)
	{
		return 1;
	}

	
	/* Run the recipe repeatedly until the retry count expires or
	 * it succeeds.
	 */
	int attempt = 0, retries = max_retries;
	proc *p = NULL;

	char *args[5];

	char *qrp=rp;

#ifdef HAS_GETCOMMANDLINE
	/* re-quote the argument to -c since this helps windows deal with it */
	int qrpsize = strlen(rp) + 3;
	qrp = malloc(qrpsize);
	qrp[0] = '"';
	strcpy(&qrp[1], rp);
	qrp[qrpsize-2] = '"';
	qrp[qrpsize-1] = '\0';
#endif

	int index = 0;
	args[index++] = shell;

	if (dotagging)  /* don't do bash -x for non-tagged commands e.g. $(shell output) */
		args[index++] = "-x";

	args[index++] = "-c";
	args[index++] = qrp;
	args[index++] = NULL;

	/* get the semaphore ready */
	talon_sem.name = buildid;
	talon_sem.timeout = timeout;
	do
	{
		char talon_attempt[TALON_ATTEMPT_STRMAX];
		double start_time = getseconds();
		
		attempt++;
		
		snprintf(talon_attempt, TALON_ATTEMPT_STRMAX-1, "%d", attempt);
		talon_attempt[TALON_ATTEMPT_STRMAX - 1] = '\0';

		talon_setenv("TALON_ATTEMPT", talon_attempt);
		
		p = process_run(shell, args, timeout);

		double end_time = getseconds();
		
		if (p) 
		{
			char status[STATUS_STRMAX];
			char timestat[STATUS_STRMAX];

			talon_returncode = p->returncode;

			if (dotagging) 
			{
				char *forcesuccessstr = force_success == 0 ? "" : " forcesuccess='FORCESUCCESS'";

				if (p->returncode != 0)
				{
					char *exitstr = retries > 0 ? "retry" : "failed";
					snprintf(status, STATUS_STRMAX - 1, "\n<status exit='%s' code='%d' attempt='%d'%s />", exitstr, p->returncode, attempt, forcesuccessstr );
				} else {
					snprintf(status, STATUS_STRMAX - 1, "\n<status exit='ok' attempt='%d'%s />", attempt, forcesuccessstr );
				}
				status[STATUS_STRMAX-1] = '\0';
	
				snprintf(timestat, STATUS_STRMAX - 1, "<time start='%.5f' elapsed='%.3f' />",start_time, end_time-start_time );
				timestat[STATUS_STRMAX-1] = '\0';

				prependattributes(p->output, attributes);
			
			if (dotagging) {
			}
				buffer_append(p->output, "\n]]>", 4);
				buffer_append(p->output, timestat, strlen(timestat));
				buffer_append(p->output, status, strlen(status));
				buffer_append(p->output, "\n</recipe>\n", 11);
			}
		
			unsigned int iterator = 0;
			byteblock *bb;
		
			if (descramble)	
				sema_wait(&talon_sem);
			while ((bb = buffer_getbytes(p->output, &iterator)))
			{
				write(STDOUT_FILENO, &bb->byte0, bb->fill);
			}
			if (descramble)	
				sema_release(&talon_sem);
		
		
			if (p->returncode == 0 || force_success)
			{
				process_free(&p);
				break;
			}

			process_free(&p);
		} else {
			error("error: failed to run shell: %s: check the SHELL environment variable.\n", args[0]);
			return 1;
		}

		retries--;
	}
	while (retries >= 0);

	if (buildid) free(buildid); buildid = NULL;
	if (attributes) free(attributes); attributes = NULL;
	if (shell) free(shell); shell = NULL;

	if (force_success)
		return 0;
	else 
		return talon_returncode;
}
