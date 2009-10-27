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

#ifdef __VC32__
 #ifdef __MSVCDOTNET__
  #include <strstream>
  #include <iomanip>
 #else //__MSVCDOTNET__
  #include <strstrea.h>
  #include <iomanip.h>
 #endif  //__MSVCDOTNET__
#else // !__VC32__
#ifdef __TOOLS2__
	#include <sstream>
	#include <iomanip>
	#include <sys/stat.h>
	#include <new>
	using namespace std;
#else
	#include <strstrea.h>
	#include <iomanip.h>
#endif
 
#endif //__VC32__
#include <e32std.h>
#include "h_utl.h"
#include "r_smrimage.h"

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
	if(iImageName.find(".img") == std::string::npos)
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
	iSmrRomHeader.iImageVersion = StrToInt(aValues.at(0).c_str());
	return ETrue;
}
TBool CSmrImage::SetHcrData(const StringVector& aValues)
{
	
	if(aValues.size() == 0)
	{
		Print(EError, "keyword hcrdata has not been set!");
		return EFalse;
	}
	if(aValues.size() > 1)
	{
		Print(EError, "Keyword hcrdata has been set more than one time!");
		return EFalse;
	}
	iHcrData = aValues.at(0);
#if defined(__MSVCDOTNET__) || defined(__TOOLS2__)
	ifstream is(iHcrData.c_str(), ios_base::binary );
#else //!__MSVCDOTNET__
	ifstream is(iHcrData.c_str(), ios::nocreate | ios::binary ); 
#endif //__MSVCDOTNET__
	if(!is)
	{
		Print(EError, "HCR data file: %s dose not exist!", iHcrData.c_str());
		return EFalse;
	}
	TUint32 magicWord = 0;
	is.read(reinterpret_cast<char*>(&magicWord),sizeof(TUint32));
	if(0x66524348 != magicWord){
		Print(EError, "HCR data file: %s is an invalid HCR data file!", iHcrData.c_str());
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
	iSmrRomHeader.iPayloadUID = StrToInt(aValues.at(0).c_str());
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
	iSmrRomHeader.iPayloadFlags = StrToInt(aValues.at(0).c_str());
	return ETrue;
}
TUint32 CSmrImage::StrToInt(const char* aStr)
{

	TUint32 value;
#ifdef __TOOLS2__
	istringstream val(aStr);
#else
	istrstream val(aStr, strlen(aStr));
#endif
#if defined(__MSVCDOTNET__) || defined(__TOOLS2__)
	val >> setbase(0);
#endif //__MSVCDOTNET
	val >> value;
	return value;
}
TInt CSmrImage::Initialise()
{
	TInt result = KErrGeneral;
	if(! SetImageName(iObeyFile->getValues("imagename")))
		return result;
	if(! SetFormatVersion(iObeyFile->getValues("formatversion")))
		return result;
	if(! SetHcrData(iObeyFile->getValues("hcrdata")))
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
	is.open(iHcrData.c_str(), ios::binary);
	if(!is)
	{
		Print(EError, "Open HCR data file: %s error!\n", iHcrData.c_str());
		return KErrGeneral;
	}
	is.seekg(0, ios::end);
	TInt fsize = is.tellg();
	imageSize = sizeof(SSmrRomHeader) + fsize;
	imageSize += (4 - imageSize) & 3;
	char* vImage = new (std::nothrow) char[imageSize];
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
	is.seekg(0, ios::beg);
	is.read(vImage + sizeof(SSmrRomHeader), fsize);
	pSmrHeader->iPayloadChecksum = HMem::CheckSum((TUint *)(vImage + sizeof(SSmrRomHeader)), imageSize - sizeof(SSmrRomHeader));
	pSmrHeader->iImageSize = imageSize;
	pSmrHeader->iImageTimestamp = time(0);
	ofstream os(iImageName.c_str(), ios::binary);
	os.write(vImage, imageSize);
	os.close();
	is.close();
	delete[] vImage;
	
	
	return KErrNone;


}
