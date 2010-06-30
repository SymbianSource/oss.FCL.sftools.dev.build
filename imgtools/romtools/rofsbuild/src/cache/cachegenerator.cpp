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
#include <iostream>
#include <fstream>
#include <filesystem.hpp>
#include <thread/thread.hpp>
#include <thread/condition_variable.hpp>

#include "cache/cacheexception.hpp"
#include "cache/cacheentry.hpp"
#include "cache/cacheablelist.hpp"
#include "cache/cachegenerator.hpp"

using namespace std ;
CacheGenerator* CacheGenerator::Only = (CacheGenerator*)0;


CacheGenerator* CacheGenerator::GetInstance(void) throw (CacheException)
{
	if(! CacheGenerator::Only)
	{
		CacheGenerator::Only = new (nothrow) CacheGenerator();
		if(! CacheGenerator::Only)
			throw CacheException(CacheException::RESOURCE_ALLOCATION_FAILURE);
	}

	return CacheGenerator::Only;
}


void CacheGenerator::ProcessFiles(void) throw (CacheException)
{
	while(1)
	{
		//pick one entry from the CacheableList.
		CacheEntry* entryref = CacheableList::GetInstance()->GetCacheable();
		if(! entryref->GetCachedFileBuffer())
			break;

		//write cacheable content into the cache.
		boost::filesystem::path filepath(entryref->GetCachedFilename());
		string filename = filepath.file_string(); 	
		ofstream fileref(filename.c_str(), ios_base::binary | ios_base::out | ios_base::trunc);
		if(! fileref.is_open())
		{
			printf("Cannot write/update cached %s\r\n", filepath.file_string().c_str());
			continue;
		}

		fileref.write(entryref->GetCachedFileBuffer(), entryref->GetCachedFileBufferLen());
		fileref.close();
	}

	return;
}


CacheGenerator::CacheGenerator(void) :  boost::thread(ProcessFiles)
{
	return;
}
