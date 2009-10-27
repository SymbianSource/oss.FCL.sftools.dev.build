/*
* Copyright (c) 2006-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* UTILSH
* Contains common utilitied required for filesystem component.
* @internalComponent
* @released
*
*/


#ifndef UTILS_H
#define UTILS_H

#include <string>

/* While generating FAT32 image, user may specify the larger partition size (say 128GB),
 * Hence to support large integer values 64 bit integers are used.
 * "__int64" is for MSVC compiler and "long long int" is for GCC compilers
 */
#ifdef _MSC_VER
	typedef __int64 Long64;
#else
	typedef long long int Long64;
#endif

typedef std::string String;

/**
Function responsible to convert given string into upper case.
Note: In FAT iamge regular entry names are need to be mentioned in Upper case.

@internalComponent
@released

@param aString - input string 
@return returns the string, were string alphabets are changed to uppercase
*/
inline String& ToUpper(String& aString)
{
	unsigned int stringLength = aString.length();
	for(unsigned int stringIndex = 0; stringIndex < stringLength; stringIndex++)
	{
		unsigned char stringChar = aString.at(stringIndex);
		//Lower case alphabets ASCII value used here, 97 is for 'a' 122 is for 'z'
		if( stringChar >= 97 && stringChar <= 122 )
		{
			stringChar -= 32; //Lower case alphabets case changed to upper case
		}
		aString[stringIndex] = stringChar;
	}
	return aString;
}

#endif //UTILS_H
