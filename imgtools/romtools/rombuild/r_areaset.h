/*
* Copyright (c) 2000-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* Area-related API
*
*/


#ifndef __R_AREASET_H__
#define __R_AREASET_H__

#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <fstream>

#include <e32std.h>
#include <e32rom.h>				// TLinAddr

typedef std::vector<std::string> TStringList;
struct DepInfo
{
public:
	TBool dependOthers;
	TBool beenDepended;
	int index;
	std::string portName;
	TStringList depFilesList;
	DepInfo()
	{
		dependOthers = EFalse;
		beenDepended = EFalse;
		index = -1;
	}
};
typedef std::map<std::string, DepInfo> TDepInfoList;

class TRomBuilderEntry;

/**
 A zone of memory in which files are stored.

 Areas (except the default one - see below) are relocated from ROM to
 RAM at boot time.

 When created an area is given a "destination base address" (the start
 of the area in RAM) and a maximum size.

 During processing the "source base address" (the start of the area in
 ROM) is set once and the area is extended each time a file is
 processed by setting repeatedly the "source limit address" (the top
 of the area in ROM).

 The default area contains files that don't need relocation.  So its
 "source base address" and "destination base address" are the same.

 @private 
*/

class Area
	{
public:
	~Area();

	const char* Name() const;

	void SetSrcBaseAddr(TLinAddr aSrcBaseAddr);
	TLinAddr SrcBaseAddr() const;

	TBool ExtendSrcLimitAddr(TLinAddr aSrcLimitAddr, TUint& aOverflow);
	TLinAddr SrcLimitAddr() const;
	
	TLinAddr DestBaseAddr() const;

	TUint MaxSize() const;
	TUint UsedSize() const;

	TBool IsDefault() const;

	void AddFile(TRomBuilderEntry* aFile);

	TInt SortFilesForPagedRom();
private:
	// only AreaSet can create areas
	Area(const char* aName, TLinAddr aDestBaseAddr, TUint aMaxSize, Area* aNext=0);
	void ReleaseAllFiles();
	void WriteDependenceGraph();
public:
	TRomBuilderEntry* iFirstPagedCode; // For PagedRom only
private:
	const char* iName;
	TLinAddr iDestBaseAddr;
	TLinAddr iSrcBaseAddr;
	TLinAddr iSrcLimitAddr;
	TUint iMaxSize;

	TBool iIsDefault;

	TRomBuilderEntry* iFiles;
	TRomBuilderEntry** iNextFilePtrPtr;

	Area* iNextArea;

	friend class AreaSet;
	friend class FilesInAreaIterator;
	friend class NonDefaultAreasIterator;
	};


inline  const char* Area::Name() const
	{
	return iName;
	}


inline void Area::SetSrcBaseAddr(TLinAddr aSrcBaseAddr)
	{
	// setting allowed only once
	assert(iSrcBaseAddr == 0);	
	assert(aSrcBaseAddr != 0);

	iSrcLimitAddr = iSrcBaseAddr = aSrcBaseAddr;
	}


inline TLinAddr Area::SrcBaseAddr() const
	{
	// must have been set before
	assert(iSrcBaseAddr != 0);
	return iSrcBaseAddr;
	}


inline TLinAddr Area::SrcLimitAddr() const
	{
	// must have been set before
	assert(iSrcBaseAddr != 0);
	return iSrcLimitAddr;
	}


inline TLinAddr Area::DestBaseAddr() const
	{
	return iDestBaseAddr;
	}


inline TUint Area::MaxSize() const
	{
	return iMaxSize;
	}


inline TUint Area::UsedSize() const
	{
	return iSrcLimitAddr-iSrcBaseAddr;
	}


inline TBool Area::IsDefault() const
	{
	return iIsDefault;
	}


////////////////////////////////////////////////////////////////////////

class TRomBuilderEntry;

/**
 Iterate over every file in a given area.

 Files are iterated in the order in which they have been appended to
 the area.  
 
 @private
*/

class FilesInAreaIterator
	{
public:
	FilesInAreaIterator(const Area& aArea);

	TBool IsDone() const;
	TRomBuilderEntry* Current() const;
	void GoToNext();

private:
	TRomBuilderEntry* iCurrentFile;
	};


inline FilesInAreaIterator::FilesInAreaIterator(const Area& aArea)
	: iCurrentFile(aArea.iFiles)
	{
	}

inline TBool FilesInAreaIterator::IsDone() const
	{
	return iCurrentFile == 0;
	}

inline TRomBuilderEntry* FilesInAreaIterator::Current() const
	{
	return iCurrentFile;
	}

////////////////////////////////////////////////////////////////////////

/**
 Set of areas indexed by name.

 There can be only one default area identified by its name
 (KDefaultAreaName).

 @private 
*/

class AreaSet
	{
public:
	enum TAddResult
		{ 
		EAdded,
		EOverlap,
		EDuplicateName,
		EOverflow,
		};

public:
	AreaSet();
	~AreaSet();

	TAddResult AddArea(const char* aName, TLinAddr aDestBaseAddr, TUint aMaxSize, const char*& aOverlappingArea);
	void ReleaseAllAreas();

	Area* FindByName(const char* aName) const;
	TInt Count() const;
	Area* DefaultArea() const;

private:
	Area* iNonDefaultAreas;
	Area* iDefaultArea;
	TInt iAreaCount;

public:
	static const char KDefaultAreaName[];

	friend class NonDefaultAreasIterator;
	};


inline TInt AreaSet::Count() const
	{
	return iAreaCount;
	}


inline Area* AreaSet::DefaultArea() const
	{
	return iDefaultArea;
	}


////////////////////////////////////////////////////////////////////////


/**

 Iterate over every non-default area of a given area set.

 @private
*/

class NonDefaultAreasIterator
	{
public:
	NonDefaultAreasIterator(const AreaSet& aAreaSet);

	TBool IsDone() const;
	Area& Current() const;
	void GoToNext();

private:
	Area* iCurrentArea;
	};

inline NonDefaultAreasIterator::NonDefaultAreasIterator(const AreaSet& aAreaSet)
	: iCurrentArea(aAreaSet.iNonDefaultAreas)
	{
	}

inline TBool NonDefaultAreasIterator::IsDone() const
	{
	return iCurrentArea == 0;
	}

inline Area& NonDefaultAreasIterator::Current() const
	{
	assert(iCurrentArea != 0);
	return *iCurrentArea;
	}

#endif // __R_AREASET_H__
