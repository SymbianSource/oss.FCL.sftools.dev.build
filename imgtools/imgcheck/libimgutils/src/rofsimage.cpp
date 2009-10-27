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
*
*/


/**
 @file
 @internalComponent
 @released
*/

#include "typedefs.h"
#include "rofsimage.h"

/** 
Constructor.

@internalComponent
@released

@param aReader - image reader pointer
*/
RofsImage::RofsImage(RCoreImageReader *aReader)
: CCoreImage(aReader) ,
iRofsHeader(0), iRofsExtnHeader(0),iAdjustment(0), 
iImageType((RCoreImageReader::TImageType)0)
{
}

/** 
Destructor deletes iRofsHeader and iRofsExtnHeader.

@internalComponent
@released

@param aReader - image reader pointer
*/
RofsImage::~RofsImage()
{
	DELETE(iRofsHeader);
	DELETE(iRofsExtnHeader);
}

/** 
Function responsible to read the ROFS image and to construct the tree for the 
elements available in Directory section.

@internalComponent
@released

@return - returns the error code
*/
TInt RofsImage::ProcessImage()
{
	int result = CreateRootDir();
	if (result == KErrNone)
	{
		if (iReader->Open())
		{
			iImageType = iReader->ReadImageType();
			if (iImageType == RCoreImageReader::E_ROFS)
			{
				iRofsHeader = new TRofsHeader;
				result = iReader->ReadCoreHeader(*iRofsHeader);
				if (result != KErrNone)
					return result;
				
				SaveDirInfo(*iRofsHeader);
				result = ProcessDirectory(0);
			}
			else if (iImageType == RCoreImageReader::E_ROFX)
			{
				iRofsExtnHeader = new TExtensionRofsHeader ;
				result = iReader->ReadExtensionHeader(*iRofsExtnHeader);
				if(result != KErrNone)
					return result;

				long filePos = iReader->FilePosition();
				iAdjustment = iRofsExtnHeader->iDirTreeOffset - filePos;

				SaveDirInfo(*iRofsExtnHeader);
				result = ProcessDirectory(iAdjustment);
			}
			else
			{
				result = KErrNotSupported;
			}
		}
		else
		{
			result = KErrGeneral;
		}
	}
	return result;
}
