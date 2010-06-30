/*
* Copyright (c) 1995-2009 Nokia Corporation and/or its subsidiary(-ies).
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

#include <new>
#include <queue>
#include <stdio.h>
#include <stdlib.h>
#include <cstring>
#include <string>

#include <thread/condition_variable.hpp>

#include "cache/cacheexception.hpp"
#include "cache/cacheentry.hpp"
#include "cache/cacheablelist.hpp"


CacheableList* CacheableList::Only = (CacheableList*)0;


CacheableList* CacheableList::GetInstance(void) throw (CacheException)
{
	if(! CacheableList::Only)
	{
		CacheableList::Only = new (std::nothrow) CacheableList();
		if(! CacheableList::Only)
			throw CacheException(CacheException::RESOURCE_ALLOCATION_FAILURE);
	}

	return CacheableList::Only;
}


void CacheableList::AddCacheable(CacheEntry* EntryRef)
{
	if(1)
	{
		boost::mutex::scoped_lock lock(this->queuemutex);
		this->filelist.push(EntryRef);
	}

	this->queuecond.notify_all();

	return;
}


CacheEntry* CacheableList::GetCacheable(void)
{
	boost::mutex::scoped_lock lock(this->queuemutex);
	while(this->filelist.empty())
		this->queuecond.wait(lock);

	CacheEntry* resref = this->filelist.front();
	this->filelist.pop();

	return resref;
}


CacheableList::~CacheableList(void)
{
	return;
}


CacheableList::CacheableList(void)
{
	return;
}
