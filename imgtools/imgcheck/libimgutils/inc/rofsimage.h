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


#ifndef ROFSIMAGE_H
#define ROFSIMAGE_H

#include <e32std.h>
#include "rofs.h"
#include "r_obey.h"
#include "r_coreimage.h"

class RCoreImageReader;
class TRofsHeader;
class TExtensionRofsHeader;
class CCoreImage;

/**
class RofsImage, Extension of core image

@internalComponent
@released
*/
class RofsImage : public CCoreImage
{
public:
	RofsImage(RCoreImageReader *aReader);
	~RofsImage(void);
	int ProcessImage(void);

	TRofsHeader *iRofsHeader;
	TExtensionRofsHeader *iRofsExtnHeader;
	long iAdjustment;
	RCoreImageReader::TImageType iImageType;
};

#endif //ROFSIMAGE_H
