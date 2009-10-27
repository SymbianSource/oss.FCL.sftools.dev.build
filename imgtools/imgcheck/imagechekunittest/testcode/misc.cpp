/*
* Copyright (c) 2008-2009 Nokia Corporation and/or its subsidiary(-ies).
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
*
*/


#include <cppunit/config/SourcePrefix.h>
#include "misc.h"

CPPUNIT_TEST_SUITE_REGISTRATION( CTestMisc );

#include "depchecker.h"
#include "exceptionreporter.h"


/**
Test the misctest output(cmdline) by E32input with directory for DBG flag.
Note: Refer the code coverage output for percentage of check.


@internalComponent
@released
*/
void CTestMisc::TestForValidE32Input()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--e32input", "--dbg", "S:/GT0415/cppunit/imgcheck_unittest/imgs/executables/UseStaticDLL.exe"};
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(4,argvect);
		if(val == ESuccess)
		{
			imgCheckerPtr = new ImgCheckManager(cmdInput);
			imgCheckerPtr->CreateObjects();
			imgCheckerPtr->Execute();
            imgCheckerPtr->FillReporterData();
            imgCheckerPtr->GenerateReport();
		}
	}
	catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
	}
	DELETE(cmdInput);
	DELETE(imgCheckerPtr);
	delete cmdInput;
}

/**
Test the misctest output(cmdline) by provinding value E32 input directory for VID and DEP.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestMisc::TestForVidDep()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dep", "--vid", "--e32input", "S:/GT0415/cppunit/imgcheck_unittest/imgs/executables/helloworld.exe", "-x"};
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(6,argvect);
		if(val == ESuccess)
		{
			imgCheckerPtr = new ImgCheckManager(cmdInput);
			imgCheckerPtr->CreateObjects();
			imgCheckerPtr->Execute();
            imgCheckerPtr->FillReporterData();
            imgCheckerPtr->GenerateReport();
		}
	}
	catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
	}
	DELETE(cmdInput);
	DELETE(imgCheckerPtr);
	delete cmdInput;
}

/**
Test the misctest output(cmdline) by provinding and ELF input for Dbg flag TRUE expecting an error message.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestMisc::TestForValidELFInput()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dbg=true", "S:/GT0415/cppunit/imgcheck_unittest/imgs/input/HelloWorld.exe"};
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == ESuccess)
		{
			imgCheckerPtr = new ImgCheckManager(cmdInput);
			imgCheckerPtr->CreateObjects();
			imgCheckerPtr->Execute();
            imgCheckerPtr->FillReporterData();
            imgCheckerPtr->GenerateReport();
		}
	}
	catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
	}
	DELETE(cmdInput);
	DELETE(imgCheckerPtr);
	delete cmdInput;
}

/**
Test the misctest output(cmdline) by provinding extension rom image for Dbg flag TRUE.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestMisc::TestForValidExtnRomimage()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dbg=true", "S:/GT0415/cppunit/imgcheck_unittest/imgs/extrom1.img"};
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == ESuccess)
		{
			imgCheckerPtr = new ImgCheckManager(cmdInput);
			imgCheckerPtr->CreateObjects();
			imgCheckerPtr->Execute();
            imgCheckerPtr->FillReporterData();
            imgCheckerPtr->GenerateReport();
		}
	}
	catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
	}
	DELETE(cmdInput);
	DELETE(imgCheckerPtr);
	delete cmdInput;
}

/**
Test the misctest output(cmdline) by provinding extension image with Dbg flag true with VID enabled and disabled VID.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestMisc::TestForEnableandSuppress()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dbg=true", "--vid", "-s=sid,vid", "S:/GT0415/cppunit/imgcheck_unittest/imgs/extrom1.img"};
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(5,argvect);
		if(val == ESuccess)
		{
			imgCheckerPtr = new ImgCheckManager(cmdInput);
			imgCheckerPtr->CreateObjects();
			imgCheckerPtr->Execute();
            imgCheckerPtr->FillReporterData();
            imgCheckerPtr->GenerateReport();
		}
	}
	catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
	}
	DELETE(cmdInput);
	DELETE(imgCheckerPtr);
	delete cmdInput;
}


/**
Test the misctest output(cmdline) by valid E32input directory for SID, expecting the warning for SID
Note: Refer the code coverage output for percentage of check.


@internalComponent
@released
*/
void CTestMisc::TestForValidSid()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--sid", "S:/GT0415/cppunit/imgcheck_unittest/imgs/executables", "--e32input"};
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(4,argvect);
		if(val == ESuccess)
		{
			imgCheckerPtr = new ImgCheckManager(cmdInput);
			imgCheckerPtr->CreateObjects();
			imgCheckerPtr->Execute();
            imgCheckerPtr->FillReporterData();
            imgCheckerPtr->GenerateReport();
		}
	}
	catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
	}
	DELETE(cmdInput);
	DELETE(imgCheckerPtr);
	delete cmdInput;
}

