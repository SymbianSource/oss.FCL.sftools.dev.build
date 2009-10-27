/*
* Copyright (c) 2008-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* Generally used functions written here
*
*/


/**
 @file
 @internalComponent
 @released
*/

#include "common.h"
#include <sstream>

/** 
Function to convert Integer to string

@internalComponent
@released

@param aValue - The value needs to be converted

@return - return the converted string
*/
String Common::IntToString(unsigned int aValue)
{
    OStringStream outStrStream;
    outStrStream << aValue;
    return outStrStream.str();
}

/** 
Function to convert string to integer

@internalComponent
@released

@param aValue - The string needs to be converted

@return - return the converted value
*/
unsigned int Common::StringToInt(String& aStringVal)
{
    std::istringstream iss(aStringVal);
    unsigned int intVal;
    iss >> std::dec >> intVal;
    return intVal;
}
