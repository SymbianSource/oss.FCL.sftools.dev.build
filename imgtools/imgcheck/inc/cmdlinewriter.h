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
const String KCmdHeader(" Executable		Attribute	Value                   Status");
const String KCmdLineDelimiter("-------------------------------------------------------------------------------");
const String KCmdHeaderNoStatus(" Executable		Attribute	Value         ");
const String KCmdLineDelimiterNoStatus("--------------------------------------------------");
const String KCmdImageName("Image Name: ");
const String KCmdLine("Command line");
const int KCmdGenBufferSize=260;
// width to fill the values displayed as 0x00000056
const unsigned int KCmdFormatEightWidth = 8;
// width to print the attribute names
const unsigned int KCmdFormatTwelveWidth = 12;
// width to print the executable names and attribute names when executable name is not emitted
const unsigned int KCmdFormatTwentyTwoWidth = 22;
//width to print the status after the attribute values are printed for SID and VID
const unsigned int KCmdFormatThirtyWidth = 30;
// this check is taken for formatting the values (like SID and VID) other that the dependency names.
const String KCmdDepName("Dependency");
const String KCmdDbgName("DBG");
const String KCmdDbgDisplayName("Debug Flag");

typedef std::stringstream OstrStream;

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
	void StartImage(const String& aImageName);
	void EndImage(void);
	void StartExecutable(const unsigned int aSerNo, const String& aExeName);
	void EndExecutable(void);
  	
   	void FormatAndWriteElement(const String& aElement);
	void WriteExeAttribute(ExeAttribute& aOneSetExeAtt);
	void WriteDelimiter(void);
	void WriteNote(void);
	const String& ReportType(void);

private:
	
	// Output streams for cmd line output.
	OstrStream iFormatMessage;
	// For Dependencies align.
	bool iForDepAlign;
	// For formating purpose.
	unsigned int iFormatSize;
	// Buffer pointer for formating purpose.
	char* iBuffer;
	//Hold the report type
	String iRptType;
	//Contains the input options
	unsigned int iCmdOptions;
};

#endif // CMDLINEWRITER_H
