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
*
*/


/**
 @file
 @internalComponent
 @released
*/

#include "typedefs.h"
#include <e32def.h>
#include "h_utl.h"
#include "r_obey.h"
#include "r_romnode.h"
#include <algorithm>

ECompression gCompress = ECompressionUnknown;
unsigned int  gCompressionMethod = 0;
TBool gPagingOverride = 0;
TInt gCodePagingOverride = -1;
TInt gDataPagingOverride = -1;
TInt gLogLevel = 0;

/** 
Function receives an UID type of an executable and identifies whether it is a
1. EXE or not,
2. DLL or not
3. Executable or not.

@internalComponent
@released

@param Uids1 - Uid1 of a E32 executable
@param aType - Type to be compared against aUids1. 
*/
bool ReaderUtil::IsExecutable(unsigned char* aUids1, int aType)
{
	//In the little-endian world
	if( aUids1[3] == 0x10 && aUids1[2] == 0x0 && aUids1[1] == 0x0 )
		{
			switch(aType)
			{
			case EExe:
				if(aUids1[0] == 0x7a)
				{
					return true;
				}
				break;
			case EDll:
				if(aUids1[0] == 0x79)
				{
					return true;
				}
				break;
			case EAll:
				if((aUids1[0] == 0x79) || (aUids1[0] == 0x7a))
				{
					return true;
				}
				break;
			}
		}
	return false;
}

/** 
Function receives an UID type of an executable and identifies whether it is a EXE or not.

@internalComponent
@released

@param aType - Type to be compared against aUids1.
*/
bool ReaderUtil::IsExe(unsigned long* aUids1)
{
	return IsExecutable((unsigned char*)aUids1, EExe);
}

/** 
Function receives an UID type of an executable and identifies whether it is a DLL or not,

@internalComponent
@released

@param aType - Type to be compared against aUids1.
*/
bool ReaderUtil::IsDll(unsigned long* aUids1)
{
	return IsExecutable((unsigned char*)aUids1, EDll);
}

/** 
Function responsible to convert lower case strings to upper case

@internalComponent
@released

@param aString - String which needs to be inserted
*/
const String&  ReaderUtil::ToLower(String& aString)
{
	unsigned int stringLength = aString.length();
	unsigned char stringChar;
	for(unsigned int stringIndex = 0; stringIndex < stringLength; stringIndex++)
	{
		stringChar = aString.at(stringIndex);
		if( stringChar >= KUpperCaseAsciiValOfCharA && stringChar <= KUpperCaseAsciiValOfCharZ )
		{
			stringChar += KUpperAndLowerAsciiDiff; //Upper case alphabets case changed to lower case
		}
		aString[stringIndex] = stringChar;
	}
	return aString;
}

/** 
Function responsible to convert integer to ASCII characters with respect to its base value.
Function takes the integer value with its base.
Calculates the first reminder by dividing the value with its base, put this value into result string .
Do the same until the value becomes zero.

Regular itoa() function from stdlib.h, definition is not available in linux.

@internalComponent
@released

@param aString - String which needs to be inserted
*/
const String ReaderUtil::IntToAscii(const int aValue, const int aBase)
{
	String result;
	// check that the base if valid, the valid range is between 2 and 16
	if (aBase < EBase2 || aBase > EBase16) 
	{ 
		return result; 
	}
	int quotient = aValue;
	do 
	{
	#ifdef __TOOLS__
		result += "0123456789abcdef"[abs(quotient % aBase)];
	#else
		result += "0123456789abcdef"[std::abs(quotient % aBase)];
	#endif
		quotient /= aBase;
	} while (quotient);
	
	// Only apply negative sign for base 10
	if (aValue < 0 && aBase == EBase10) 
	{
		result += '-';
	}
	std::reverse(result.begin(), result.end());
	return result;
}

/** 
Function responsible to convert string to integer.
Regular atoi() function from stdlib.h, definition is not available in linux.

@internalComponent
@released

@param aString - String which needs to be converted.
*/
Long64 ReaderUtil::DecStrToInt(String& aString)
{
	Long64 val = 0;
	std::string::iterator strBegIter = aString.begin();
	std::string::iterator strEndIter = aString.end();

	while(strBegIter != strEndIter)
	{
		val *= EBase10;
		val += *strBegIter - KAsciiValueOfZero;
		++strBegIter;
	}
	return val;
}

/**
Function to convert String to any numeric type.

@internalComponent
@released

@param aStringVal - the string which has to be converted.
@return - returns the coverted value.
*/
unsigned int ReaderUtil::HexStrToInt(String& aStringVal)
{
	IStringStream inputStrStream(aStringVal);
	unsigned int intVal = 0;
	inputStrStream >> std::hex >> intVal;
	return intVal;
}
