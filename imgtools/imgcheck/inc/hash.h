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
* class Hash Table declaration
* @internalComponent
* @released
*
*/


#ifndef HASH_H
#define HASH_H

#pragma warning(disable: 4786) // identifier was truncated to '255' characters in the debug information

#include<iostream>
#include<list>
#include<map>
#include<string>

typedef std::list<std::string> StringList;
typedef std::map<unsigned int,StringList> Table;
typedef std::string String;

/** 
class Hash Table

@internalComponent
@released
*/
class HashTable 
{
public:
	HashTable(int aSize);
	~HashTable(void);
	int Hash(String aString);
	bool IsAvailable(String aString);
	void Insert(String aString);
	void InsertStringList(StringList& aList);
	void Delete(String aString);

private:
	int iSize;       /* the size of the table */
	Table iTable;
};
#endif //HASH_H
