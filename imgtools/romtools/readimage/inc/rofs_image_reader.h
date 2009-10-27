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


#ifndef __ROFS_IMAGE_READER__
#define __ROFS_IMAGE_READER__

#include <stdio.h>
#include "image_reader.h"
#include "e32def.h"
#include "e32cmn.h"
#include "e32std.h"
#include "rofs.h"
#include "r_romnode.h"
#include "r_coreimage.h"
#include "f32file.h"

extern TUint gCompressionMethod;

class CCoreImage;
class RCoreImageReader;
class TRofsHeader;
class TExtensionRofsHeader;
class TRomNode;

class RofsImage : public CCoreImage
{
public:
	RofsImage(RCoreImageReader *aReader);
	TInt			ProcessImage();

	TRofsHeader				*iRofsHeader;
	TExtensionRofsHeader	*iRofsExtnHeader;
	long					iAdjustment;
	RCoreImageReader::TImageType iImageType;
};

class RofsImageReader : public ImageReader
{
public:
	RofsImageReader(char* aFile);
	~RofsImageReader();

	void ReadImage();
	void ProcessImage();
	void Validate();
	void Dump();
	void DumpHeader();
	void DumpDirStructure();
	void DumpFileAttributes();
	void MarkNodes();
	void SetSeek(streampos aOff, ios::seek_dir aStartPos=ios::beg);
	void ExtractImageContents();
	void CheckFileExtension(char* aFileName,TRomBuilderEntry* aEntry,TRomNode* aNode,ofstream& aLogFile );
	void GetCompleteNodePath(TRomNode* aNode,string& aName,char* aAppStr);
	void WriteEntryToFile(char* aFileName,TRomNode* aNode,ofstream& aLogFile);

	void GetFileInfo(FILEINFOMAP &aFileMap);
	TUint32 GetImageSize();

private:
	CCoreImage			*iImage;
	RCoreImageReader	*iImageReader;
	
	TRomNode			*iRootDirEntry;

	ifstream			*iInputFile;
};

#endif //__ROFS_IMAGE_READER__

