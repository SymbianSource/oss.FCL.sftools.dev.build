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
* Checker interface class declaration
* @internalComponent
* @released
*
*/


#ifndef CHECKER_H
#define CHECKER_H

#include "cmdlinehandler.h"
#include "reporter.h"
#include "imagereader.h"

typedef std::map<std::string, ExeVsIdDataMap> ImgVsExeIdData;

/** 
Different status of a dependency

@internalComponent
@released
*/
const String KStatusYes("Available");
const String KStatusNo("Missing");
const String KStatusHidden("Hidden");
const String KDependency("Dependency");

/** 
All SID validation status constants

@internalComponent
@released
*/
const String KUniqueAlias("Unique(alias)");
const String KUnique("Unique");
const String KDuplicate("Duplicate");
const String KSid("SID");

/** 
VID and Debuggable flag validation status constants

@internalComponent
@released
*/
const String KValid("Valid");
const String KInValid("Invalid");
const String KDbgMatching("Matching");
const String KDbgNotMatching("Not Matching");
const String KDbgFlag("DBG");
const String KVid("VID");

/**
This class is a virtual base. If any new checks or validation needs to be 
included as part of this tool, the new checker or validator class should be
derived from this class.

@internalComponent
@released
*/
class Checker
{
protected:
	CmdLineHandler* iCmdLine;
	ImageReaderPtrList iImageReaderList;
	//To identify whether missing or all dependency data to be generated
	bool iAllExecutables;
	//To disable all checks
	bool iNoCheck;

public:
	Checker(CmdLineHandler* aCmdPtr,ImageReaderPtrList& aImageReaderList);
	virtual ~Checker();
	virtual void Check(ImgVsExeStatus& imgVsExeStatus)=0;
	virtual void PrepareAndWriteData(ExeContainer* aExeContainer)=0;
};
#endif//CHECKER_H
