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

#include "loggingexception.h"


int LoggingException::RESOURCE_ALLOCATION_FAILURE = 1;
int LoggingException::INVALID_LOG_FILENAME        = 2;
int LoggingException::UNKNOWN_IMAGE_TYPE          = 3;


LoggingException::LoggingException(int ErrorCode)
{
	this->errcode = ErrorCode;

	return;
}


int LoggingException::GetErrorCode(void)
{
	return this->errcode;
}


const char* LoggingException::GetErrorMessage(void)
{
	if(this->errcode == LoggingException::RESOURCE_ALLOCATION_FAILURE)
		return "Not enough system resources to initialize logging module.";
	else if(this->errcode == LoggingException::INVALID_LOG_FILENAME)
		return "Invalid log filename as input.";
	else if(this->errcode == LoggingException::UNKNOWN_IMAGE_TYPE)
		return "the image type not supported.";
//	else if(this->errcode == CacheException::CACHE_IS_EMPTY)
//		return "Cache is empty.";
//	else if(this->errcode == CacheException::HARDDRIVE_FAILURE)
//		return "A hard drive failure occurred in Cache operations.";

	return "Undefined error type.";
}


LoggingException::~LoggingException(void)
{
	return;
}
