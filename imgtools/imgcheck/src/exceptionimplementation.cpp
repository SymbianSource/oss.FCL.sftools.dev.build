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
* This class is used to log and/or display the error, warning and status
* messages. This is a sigleton class.
*
*/


/**
 @file
 @internalComponent
 @released
*/

#include "exceptionimplementation.h"

enum MessageArraySize{MAX=42};

/**
Message objects are created and these objects holds the error, warning and status
message required by imgcheck tool.

@internalComponent
@released
*/
struct Messages MessageArray[MAX]=
{
	{UNKNOWNIMAGETYPE, "Error: Image Type Unknown: '%s'"},
	{UNKNOWNPREFIX,"Error: Option has Un-Known Prefix: '%s'"},
	{VALUEEXPECTED,"Error: Value expected for option: '%s'"},
	{VALUENOTEXPECTED,"Error: Value not expected for option: '%s'"},
	{UNKNOWNOPTION,"Error: Unknown option: '%s'"},
	{QUIETMODESELECTED,"Error: Quiet mode selected while not generating XML report"},
	{NOIMAGE,"Error: No images specified in the input"},
	{NOROMIMAGE,"Warning: ROM image not passed"},
	{XMLOPTION,"Warning: XML file name specified while not generating XML report"},
	{NOMEMORY,"Error:%s:%d: Insuffient program memory"},
	{FILENAMETOOBIG,"Error:'%s':%d: Improper File Name Size"},
	{XMLNAMENOTVALID,"Error: Not a valid Xml File name"},
	{REPORTTYPEINVALID,"Error: Not a valid report type"},
	{FILEOPENFAIL,"Error:%s:%d: Cannot Open file: '%s'"},
	{XSLCREATIONFAILED,"Warning:%s:%d: Unable to Create XSL file: '%s'"},
	{UNEXPECTEDNUMBEROFVALUE, "Error: Unexpected number of values received for option: '%s'"},
	{INVALIDVIDVALUE, "Error: Invalid VID value: '%s'"},
	{UNKNOWNSUPPRESSVAL, "Error: Unknown suppress value: '%s'"},
	{ALLCHECKSSUPPRESSED, "Error: All Validations suppressed"},
	{SUPPRESSCOMBINEDWITHVIDVAL, "Warning: VID values received but VID validation suppressed"},
	{SIDALLCOMBINEDWITHSID, "Warning: --sidall option received but SID validation suppressed"},
	{DATAOVERFLOW, "Overflow: Input value '%s'"},
	{VALIDIMAGE, "Success: Image(s) are valid"},
	{IMAGENAMEALREADYRECEIVED, "Warning: Image '%s' passed in multiple times, first one is considered and rest are ignored."},
	{UNKNOWNDBGVALUE , "Error: Invalid value is passed to --dbg, expected values are TRUE or FALSE."},
	{ONLYSINGLEDIRECTORYEXPECTED , "Error: Only single directory should be passed as input when E32Input is enabled."},
	{INVALIDDIRECTORY , "Error: Invalid directory or E32 file received as E32Input."},
	{INCORRECTVALUES , "Warning: The status reported for Dependency and SID check may not be correct in E32 input mode."},
	{NOVALIDATIONSENABLED , "Error: No validations are enabled."},
	{NOEXEPRESENT, "Error: No valid executables are present"},
	{E32INPUTNOTEXIST, "Error: Invalid E32 input '%s'"},
	{VALIDE32INPUT, "Success: E32 executable(s) are validated"},
	// Add the New Error and warning messages above this line
	{GATHERINGDEPENDENCIES,"Gathering dependencies for '%s'"},
	{WRITINGINTOREPORTER,"'%s' Checker writing data into Reporter"},
	{COLLECTDEPDATA,"Collecting dependency data for '%s'"},
	{NOOFEXECUTABLES,"No of executables in '%s': %d"},
	{NOOFHEXECUTABLES,"No of hidden executables in '%s': %d"},
	{READINGIMAGE,"Reading image: '%s'"},
	{GATHERINGIDDATA,"Gathering %s data for '%s'"},
	{GENERATINGREPORT,"Generating '%s' Report"},
	{REPORTGENERATION,"Report generation %s"},
	//Add the new status informations below this line
	{NODISKSPACE,"Error: No enough disk space for %s"}
};

/**
Static variables used to construct singleton class are initialized

@internalComponent
@released
*/
unsigned int ExceptionImplementation::iCmdFlag = 0;
ExceptionImplementation* ExceptionImplementation::iInstance = KNull;

/**
Static function provides the way to get the instance of ExceptionImplementation
class. It takes aCmdFlag as argument, this argument contains the specified 
commandline options and this flag is used to display the status information to 
standard output upon receiving verbose mode flag.

@internalComponent
@released

@param aCmdFlag - has all the options received in commandline.

@return - returns the instance
*/
ExceptionImplementation* ExceptionImplementation::Instance(unsigned int aCmdFlag)
{
	if(iInstance == KNull)
	{
		iCmdFlag = aCmdFlag;
		iInstance = new ExceptionImplementation();
	}
	return iInstance;
}

/**
Static function to delete the instance.

@internalComponent
@released
*/
void ExceptionImplementation::DeleteInstance()
{
	DELETE(iInstance);
}

/**
Constructor opens the output stream and traverses through MessageArray objects to 
initialize iMessage map. This map is used later to log the messages.

@internalComponent
@released
*/
ExceptionImplementation::ExceptionImplementation()
:iMsgIndex(0)
{
	iLogStream.open(gLogFileName.c_str(),Ios::out);
	int i;
	for(i = 0; i < MAX; i++)
	{
		iMessage.insert(std::make_pair(MessageArray[i].iIndex,MessageArray[i].iMessage));
	}
}

/**
Destructor closes the output stream opened during construction.

@internalComponent
@released
*/
ExceptionImplementation::~ExceptionImplementation()
{
	iLogStream.close();
}

/**
Function returns the message equivalent to the recived enum value.

@internalComponent
@released

@param aMsgIndex - enum value
*/
String& ExceptionImplementation::Message(const int aMsgIndex)
{
	iMsgIndex = aMsgIndex;
	return iMessage[aMsgIndex];
}

/**
Function to log the error, warning and status information.
Irrespective of the messgae type all the messages are logged into the imgcheck 
logfile. The warning and error messages are needed to be displayed on the command
prompt always. But the status information is displayed at standard output only if
the verbose mode is selected by the user.

@internalComponent
@released

@param aMsgIndex - enum value
*/
void ExceptionImplementation::Log(const String aMsg)
{
	iLogStream <<  aMsg.c_str() << "\n";
    
	if(iCmdFlag & KVerbose)
	{
		cout << aMsg.c_str() << endl;
	}
}

/**
Function to report the error and warning information.
Irrespective of the messgae type all the messages are logged into the imgcheck 
logfile. The warning and error messages are needed to be displayed on the command
prompt always. 

@internalComponent
@released

@param aMsgIndex - enum value
*/
void ExceptionImplementation::Report(const String aMsg)
{
	iLogStream <<  aMsg.c_str() << "\n";
	if(aMsg.find("Success") != String::npos)
	{
		cout << aMsg.c_str() << endl;
	}
	else
	{
		cerr << aMsg.c_str() << endl;
	}
}
