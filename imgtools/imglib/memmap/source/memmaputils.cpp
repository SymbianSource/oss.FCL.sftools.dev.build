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


#include "memmaputils.h"

/**
Constructor: MemmapUtils class
Initilize the parameters to data members.

@internalComponent
@released
*/
MemmapUtils::MemmapUtils( )
: iHFile(0)
{
#ifdef WIN32
	iHMMFile = 0;
#endif
}


/**
Destructor: MemmapUtils class
Deallocates the memory for data members

@internalComponent
@released
*/
MemmapUtils::~MemmapUtils( )
{
	CloseMapFile();

	DeleteMapFile();
}

/**
OpenMemMapPointer: Opens the memory map pointer

@internalComponent
@released

@param aOffset - Starting offset of the memory map
@param aSize - Size of the memory map
*/
void* MemmapUtils::OpenMemMapPointer(unsigned long aOffset, unsigned long aSize)
{
#ifdef WIN32
	// Create map view pointer
	return (void*)MapViewOfFile(iHMMFile, FILE_MAP_ALL_ACCESS, 0, aOffset, aSize);
#else
	return KStatFalse;
#endif
}

/**
CloseMemMapPointer: Closes the memory map pointer

@internalComponent
@released

@param aData - Memory map pointer
@param aSize - Size of the memory map
*/
int MemmapUtils::CloseMemMapPointer(void* aData, unsigned long aSize)
{
	unsigned long statusFlg = KStatFalse;

	if(aData && iHFile)
	{
#ifdef WIN32
		statusFlg = FlushViewOfFile(aData, aSize);
		statusFlg &= FlushFileBuffers((HANDLE)_get_osfhandle(iHFile));
		statusFlg &= UnmapViewOfFile(aData);
#endif
	}

	if(statusFlg == (unsigned long)KStatFalse)
	{
		return KStatFalse;
	}

	return KStatTrue;
}

/**
OpenMapFile: Opens the file for memory mapping

@internalComponent
@released
*/
int MemmapUtils::OpenMapFile()
{
	GetMapFileName(iMapFileName);

	if(iMapFileName.empty())
	{
		return KStatFalse;
	}

#ifdef WIN32
	iHFile = open((const char*)iMapFileName.data(), (_O_CREAT | _O_BINARY | _O_RDWR));
#endif

	if((iHFile == (-1)) || (!iHFile))
	{
		Print(EAlways, "Cannot open the memory map file %s", (char*)iMapFileName.data());
		iHFile = 0;

		return KStatFalse;
	}

	return KStatTrue;
}

/**
IsMapFileOpen: Returns the open status of the memory map file

@internalComponent
@released
*/
int MemmapUtils::IsMapFileOpen()
{
	return (iHFile) ? KStatTrue : KStatFalse;
}

/**
CloseMapFile: Closes the file for memory mapping

@internalComponent
@released
*/
void MemmapUtils::CloseMapFile()
{
	if(iHFile)
	{
#ifdef WIN32
		close(iHFile);
#endif
		iHFile = 0;
	}
}

/**
DeleteMapFile: Deletes the file for memory mapping

@internalComponent
@released
*/
void MemmapUtils::DeleteMapFile()
{
#ifdef WIN32
	unlink((char*)iMapFileName.data());
#endif
}

/**
CreateFileMapObject: Creates the map file object

@internalComponent
@released

@param aSize - Size of the memory map
*/
int MemmapUtils::CreateFileMapObject(unsigned long aSize)
{
#ifdef WIN32
	// Create memory map object for the given size of the file
	iHMMFile = CreateFileMapping((HANDLE)_get_osfhandle(iHFile), NULL, 
				PAGE_READWRITE, 0, aSize, NULL);

	if(!iHMMFile || (iHMMFile == INVALID_HANDLE_VALUE))
	{
		return KStatFalse;
	}
#endif

	return KStatTrue;
}

/**
CloseFileMapObject: Closes the map file object

@internalComponent
@released
*/
void MemmapUtils::CloseFileMapObject()
{
#ifdef WIN32
	if(iHMMFile)
	{
		CloseHandle(iHMMFile);
		iHMMFile = 0;
	}
#endif
}

/**
GetMapFileName: Generates a temporary file name

@internalComponent
@released

@param aFile - Returns the name of the temporary file
*/
void MemmapUtils::GetMapFileName(String& aFile)
{
	char *fileName = 0;

#ifdef WIN32
	fileName = new char[MAX_PATH];

	if(fileName)
		GetTempFileName(".", "MMAP", 0, fileName);

	aFile.assign(fileName);
#endif

	if(fileName)
		delete[] fileName;

}

