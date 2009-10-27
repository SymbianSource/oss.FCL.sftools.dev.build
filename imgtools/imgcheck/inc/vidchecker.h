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
* Checker interface class declaration
* @internalComponent
* @released
*
*/


#ifndef VIDCHECKER_H
#define VIDCHECKER_H

#include "checker.h"

/** 
Symbian Vendor Id

@internalComponent
@released
*/
const unsigned int KDefaultVid = 0x70000001;

/**
class VID Checker for VID validation

@internalComponent
@released
*/
class VidChecker : public Checker
{
protected:
	UnIntList iVidValList;

public:
	VidChecker(CmdLineHandler* aCmdPtr, ImageReaderPtrList& aImageReaderList);
	~VidChecker(void);
	void Check(ImgVsExeStatus& aImgVsExeStatus);
	void PrepareAndWriteData(ExeContainer* aExeContainer);

private:
	void FillExeVidStatus(IdData* aIdData);
};
#endif//VIDCHECKER_H
