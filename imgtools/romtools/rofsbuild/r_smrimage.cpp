/*
* Copyright (c) 1996-2009 Nokia Corporation and/or its subsidiary(-ies).
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


#include <stdlib.h>
#include <string.h>
#include <time.h>
 
#include <strstream>
#include <iomanip> 
 
#include <e32std.h>
#include "h_utl.h"
#include "r_smrimage.h"
using namespace std; 
CSmrImage::CSmrImage(CObeyFile* aObeyFile)
	:iObeyFile(aObeyFile)
{	
	HMem::Set(&iSmrRomHeader, 0, sizeof(SSmrRomHeader));
}
CSmrImage::~CSmrImage()
{
}
TBool CSmrImage::SetImageName(const StringVector& aValues)
{
	if(aValues.size() == 0)
	{
		Print(EError, "Keyword Imageanme has not been set!");
		return EFalse;

	}
	if(aValues.size() > 1)
	{
		Print(EError, "Keyword Imagename has been set more than one time!");
		return EFalse;
	}
	iImageName = aValues.at(0);
	if(iImageName.find(".img") == string::npos)
	{
		iImageName += ".img";
	}
	return ETrue;
}
TBool CSmrImage::SetFormatVersion(const StringVector& aValues)
{
	if(aValues.size() == 0)
	{
		Print(EError, "keyword formatversion has not been set!");
		return EFalse;
	}
	if(aValues.size() > 1)
	{
		Print(EError, "Keyword Formatversion has been set more than one time!");
		return EFalse;
	}
	Val(iSmrRomHeader.iImageVersion,aValues.at(0).c_str()); 
	return ETrue;
}
TBool CSmrImage::SetSmrData(const StringVector& aValues)
{
	
	if(aValues.size() == 0)
	{
		Print(EError, "keyword smrdata has not been set!");
		return EFalse;
	}
	if(aValues.size() > 1)
	{
		Print(EError, "Keyword smrdata has been set more than one time!");
		return EFalse;
	}
	iSmrData = aValues.at(0);

	ifstream is(iSmrData.c_str(), ios_base::binary );
	if(!is)
	{
		Print(EError, "SMR data file: %s dose not exist!", iSmrData.c_str());
		return EFalse;
	}
	is.close();
	return ETrue;
}
TBool CSmrImage::SetPayloadUID(const StringVector& aValues)
{

	if(aValues.size() == 0)
	{
		Print(EError, "keyword PayloadUID has not been set!");
		return EFalse;
	}
	if(aValues.size() > 1)
	{
		Print(EError, "Keyword PayloadUID has been set more than one time!");
		return EFalse;
	}
	Val(iSmrRomHeader.iPayloadUID,aValues.at(0).c_str()); 
	return ETrue;
}
TBool CSmrImage::SetPayloadFlags(const StringVector& aValues)
{

	if(aValues.size() == 0)
	{
		Print(EError, "keyword Payloadflags has not been set!");
		return EFalse;
	}
	if(aValues.size() > 1)
	{
		Print(EError, "Keyword Payloadfalgs has been set more than one time!");
		return EFalse;
	}
	Val(iSmrRomHeader.iPayloadFlags , aValues.at(0).c_str());
	return ETrue;
}

TInt CSmrImage::Initialise()
{
	TInt result = KErrGeneral;
	if(! SetImageName(iObeyFile->getValues("imagename")))
		return result;
	if(! SetFormatVersion(iObeyFile->getValues("formatversion")))
		return result;
	if(! SetSmrData(iObeyFile->getValues("smrdata")))
		return result;
	if(! SetPayloadUID(iObeyFile->getValues("payloaduid")))
		return result;
	if(! SetPayloadFlags(iObeyFile->getValues("payloadflags")))
		return result;
	result = KErrNone;
	return result;
}
TInt CSmrImage::CreateImage()
{
	TInt imageSize = 0;
	ifstream is;
	is.open(iSmrData.c_str(), ios_base::binary);
	if(!is)
	{
		Print(EError, "Open SMR data file: %s error!\n", iSmrData.c_str());
		return KErrGeneral;
	}
	is.seekg(0, ios_base::end);
	TInt fsize = is.tellg();
	imageSize = sizeof(SSmrRomHeader) + fsize;
	imageSize += (4 - imageSize) & 3;
	char* vImage = new (nothrow) char[imageSize];
	if(vImage == NULL)
	{
		Print(EError, "Not enough system memory generate SMR partition!\n");
		return KErrNoMemory;
	}
	HMem::Set(vImage, 0, imageSize);
	HMem::Copy(vImage, &iSmrRomHeader, sizeof(SSmrRomHeader));
	SSmrRomHeader* pSmrHeader = (SSmrRomHeader *) vImage;
	pSmrHeader->iFingerPrint[0] = 0x5F524D53;
	pSmrHeader->iFingerPrint[1] = 0x54524150;
	is.seekg(0, ios_base::beg);
	is.read(vImage + sizeof(SSmrRomHeader), fsize);
	pSmrHeader->iPayloadChecksum = HMem::CheckSum((TUint *)(vImage + sizeof(SSmrRomHeader)), imageSize - sizeof(SSmrRomHeader));
	pSmrHeader->iImageSize = imageSize;
	pSmrHeader->iImageTimestamp = time(0);
	ofstream os(iImageName.c_str(), ios_base::binary);
	os.write(vImage, imageSize);
	os.close();
	is.close();
	delete[] vImage;	
	
	return KErrNone;


}
