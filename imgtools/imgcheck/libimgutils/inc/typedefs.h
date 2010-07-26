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

 
#include <iostream>
#include <fstream>
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

typedef list<string> StringList; 
typedef map<unsigned int, string> UintVsString; 
typedef map<unsigned int, UintVsString*> RomAddrVsExeName;
typedef vector<unsigned int> VectorList;
typedef map<string, StringList > ExeNamesVsDepListMap;
typedef map<string, E32Image*> ExeVsE32ImageMap;
typedef map<string, unsigned int> ExeVsOffsetMap;
typedef map<string, RomImageFSEntry*> ExeVsRomFsEntryMap; 
 

/**
Class used to preserve each attribute of a E32 exectuble.

@internalComponent
@released
*/
typedef struct IdData
{
	unsigned long int iUid;
	unsigned long int iSid;
	string iSidStatus;
	unsigned long int iVid;
	string iVidStatus;
	bool iDbgFlag;
	string iDbgFlagStatus;
    unsigned long int iFileOffset;
}IdData;

typedef map<string,IdData*> ExeVsIdDataMap;
typedef multimap<unsigned long, string> SidVsExeMap;

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

const char KUnknownDependency[] = "unknown"; 
const char KDirSeperaor = '/';
const char KNull = '\0';
const long KFileHidden_9_1 = 0x0;

template<typename m, typename l,typename r>
static typename m::iterator put_item_to_map(m& o, l a,r& b){	
	typedef typename m::iterator iterator;
	pair<iterator, bool> ret = o.insert(pair<l,r>(a,b));
	if(false == ret.second){
		ret.first->second = b ;
	}
	return ret.first ;
}

template<typename m, typename l,typename r>
static typename m::iterator put_item_to_map_2(m& o, l a,r& b){	
	typedef typename m::iterator iterator;
	pair<iterator,bool> ret = o.insert(pair<l,r>(a,b));
	if(false == ret.second){
		if(ret.first->second)
			delete ret.first->second;
		ret.first->second = b ;
	}
	return ret.first ;
}
#ifdef __LINUX__
const char SLASH_CHAR1 = '/' ;
const char SLASH_CHAR2 = '\\' ;
#else
const char SLASH_CHAR1 = '\\' ;
const char SLASH_CHAR2 = '/'  ;
#endif

#endif// TYPEDEFS_H
