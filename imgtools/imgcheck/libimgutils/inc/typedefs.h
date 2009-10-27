/*
* Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* @internalComponent
* @released
*
*/


#ifndef TYPEDEFS_H
#define TYPEDEFS_H

#ifdef _MSC_VER
	#pragma warning(disable: 4786) // identifier was truncated to '255' characters in the debug information
	#pragma warning(disable: 4503) // decorated name length exceeded, name was truncated
#endif

#undef _L

#include <fstream.h>
#include <iostream.h>
#include <list>
#include <vector>
#include <map>
#include <string>
#include <sstream>

#include "utils.h"

/**
Forward declaration

@internalComponent
@released
*/
class E32Image;
class RomImageFSEntry;

/**
Typedefs used all over the tool.

@internalComponent
@released
*/
typedef ios Ios;
typedef std::string String;
typedef ofstream Ofstream;
typedef ifstream Ifstream;
typedef std::list<String> StringList;
typedef std::map<unsigned int, String> UintVsString;
typedef std::map<unsigned int, UintVsString> RomAddrVsExeName;
typedef std::vector<unsigned int> VectorList;
typedef std::multimap<String, StringList> ExeNamesVsDepListMap;
typedef std::multimap<String, E32Image*> ExeVsE32ImageMap;
typedef std::map<String, unsigned int> ExeVsOffsetMap;
typedef std::map<String, RomImageFSEntry*> ExeVsRomFsEntryMap;
typedef std::istringstream IStringStream;
typedef std::ostringstream OStringStream;

/**
Class used to preserve each attribute of a E32 exectuble.

@internalComponent
@released
*/
typedef struct IdData
{
	unsigned long int iUid;
	unsigned long int iSid;
	String iSidStatus;
	unsigned long int iVid;
	String iVidStatus;
	bool iDbgFlag;
	String iDbgFlagStatus;
    unsigned long int iFileOffset;
}IdData;

typedef std::map<String,IdData*> ExeVsIdDataMap;
typedef std::multimap<unsigned long int, String> SidVsExeMap;

/**
Enums to represent input image type.

@internalComponent
@released
*/
typedef enum EImageType
{
	EUnknownImage,
	ERomImage,
	ERomExImage,
	ERofsImage,
	ERofsExImage,
	EE32Directoy,
	EE32File,
	EE32InputNotExist
	//more here...
};

const String KUnknownDependency("unknown");
typedef const char* c_str ;
const c_str KDirSeperaor = "/";
const char KNull = '\0';
const long KFileHidden_9_1 = 0x0;

#endif// TYPEDEFS_H
