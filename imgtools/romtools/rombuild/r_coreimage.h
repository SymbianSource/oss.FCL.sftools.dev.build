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


#ifndef __R_COREIMAGE_H__
#define __R_COREIMAGE_H__

#include <string>

typedef std::string String;
typedef std::ifstream Ifstream;

#include "r_mromimage.h"
#include "r_coreimagereader.h"

class THardwareVariant;


/** 
class CoreRomImage

@internalComponent
@released
*/
class CoreRomImage : public MRomImage
{
private:
	CoreRomImageReader* iReader;
	String iFileName;

	TRomHeader *iRomHdr;
	// Directory Structure
	TRomNode* iRootDirectory;

	TInt32 iNumVariants;
	THardwareVariant *iVariants;

	TUint32 iRomAlign;
	TUint32 iDataRunAddress;

public:
	CoreRomImage(char* aFileName);
	~CoreRomImage();

	TBool ProcessImage(TBool aUseMemMap = EFalse);
	TRomNode* CopyDirectory(TRomNode*& aSourceDirectory);

	TRomNode* RootDirectory();
	TText* RomFileName();
	TUint32 RomBase();
	TUint32 RomSize();
	TVersion Version();
	TInt64 Time();
	TUint32 CheckSum();
	TUint32 RomAlign();
	TUint32 DataRunAddress();
	TUint32 CompressionType();
	TInt32 VariantCount();
	THardwareVariant* VariantList();
	void SetRomAlign(const TUint32 aAlign);
	void SetDataRunAddress(const TUint32 aRunAddress);

	void DisplayNodes();
};

#endif //__R_COREIMAGE_H__
