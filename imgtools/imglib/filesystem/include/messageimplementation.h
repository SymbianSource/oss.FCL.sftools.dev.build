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
* Message Implementation Class for FileSystem tool
* @internalComponent
* @released
*
*/



#ifndef MESSAGEIMPLEMENTATION_H
#define MESSAGEIMPLEMENTATION_H

#ifdef _MSC_VER 
	#pragma warning(disable: 4514) // unreferenced inline function has been removed
	#pragma warning(disable: 4702) // unreachable code
	#pragma warning(disable: 4710) // function not inlined
	#pragma warning(disable: 4786) // identifier was truncated to '255' characters in the debug information
	#pragma warning(disable: 4103) // used #pragma pack to change alignment
#endif

#include <map>
#include <string>
#include <stdarg.h>

typedef std::map<int,char*> Map;
typedef std::string String;

enum 
{ 
	ERROR = 0,
	WARNING,
	INFORMATION
};
/**
To include more error or warning messages, Just include the key word here and
write the key word contents into the Message array at ".cpp" file.
Then increase the Message array size by number of messages included
*/
enum 
{	FILEOPENERROR = 1,
	FILEREADERROR,
	FILEWRITEERROR,
	MEMORYALLOCATIONERROR,
	ENTRYCREATEMSG,
	BOOTSECTORERROR,
	BOOTSECTORCREATEMSG,
	BOOTSECTORWRITEMSG,
	FATTABLEWRITEMSG,
	IMAGESIZETOOBIG,
	NOENTRIESFOUND,
	EMPTYFILENAME,
	EMPTYSHORTNAMEERROR,
	CLUSTERERROR,
	ROOTNOTFOUND,
	UNKNOWNERROR
};


/**
Abstract base Class for Message Implementation.

@internalComponent
@released
*/
class Message
{
    public:
		virtual ~Message(){};
		// get error string from message file
		virtual char * GetMessageString(int errorIndex)=0;
		// display message to output device
		virtual void Output(const char *aName) =0;
		// start logging to a file
		virtual void StartLogging(char *fileName)=0;
		virtual void ReportMessage(int aMsgType, int aMsgIndex,...)=0;
		virtual void InitializeMessages()=0;
};

/**
Class for Message Implementation.

@internalComponent
@released
*/
class MessageImplementation : public Message
{
    public:
		MessageImplementation();
		~MessageImplementation();

		//override base class methods
		char* GetMessageString(int errorIndex);
		void Output(const char *aName);
		void LogOutput(const char *aString);
		void StartLogging(char *fileName);
		void ReportMessage(int aMsgType, int aMsgIndex,...);
		void InitializeMessages();
    private:

		bool iLogging;
		char* iLogFileName;
		FILE *iLogPtr;
		Map iMessage;
};

/**
Structure for Messages.

@internalComponent
@released
*/
struct EnglishMessage
{
	int index;
	char message[1024];
};

#endif //MESSAGEIMPLEMENTATION_H
