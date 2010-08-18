/*
* Copyright (c) 2008-2009 Nokia Corporation and/or its subsidiary(-ies).
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


#ifndef __SISUTILS_H__
#define __SISUTILS_H__

#ifdef _MSC_VER 
	#pragma warning(disable: 4786) // identifier was truncated to '255' characters in the debug information
	#pragma warning(disable: 4503) // decorated name length exceeded, name was truncated
#endif

#include <string>
#include <list>
#include <iostream>
#include <fstream>
#include <iomanip>
#undef _L


#include <e32def.h>
#include <e32cmn.h>

#define STAT_SUCCESS  (0)
#define STAT_FAILURE  (-1)

#ifdef WIN32
#define PATHSEPARATOR  "\\"
#else // linux
#define PATHSEPARATOR  "/"
 
//int wcsnicmp(const wchar_t* str1,const wchar_t* str2,size_t n);
//int wcsicmp(const wchar_t* str1,const wchar_t* str2);
//int iswdigit(wchar_t ch);
char *_fullpath( char *absPath, const char *relPath, size_t maxLength );
#endif

 
using namespace std ;

/** 
class SisUtils

@internalComponent
@released
*/
class SisUtils
{
public:
	SisUtils(const char* aFile);
	virtual ~SisUtils();

	void SetVerboseMode();

	virtual void ProcessSisFile() = 0;
	virtual void GenerateOutput() = 0;

	static string iExtractPath;
	static string iOutputPath;

protected:
	TBool IsVerboseMode();
	TBool IsFileExist(string aFile);
	TBool MakeDirectory(const string& aPath);
	const char* SisFileName();
	TUint32 RunCommand(const char* aCmd);
	void TrimQuotes(string& aStr);

private:
	TBool iVerboseMode;
	string iSisFile;
};

// SisUtils Exception handler
class SisUtilsException
{
public:
	SisUtilsException(const char* aFile, const char* aErrMessage);
	virtual ~SisUtilsException();
	virtual void Report();

private:
	string iSisFileName;
	string iErrMessage;
};


#endif //__SISUTILS_H__
