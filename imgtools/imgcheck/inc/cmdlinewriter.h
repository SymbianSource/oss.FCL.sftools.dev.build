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
* Cmdlinewriter class declaration.
* @internalComponent
* @released
*
*/


#ifndef CMDLINEWRITER_H
#define CMDLINEWRITER_H

#include "reportwriter.h"
#include "common.h"

/**
Constants for Cmd Line report section.
*/
 
const char KCmdLineDelimiter[] = "-------------------------------------------------------------------------------"; 
const char KCmdLineDelimiterNoStatus[] = "--------------------------------------------------";
const char KCmdImageName[] = "Image Name: ";
const char KCmdLine[] = "Command line"; 
 
// width to print the attribute names
const unsigned int KCmdFormatTwelveWidth = 12; 
// width to print the executable names and attribute names when executable name is not emitted
//width to print the status after the attribute values are printed for SID and VID
const unsigned int KCmdFormatTwentyEightWidth = 28;
// this check is taken for formatting the values (like SID and VID) other that the dependency names.
const char KCmdDepName[] = "Dependency";
const char KCmdDbgName[] = "DBG";
const char KCmdDbgDisplayName[] = "Debug Flag";

 

/** 
class command line writer

@internalComponent
@released
*/
class CmdLineWriter: public ReportWriter
{
public:

	CmdLineWriter(unsigned int aInputOptions);
	~CmdLineWriter(void);
	void StartReport(void);
	void EndReport(void);
	void StartImage(const string& aImageName);
	void EndImage(void);
	void StartExecutable(const unsigned int aSerNo, const string& aExeName);
	void EndExecutable(void);
  	
   	void FormatAndWriteElement(const string& aElement);
	void WriteExeAttribute(ExeAttribute& aOneSetExeAtt);
	void WriteDelimiter(void);
	void WriteNote(void);
	const string& ReportType(void);

private:
	
	// Output streams for cmd line output.
	stringstream iFormatMessage;
	// For Dependencies align.
	bool iForDepAlign;
	// For formating purpose.
	unsigned int iFormatSize; 
	//Hold the report type
	string iRptType;
	//Contains the input options
	unsigned int iCmdOptions;
};

#endif // CMDLINEWRITER_H
