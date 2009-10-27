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


#ifndef ROMREADER_H
#define ROMREADER_H

#include <e32image.h>
#include "imagereader.h"

class TRomRootDirectoryList;
class TRomDir;
class TRomImageHeader;
class TRomEntry;
class RomImageFSEntry;
class RomImageHeader;

const String KEpocIdentifier("EPOC");
const String KRomImageIdentifier("ROM");

const unsigned int KLdrOpcode = 0xe51ff004;
const unsigned int KRomBase = 0x80000000;
const unsigned int KRomBaseMaxLimit = 0x82000000;

/**
Class for ROM reader

@internalComponent
@released
*/
class RomReader : public ImageReader
{
private:
	RomAddrVsExeName iAddVsExeMap;
	VectorList	iImageAddress;

public:
	RomReader(const char* aFile, EImageType aImgType );
	~RomReader(void);

	static bool IsRomImage(const String& aWord);
	static bool IsRomExtImage(const String& aWord);
	void ReadImage(void);
	void ProcessImage(void);
	void BuildDir(TRomDir *aDir, RomImageFSEntry* aPaFSEntry);
	void BuildDir(short int *aOffsetTbl, short int aOffsetTblCount, 
					TRomDir *aDir, RomImageFSEntry* aPaFSEntry);
	void GetRomDirTbl(short int** aBase, short int& aCount, TRomDir *aRomDir);
	void AddChild(RomImageFSEntry *aPa, RomImageFSEntry *aChild, TRomEntry* aRomEntry);
	void Name(String& aName, const char * aUnicodeName, const int aLen);
       
	const unsigned long int ImageCompressionType(void) const;
	const char* RomHdrPtr(void) const;
	const unsigned long int RomBase(void) const;
	const unsigned int HdrSize(void) const;
	const unsigned long int RootDirList(void) const;
	const unsigned int ImgSize() const;
    
	void PrepareExecutableList(void);
	ExeNamesVsDepListMap& GatherDependencies(void);
	void PrepareAddVsExeMap(void);
	void CollectImportExecutableNames(const RomImageFSEntry* aEntry, StringList& aImportExecutableNameList);
	unsigned int CodeSectionAddress(unsigned int& aImageAddress);
    void PrepareExeVsIdMap(void);
    const ExeVsIdDataMap& GetExeVsIdMap(void) const;
  
    void PrepareExeVsRomFsEntryMap(void);
	RomImageHeader *iImageHeader;
	TRomRootDirectoryList *iRootDirList;
	RomImageFSEntry	*iRomImageRootDirEntry;
	unsigned char *iData;
    ExeVsRomFsEntryMap iExeVsRomFsEntryMap;

	EImageType iImgType;
	static bool iNoRomLoaderHeader;
};
 
#endif //ROMREADER_H
