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
* buffer.c
* Resizable buffer for output from subprocesses.
*
*/




#ifndef _TALON_BUFFER_H_
#define _TALON_BUFFER_H_


typedef struct {
	unsigned int size, fill;
	/* This struct will be followed by the number of bytes in "size" */
	char byte0;
} byteblock;

typedef struct {
	byteblock **blocks;
	int maxblocks;
	int lastblock;
	unsigned int size;
} buffer;

buffer *buffer_new(void);
char *buffer_append(buffer *b, char *bytes, unsigned int size);
char *buffer_prepend(buffer *b, char *bytes, unsigned int size);
char *buffer_makespace(buffer *b, unsigned int size);
void buffer_usespace(buffer *b, unsigned int nbytes);
byteblock *buffer_getbytes(buffer *b, int *iterator);
void buffer_free(buffer **b);

#endif
