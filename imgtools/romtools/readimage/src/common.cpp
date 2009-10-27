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


#include "common.h"
 
ImageReaderException::ImageReaderException(const char* aFile, const char* aErrMessage) : \
	iImgFileName(aFile), iErrMessage(aErrMessage)
{
}

void ImageReaderException::Report()
{
	*out << "Error : " << iImgFileName.c_str() << " : " << iErrMessage.c_str() << endl;
}

ImageReaderUsageException::ImageReaderUsageException(const char* /* aOption */,const char* aErrMessage) : \
	ImageReaderException("", aErrMessage)
{
}

void ImageReaderUsageException::Report()
{
	*out << "Usage Error:" << iErrMessage.c_str() << endl;
}

ostream& DumpInHex(char* aDesc, TUint32 aData, bool aContinue, TUint aDataWidth, \
				   char aFiller, TUint aMaxDescWidth)
{
	TUint aDescLen = strlen(aDesc);
	
	*out << aDesc;
	if( !aContinue )
	{
		while( aDescLen < aMaxDescWidth ){
			*out << ".";
			aDescLen++;
		}
	}
	out->width(aDataWidth);
	out->fill(aFiller);
	
	*out << hex << aData;

	return *out;
}

bool ReaderUtil::IsExecutable(TUint8* Uids1)
{
	//In the little-endian world
	if( Uids1[3] == 0x10 && Uids1[2] == 0x0 && Uids1[1] == 0x0 )
	{
		if(Uids1[0] == 0x79 || Uids1[0] == 0x7a)
			return true;
	}
	return false;
}

