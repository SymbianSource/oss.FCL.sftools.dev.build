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
#include <queue>
#include <time.h>
#include <stdio.h>
#include <stdlib.h>

#include "cache/cacheexception.hpp"
#include "cache/cacheentry.hpp"


CacheEntry::CacheEntry(void)
{
	this->next                 = (CacheEntry*)0;
	this->cachedfilebuffer     = (char*)0      ;
	this->cachedfilebuffersize = 0             ;

	return;
}


void CacheEntry::SetOriginalFilename(const char* OriginalFilename)
{
	this->originalfile.clear();
	this->originalfile.assign(OriginalFilename);

	return;
}


const char* CacheEntry::GetOriginalFilename(void) const
{
	return this->originalfile.c_str();
}


void CacheEntry::SetCachedFilename(const char* CachedFilename)
{
	this->cachedfile.clear();
	this->cachedfile.assign(CachedFilename);

	return;
}


const char* CacheEntry::GetCachedFilename(void) const
{
	return this->cachedfile.c_str();
}


void CacheEntry::SetOriginalFileCreateTime(time_t* CreateRawTime)
{
	this->originalfilecreatetime.clear();
	this->originalfilecreatetime.assign(ctime(CreateRawTime));

	size_t newlinepos = this->originalfilecreatetime.find("\n");
	while(newlinepos != std::string::npos)
	{
		this->originalfilecreatetime.erase(newlinepos, 1);
		newlinepos = this->originalfilecreatetime.find(("\n"));
	}

	return;
}


void CacheEntry::SetOriginalFileCreateTime(const char* CreateRawTime)
{
	this->originalfilecreatetime.clear();
	this->originalfilecreatetime.assign(CreateRawTime);

	return;
}


const char* CacheEntry::GetOriginalFileCreateTime(void) const
{
	return this->originalfilecreatetime.c_str();
}


void CacheEntry::SetOriginalFileCompression(const char* CompressionMethodID)
{
	this->originalfilecompression.clear();
	this->originalfilecompression.assign(CompressionMethodID);

	return;
}


void CacheEntry::SetOriginalFileCompression(unsigned int CompressionMethodID)
{
	char methodid[30];
	memset(methodid, 0, sizeof(methodid));
	sprintf(methodid, "%d", CompressionMethodID);

	this->originalfilecompression.clear();
	this->originalfilecompression.assign(methodid);

	return;
}


const char* CacheEntry::GetOriginalFileCompressionID(void) const
{
	return this->originalfilecompression.c_str();
}


void CacheEntry::SetCachedFileCompression(const char* CompressionMethodID)
{
	this->cachedfilecompression.clear();
	this->cachedfilecompression.assign(CompressionMethodID);

	return;
}


void CacheEntry::SetCachedFileCompression(unsigned int CompressionMethodID)
{
	char methodid[128];
	memset(methodid, 0, sizeof(methodid));
	sprintf(methodid, "%d", CompressionMethodID);

	this->cachedfilecompression.clear();
	this->cachedfilecompression.assign(methodid);

	return;
}


const char* CacheEntry::GetCachedFileCompressionID(void) const
{
	return this->cachedfilecompression.c_str();
}


void CacheEntry::SetCachedFileBuffer(char* FileBuffer, int FileBufferLen)
{
	this->cachedfilebuffer     = (char*)malloc(sizeof(char)*FileBufferLen);
	memcpy(this->cachedfilebuffer, FileBuffer, FileBufferLen);
	this->cachedfilebuffersize = FileBufferLen;

	return;
}


const char* CacheEntry::GetCachedFileBuffer(void) const
{
	return this->cachedfilebuffer;
}


int CacheEntry::GetCachedFileBufferLen(void) const
{
	return this->cachedfilebuffersize;
}


void CacheEntry::AppendEntry(CacheEntry* EntryRef)
{
	//the parameter EntryRef must be valid, should be verified by the caller.
	this->next = EntryRef;

	return;
}


CacheEntry* CacheEntry::GetNextEntry(void) const
{
	return this->next;
}


void CacheEntry::SetNextEntry(CacheEntry* EntryRef)
{
	this->next = EntryRef;

	return;
}


bool CacheEntry::Equals(CacheEntry* EntryRef)
{
	if( (this->originalfile.compare(EntryRef->GetOriginalFilename())==0) &&
	    (this->originalfilecreatetime.compare(EntryRef->GetOriginalFileCreateTime())==0) &&
	    (this->originalfilecompression.compare(EntryRef->GetOriginalFileCompressionID())==0) &&
	    (this->cachedfile.compare(EntryRef->GetCachedFilename())==0) &&
	    (this->cachedfilecompression.compare(EntryRef->GetCachedFileCompressionID())==0)
	  )
		return true;

	return false;
}


CacheEntry::~CacheEntry(void)
{
	if(this->cachedfilebuffer)
	{
		free(this->cachedfilebuffer);
		this->cachedfilebuffer = NULL;
	}

	return;
}
