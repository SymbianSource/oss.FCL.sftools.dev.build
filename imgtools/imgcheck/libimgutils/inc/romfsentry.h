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
	RomImageFSEntry (const char* aName) 
	: iName(aName), iSibling(0), iChildren(0){
	}

	virtual ~RomImageFSEntry() {
	}

	virtual bool IsDirectory() const = 0;
	virtual bool IsExecutable() const = 0;
	const char *Name() const { return iName.c_str();}

	void Destroy() {
		RomImageFSEntry *current = this; // root has no siblings
		while (current) {
			if (current->iChildren)
				current->iChildren->Destroy();
			RomImageFSEntry* prev=current;
			current=current->iSibling;
			delete prev;
		}
	}

	string iName;
	string iPath;
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
	RomImageFileEntry(const char* aName) 
	: RomImageFSEntry(aName),iExecutable(true){
	}
	~RomImageFileEntry() {
	}
	bool IsDirectory() const {
		return false;
	}
	union ImagePtr {
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
	bool IsExecutable() const {
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
	RomImageDirEntry(const char* aName) : RomImageFSEntry(aName){
	}
	~RomImageDirEntry() {
	}
	bool IsDirectory() const {
		return true;
	}
	bool IsExecutable() const {
		return false;
	}
};

#endif //ROMFSENTRY_H
