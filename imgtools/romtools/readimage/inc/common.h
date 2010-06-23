/*
* Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* @internalComponent
* @released
*
*/


#ifndef __IMAGE_READER_COMMON_H_
#define __IMAGE_READER_COMMON_H_

#include <string>
#include <iostream>
#include <iomanip>
#ifdef __MSVCDOTNET__ 
#include <ctype.h>
#endif
 

#include <e32std.h>
#include <e32std_private.h>
#include <e32rom.h>
#include <u32std.h>
#include <f32file.h>

#include "e32image.h"

#define EXIT_SUCCESS 0
#define EXIT_FAILURE 1

extern ostream *out;

#define DLL_UID1	10000079
#define EXE_UID1	1000007a

typedef enum EImageType
{
	EUNKNOWN_IMAGE,
	EROM_IMAGE,
	EROMX_IMAGE,
	EROFS_IMAGE,
	EROFX_IMAGE,
	//more here...
	EE32_IMAGE,
    //EBAREROM_IMAGE is introduced for handling bare ROM image (an image without loader header)
    EBAREROM_IMAGE
};
#ifdef __LINUX__
const char SLASH_CHAR1 = '/' ;
const char SLASH_CHAR2 = '\\' ;
#define MKDIR(a)		mkdir(a,0777)
#else
const char SLASH_CHAR1 = '\\' ;
const char SLASH_CHAR2 = '/' ;
#define MKDIR(a)		mkdir(a)
#endif
#define DUMP_HDR_FLAG			0x1
#define DUMP_VERBOSE_FLAG		0x2
#define DUMP_DIR_ENTRIES_FLAG	0x4
#define DUMP_E32_IMG_FLAG		0x8

#define LOG_IMAGE_CONTENTS_FLAG	0x10
#define EXTRACT_FILES_FLAG		0x20
#define MODE_SIS2IBY			0x40
#define RECURSIVE_FLAG			0x80
#define EXTRACT_FILE_SET_FLAG	0x100

// maximum buffer size.
#define _MAX_BUFFER_SIZE_		256 

class ReaderUtil
{
public:
	static bool IsExecutable(TUint8* Uids1);
};

class ImageReaderException
{
public:
	ImageReaderException(const char* aFile, const char* aErrMessage);
	virtual ~ImageReaderException(){}
	virtual void Report();

	string iImgFileName;
	string iErrMessage;
};

class ImageReaderUsageException : public ImageReaderException
{
public:
	ImageReaderUsageException(const char* aFile, const char* aErrMessage);
	void Report();
};

ostream& DumpInHex(char* aDesc, TUint32 aData, bool aContinue = false,TUint aDataWidth=8,\
				   char aFiller='0', TUint aMaxDescWidth=28);

#endif //__IMAGE_READER_COMMON_H_
