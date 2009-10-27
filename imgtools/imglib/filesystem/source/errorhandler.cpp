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
* ErrorHandler class receives the message index and the message.
* Formats the error message using MessageHandler then writes the
* same into the log file and standard output.
* @internalComponent
* @released
*
*/

#include "errorhandler.h"
#include "messagehandler.h"

char *errMssgPrefix="FileSystem : Error:";
char *Gspace=" ";

/**
ErrorHandler constructor for doing common thing required for derived 
class functions.

In some error conditions aSubMessage is required to be passed. So overloaded 
constructor used here.

@internalComponent
@released

@param aMessageIndex - Message Index
@param aSubMessage - Should be displayed  with original message
@param aFileName - File name from where the error is thrown
@param aLineNumber - Line number from where the error is thrown
*/
ErrorHandler::ErrorHandler(int aMessageIndex, char* aSubMessage, char* aFileName, int aLineNumber)
                            :iSubMessage(aSubMessage), iFileName(aFileName), iLineNumber(aLineNumber)
{
	iMessageIndex = aMessageIndex;
	iMessage = errMssgPrefix;
	iMessage += Gspace;
}

/**
ErrorHandler constructor for doing common thing required for derived 
class functions.

@internalComponent
@released

@param aMessageIndex - Message Index
@param aFileName - File name from where the error is thrown
@param aLineNumber - Line number from where the error is thrown
*/
ErrorHandler::ErrorHandler(int aMessageIndex, char* aFileName, int aLineNumber)
                            : iFileName(aFileName), iLineNumber(aLineNumber)
{
	iMessageIndex = aMessageIndex;
	iMessage = errMssgPrefix;
	iMessage += Gspace;
}

/**
ErrorHandler destructor.

@internalComponent
@released
*/
ErrorHandler::~ErrorHandler()
{
	MessageHandler::CleanUp();
}

/**
Function to report the error

@internalComponent
@released
*/
void ErrorHandler::Report()
{
	char *tempMssg;
	char *errMessage;

	errMessage=MessageHandler::GetInstance()->GetMessageString(iMessageIndex);
	if(errMessage)
	{
		tempMssg = new char[strlen(errMessage) + strlen(iFileName.c_str()) + sizeof(int) + strlen(iSubMessage.c_str())];
		sprintf(tempMssg, errMessage, iFileName.c_str(), iLineNumber, iSubMessage.c_str());
		iMessage += tempMssg;
		MessageHandler::GetInstance()->Output(iMessage.c_str());
		delete[] tempMssg;
	}
}
