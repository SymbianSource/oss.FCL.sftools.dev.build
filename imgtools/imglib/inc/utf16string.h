/*
* Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
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
* @internalComponent * @released
*
*/

#ifndef __UTF16_STRING_H__
#define __UTF16_STRING_H__
#include <e32std.h> 
#include <string>
#include <fstream>
using namespace std ;

class UTF16String {
public :
	
	UTF16String();
	UTF16String(const UTF16String& aRight);
	UTF16String(const string& aUtf8Str);
	UTF16String(const TUint16* aUtf16Str,TInt aLength = -1);
	UTF16String(const char* aUtf8Str,TInt aLength = -1);	
	~UTF16String();	
	
	bool FromFile(const char* aFileName);
	bool ToUTF8(string& aResult) const ;	
	bool Assign(const char* aUtf8Str,TInt aLength = -1);	
	inline TUint length() const { return iLength ;} 
	inline TUint bytes() const { return (iLength << 1) ;} 
	const TUint16* c_str() const ;
	inline bool IsEmpty() const { return  (0 == iLength) ;}	
	UTF16String& operator = (const UTF16String& aRight);
	int Compare(const TUint16* aUtf16Str) const ;
	int CompareNoCase(const TUint16* aUtf16Str) const ;
	TUint16* Alloc(size_t aNewLen);
	
protected:
	TUint16* iData ;
	TUint iLength ;	
};
#endif
