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


#if !defined(__MEMMAPUTILS_H__)
#define __MEMMAPUTILS_H__
#include "h_utl.h"
#ifdef WIN32
#ifdef _STLP_INTERNAL_WINDOWS_H
#define __INTERLOCKED_DECLARED
#endif
#include <windows.h>
#include <io.h>
#endif

#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
 

const int KStatTrue = 1;
const int KStatFalse = 0;

/** 
class MemmapUtils

@internalComponent
@released
*/
class MemmapUtils
{
private:
	// Memory map file descriptor
	int iHFile;

#ifdef WIN32
	// Windows specific Memory map object handle
	HANDLE iHMMFile;
#endif
	// Map file name
	string iMapFileName;

public:
	MemmapUtils();
	~MemmapUtils();

	// Generate temporary file name
	void GetMapFileName(string& aFile);

	// Create the memory map
	void* OpenMemMapPointer(unsigned long aOffset, unsigned long aSize);
	// Close the memory map
	int CloseMemMapPointer(void* aData, unsigned long aSize);
	// Open the file for memory mapping
	int OpenMapFile();
	// Close the memory mapped file
	void CloseMapFile();
	// Delete the memory mapped file
	void DeleteMapFile();

	int IsMapFileOpen();

	// Windows specific file mapping object
	int CreateFileMapObject(unsigned long aSize);
	void CloseFileMapObject();
};

#endif //__MEMMAPUTILS_H__
