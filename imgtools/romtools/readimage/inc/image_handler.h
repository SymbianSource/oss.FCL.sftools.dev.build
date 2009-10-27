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


#ifndef __IMAGE_HANDLER_H__
#define __IMAGE_HANDLER_H__

#include "image_reader.h"
#include "sisutils.h"


const unsigned int KRomBase = 0x80000000;
const unsigned int KRomBaseMaxLimit = 0x82000000;



class ImageHandler
{
public:
	ImageHandler();
	~ImageHandler();

	void		ProcessArgs(int argc, char**argv);

	void		HandleInputFiles();
	EImageType	ReadMagicWord();
    EImageType  ReadBareImage(ifstream& aIfs);
	void		PrintUsage();
	void		PrintVersion();
	void		SetInputFile(char* aFile) { iInputFileName = aFile;}

private:
	ImageReader *iReader;
	string		iInputFileName;
	string		iOutFile;
	TUint		iOptions;

	SisUtils	*iSisUtils;
};

#endif //__IMAGE_HANDLER_H__
