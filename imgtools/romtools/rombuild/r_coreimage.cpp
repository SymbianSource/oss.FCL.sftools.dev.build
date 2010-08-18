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
*
*/


#include <e32def.h>
#include <e32def_private.h>
#include <e32rom.h>

#include "h_utl.h"
#include "r_rom.h"

#include "r_coreimage.h"

// CoreRomImage
//
CoreRomImage::CoreRomImage(const char* aFileName) : 
iReader(0),
iFileName(aFileName),
iRomHdr(0),
iRootDirectory(0),
iNumVariants(0),
iVariants(0),
iRomAlign(0),
iDataRunAddress(0) 
{	 
}

CoreRomImage::~CoreRomImage()
{
	if(iReader)
		delete iReader;

	if(iVariants)
		delete[] iVariants;
}

TBool CoreRomImage::ProcessImage(const TBool aUseMemMap)
{
	TBool Status = EFalse;
	TRomRootDirectoryList *rootDirInfo = 0;
	TInt dirCount = 0;

	iReader = new CoreRomImageReader(iFileName.c_str(), aUseMemMap);

	if(!iReader)
	{
		return EFalse;
	}

	if(iReader->OpenImage())
	{
		Status = iReader->ProcessImage();
	}

	if(Status)
	{
		// CoreRomHeader Info
		iRomHdr = iReader->GetCoreRomHeader();

		if(iRomHdr)
		{
			// Root Directory Info
			rootDirInfo = iReader->GetRootDirList();
			dirCount = rootDirInfo->iNumRootDirs;
			if(dirCount)
			{
				iNumVariants = dirCount;
				iVariants = new THardwareVariant[dirCount];

				if(iVariants)
				{
					while(dirCount--)
					{
						iVariants[dirCount] = rootDirInfo->iRootDir[dirCount].iHardwareVariant;
					}
				}

				// RootDirectory Info
				iRootDirectory = iReader->GetRootDirectory();
			}
			else
			{
				Status = EFalse;
			}
		}
		else
		{
			Status = EFalse;
		}
	}

	return Status;
}

TRomNode* CoreRomImage::CopyDirectory(TRomNode*& aSourceDirectory) {
	return iRootDirectory->CopyDirectory(aSourceDirectory,0); 
}

TUint32 CoreRomImage::RomBase() const {
	return (iRomHdr->iRomBase);
}

TUint32 CoreRomImage::RomSize() const {
	return (iRomHdr->iRomSize);
}

TVersion CoreRomImage::Version() const {
	return (iRomHdr->iVersion);
}

TInt64 CoreRomImage::Time() const {
	return (iRomHdr->iTime);
}

TUint32 CoreRomImage::CheckSum() const {
	return (iRomHdr->iCheckSum);
}

TUint32 CoreRomImage::CompressionType() const {
	return (iRomHdr->iCompressionType);
}

TRomNode* CoreRomImage::RootDirectory() const {
	return iRootDirectory; 
}

const char* CoreRomImage::RomFileName() const {
	return iFileName.data();
}

TUint32 CoreRomImage::RomAlign() const {
	return iRomAlign;
}

TUint32 CoreRomImage::DataRunAddress() const {
	return iDataRunAddress;
}

TInt32 CoreRomImage::VariantCount() const {
	return iNumVariants; 
}

THardwareVariant* CoreRomImage::VariantList() const {
	return iVariants;
}

void CoreRomImage::SetRomAlign(const TUint32 aAlign)  {
	iRomAlign = aAlign;
}

void CoreRomImage::SetDataRunAddress(const TUint32 aRunAddress)
{
	iDataRunAddress = aRunAddress;
}

void CoreRomImage::DisplayNodes()
{ 
	iReader->Display(iRootDirectory);
	return;
}

