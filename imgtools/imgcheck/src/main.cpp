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
* Begining of imgcheck tool.
*
*/


/**
 @file
 @internalComponent
 @released
*/

#include "imgcheckmanager.h"
#include "exceptionreporter.h"

/**
Global pointers declaration.

@internalComponent
@released
*/
CmdLineHandler* cmdInput = KNull;
ImgCheckManager* imgCheckerPtr = KNull;

/**
Function to delete the created instances

@internalComponent
@released
*/

void DeleteInstances()
{
	DELETE(imgCheckerPtr);
	DELETE(cmdInput);
}

/**
Main function for imgcheck Tool, invokes ImgCheckManager public functions
to carry out the validation and to generate report.

@internalComponent
@released

@param argc - commandline argument count
@param argv - argument variables

@return - returns Exit status success or failure
*/
int main(int argc,char* argv[])
{
	try
	{
		cmdInput = new CmdLineHandler();
		if(cmdInput == KNull)
		{
			throw ExceptionReporter(NOMEMORY, __FILE__, __LINE__);
		}
		ReturnType val = cmdInput->ProcessCommandLine(argc,argv);

		int ret = 0;
		switch(val)
		{
			case EQuit:
				ret = EXIT_SUCCESS;
				break;
	
			case ESuccess:
				imgCheckerPtr = new ImgCheckManager(cmdInput);
				if(imgCheckerPtr == KNull)
				{
					throw ExceptionReporter(NOMEMORY, __FILE__, __LINE__);
				}
				imgCheckerPtr->CreateObjects();
				imgCheckerPtr->Execute();
				imgCheckerPtr->FillReporterData();
				imgCheckerPtr->GenerateReport();
				break;
			
			case EFail:
				ret = EXIT_FAILURE;
				break;
		}
		DeleteInstances();
		ExceptionImplementation::DeleteInstance();
		return ret;
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		ExceptionImplementation::DeleteInstance();
		DeleteInstances();
		return EXIT_FAILURE;
	}
}
