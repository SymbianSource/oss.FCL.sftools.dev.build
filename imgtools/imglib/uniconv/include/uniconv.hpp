/*
* Copyright (c) 1995-2009 Nokia Corporation and/or its subsidiary(-ies).
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


#ifndef BU_ROMTOOLS_IMGLIB_UNICONV_HPP_
#define BU_ROMTOOLS_IMGLIB_UNICONV_HPP_


/**
 * @class UniConv
 * @brief a helper class used to convert text stream from one encoding into another.
 */
class UniConv
{
public:
	static int DefaultCodePage2UTF8(const char* DCPStringRef, unsigned int DCPLength, char** UTF8StringRef, unsigned int* UTFLength) throw ();

	static int UTF82DefaultCodePage(const char* UTF8StringRef, unsigned int UTFLength, char** DCPStringRef, unsigned int* DCPLength) throw ();

	static bool IsPureASCIITextStream(const char* StringRef) throw ();
protected:
private:
	UniConv(void);

	UniConv(const UniConv&);

	UniConv& operator = (const UniConv&);
};


#endif  /* defined BU_ROMTOOLS_IMGLIB_UNICONV_HPP_ */
