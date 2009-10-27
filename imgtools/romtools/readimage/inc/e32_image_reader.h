/*
* Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
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


#ifndef __E32_IMAGE_READER__
#define __E32_IMAGE_READER__

#include "image_reader.h"

class E32ImageReader : public ImageReader
{
public:
	E32ImageReader();
	E32ImageReader(char* aFile);
	~E32ImageReader();

	void ReadImage();
	void ProcessImage();
	void Validate();
	void Dump();
	static void DumpE32Attributes(E32ImageFile& aE32Image);

	E32ImageFile	*iE32Image;
};

#endif //__E32_IMAGE_READER__

