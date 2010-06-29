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
* Class to read the directory
* @internalComponent
* @released
*
*/


#ifndef DIRREADER_H
#define DIRREADER_H

#include "imagereader.h"

const string KParentDir("..");
const string KChildDir(".");

/**
Class Directory reader

@internalComponent
@released
*/
class DirReader : public ImageReader
{ 
public:
	DirReader(const char* aDirName);
	~DirReader(void);
	void ReadImage(void);
	void ProcessImage(void);
	void PrepareExeVsIdMap(void);
	const ExeVsIdDataMap& GetExeVsIdMap() const;
	ExeNamesVsDepListMap& GatherDependencies(void);
	void PrepareExeDependencyList(E32Image* aE32Image, StringList& aExecutables);
	static EImageType EntryType(string& aStr);

private:	
	void ReadDir(const string& aPath);
	bool IsExecutable(const string& aName); 
	ExeVsE32ImageMap iExeVsE32ImageMap;
};
 
#endif //DIRREADER_H
