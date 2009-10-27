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


#ifndef IMAGEREADER_H
#define IMAGEREADER_H

#include "typedefs.h"

class TRomNode;

/**
Base class to read and process the image(ROFS/ROM/E32)

@internalComponent
@released
*/
class ImageReader
{
protected:
	String	iImgFileName;
	Ifstream iInputStream;
	StringList iExecutableList;
	StringList iHiddenExeList;
	unsigned int iImageSize;
    ExeVsIdDataMap iExeVsIdData;
	ExeNamesVsDepListMap iImageVsDepList;
	bool iExeAvailable;

public:
	ImageReader(const char* aFile);
	virtual ~ImageReader(void);
	virtual void ReadImage(void) = 0;
	virtual void ProcessImage(void) = 0;
	virtual void PrepareExecutableList(void);
	virtual ExeNamesVsDepListMap& GatherDependencies(void) = 0;
    virtual void PrepareExeVsIdMap(void) = 0;
    virtual const ExeVsIdDataMap& GetExeVsIdMap(void) const = 0;
    
	const StringList& GetExecutableList(void) const;
	const StringList& GetHiddenExeList(void) const;
	String& ImageName(void);
	static EImageType ReadImageType(const String aImageName);
	bool ExecutableAvailable(void);
};

#endif //IMAGEREADER_H
