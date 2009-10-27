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
* This class is used to receive the enum index of the original 
* message with some more variable arguments. These variable 
* arguments are split and put into the original message.
*
*/


/**
 @file
 @internalComponent
 @released
*/

#include "exceptionreporter.h"
#include "utils.h"

/** 
Constructor receives the variable arguements and gets the instance 
of MessageImplementation class. Invokes GetMessage to get the 
original message. Find %d and %s inside the original message and
replace these specifiers with the received variable argument value.

@internalComponent
@released

@param aMsgIndex - an enum index to get original message from 
MessageImplementation class
@param ... - variable arguments.
*/
ExceptionReporter::ExceptionReporter(int aMsgIndex, ...)
{
	iExcepImplPtr = ExceptionImplementation::Instance(0);
	iMessage = iExcepImplPtr->Message(aMsgIndex);
	int fileNameIndex = 0;
	if(iMessage.length() > 0)
	{
		va_list argList;
		va_start(argList,aMsgIndex);
		
		int intVal;
		String strVal;
		
		unsigned int index = iMessage.find("%");
		String subStr = iMessage.substr(index + 1);//skip '%'
		while( index != String::npos )
		{
			switch(iMessage.at(index + 1)) 
			{
				case 'd':
					intVal = va_arg(argList, int);
					iMessage.erase(index, 2);//delete two characters "%d"
					iMessage.insert(index, ReaderUtil::IntToAscii(intVal, EBase10));
					break;
				case 's':
					strVal.assign(va_arg(argList, char*));
					#ifdef __TOOLS2__
					fileNameIndex = strVal.find_last_of('\\');
					++fileNameIndex;
					#endif 
					#ifdef __LINUX__
					fileNameIndex = strVal.find_last_of('/'); //Remove the 
					++fileNameIndex;
					#endif
					strVal = (index != String::npos)? strVal.substr(fileNameIndex) : strVal;
					iMessage.erase(index, 2); //delete two characters "%s"
					iMessage.insert(index, strVal);
					break;
			}
			index = iMessage.find("%");
		}
	}
}


/** 
Destructor. 

@internalComponent
@released
*/
ExceptionReporter::~ExceptionReporter()
{
}


/**
Invokes the Log function of ExceptionImplementation, which puts the 
data into logfile directly and takes decision whether to put the same 
on standard output or not.

@internalComponent
@released
*/
void ExceptionReporter::Log(void) const
{
	iExcepImplPtr->Log(iMessage);
}

/**
Invokes the Report function of ExceptionImplementation to report error or warning.

@internalComponent
@released
*/
void ExceptionReporter::Report(void) const
{
	iExcepImplPtr->Report(iMessage);
}
