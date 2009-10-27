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


#ifndef __R_COREIMAGEREADER_H__
#define __R_COREIMAGEREADER_H__

class TRomNode;
class TRomLoaderHeader;
class Memmap;

/** 
class CoreRomImageReader

@internalComponent
@released
*/
class CoreRomImageReader
{
private:

	String iImgFileName;

	TUint8* iData;

	// Core ROM Image Headers
	TRomLoaderHeader	*iLoaderHdr;
	TRomHeader			*iRomHdr;
	TRomRootDirectoryList	*iRootDirList;

	// Directory Structure
	TRomNode* iRootDirectory;

	TBool IsCoreROM();
	TBool StoreImageHeader();
	TInt GetDirectoryStructures();
	TInt BuildDir(TRomDir* aDir, TRomNode* aPaFSEntry);
	TInt BuildDir(TInt16 *aOffsetTbl, TInt16 aOffsetTblCount, TRomDir *aPaRomDir, TRomNode* aPaFSEntry);
	TInt CreateRootDirectory();
	TInt AddFile(TRomNode *aPa, char *entryName, TRomEntry* aRomEntry);
	void Name(String& aName, char * aUnicodeName, int aLen);
	TBool IsExecutable(TUint8* Uids1);
	TUint GetHdrSize();

	TBool iUseMemMap;
	Memmap* iImageMap;

	TBool AllocateImageMap(Memmap*& aImageMap, TUint8*& aData, TUint aLen);
public:

	CoreRomImageReader(String aFileName, TBool aUseMemMap = EFalse);
	~CoreRomImageReader();

	TBool OpenImage();
	TBool ProcessImage();

	TRomNode* GetRootDirectory()
	{ 
		return iRootDirectory; 
	}

	TRomHeader* GetCoreRomHeader()
	{
		return iRomHdr;
	}
	TRomRootDirectoryList* GetRootDirList()
	{
		return iRootDirList;
	}

	void DeleteAll(TRomNode *node);
	void Display(TRomNode *node, TInt pad = 1);
	friend TInt OffsetCompare(const void *left, const void *right);
};

#endif //__R_COREIMAGEREADER_H__
