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


#ifndef ROFSREADER_H
#define ROFSREADER_H

#include "imagereader.h"
#include "e32reader.h"
#include "typedefs.h"
#include "rofsimage.h"

const string KRofsImageIdentifier = "ROFS";
const string KRofsExtImageIdentifier = "ROFx";

/**
class to read rofs image

@internalComponent
@released
*/
class RofsReader : public ImageReader
{
public:
	RofsReader(const char *aFile, EImageType aImgType);
	~RofsReader(void);
	static bool IsRofsImage(const string& aWord);
	static bool IsRofsExtImage(const string& aWord);
    bool IsExecutable(const string& aName);
	void ReadImage(void);
	void ProcessImage(void);
	ExeNamesVsDepListMap& GatherDependencies(void);
	void PrepareExeDependencyList(E32Image* aE32Image, StringList& aExecutables);
	void PrepareExecutableList(void);
    void PrepareExeVsE32ImageMap(TRomNode* aEntry, CCoreImage *aImage, EImageType aImageType, ifstream& aInputStream, ExeVsE32ImageMap& aExeVsE32ImageMap, ExeVsOffsetMap& aExeVsOffsetMap, StringList& aHiddenExes);
	void DeleteHiddenExecutableVsE32ImageEntry(void);
    void PrepareExeVsIdMap(void);
    const ExeVsIdDataMap& GetExeVsIdMap(void) const;

private:
	CCoreImage *iImage;
	RCoreImageReader *iImageReader;
	TRomNode *iRootDirEntry;
    ExeVsOffsetMap iExeVsOffsetMap;

	EImageType iImageType;
	ExeVsE32ImageMap iExeVsE32ImageMap;
};

#endif //ROFSREADER_H
