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
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <cstring>
#include <time.h>
#include <map>
#include <iostream>
#include <fstream>
#include <filesystem.hpp>
#include <thread/mutex.hpp>

#include "cache/cacheexception.hpp"
#include "cache/cacheentry.hpp"
#include "cache/cache.hpp"
#include "cache/cachevalidator.hpp"

using namespace std ;
CacheValidator* CacheValidator::Only = (CacheValidator*)0;


CacheValidator* CacheValidator::GetInstance(void) throw (CacheException)
{
	if(! CacheValidator::Only)
	{
		CacheValidator::Only = new (nothrow) CacheValidator();
		if(! CacheValidator::Only)
			throw CacheException(CacheException::RESOURCE_ALLOCATION_FAILURE);
	}

	return CacheValidator::Only;
}


CacheEntry* CacheValidator::Validate(const char* OriginalFilename, int CurrentCompressionID)
{
	if(! OriginalFilename)
		return (CacheEntry*)0;

	//an executable will be validated if its creation time does not altered and the compression method is not different against previous image build used.
	CacheEntry* entryref = Cache::GetInstance()->GetEntryList(OriginalFilename);
	if(! entryref)
	{
		return (CacheEntry*)0;
	}

	boost::filesystem::path originalfile(OriginalFilename);
	time_t originalcreationtime = last_write_time(originalfile);
	string creationtime(ctime(&originalcreationtime));
	size_t newlinepos = creationtime.find("\n");
	while(newlinepos != string::npos)
	{
		creationtime.erase(newlinepos, 1);
		newlinepos = creationtime.find(("\n"));
	}
	while(entryref)
	{
		if((creationtime.compare(entryref->GetOriginalFileCreateTime())== 0) && (atoi(entryref->GetCachedFileCompressionID())==CurrentCompressionID))
		{
			boost::filesystem::path cachedfile(entryref->GetCachedFilename());
			string filename = cachedfile.file_string(); 
			ifstream filecontentreader(filename.c_str(), ios_base::in | ios_base::binary);
			if(! filecontentreader.is_open()){
				cerr << "Cannot open cached file " << filename << endl ;
				return NULL;
			}
			filecontentreader.seekg(0, ios_base::end);
			int contentlength = filecontentreader.tellg();
			char* bufferref = new char[contentlength + 1];
			filecontentreader.seekg(0, ios_base::beg);
			filecontentreader.read(bufferref, contentlength);
			bufferref[contentlength] = 0 ;
			entryref->SetCachedFileBuffer(bufferref, contentlength);
			delete []bufferref;

			cout << "Using cached" <<  OriginalFilename << endl ;

			return entryref;
		}

		entryref = entryref->GetNextEntry();
	}

	return (CacheEntry*)0;
}


CacheValidator::CacheValidator(void)
{
	return;
}
