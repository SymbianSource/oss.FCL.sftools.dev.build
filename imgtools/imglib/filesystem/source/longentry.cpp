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
* This class provides the basic set and get operations associated 
* with longentry attributes.
* @internalComponent
* @released
*
*/


#include "longentry.h"

/**
Constructor responsible to initialze the possible attributes of 
long entry

@internalComponent
@released

@param aChckSum - Short entry checksum value
*/

CLongEntry::CLongEntry(	char aChckSum):
						iDirOrder(0),
						iAttribute(EAttrLongName),
						iDirType(KDirSubComponent),
						iCheckSum(aChckSum),
						iFirstClusterNumberLow(0)						
{
}

/**
Destructor:

@internalComponent
@released

*/
CLongEntry::~CLongEntry()
{
}

/**
Function responsible to return Directory entry Order

@internalComponent
@released

@return iDirOrder - Long name sub entry order
*/
char CLongEntry::GetDirOrder() const
{
	return iDirOrder;
}

/**
Function responsible to initialize Directory entry Order

@internalComponent
@released

@param aDirOrder - Long name sub entry order
*/
void CLongEntry::SetDirOrder(char aDirOrder)
{
	iDirOrder = aDirOrder;
}

/**
Function responsible to return SubName1

@internalComponent
@released

@return iSubName1 - returns sub name 1 of a long entry
*/
String& CLongEntry::GetSubName1()
{
	return iSubName1;
}

/**
Function responsible to set SubName3

@internalComponent
@released

@param aSubName1 - a long entry sub name 1
*/
void CLongEntry::SetSubName1(String aSubName1)
{
	iSubName1 = aSubName1;
}

/**
Function responsible to return SubName2

@internalComponent
@released

@return iSubName2 - returns sub name 2 of a long entry
*/
String& CLongEntry::GetSubName2()
{
	return iSubName2;
}

/**
Function responsible to set SubName2

@internalComponent
@released

@param aSubName2 - a long entry sub name 2
*/
void CLongEntry::SetSubName2(String aSubName2)
{
	iSubName2 = aSubName2;
}

/**
Function responsible to return SubName3

@internalComponent
@released

@return iSubName3 - returns sub name 3 of a long entry
*/
String& CLongEntry::GetSubName3()
{
	return iSubName3;
}

/**
Function responsible to set SubName3

@internalComponent
@released

@param aSubName3 - a long entry sub name 3
*/
void CLongEntry::SetSubName3(String aSubName3)
{
	iSubName3 = aSubName3;
}

/**
Function responsible to return attribute

@internalComponent
@released

@return iAttribute - returns a long entry attribute
*/
char CLongEntry::GetAttribute() const
{
	return iAttribute;
}

/**
Function responsible to return check sum

@internalComponent
@released

@return iCheckSum - returns long entry check sum
*/
char CLongEntry::GetCheckSum() const
{
	return iCheckSum;
}

/**
Function responsible to return Dir Type

@internalComponent
@released

@return iDirType - returns long entry dir type
*/
char CLongEntry::GetDirType() const
{
	return iDirType;
}

/**
Function responsible to return Low cluster number

@internalComponent
@released

@return iFirstClusterNumberLow - returns Low cluster number
*/
unsigned short int CLongEntry::GetClusterNumberLow() const
{
	return iFirstClusterNumberLow;
}
