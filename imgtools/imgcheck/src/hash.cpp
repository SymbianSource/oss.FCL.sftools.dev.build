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
* Hash class for imgcheck tool. All the executable names of ROM/ROFS 
* are stored into this hash table. After gathering the dependencies
* for those executables, dependencies existence is checked very 
* efficiently using this table.
*
*/


/**
 @file
 @internalComponent
 @released
*/

#include "common.h"
#include "hash.h"

/** 
Constructor, intializes the table size

@internalComponent
@released

@param aSize - Hash table size (Number of dissimilar data can stored)
*/
HashTable::HashTable(int aSize)
:iSize(aSize)
{
}

/** 
Destructor

@internalComponent
@released
*/
HashTable::~HashTable()
{
}

/** 
Function responsible to return the Hash value for the received string.

@internalComponent
@released

@param aString - String on which Hash value calcualtion to be done
*/
int HashTable::Hash(String aString)
{
	unsigned int hashVal = 0;
	int length = aString.length();
	/* we start our hash out at 0 */

	/* for each character, we multiply the old hash by 31 and add the current
	 * character.  Remember that shifting a number left is equivalent to 
	 * multiplying it by 2 raised to the number of places shifted.  So we 
	 * are in effect multiplying hashval by 32 and then subtracting hashval.  
	 * Why do we do this?  Because shifting and subtraction are much more 
	 * efficient operations than multiplication.
	 */
	for(int strIter = 0; strIter < length ; strIter++)
	{
		hashVal = aString[strIter] + (hashVal << 5) - hashVal;
	}
	/* we then return the hash value mod the hashtable size so that it will
	 * fit into the necessary range
	 */
	return hashVal % iSize;

}

/** 
Function returns ture or false based on the String availability in Hash

@internalComponent
@released

@param aString - String which needs to be searched
*/
bool HashTable::IsAvailable(String aString)
{
	unsigned int hashVal = Hash(aString);
	if (iTable[hashVal].size() > 0)
	{
		StringList nameList = iTable[hashVal];
		StringList::iterator listIter = nameList.begin();
		while(listIter != nameList.end())
		{
			if ((*listIter) == aString)
			{
				return true;
			}
			++listIter;
		}
	}
	return false;
}

/** 
Function responsible to insert a single string into Hash table

@internalComponent
@released

@param aString - String which needs to be inserted
*/
void HashTable::Insert(String aString)
{
	unsigned int hashVal = Hash(aString);
	if(!IsAvailable(aString)) //Is exists
	{
		iTable[hashVal].push_back(aString);
	}
}

/** 
Function responsible to insert list of strings into Hash table

@internalComponent
@released

@param aString - String which needs to be inserted
*/
void HashTable::InsertStringList(StringList& aList)
{
	StringList::iterator beginIter = aList.begin();
	StringList::iterator endIter = aList.end();
	while(beginIter != endIter)
	{
		Insert((*beginIter));
		++beginIter;
	}
}

/** 
Function to delete an entry from Hash

@internalComponent
@released

@param aString - String which needs to be deleted
*/
void HashTable::Delete(String aString)
{
	unsigned int hashVal = Hash(aString);
	if(iTable[hashVal].size() > 0)
	{
		StringList list = iTable[hashVal];
		StringList::iterator beginIter = list.begin();
		StringList::iterator endIter = list.end();
		while(beginIter != endIter)
		{
			if((*beginIter) == aString)
			{
				list.erase(beginIter);
				iTable[hashVal] = list;
				return;
			}
			++beginIter;
		}
	}
}
