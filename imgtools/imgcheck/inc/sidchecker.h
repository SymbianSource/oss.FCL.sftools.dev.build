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


#ifndef SIDCHECKER_H
#define SIDCHECKER_H

#include "checker.h"

/**
class SID checker for SID validation

@internalComponent
@released
*/
class SidChecker : public Checker
{
protected:
	SidVsExeMap iSidVsExeMap;
	bool iSidAll;
	bool iE32Mode;

public:
	SidChecker(CmdLineHandler* aCmdPtr, ImageReaderPtrList& aImageReaderList);
	~SidChecker(void);
	void Check(ImgVsExeStatus& aImgVsExeStatus);
	void PrepareAndWriteData(ExeContainer* aExeContainer);

private:
	void FillExeSidStatus(ExeContainer* aExeContainer);
	const unsigned int GetExecutableOffset(const String& aExeName);
	void FillExeAttribute(ExeContainer* aExeContainer);
};
#endif//SIDCHECKER_H
