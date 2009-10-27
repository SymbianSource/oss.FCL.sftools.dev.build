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
* These declarations are used all over the program.
* @internalComponent
* @released
*
*/



#ifndef COMMON_H
#define COMMON_H

#include "typedefs.h"

/**
Forward declaration

@internalComponent
@released
*/
class ReportWriter;
class Checker;
class ImageReader;

/**
Typedefs used all over the tool.

@internalComponent
@released
*/
typedef std::multimap<String, ExeNamesVsDepListMap> ImageVsDependencyMap;
typedef std::list<unsigned int> UnIntList;
typedef std::vector<ReportWriter*> WriterPtrList;
typedef std::vector<Checker*> CheckerPtrList;
typedef std::vector<ImageReader*> ImageReaderPtrList;

/**
Constants used to mark whether the option received or not.

@internalComponent
@released
*/
const unsigned int KNone = 0x0;
const unsigned int QuietMode = 0x1;
const unsigned int KAll = 0x2;
const unsigned int KXmlReport = 0x4;
const unsigned int KVerbose = 0x8;
const unsigned int KSidAll = 0x10;
const unsigned int KNoCheck = 0x20;
const unsigned int KE32Input = 0x40;
//Can set value for new options over here

/**
Class used to put each attribute of a exetuble into integrated container.

@internalComponent
@released
*/
class ExeAttribute
{
public:
	ExeAttribute(){};
	~ExeAttribute(){};

	String iAttName;
	String iAttValue;
	String iAttStatus;
};

/**
Enums used during command line input processing.

@internalComponent
@released
*/
typedef enum ReturnType
{
	ESuccess = 0,
	EQuit,
	EFail
};

/**
Tool's exit status

@internalComponent
@released
*/
#define EXIT_SUCCESS 0
#define EXIT_FAILURE 1

/**
Class Common, all general purpose funtions can be included here.

@internalComponent
@released
*/
class Common
{
public:
	static String IntToString(unsigned int aValue);
	static unsigned int StringToInt(String& aStringVal);
};

/** 
Default Log file name, used for logging the progress of application.

@internalComponent
@released
*/
const String gLogFileName ("imgcheck.log");

#endif //COMMON_H
