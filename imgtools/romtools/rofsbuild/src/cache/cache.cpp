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
#include <cstring>
#include <string>
#include <iostream>
#include <fstream>
#include <queue>
#include <map>

#include "e32image.h"

#include <filesystem.hpp>
#include <thread/thread.hpp>
#include <thread/mutex.hpp>
#include <thread/condition_variable.hpp>

#include "cache/cacheexception.hpp"
#include "cache/cacheentry.hpp"
#include "cache/cacheablelist.hpp"
#include "cache/cache.hpp"
#include "cache/cachegenerator.hpp"
#include "cache/cachevalidator.hpp"
#include "cache/cachemanager.hpp"
#include <malloc.h>
#ifdef __LINUX__
#define _alloca alloca
#endif

Cache* Cache::Only = (Cache*)0;


Cache* Cache::GetInstance(void) throw (CacheException)
{
	if(! Cache::Only)
	{
		Cache::Only = new (std::nothrow) Cache();
		if(! Cache::Only)
			throw CacheException(CacheException::RESOURCE_ALLOCATION_FAILURE);
	}

	return Cache::Only;
}


void Cache::Initialize(void) throw (CacheException)
{
	//create and open cache meta data file.
	 
	 
	metafile = CacheManager::GetInstance()->GetCacheRoot();
	metafile +=  "/.rofsmeta"; 
	boost::filesystem::path metafilepath(metafile.c_str());
	if(!exists(metafilepath))
	{
		//create cache root directory if it's not present.
		boost::filesystem::path createcacheroot(CacheManager::GetInstance()->GetCacheRoot());
		create_directory(createcacheroot);

		//create cache index file.
		ofstream openmetafile(metafilepath.file_string().c_str(), ios_base::app | ios_base::out);
		if(! openmetafile.is_open())
			throw CacheException(CacheException::CACHE_INVALID);
		openmetafile.close();
	}
	printf("Loading cache meta file : %s\r\n", metafilepath.file_string().c_str());
	ifstream metafileref(metafilepath.file_string().c_str(), ios_base::in);
	if(! metafileref.is_open())
		throw CacheException(CacheException::HARDDRIVE_FAILURE);

	//read ROFS meta file and construct entry map.
	string inboundbuffer;
	while(getline(metafileref, inboundbuffer))
	{
		//validate cache index record.
		if(! ValidateEntry(inboundbuffer))
			throw CacheException(CacheException::CACHE_INVALID);

		//instantiate a new instance of class CacheEntry.
		CacheEntry* entryref = new (nothrow) CacheEntry();
		if(!entryref)
			throw CacheException(CacheException::RESOURCE_ALLOCATION_FAILURE);

		//set entry's attributes.
		
		char* attrwalker  = (char*)_alloca(inboundbuffer.length() + 1);
		memcpy(attrwalker,inboundbuffer.c_str(),inboundbuffer.length() + 1);
		 
		char* start = attrwalker ;
		while(*start != ';')
			start++;
		*start++ = 0;
		entryref->SetOriginalFilename(attrwalker);
		attrwalker = start;
		while(*start != ';')
			start++;
		*start++ = 0;
		entryref->SetOriginalFileCreateTime(attrwalker);
		attrwalker = start;
		while(*start != ';')
			start++;
		*start++ = 0;
		entryref->SetOriginalFileCompression(attrwalker);
		attrwalker = start;
		while(*start != ';')
			start++;
		*start++ = 0;
		entryref->SetCachedFilename(attrwalker);
		attrwalker = start;
		entryref->SetCachedFileCompression(attrwalker);

		//add newly created entry into entry-map.
		string newentrystring(entryref->GetOriginalFilename());
		CacheEntry* existentryref = entrymap[newentrystring];
		if(existentryref) {
			while(existentryref->GetNextEntry())
				existentryref = existentryref->GetNextEntry();
			existentryref->AppendEntry(entryref);
		}
		else {
			entrymap[newentrystring] = entryref;
		}

		//reinitialize inbound buffer.
		inboundbuffer.clear(); 
	}

	return;
}


CacheEntry* Cache::GetEntryList(const char* OriginalFilename)
{
	//retrieval could be performed concurrently.
	boost::lock_guard<boost::mutex> lock(cachemutex);
	string originalfile(OriginalFilename);
	CacheEntry* resultentries = entrymap[originalfile];

	return resultentries;
}


void Cache::AddEntry(const char* OriginalFilename, CacheEntry* EntryRef)
{
	string originalfile(OriginalFilename);

	//addtions could be performed concurrently.
	boost::lock_guard<boost::mutex> lock(cachemutex);

	entrymap[originalfile] = EntryRef;

	return;
}


void Cache::CloseCache(void) throw (CacheException)
{
	//open up the cache meta file.
	boost::filesystem::path metafilepath(metafile);
	ofstream metafileref;
	if(! exists(metafilepath))
		metafileref.open(metafilepath.file_string().c_str(), ios_base::out | ios_base::app);
	else
		metafileref.open(metafilepath.file_string().c_str(), ios_base::out | ios_base::trunc);
	if(! metafileref.is_open())
		throw CacheException(CacheException::HARDDRIVE_FAILURE);

	//save cache meta onto hard drive along with changed cache files.
	char* delimiter = ";";
	map<string, CacheEntry*>::iterator mapitem;
	for(mapitem=entrymap.begin(); mapitem != entrymap.end(); mapitem++)
	{
		CacheEntry* concreteentryref = (*mapitem).second;
		while(concreteentryref)
		{
			metafileref.write(concreteentryref->GetOriginalFilename(), strlen(concreteentryref->GetOriginalFilename()));
			metafileref.write(delimiter, strlen(delimiter));
			metafileref.write(concreteentryref->GetOriginalFileCreateTime(), strlen(concreteentryref->GetOriginalFileCreateTime()));
			metafileref.write(delimiter, strlen(delimiter));
			metafileref.write(concreteentryref->GetOriginalFileCompressionID(), strlen(concreteentryref->GetOriginalFileCompressionID()));
			metafileref.write(delimiter, strlen(delimiter));
			metafileref.write(concreteentryref->GetCachedFilename(), strlen(concreteentryref->GetCachedFilename()));
			metafileref.write(delimiter, strlen(delimiter));
			metafileref.write(concreteentryref->GetCachedFileCompressionID(), strlen(concreteentryref->GetCachedFileCompressionID()));
			metafileref.write("\n", strlen("\n"));

//			CacheEntry* tobedeletedentryref = concreteentryref;
			concreteentryref = concreteentryref->GetNextEntry();
//			delete tobedeletedentryref;
		}
	}

	//close cache meta file.
	metafileref.close();

	return;
}


bool Cache::ValidateEntry(string& EntryRawText)
{
	//an entry is formed as original_filename;original_file_create_time;original_file_compression_id;cached_filename;cached_file_compression_id(end of line - '\n')

	//format validation.
	int    semicolon         = 0;
	size_t semicolonposition = 0;
	while(1) {
		semicolonposition = EntryRawText.find(';', semicolonposition);
		if(semicolonposition != string::npos) {
			semicolonposition++;
			semicolon++;
		}
		else
			break;
	}
	if(semicolon != 4)
		return false;

	return true;
}


Cache::Cache(void)
{
	 return;
}
 
