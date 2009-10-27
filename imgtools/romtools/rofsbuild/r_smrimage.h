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


#ifndef __R_SMRIAMGE_H__
#define __R_SMRIAMGE_H__
#include "r_obey.h"

class CSmrImage
{
public:
	CSmrImage(CObeyFile* aObeyFile);
	~CSmrImage();
	TInt CreateImage();
	TBool SetImageName(const StringVector& aValues);
	TBool SetFormatVersion(const StringVector& aValues);
	TBool SetHcrData(const StringVector& aValues);
	TBool SetPayloadUID(const StringVector& aValues);
	TBool SetPayloadFlags(const StringVector& aValues);
	TInt Initialise();
	String GetImageName(){ return iImageName; };
private:
	CObeyFile* iObeyFile;
	SSmrRomHeader iSmrRomHeader;
	String iImageName;
	String iHcrData;
private:
	TUint32 StrToInt(const char* aStr);

};

#endif
