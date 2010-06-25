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

#include "cache/cacheexception.hpp"


int CacheException::EPOCROOT_NOT_FOUND          = 1;
int CacheException::RESOURCE_ALLOCATION_FAILURE = 2;
int CacheException::CACHE_NOT_FOUND             = 3;
int CacheException::CACHE_INVALID               = 4;
int CacheException::CACHE_IS_EMPTY              = 5;
int CacheException::HARDDRIVE_FAILURE           = 6;


CacheException::CacheException(int ErrorCode)
{
	this->errcode = ErrorCode;

	return;
}


int CacheException::GetErrorCode(void)
{
	return this->errcode;
}


const char* CacheException::GetErrorMessage(void)
{
	if(this->errcode == CacheException::EPOCROOT_NOT_FOUND)
		return "EPOCROOT environment variable is not set.";
	else if(this->errcode == CacheException::RESOURCE_ALLOCATION_FAILURE)
		return "Not enough system resources to initialize cache module.";
	else if(this->errcode == CacheException::CACHE_NOT_FOUND)
		return "Cache is not present in the current system.";
	else if(this->errcode == CacheException::CACHE_INVALID)
		return "Cache is invalid.";
	else if(this->errcode == CacheException::CACHE_IS_EMPTY)
		return "Cache is empty.";
	else if(this->errcode == CacheException::HARDDRIVE_FAILURE)
		return "A hard drive failure occurred in Cache operations.";

	return "Undefined error type.";
}


CacheException::~CacheException(void)
{
	return;
}
