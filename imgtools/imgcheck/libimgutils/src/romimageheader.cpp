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
#include "romimageheader.h"
/** 
Constructor intializes the Rom image header.

@internalComponent
@released

@param aHdr - ROM laoder header
@param aImgType - Image type
*/
RomImageHeader::RomImageHeader(char* aHdr, EImageType aImgType , bool aNoRomLoaderHeader)
{
	switch(aImgType)
	{
	case ERomImage:
		if(!aNoRomLoaderHeader)
		{
		iLoaderHdr = (TRomLoaderHeader*)aHdr;
		iRomHdr = (TRomHeader*)(aHdr + sizeof(TRomLoaderHeader));
		}
		else
		{
			iRomHdr = (TRomHeader*)(aHdr);
		}
		iExtRomHdr = 0;
		break;

	case ERomExImage:
		iExtRomHdr = (TExtensionRomHeader*)(aHdr);
		iRomHdr = 0;
		iLoaderHdr = 0;
		break;
	default:
	 iLoaderHdr = 0 ;
	 iRomHdr = 0;
	 iExtRomHdr = 0 ; 
		break ;
	}
}
