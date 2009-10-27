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


#ifndef ROMIMAGEHEADER_H
#define ROMIMAGEHEADER_H

#include "typedefs.h"
#include "e32std.h"
#include "e32def.h"

class TRomLoaderHeader;
class TRomHeader;
class TExtensionRomHeader;

const unsigned int KRomWrapperSize = 0x100;
const unsigned int KRomNameSize = 16;

/**
Class for ROM Loader

@internalComponent
@released
*/
class TRomLoad
{
public:
	unsigned short int name[KRomNameSize];
	unsigned short int versionStr[4];
	unsigned short int buildNumStr[4];
	unsigned int romSize;
	unsigned int wrapSize;
};

const TUint KFillSize = KRomWrapperSize - sizeof(TRomLoad);

class CObeyFile;

/**
Class for ROM Loader header

@internalComponent
@released
*/
class TRomLoaderHeader
{
public:
	void SetUp(CObeyFile *aObey);
private:
	TRomLoad iLoad;
	unsigned char filler[KFillSize];
};

/**
Class for ROM image header

@internalComponent
@released
*/
class RomImageHeader
{
public:
	RomImageHeader(char* aHdr, EImageType aImgType = ERomImage, bool aNoRomLoaderHeader = false );
	TRomLoaderHeader	*iLoaderHdr;
	TRomHeader			*iRomHdr;
	TExtensionRomHeader	*iExtRomHdr;
};

#endif //ROMIMAGEHEADER_H
