/*
* Copyright (c) 1997-2009 Nokia Corporation and/or its subsidiary(-ies).
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


#if !defined(__ARRAY_H__)
#define __ARRAY_H__

// ArrayItem

class ArrayItem
	{
public:
	virtual ~ArrayItem() {}
	};

// Array

class ArrayIterator;
class Array
	{
	friend class ArrayIterator;
public:
	void Empty();		// Empty store without calling delete on individual elements.
	void DeleteAll();	// Delete elements in store and then empty it out.
	int Size() const;
protected:
	Array();
	Array(const Array&);
	virtual ~Array();
	ArrayItem*& operator[](int aIndex) const;
	Array& operator=(const Array&);
	void Add(ArrayItem* aNewItem);
	void Add(int aIndex, ArrayItem* pNewItem);
	void Discard(ArrayItem* pItemToRemove);
	void Discard(int aIndex);
private:
	ArrayItem** iData;
	int iItemCount;
	int iItemAllocCount;
	};

// ArrayIterator

class ArrayIterator
	{
public:
	void Reset();
protected:
	ArrayIterator(const Array& c);
	ArrayItem * operator()();
private:
	const Array* iArray;
	int iCurrentIndex;
	};

#endif
