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
* E32Reader class
* @internalComponent
* @released
*
*/


#ifndef E32READER_H
#define E32READER_H

#include "imagereader.h"
#include "e32image.h"

class E32Image : public E32ImageFile
{
public:
	E32Image(void);
	~E32Image(void);
	char** GetImportExecutableNames(int& count);
};

/**
class to read E32 image

@internalComponent
@released
*/
class E32Reader : public ImageReader
{
private:
	StringList iDependencyList;
	E32Image *iE32Image;
	String iExeName;

public:
	void ReadImage(void);
	void ProcessImage(void);
	E32Reader(char* aImageName);
	~E32Reader(void);

	const StringList& GetDependencyList(void);
	ExeNamesVsDepListMap& GatherDependencies(void);
	static bool IsE32Image(char* aImageName);
	void PrepareExeVsIdMap(void);
	const ExeVsIdDataMap& GetExeVsIdMap() const;
};

#endif //E32READER_H
