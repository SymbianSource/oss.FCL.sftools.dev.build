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
* ReportWriter class declaration.
* @internalComponent
* @released
*
*/


#ifndef REPORTWRITER_H
#define REPORTWRITER_H
 
#include <iomanip> 
#include <fstream>
#include <iostream>
#include <sstream>
using namespace std;

#include "common.h"
#include "exceptionreporter.h"

/**
Note message to explain about unknown dependency in ROM image
 
@internalComponent
@released
*/
const char KNoteMesg[] = " - Executable is hidden in ROM image, but all the links to this executable are statically resolved.";
const char KNote[] = "Note";

/** 
Report Writer cass (Abstract base class for cmdline and xml derived writer class)

@internalComponent
@released
*/
class ReportWriter
{
public:

    ReportWriter(void){};
    virtual ~ReportWriter(void){};

	virtual void StartReport(void)=0;
	virtual void EndReport(void)=0;
	virtual void StartImage(const string& aImageName)=0;
    virtual void EndImage(void)=0;
	virtual void WriteExeAttribute(ExeAttribute& aOneSetExeAtt)=0;
	virtual void StartExecutable(const unsigned int aSerNo, const string& aExeName)=0;
	virtual void EndExecutable(void)=0;
	virtual void WriteNote(void)=0;
	virtual const string& ReportType(void)=0;
};

#endif // REPORTWRITER_H
