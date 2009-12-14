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
* Expanding text buffer
*
*/




#include <malloc.h>
#include "buffer.h"
#include <string.h>

/* efficient allocation unit: */
#define ALLOCSIZE 4096
#define INITIALBLOCKCOUNT 128

byteblock *buffer_newblock(buffer *b, unsigned int size)
{
	byteblock *bb;
	if (!b)
		return NULL;
	
	b->lastblock++;
	
	if (b->lastblock == b->maxblocks)
	{
		byteblock **nbb = (byteblock **)realloc(b->blocks, sizeof(byteblock *) * (b->maxblocks + INITIALBLOCKCOUNT));
		if (!nbb)
			return NULL;

		b->blocks = nbb;
		b->maxblocks += INITIALBLOCKCOUNT;
	}

	bb = malloc(sizeof(byteblock) + size-1);

	if (!bb)
	{
		
		return NULL;
	}
	
	b->blocks[b->lastblock] = bb;

	bb->fill = 0;
	bb->size = size;

	return bb;
}

buffer *buffer_new(void)
{
	buffer *b = malloc(sizeof(buffer));

	if (b)
	{
		b->lastblock = -1; /* no blocks as yet */
		b->maxblocks = INITIALBLOCKCOUNT;
		b->blocks = (byteblock **)malloc(sizeof(byteblock *) * b->maxblocks);
		if (!b->blocks)
		{
			free(b);
			return NULL;
		}

		buffer_newblock(b, ALLOCSIZE);
	}
	
	return b;
}


char *buffer_append(buffer *b, char *bytes, unsigned int size)
{
	if (!b || !bytes) 
		return NULL;

	char *space = buffer_makespace(b, size);
	if (!space)
		return NULL;
	memcpy(space, bytes, size);
	buffer_usespace(b, size);

	return space;
}

char *buffer_prepend(buffer *b, char *bytes, unsigned int size)
{
	byteblock *bb;

	if (!b || !bytes) 
		return NULL;
	
    	bb = buffer_newblock(b, size);
	/* cheat by moving the new block from the end to the start. */

	bb = b->blocks[b->lastblock];
	if (b->lastblock != 0)
	{
		memmove(b->blocks+1, b->blocks, sizeof(byteblock *) * b->lastblock );
		b->blocks[0] = bb;
	}

	memcpy(&(b->blocks[0]->byte0), bytes, size);

	b->blocks[0]->fill = size;

	return &(b->blocks[0]->byte0);
}

/* Allocate memory at the end of the buffer (if there isn't
 * enough already) so that the user can append at least that 
 * many bytes without overrunning the buffer.  This is useful
 * where one may not know in advance how many bytes are to be
 * added (e.g. reading from a socket) but one does know the 
 * upper limit.
 */
char *buffer_makespace(buffer *b, unsigned int size)
{
	byteblock *bb;
	byteblock *last;
	if (!b)
		return NULL;

	last = b->blocks[b->lastblock];

	if (last->size - last->fill > size)
		return (&last->byte0 + last->fill);

	if (size > ALLOCSIZE)
	{
       		bb = buffer_newblock(b, size);
	} else {
       		bb = buffer_newblock(b, ALLOCSIZE);
	}
	
	if (!bb) 
		return NULL;

	return &bb->byte0;
}

void buffer_usespace(buffer *b, unsigned int nbytes)
{
	byteblock *last;
      
       	if (!b)
		return;	

	last = b->blocks[b->lastblock];

	if (last->fill + nbytes < last->size)
		last->fill += nbytes;
	else
		last->fill = last->size; /* really an error - no exceptions though. */
}

byteblock *buffer_getbytes(buffer *b, int *iterator)
{
	if (!b)
		return NULL;

	if (*iterator > b->lastblock)
		return NULL;

	return b->blocks[(*iterator)++];
}

void buffer_free(buffer **b)
{
	int i;
	buffer *bf;

	if (!b || !*b)
		return;

	bf=*b;

	if (bf->blocks)
	{
		for (i=0; i <= bf->lastblock; i++)
		{
			if (bf->blocks[i])
				free(bf->blocks[i]);
		}
		free(bf->blocks);
	}
	free(bf);

	*b = NULL;
}

