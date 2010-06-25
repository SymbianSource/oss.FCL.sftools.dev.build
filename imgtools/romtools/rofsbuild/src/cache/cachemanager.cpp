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

#include <stdlib.h>
#include <string>
#include <queue>
#include <new>

#include "e32image.h"

#include <filesystem.hpp>
#include <thread/thread.hpp>
#include <thread/mutex.hpp>
#include <thread/condition_variable.hpp>

#include "cache/cacheexception.hpp"
#include "cache/cacheentry.hpp"
#include "cache/cache.hpp"
#include "cache/cachegenerator.hpp"
#include "cache/cachevalidator.hpp"
#include "cache/cacheablelist.hpp"
#include "cache/cachemanager.hpp"

using namespace std;


CacheManager* CacheManager::Only = (CacheManager*)0;
boost::mutex  CacheManager::creationlock;


CacheManager* CacheManager::GetInstance(void) throw (CacheException)
{
	if(! CacheManager::Only)
	{
		boost::mutex::scoped_lock lock(CacheManager::creationlock);
		if(! CacheManager::Only)
		{
			CacheManager::Only = new (nothrow) CacheManager();
			if(!CacheManager::Only)
				throw CacheException(CacheException::RESOURCE_ALLOCATION_FAILURE);
			CacheManager::Only->InitializeCache();
		}
	}

	return CacheManager::Only;
}


E32ImageFile* CacheManager::GetE32ImageFile(char* OriginalFilename, int CurrentCompressionID)
{
	this->NormalizeFilename(OriginalFilename);
	CacheEntry* validatedfile =CacheValidator::GetInstance()->Validate(OriginalFilename, CurrentCompressionID);
	if(! validatedfile)
		return (E32ImageFile*)0;

	printf("%s is validated in cache.\r\n", OriginalFilename);
	E32ImageFile* cachedimagefile = new (nothrow) E32ImageFile();
	if(! cachedimagefile)
		return (E32ImageFile*)0;
	boost::filesystem::path cachedfile(validatedfile->GetCachedFilename());
	ifstream filecontentreader(cachedfile.file_string().c_str(), ios_base::in | ios_base::binary);
	if(! filecontentreader.is_open())
		return (E32ImageFile*)0;
	filecontentreader.seekg(0, ios_base::end);
	int contentlength = filecontentreader.tellg();
	cachedimagefile->iData = (char*)malloc(sizeof(char)*contentlength);
	filecontentreader.seekg(0, ios_base::beg);
	filecontentreader.read(cachedimagefile->iData, contentlength);
	cachedimagefile->iHdr->iUncompressedSize = contentlength - cachedimagefile->iHdr->TotalSize();

	return cachedimagefile;
}


CacheEntry* CacheManager::GetE32ImageFileRepresentation(char* OriginalFilename, int CurrentCompressionID)
{
	this->NormalizeFilename(OriginalFilename);

	return CacheValidator::GetInstance()->Validate(OriginalFilename, CurrentCompressionID);
}


void CacheManager::Invalidate(char* Filename, CacheEntry* EntryRef) throw (CacheException)
{
	//update cache meta file.
	this->NormalizeFilename(Filename);
	Cache::GetInstance()->AddEntry(Filename, EntryRef);

	//update cache content.
	CacheableList::GetInstance()->AddCacheable(EntryRef);

	printf("Caching %s\r\n", Filename);

	return;
}


void CacheManager::CleanCache(void) throw (CacheException)
{
	//check if the cache is present in the current system.
	boost::filesystem::path cacherootdir(this->cacheroot);
	if(! exists(cacherootdir))
		throw CacheException(CacheException::CACHE_NOT_FOUND);

	//remove files iteratively from cache root directory.
	if(remove_all(cacherootdir) <= 0)
		throw CacheException(CacheException::CACHE_IS_EMPTY);

	return;
}


const char* CacheManager::GetCacheRoot(void)
{
	return this->cacheroot;
}


CacheManager::~CacheManager(void)
{
	CacheEntry* newentryref = new (nothrow) CacheEntry();
	CacheableList::GetInstance()->AddCacheable(newentryref);
	Cache::GetInstance()->CloseCache();
	CacheGenerator::GetInstance()->join();

	delete CacheValidator::GetInstance();
	delete Cache::GetInstance();
	delete CacheGenerator::GetInstance();
	delete CacheableList::GetInstance();

	return;
}


void CacheManager::InitializeCache(void) throw (CacheException)
{
	//assume the root directory is EPOCROOT/epoc32/build/.cache
	char* epocroot = getenv("EPOCROOT");
	if(! epocroot)
		throw CacheException(CacheException::EPOCROOT_NOT_FOUND);

	//initialize cacheroot member variable.
	int cacherootstrlen = sizeof(char)*(strlen(epocroot)+strlen("/epoc32/build/.cache")+1);
	this->cacheroot = (char*)malloc(cacherootstrlen);
	if(! this->cacheroot)
		throw CacheException(CacheException::RESOURCE_ALLOCATION_FAILURE);
	memset(this->cacheroot, 0, cacherootstrlen);
	sprintf(this->cacheroot, "%s%s", epocroot, "/epoc32/build/.cache");

	//normalize cache root path.
	this->NormalizeFilename(this->cacheroot);

	//create cache root directory if it is not present.
	boost::filesystem::path cacherootdir(this->cacheroot);
	if(! exists(cacherootdir))
		create_directories(cacherootdir);
	printf("Using %s as cache root directory.\r\n", cacherootdir.file_string().c_str());

	//create cache instance.
	Cache* cacheref = Cache::GetInstance();
	if(! cacheref)
		throw CacheException(CacheException::RESOURCE_ALLOCATION_FAILURE);

	//create cache validator instance.
	if(! CacheValidator::GetInstance())
		throw CacheException(CacheException::RESOURCE_ALLOCATION_FAILURE);

	//create cacheable list instance
	if(! CacheableList::GetInstance())
		throw CacheException(CacheException::RESOURCE_ALLOCATION_FAILURE);

	//initialize cache container.
	cacheref->Initialize();

	//start cache generator.
	CacheGenerator::GetInstance();

	return;
}


void CacheManager::NormalizeFilename(char* Filename)
{
	if(!Filename)
		return;

	//convert back slashes into forward slashes.
	char* normalizedfilename = Filename;
	while(*normalizedfilename)
	{
		if(*normalizedfilename == '\\')
			*normalizedfilename = '/';

		normalizedfilename++;
	}

	//remove redundant slashes.
	char* redundantfilename = Filename;
	while(*redundantfilename)
	{
		if((*redundantfilename=='/') && (*(redundantfilename+1)=='/'))
		{
			redundantfilename++;
			continue;
		}
		*Filename++ = *redundantfilename++;
	}
	*Filename = 0;

	return;
}


CacheManager::CacheManager(void)
{
	return;
}
