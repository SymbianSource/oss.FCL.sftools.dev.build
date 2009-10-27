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

/**
Constructor: CmdLineWriter class

@internalComponent
@released
*/
CmdLineWriter::CmdLineWriter(unsigned int aInputOptions)
: iForDepAlign(0), iFormatSize(0), iBuffer(0), iRptType(KCmdLine), iCmdOptions(aInputOptions)
{
	iFormatMessage.flush();
}


/**
Destructor:	CmdLineWriter class

Clear the Buffer.

@internalComponent
@released
*/
CmdLineWriter::~CmdLineWriter(void)
{
	delete [] iBuffer;
}


/**
Writes report header to the cmd line..
Allocates the memory for formatting purpose.

@internalComponent
@released
*/
void CmdLineWriter::StartReport(void)
{
	iBuffer = new char[KCmdGenBufferSize];
	if (iBuffer == KNull)
	{
		throw ExceptionReporter(NOMEMORY, __FILE__, __LINE__);
	}
}


/**
Writes the end report info..
Transfer the stream data to stdout.

@internalComponent
@released
*/
void CmdLineWriter::EndReport(void)
{
	String outMsg = iFormatMessage.str();
	std::cout << outMsg.c_str();
}


/**
Writes the executable element footer.

@internalComponent
@released
*/
void CmdLineWriter::EndExecutable(void)
{
	iFormatMessage << std::endl;
	iForDepAlign = false;

}


/**
Writes the Delimiter to cmd line.

@internalComponent
@released
*/
void CmdLineWriter::WriteDelimiter(void)
{
	if(iCmdOptions & KNoCheck)
	{
		iFormatMessage << KCmdLineDelimiterNoStatus.c_str() << std::endl;
	}
	else
	{
		iFormatMessage << KCmdLineDelimiter.c_str() << std::endl;
	}
}


/**
Formats the given element based on set size and places to outstream.

@internalComponent
@released

@param aElement - Reference element to be formated
*/
void CmdLineWriter::FormatAndWriteElement(const String& aElement)
{
	if (aElement.size() < iFormatSize)
	{
		memset(iBuffer,' ',iFormatSize);
		iBuffer[iFormatSize] = '\0';
		memcpy(iBuffer,aElement.c_str(),aElement.size());
	}
	else if(aElement.size() >= (unsigned long)KCmdGenBufferSize)
	{
		throw ExceptionReporter(FILENAMETOOBIG, __FILE__, __LINE__);
	}
	else
	{
		strcpy(iBuffer,aElement.c_str());
	}
	iFormatMessage << iBuffer << '\t';
}

/**
Writes the note about unknown dependency.

@internalComponent
@released
*/
void CmdLineWriter::WriteNote(void)
{
	iFormatMessage << KNote.c_str() << ": " << KUnknownDependency << KNoteMesg.c_str() << std::endl;
}


/**
Writes the image element footer.

@internalComponent
@released
*/
void CmdLineWriter::EndImage(void)
{
	WriteDelimiter();	
}


/**
Writes the executable name element.

@internalComponent
@released

@param aExeName  - Reference to executable name.
*/
void CmdLineWriter::StartExecutable(const unsigned int /* aSerNo */, const String& aExeName)
{
	iFormatSize = KCmdFormatTwentyTwoWidth;
	FormatAndWriteElement(aExeName);
	iForDepAlign = true;
}	


/**
Writes the image name element.

@internalComponent
@released

@param aImageName  - Reference to image name.
*/
void CmdLineWriter::StartImage(const String& aImageName)
{
	WriteDelimiter();
	iFormatMessage << KCmdImageName.c_str() << aImageName.c_str() << std::endl;
	WriteDelimiter();
	if(iCmdOptions & KNoCheck)
	{
		iFormatMessage << KCmdHeaderNoStatus.c_str() << std::endl;
	}
	else
	{
		iFormatMessage << KCmdHeader.c_str() << std::endl;
	}
	WriteDelimiter();
}


/**
Writes the attribute, their values and the status along with formating the output.

@internalComponent
@released

@param aOneSetExeAtt - Reference to the attributes, their value and status
*/	
void CmdLineWriter::WriteExeAttribute(ExeAttribute& aOneSetExeAtt)
{
	if(!iForDepAlign)
	{
		iFormatSize = KCmdFormatTwentyTwoWidth;
		FormatAndWriteElement("");
	}

	iFormatSize = KCmdFormatTwelveWidth;
	if(KCmdDbgName != aOneSetExeAtt.iAttName)
	{
		FormatAndWriteElement(aOneSetExeAtt.iAttName.c_str());
	}
	else
	{
		FormatAndWriteElement(KCmdDbgDisplayName.c_str());
	}
	
   	if (KCmdDepName != aOneSetExeAtt.iAttName && KCmdDbgName != aOneSetExeAtt.iAttName)
	{
		unsigned int val;
		val = Common::StringToInt(aOneSetExeAtt.iAttValue);
		
		// to display the hex value in the format of 0x00000000 if the value is 0
		iFormatMessage << "0x";
		iFormatMessage.width(KCmdFormatEightWidth);
		iFormatMessage.fill('0');
		iFormatMessage << std::hex << val << '\t';	
		iFormatMessage.fill(' ');
		iFormatMessage.width(KCmdFormatThirtyWidth);
	}
	else
	{
		iFormatSize = KCmdFormatTwentyTwoWidth;
		FormatAndWriteElement(aOneSetExeAtt.iAttValue.c_str());
	}
	iFormatSize = KCmdFormatTwentyTwoWidth;
	FormatAndWriteElement(aOneSetExeAtt.iAttStatus.c_str());
	iFormatMessage << std::endl;
	iForDepAlign = false;
}


/**
Returns the report type.

@internalComponent
@released
*/
const String& CmdLineWriter::ReportType(void)
{
	return iRptType;
}
