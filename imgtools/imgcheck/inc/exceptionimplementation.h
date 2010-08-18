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
* @internalComponent
* @released
*
*/


#ifndef EXCEPTIONIMPLEMENTATION_H
#define EXCEPTIONIMPLEMENTATION_H

#include "common.h"

typedef map<int,string> IndexVsMessageMap;
const unsigned int KMAXWARNINGSORERROR = 100;

/**
To include more error or warning messages, Just include the key word here and
write the key word contents into the Message array at ".cpp" file.
Then increase the Message array MAX size by number of messages included

@internalComponent
@released
*/
enum
{
	UNKNOWNIMAGETYPE = 1,
	UNKNOWNPREFIX,
	VALUEEXPECTED,
	VALUENOTEXPECTED,
	UNKNOWNOPTION,
	QUIETMODESELECTED,
	NOIMAGE,
	NOROMIMAGE,
	XMLOPTION,
	NOMEMORY,
	FILENAMETOOBIG,
	XMLNAMENOTVALID,
	REPORTTYPEINVALID,
	FILEOPENFAIL,
	XSLCREATIONFAILED,
	UNEXPECTEDNUMBEROFVALUE,
	INVALIDVIDVALUE,
	UNKNOWNSUPPRESSVAL,
	ALLCHECKSSUPPRESSED,
	SUPPRESSCOMBINEDWITHVIDVAL,
	SIDALLCOMBINEDWITHSID,
	DATAOVERFLOW,
	VALIDIMAGE,
	IMAGENAMEALREADYRECEIVED,
	UNKNOWNDBGVALUE,
	ONLYSINGLEDIRECTORYEXPECTED,
	INVALIDDIRECTORY,
	INCORRECTVALUES,
	NOVALIDATIONSENABLED,
	NOEXEPRESENT,
	E32INPUTNOTEXIST,
	VALIDE32INPUT,
	// Add the New Error and warning messages above this line
	GATHERINGDEPENDENCIES = 101,
	WRITINGINTOREPORTER,
	COLLECTDEPDATA,
	NOOFEXECUTABLES,
	NOOFHEXECUTABLES,
	READINGIMAGE,
	GATHERINGIDDATA,
	GENERATINGREPORT,
	REPORTGENERATION,
	//Add the new status informations below this line
	NODISKSPACE
};

/**
Structure for Messages.

@internalComponent
@released
*/
struct Messages
{
	int iIndex;
	char* iMessage;
};

/**
Class Exception implementation.

@internalComponent
@released
*/
class ExceptionImplementation
{
public:
	static ExceptionImplementation* Instance(unsigned int aCmdFlag);
	static void DeleteInstance(void);
	string& Message(int aMsgIndex);
	void Log(const string aMsg);
	void Report(const string aMsg);
	
private:
	ofstream iLogStream;
	IndexVsMessageMap iMessage;
	unsigned int iMsgIndex;
	static unsigned int iCmdFlag;
	static ExceptionImplementation* iInstance;
	ExceptionImplementation(void);
	~ExceptionImplementation(void);
};

#endif //EXCEPTIONIMPLEMENTATION_H
