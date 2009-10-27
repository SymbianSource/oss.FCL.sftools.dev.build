/*
* Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
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


#ifndef ROMFSENTRY_H
#define ROMFSENTRY_H

#include "typedefs.h"

/**
Class RomImageFSEntry, Base class ROM image file and directory entry structure

@internalComponent
@released
*/
class RomImageFSEntry 
{
public:
	RomImageFSEntry (char* aName) 
	: iName(aName), iSibling(0), iChildren(0)
	{
	}

	virtual ~RomImageFSEntry(void)
	{
	}

	virtual bool IsDirectory(void) = 0;
	virtual bool IsExecutable(void) = 0;
	const char *Name(void) { return iName.data();}

	void Destroy(void)
	{
		RomImageFSEntry *current = this; // root has no siblings
		while (current)
		{
			if (current->iChildren)
				current->iChildren->Destroy();
			RomImageFSEntry* prev=current;
			current=current->iSibling;
			DELETE(prev);
		}
	}

	String iName;
	String iPath;
	RomImageFSEntry *iSibling;
	RomImageFSEntry *iChildren;
};

/**
Class RomImageFileEntry, ROM image file entry structure

@internalComponent
@released
*/
class RomImageFileEntry : public RomImageFSEntry 
{
public:
	RomImageFileEntry(char* aName) 
	: RomImageFSEntry(aName),iExecutable(true)
	{
	}
	~RomImageFileEntry(void)
	{
	}
	bool IsDirectory(void)
	{
		return false;
	}
	union ImagePtr
	{
		TRomImageHeader *iRomFileEntry;
		TLinAddr iDataFileAddr;
	}ImagePtr;
	TRomEntry *iTRomEntryPtr;
	bool iExecutable;
	/** 
	Function responsible to return the node is executable or not.

	@internalComponent
	@released

	@return - returns 'true' if executable or 'false'
	*/
	bool IsExecutable(void)
	{
		if (iExecutable)
			return true;
		else
			return false;
	}
};

/**
Class RomImageDirEntry, ROM image Directory entry structure

@internalComponent
@released
*/
class RomImageDirEntry : public RomImageFSEntry
{
public:
	RomImageDirEntry(char* aName) : RomImageFSEntry(aName)
	{
	}
	~RomImageDirEntry(void)
	{
	}
	bool IsDirectory(void)
	{
		return true;
	}
	bool IsExecutable(void)
	{
		return false;
	}
};

#endif //ROMFSENTRY_H
