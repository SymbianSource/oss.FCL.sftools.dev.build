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
* CmdLineHandler class declaration.
* @internalComponent
* @released
*
*/


#ifndef CMDLINEHANDLER_H
#define CMDLINEHANDLER_H

#include "common.h"
#include "exceptionreporter.h"
#include "version.h"
#include "hash.h"
#include <map>
#include <vector>

/** 
Tydefs used in this class.

@internalComponent
@released
*/

typedef std::map<String,unsigned int> OptionsMap;
typedef std::map<String,unsigned int> SuppressionsMap;
typedef std::vector<char*> ArgumentList;


/** 
Long options will be intialized into an MAP, this data is used later to
validate the received command line arguments.

@internalComponent
@released
*/
const String KLongHelpOption("--help");
const String KLongXmlOption("--xml");
const String KLongQuietOption("--quiet");
const String KLongAllOption("--all");
const String KLongOutputOption("--output");
const String KLongVerboseOption("--verbose");
const String KLongSuppressOption("--suppress");
const String KLongVidValOption("--vidlist");
const String KLongSidAllOption("--sidall");
const String KLongE32InputOption("--e32input");

/** 
Short options will be intialized into an MAP, this data is used later to
validate the received command line arguments.

@internalComponent
@released
*/
const String KShortHelpOption("-h");
const String KShortXmlOption("-x");
const String KShortQuietOption("-q");
const String KShortAllOption("-a");
const String KShortOutputOption("-o");
const String KShortVerboseOption("-v");
const String KShortSuppressOption("-s");
const String KShortNoCheck("-n");

/**
options to enable required Validation

@internalComponent
@released
*/
const String KLongEnableDepCheck("--dep");
const String KLongEnableSidCheck("--sid");
const String KLongEnableVidCheck("--vid");
const String KLongEnableDbgFlagCheck("--dbg");
const String KLongNoCheck("--nocheck");

/**
option values to disable specific Validation.

@internalComponent
@released
*/
const String KSuppressDependency("dep");
const String KSuppressSid("sid");
const String KSuppressVid("vid");

/**
To mark whether validaition is enabled or not

@internalComponent
@released
*/
const unsigned int KMarkEnable = 0x80000000;

/**
VID value size

@internalComponent
@released
*/
const unsigned int KHexEightByte = 8;
const unsigned int KDecHighValue = 0xFFFFFFFF;

/**
Applicable values of option suppress or -s, allocate each bit for every Validation.

@internalComponent
@released
*/
typedef enum Suppress
{
    EDep = 0x1,
    ESid = 0x2,
    EVid = 0x4,
	EDbg = 0x8,
    //While including more checks, define the constants here;
    EAllValidation = EDep | ESid | EVid //Add the new check over here.
};

/**
Constants to define number of values.

@internalComponent
@released
*/
typedef enum NumberOfValue
{
    ENone = 0x0,
    ESingle = 0x1,
    //Include new number of values here 
    EMultiple = 0x2,
	EOptional
};

/** 
Prefix to the short option

@internalComponent
@released
*/
const char KShortOptionPrefix = '-';

/** 
XML file extension, if the extension is not provided as part of report name,
this string is appended.

@internalComponent
@released
*/
const String KXmlExtension(".xml");

/** 
Default XML report name, used if the output report name is not passed through 
command line.

@internalComponent
@released
*/
const String GXmlFileName("imgcheckreport.xml");

/** 
Tool name

@internalComponent
@released
*/
const String KToolName("imgcheck");

/**
Constants used validate the input Decimal or Hexadecimal values

@internalComponent
@released
*/
const String KHexNumber("0123456789abcdef");
const String KDecNumber("0123456789");

/** 
class command line handler

@internalComponent
@released
*/
class CmdLineHandler
{
public:
	CmdLineHandler(void);
	~CmdLineHandler(void);
	void Usage(void);
	void Version(void);
	const String& PrintUsage(void) const;
	const String& PrintVersion(void) const;
	String NextImageName(void);
	unsigned int NoOfImages(void) const;
	const unsigned int ReportFlag(void) const;
	const String& XmlReportName(void) const;
	ReturnType ProcessCommandLine(unsigned int aArgc, char* aArgv[]);
	void ValidateArguments(void) const;
	const unsigned int EnabledValidations(void) const;
	UnIntList& VidValueList(void);
	const String& Command(void) const;
	bool DebuggableFlagVal(void);
	void ValidateImageNameList(void);
	void ValidateE32NoCheckArguments(void);

private:
	bool IsOption(const String& aName, int& aLongOptionFlag);
	bool Validate(const String& aName, bool aOptionValue, unsigned int aNoOfVal);
	void NormaliseName(void);
	void ParseOption(const String& aFullName, String& aOptionName, StringList& aOptionValues, bool& aOptionValue);
	void HandleImage(const String& aImageName);
	void StringListToUnIntList(StringList& aStrList, UnIntList& aUnIntList);
	bool AlreadyReceived(String& aName);

private:
	StringList iImageNameList;
	OptionsMap iOptionMap;
	SuppressionsMap iSuppressVal;
	UnIntList iVidValList;
	bool iDebuggableFlagVal;
	String iInputCommand;
	String iXmlFileName;
	bool iNoImage;
	unsigned int iCommmandFlag;
	unsigned int iValidations;
	unsigned int iSuppressions;
	String iVersion;
	String iUsage;
};

#endif //CMDLINEHANDLER_H
