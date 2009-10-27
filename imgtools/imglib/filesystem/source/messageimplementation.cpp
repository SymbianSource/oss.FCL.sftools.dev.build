/*
* Copyright (c) 2006-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* This class is used get the message strings and provides operations 
* to log them into log file
* @internalComponent
* @released
*
*/



#include "messageimplementation.h"
#include "errorhandler.h"

using std::endl;
using std::cout;
typedef std::string String;

char *errorMssgPrefix="FileSystem : Error:";
char *warnMssgPrefix="FileSystem : Warning:";
char *infoMssgPrefix="FileSystem : Information:";
char *Space=" ";

enum MessageArraySize{MAX=16};

//Messages stored required for the program
struct EnglishMessage MessageArray[MAX]=
{
	{FILEOPENERROR,"%s:%d: Could not open file : %s."},
	{FILEREADERROR,"%s:%d: Could not read file : %s."},
	{FILEWRITEERROR,"%s:%d: Could not write input image file."},
	{MEMORYALLOCATIONERROR,"%s:%d: Memory allocation failure."},
	{ENTRYCREATEMSG,"Creating the entry : %s."},
	{BOOTSECTORERROR,"%s:%d: Boot Sector Error: %s."},
	{BOOTSECTORCREATEMSG,"Creating bootsector : %s."},
	{BOOTSECTORWRITEMSG,"Writing bootsector : %s"},
	{FATTABLEWRITEMSG, "Writing FAT table for : %s"},
	{IMAGESIZETOOBIG,"%s:%d: Current image size is greater than the given partition size: %s"},
	{NOENTRIESFOUND,"%s:%d: No entries found under root."},
	{EMPTYFILENAME,"%s:%d: Empty name received."},
	{EMPTYSHORTNAMEERROR,"%s:%d: Empty short name."},
	{CLUSTERERROR,"%s:%d: Cluster Instance error."},
	{ROOTNOTFOUND,"%s:%d: None of the entries received."},
	{UNKNOWNERROR,"%s:%d: Unknown exception occured."}
};

/**
Constructor to reset the logging option flag.

@internalComponent
@released
*/
MessageImplementation::MessageImplementation()
{
    iLogging = false;
}

/**
Destructor to close log file if logging is enabled and to clear the messaged.

@internalComponent
@released
*/
MessageImplementation::~MessageImplementation()
{
    if(iLogging)
    {
		fclose(iLogPtr);
    }
	iMessage.clear();
}

/**
Function to Get Message stored in map.

@internalComponent
@released

@param aMessageIndex - Index of the Message to be displayed
@return Message string to be displayed
*/
char * MessageImplementation::GetMessageString(int aMessageIndex)
{
	Map::iterator p = iMessage.find(aMessageIndex);
	if(p != iMessage.end())
	{
		return p->second;
	}
	else
	{
		if(aMessageIndex <= MAX)
		{
			return MessageArray[aMessageIndex-1].message;
		}
		else
		{
			return NULL;
		}
	}
}

/**
Function to log message in log file if logging is enable.

@internalComponent
@released

@param aString - Message to be displayed
*/
void MessageImplementation::LogOutput(const char *aString)
{
    if (iLogging)
    {
		fputs(aString,iLogPtr);
		fputs("\n",iLogPtr);
    }
}


/**
Function to display output and log message in log file if logging is enable.

@internalComponent
@released

@param aString - Message to be displayed
*/
void MessageImplementation::Output(const char *aString)
{

    if (iLogging)
    {
		fputs(aString,iLogPtr);
		fputs("\n",iLogPtr);
    }
	cout << aString << endl;
}

/**
Function to Get Message stored in map and to display the Message

@internalComponent
@released

@param aMessageType - The type of the message, whether it is Error or Warning or Information.
@param aMsgIndex - The index of the information and the corresponding arguments.
*/
void MessageImplementation::ReportMessage(int aMessageType, int aMsgIndex,...)
{
	String reportMessage;
	char* ptr;

	va_list ap;
	va_start(ap,aMsgIndex);
	
	ptr = GetMessageString(aMsgIndex);
	
	if(ptr)
	{
		switch (aMessageType)
		{
			case ERROR:
				reportMessage += errorMssgPrefix;
				break;
			case WARNING:
				reportMessage += warnMssgPrefix;
				break;
			case INFORMATION:
				reportMessage += infoMssgPrefix;
				break;
			default:
				break;
		}
		reportMessage += Space;
		reportMessage.append(ptr);
		int location = reportMessage.find('%',0);
		//Erase the string from % to the end, because it is no where required.
		reportMessage.erase(location);
		reportMessage += va_arg(ap, char *);

		LogOutput(reportMessage.c_str());
	}
}

/**
Function to start logging.

@internalComponent
@released

@param aFileName - Name of the Log file
*/
void MessageImplementation::StartLogging(char *aFileName)
{
	char logFile[1024];
	FILE *fptr;

	strcpy(logFile,aFileName);

	// open file for log etc.
	if((fptr=fopen(logFile,"a"))==NULL)
	{
		ReportMessage(WARNING, FILEOPENERROR,aFileName);
	}
	else
	{
	    iLogging = true;
		iLogPtr=fptr;
	}
}

/**
Function to put Message string in map which is stored in message file.
If file is not available the put message in map from Message Array structure.

@internalComponent
@released

@param aFileName - Name of the Message file passed in
*/
void MessageImplementation::InitializeMessages()
{
	char *errStr;
	int i;

	for(i=0;i<MAX;i++)
	{
		errStr = new char[strlen(MessageArray[i].message) + 1];
		strcpy(errStr, MessageArray[i].message);
		iMessage.insert(std::pair<int,char*>(MessageArray[i].index,errStr));
	}
}
