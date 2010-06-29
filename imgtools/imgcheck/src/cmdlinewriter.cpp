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
* Generates commandline report.
*
*/


/**
@file
@internalComponent
@released
*/

#include "cmdlinewriter.h"
#include <stdio.h>
/**
Constructor: CmdLineWriter class

@internalComponent
@released
*/
CmdLineWriter::CmdLineWriter(unsigned int aInputOptions)
: iForDepAlign(0), iFormatSize(0),  iRptType(KCmdLine), iCmdOptions(aInputOptions) {
	//iFormatMessage.flush();
}


/**
Destructor:	CmdLineWriter class

Clear the Buffer.

@internalComponent
@released
*/
CmdLineWriter::~CmdLineWriter(void) {

}


/**
Writes report header to the cmd line..
Allocates the memory for formatting purpose.

@internalComponent
@released
*/
void CmdLineWriter::StartReport(void) { 
}


/**
Writes the end report info..
Transfer the stream data to stdout.

@internalComponent
@released
*/
void CmdLineWriter::EndReport(void) {
	iFormatMessage.flush();
	string str ;
	while(!iFormatMessage.eof()){
		getline(iFormatMessage,str);
		cout << str.c_str()<<endl ;
	}
}


/**
Writes the executable element footer.

@internalComponent
@released
*/
void CmdLineWriter::EndExecutable(void) {
	iFormatMessage << endl;
	iForDepAlign = false;

}


/**
Writes the Delimiter to cmd line.

@internalComponent
@released
*/
void CmdLineWriter::WriteDelimiter(void) {
	if(iCmdOptions & KNoCheck) {
		iFormatMessage << KCmdLineDelimiterNoStatus << endl;
	}
	else {
		iFormatMessage << KCmdLineDelimiter << endl;
	}

}


/**
Formats the given element based on set size and places to outstream.

@internalComponent
@released

@param aElement - Reference element to be formated
*/
void CmdLineWriter::FormatAndWriteElement(const string& aElement) {
	if(aElement.length() < iFormatSize)
		iFormatMessage << setw(iFormatSize) << aElement.c_str(); 
	else 
		iFormatMessage << aElement.c_str() << ' '; 
}

/**
Writes the note about unknown dependency.

@internalComponent
@released
*/
void CmdLineWriter::WriteNote(void){
	iFormatMessage << KNote << ": " << KUnknownDependency << KNoteMesg << endl;
}


/**
Writes the image element footer.

@internalComponent
@released
*/
void CmdLineWriter::EndImage(void){
	WriteDelimiter();	

}


/**
Writes the executable name element.

@internalComponent
@released

@param aExeName  - Reference to executable name.
*/
void CmdLineWriter::StartExecutable(const unsigned int /* aSerNo */, const string& aExeName) {
	iFormatSize = KCmdFormatTwentyEightWidth; 
	FormatAndWriteElement(aExeName);
	iForDepAlign = true;
}	


/**
Writes the image name element.

@internalComponent
@released

@param aImageName  - Reference to image name.
*/
void CmdLineWriter::StartImage(const string& aImageName) {
	WriteDelimiter();
	iFormatMessage << KCmdImageName << aImageName.c_str() << endl;
	WriteDelimiter();
	iFormatMessage << setw(KCmdFormatTwentyEightWidth) << left <<setfill(' ')<< "Executable" ;
	iFormatMessage << setw(KCmdFormatTwelveWidth)  << "Attribute" ;
	iFormatMessage << setw(KCmdFormatTwelveWidth) << "Value" ;
	if(0 == (iCmdOptions & KNoCheck)) {
		iFormatMessage << setw(KCmdFormatTwelveWidth) << "Status" ;
	}
	iFormatMessage<<endl;
	WriteDelimiter();
}


/**
Writes the attribute, their values and the status along with formating the output.

@internalComponent
@released

@param aOneSetExeAtt - Reference to the attributes, their value and status
*/	
void CmdLineWriter::WriteExeAttribute(ExeAttribute& aOneSetExeAtt) {
	if(!iForDepAlign) {		
		iFormatSize = KCmdFormatTwentyEightWidth;
		FormatAndWriteElement("");
	}
	iFormatSize = KCmdFormatTwelveWidth; 
	if(KCmdDbgName != aOneSetExeAtt.iAttName) { 
		FormatAndWriteElement(aOneSetExeAtt.iAttName);
	}
	else {
		FormatAndWriteElement(KCmdDbgDisplayName);
	}

	if (KCmdDepName != aOneSetExeAtt.iAttName && KCmdDbgName != aOneSetExeAtt.iAttName) {
		unsigned int val = Common::StringToInt(aOneSetExeAtt.iAttValue);
		char str[20];
		sprintf(str,"0x%08X",val);
		// to display the hex value in the format of 0x00000000 if the value is 0
		iFormatMessage << setw(KCmdFormatTwelveWidth)  << str ; 
	}
	else {
		iFormatSize = KCmdFormatTwentyEightWidth;
		FormatAndWriteElement(aOneSetExeAtt.iAttValue);
	}
	iFormatSize = KCmdFormatTwelveWidth;
	FormatAndWriteElement(aOneSetExeAtt.iAttStatus);  
	iFormatMessage << endl;
	iForDepAlign = false;
}


/**
Returns the report type.

@internalComponent
@released
*/
const string& CmdLineWriter::ReportType(void) {
	return iRptType;
}
