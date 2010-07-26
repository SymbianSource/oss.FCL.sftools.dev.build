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

typedef map<string,unsigned int> OptionsMap;
typedef map<string,unsigned int> SuppressionsMap; 
typedef vector<const char*> cstrings ;

/** 
Long options will be intialized into an MAP, this data is used later to
validate the received command line arguments.

@internalComponent
@released
*/
const string KLongHelpOption("--help");
const string KLongXmlOption("--xml");
const string KLongQuietOption("--quiet");
const string KLongAllOption("--all");
const string KLongOutputOption("--output");
const string KLongVerboseOption("--verbose");
const string KLongSuppressOption("--suppress");
const string KLongVidValOption("--vidlist");
const string KLongSidAllOption("--sidall");
const string KLongE32InputOption("--e32input");

/** 
Short options will be intialized into an MAP, this data is used later to
validate the received command line arguments.

@internalComponent
@released
*/
const string KShortHelpOption("-h");
const string KShortXmlOption("-x");
const string KShortQuietOption("-q");
const string KShortAllOption("-a");
const string KShortOutputOption("-o");
const string KShortVerboseOption("-v");
const string KShortSuppressOption("-s");
const string KShortNoCheck("-n");

/**
options to enable required Validation

@internalComponent
@released
*/
const string KLongEnableDepCheck("--dep");
const string KLongEnableSidCheck("--sid");
const string KLongEnableVidCheck("--vid");
const string KLongEnableDbgFlagCheck("--dbg");
const string KLongNoCheck("--nocheck");

/**
option values to disable specific Validation.

@internalComponent
@released
*/
const string KSuppressDependency("dep");
const string KSuppressSid("sid");
const string KSuppressVid("vid");

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
const char KXmlExtension[] = ".xml";

/** 
Default XML report name, used if the output report name is not passed through 
command line.

@internalComponent
@released
*/
const char GXmlFileName[] = "imgcheckreport.xml";

/** 
Tool name

@internalComponent
@released
*/
const char KToolName[] = "imgcheck";

/**
Constants used validate the input Decimal or Hexadecimal values

@internalComponent
@released
*/
const char KHexNumber[] = "0123456789abcdef";
const char KDecNumber[] = "0123456789"; 
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
	const string& PrintUsage(void) const;
	const string& PrintVersion(void) const;
	const char* NextImageName(void);
	unsigned int NoOfImages(void) const;
	const unsigned int ReportFlag(void) const;
	const string& XmlReportName(void) const;
	ReturnType ProcessCommandLine(unsigned int aArgc, char* aArgv[]);
	void ValidateArguments(void) const;
	const unsigned int EnabledValidations(void) const;
	UnIntList& VidValueList(void);
	const string& Command(void) const;
	bool DebuggableFlagVal(void);
	void ValidateImageNameList(void);
	void ValidateE32NoCheckArguments(void);

private:
	bool IsOption(const char* aName, int& aLongOptionFlag);
	bool Validate(const string& aName, bool aOptionValue, unsigned int aNoOfVal);
	void NormaliseName(void);
	void ParseOption(char* aFullName, cstrings& aOptionValues, bool& aOptionValue);
	void HandleImage(const char* aImageName);
	void StringListToUnIntList(cstrings& aStrList, UnIntList& aUnIntList);
	bool AlreadyReceived(const char* aName);

private:
	cstrings iImageNameList;
	OptionsMap iOptionMap;
	SuppressionsMap iSuppressVal;
	UnIntList iVidValList;
	bool iDebuggableFlagVal;
	string iInputCommand;
	string iXmlFileName;
	bool iNoImage;
	unsigned int iCommmandFlag;
	unsigned int iValidations;
	unsigned int iSuppressions;
	string iVersion;
	string iUsage;
};

#endif //CMDLINEHANDLER_H
