/*
* Copyright (c) 2009-2010 Nokia Corporation and/or its subsidiary(-ies).
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
* This program reads from stdin into a "buffer" structure. It is designed to be
* run from within valgrind to detect memory corruption errors.
* The buffer is then written to /tmp/outfile where it can be compared
* with the input to determine if they are the same
*/




#include <stdio.h>
#include <string.h>
#include "buffer.h"
#include <unistd.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#define OSIZE 40
#define ISIZEMAX 2049

int main(int argc, char *argv[])
{
	int nbytes = 0;
	byteblock *bb=NULL;
	buffer *b;
	char *pointertospace = NULL;
	int iterator = 0;
	int ofile;
	unsigned int space=51;

	b = buffer_new();

	do {
// space %= 5;
//		space++;
		pointertospace = buffer_makespace(b, space);
		if (!pointertospace)
			exit(1);

		nbytes = read(STDIN_FILENO, pointertospace, space);
		if (nbytes == -1)
			break;

		buffer_usespace(b, nbytes);
	}
	while (nbytes == space);

	iterator = 0;
	ofile = open("/tmp/outfile", O_CREAT | O_WRONLY, 00777);

	if (ofile <= 0)
	{
		perror("error");
		return 1;
	}
	
	while ((bb = buffer_getbytes(b, &iterator)))
	{
		write(ofile, &bb->byte0, bb->fill);
	}
	close(ofile);

	buffer_free(&b);
	return 0;
}
