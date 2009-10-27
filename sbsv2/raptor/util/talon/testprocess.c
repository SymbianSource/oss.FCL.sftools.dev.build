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
#include <stdio.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>


#include "process.h"

int main(int argc, char *argv[])
{
	char *shell = getenv("TALON_SHELL");
	char **args = malloc((argc+2)*sizeof(char *));
	int i;
	proc *p;

	for (i=1; i < argc; i++)
	{
		args[i] = argv[i];
		printf("arg: %s\n", args[i]);
	}
	args[argc] = NULL;

	if (! shell)
	{
		fprintf(stderr, "error: %s", "TALONSHELL not set in environment\n");
		return 1;
	}

	args[0]  = shell;
	p = process_run(shell, args, 4000);

	if (p) 
	{

		buffer_prepend(p->output, "<recipe>\n<!CDATA<[[\n", 20);
		buffer_append(p->output, "\n]]></recipe>\n", 13);

		unsigned int iterator = 0;
		byteblock *bb;
		while ((bb = buffer_getbytes(p->output, &iterator)))
		{
			write(STDOUT_FILENO, &bb->byte0, bb->fill);
		}

		process_free(&p);
	} else {
		fprintf(stderr, "error: %s", "failed to run process\n");
		return 1;
	}

	free(args);
	return 0;
}
