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
 

#include<iostream>
#include<list>
#include<map>
#include<string>
using namespace std;


typedef multimap<unsigned int,string > Table;
 
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
	int Hash(const string& aString);
	bool IsAvailable(const string& aString);
	void Insert(const string& aString);
	void InsertStringList(const StringList& aList);
	void Delete(const string& aString);

private:
	int iSize;       /* the size of the table */
	Table iTable;
};
#endif //HASH_H
