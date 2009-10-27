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


#ifndef __ROM_IMAGE_READER__
#define __ROM_IMAGE_READER__

#include "image_reader.h"

class TRomLoaderHeader;
#include <wchar.h>
class RomImageFSEntry 
{
public:
	RomImageFSEntry (const char* aName) ;
	virtual ~RomImageFSEntry() ;
	virtual bool IsDirectory() = 0;
	const char *Name() { return iName.c_str();}

	string iName;
	string iPath;
	RomImageFSEntry 	*iSibling;
	RomImageFSEntry 	*iChildren;
};

class RomImageFileEntry : public RomImageFSEntry 
{
public:
	RomImageFileEntry(const char* aName) : RomImageFSEntry(aName), iExecutable(true)
	{
	}

	bool IsDirectory() {
		return false;
	}
	
	union ImagePtr
	{
		TRomImageHeader		*iRomFileEntry;
		TLinAddr			iDataFileAddr;
	}ImagePtr;

	TRomEntry		*iTRomEntryPtr;

	bool iExecutable;
};

class RomImageDirEntry : public RomImageFSEntry
{
public:
	RomImageDirEntry(const char* aName) : RomImageFSEntry(aName)
	{
	}

	bool IsDirectory()
	{
		return true;
	}

};


class RomImageHeader
{
public:
	RomImageHeader(char* aHdr, EImageType aImgType = EROM_IMAGE );
	TRomLoaderHeader	*iLoaderHdr;
	TRomHeader			*iRomHdr;
	TExtensionRomHeader	*iExtRomHdr;
	
	void DumpRomHdr();
	void DumpRomXHdr();
};

class RomImageReader : public ImageReader
{
public:
	RomImageReader(const char* aFile, EImageType aImgType = EROM_IMAGE );
	~RomImageReader();

	void ReadImage();
	void ProcessImage();
	void BuildDir(TRomDir *aDir, RomImageFSEntry* aPaFSEntry); 

	void AddChild(RomImageFSEntry *aParent, RomImageFSEntry *aChild, TRomEntry* aRomEntry);
	void Name(string& aName, const wchar_t* aUnicodeName, TUint aLen);
	void Validate();
	void Dump();
	void DumpTree();
	void DumpSubTree(RomImageFSEntry* aFsEntry);
	void DumpImage(RomImageFileEntry*);
	void DumpAttribs(RomImageFSEntry* aFsEntry);
	void DumpDirStructure();
	void DumpDirStructure(RomImageFSEntry*, int &aPadding);
	void ExtractImageContents();
	void TraverseImage(RomImageFSEntry*  aEntity,ofstream& aFile);
	void CheckFileExtension(RomImageFSEntry*  aEntity,ofstream& aFile);
	void LogRomEnrtyToFile(const char* aPath,const char* aEntityName,ofstream& aFile);

	void GetFileInfo(FILEINFOMAP &aFileMap);
	void ProcessDirectory(RomImageFSEntry *aEntity, FILEINFOMAP &aFileMap);
	TUint32 GetImageSize();
	
	TUint32 GetImageCompressionType(); 

	TLinAddr GetRomBase();
	TUint GetHdrSize();
	TLinAddr GetRootDirList();

	RomImageHeader			*iImageHeader; 
	RomImageFSEntry			*iRomImageRootDirEntry;

protected:	
	void					ReadData(char* aBuffer, TUint aLength);	

	ifstream				iFile ;
	TUint32					iRomSize ;
	char*					iHeaderBuffer ;
	char*					iRomLayoutData ; 
	EImageType				iImgType; 

};

#endif //__ROM_IMAGE_READER__

