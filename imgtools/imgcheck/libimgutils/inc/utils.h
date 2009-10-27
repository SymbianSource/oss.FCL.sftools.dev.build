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


#ifndef UTILS_H
#define UTILS_H

/**
Macro to check and delete the pointer.

@internalComponent
@released
*/
#define DELETE(aPtr) if(aPtr != NULL) delete aPtr; aPtr = 0;

typedef std::string String;

/**
To support large integer values, 64 bit integers are used.
"__int64" is for MSVC compiler and "long long int" is for GCC compilers

@internalComponent
@released
*/

#ifdef _MSC_VER
	typedef __int64 Long64;
#else
	typedef long long int Long64;
#endif

/**
Constants for Ascii values

@internalComponent
@released
*/
const int KUpperCaseAsciiValOfCharA = 65;
const int KUpperCaseAsciiValOfCharZ = 90;
const int KUpperAndLowerAsciiDiff = 32;
const int KAsciiValueOfZero = 48;

/**
Enum for different base

@internalComponent
@released
*/
enum
{
	EBase2 = 2,
	EBase10 = 10,
	EBase16 = 16
};

/**
Enums for different executable type

@internalComponent
@released
*/
enum
{
	EAll = 0,
	EExe = 1,
	EDll = 2
};

/**
class ReaderUtil

@internalComponent
@released
*/
class ReaderUtil
{
public:
	static bool IsExecutable(unsigned char* aUids1, int aType = EAll);
	static bool IsExe(unsigned long* Uids1);
	static bool IsDll(unsigned long* Uids1);
	static const String& ToLower(String& aString);
	static const String IntToAscii(const int aValue, const int aBase);
	static Long64 DecStrToInt(String& aString);
	static unsigned int HexStrToInt(String& aStringVal);
};
#endif //UTILS_H
