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
* Checker interface class.
*
*/


/**
 @file
 @internalComponent
 @released
*/

#include "checker.h"

/** 
Constructor intializes iCmdLine and iImageReaderList members.

@internalComponent
@released

@param aCmdPtr - pointer to a processed CmdLineHandler object
@param aImageReaderList - List of ImageReader insatance pointers
*/
Checker::Checker(CmdLineHandler* aCmdPtr, ImageReaderPtrList& aImageReaderList)
:iCmdLine(aCmdPtr), iImageReaderList(aImageReaderList), iAllExecutables(false), iNoCheck(false)
{
    /**
	The funciton iCmdLine->ReportFlag(), needs to be called for each and 
	every executable present in the image. To increase the performance it is 
	better to preserve this value.
	*/
	if(iCmdLine->ReportFlag() & KAll)
	{
		iAllExecutables = true;
	}

	if(iCmdLine->ReportFlag() & KNoCheck)
	{
		iNoCheck = true;
	}
}

/** 
Destructor

@internalComponent
@released
*/
Checker::~Checker()
{
	iCmdLine = 0;
}
