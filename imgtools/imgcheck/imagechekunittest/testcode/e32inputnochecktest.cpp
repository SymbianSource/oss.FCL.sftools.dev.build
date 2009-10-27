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
#include "e32inputnochecktest.h"

CPPUNIT_TEST_SUITE_REGISTRATION( CTestE32InputNoCheck );

#include "depchecker.h"
#include "exceptionreporter.h"


/**
Test the E32 Input results by provinding  directory with valid E32executables and check for the DBG flag to be false by default.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestE32InputNoCheck::TestForRofsImageOutputforE32inputDbg()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dbg", "--e32input", "S:/GT0415/cppunit/imgcheck_unittest/imgs/executables" };
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
Test the E32 Input results by provinding  directory with valid E32executables and check for the DBG flag to be true
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestE32InputNoCheck::TestForRofsImageOutputforE32inputDbgTrue()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dbg=true", "--e32input", "S:/GT0415/cppunit/imgcheck_unittest/imgs/executables", "-x" };
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
Test the E32 Input results by provinding  directory with valid E32executables and check for the DBG flag to be true along with VID check
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestE32InputNoCheck::TestForRofsImageOutputforE32inputDbgTrueandVID()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dbg=true", "--vid", "--all", "--e32input", "S:/GT0415/cppunit/imgcheck_unittest/imgs/executables" };
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
Test the E32 Input results by provinding  directory with valid E32executables and check for the DBG flag to be true along with VID & SID check
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestE32InputNoCheck::TestForRofsImageOutputforE32inputDbgTrueandVIDSID()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dbg=true", "--vid", "--all", "--sid", "--sidall", "--e32input", "S:/GT0415/cppunit/imgcheck_unittest/imgs/executables" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(8,argvect);
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
Test the E32 Input results by provinding  directory with valid E32executables and check for the DBG flag to be true along with VID & SID ALL checks
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestE32InputNoCheck::TestForRofsImageOutputforE32inputandNoCheck()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dbg=true", "--vid", "--all", "--sid", "--sidall", "--e32input", "S:/GT0415/cppunit/imgcheck_unittest/imgs/executables", "-n" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(9,argvect);
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
Test the E32 Input results by provinding  directory with valid E32executables and check for the DBG flag to be true along with VID, DEP, SID ALL checks
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestE32InputNoCheck::TestForRofsImageOutputforE32inputandNoCheckforAll()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dbg=true", "--vid", "--all", "--sid", "--sidall", "--e32input", "S:/GT0415/cppunit/imgcheck_unittest/imgs/executables", "-n" ,"--dep" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(10,argvect);
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
Test the E32 Input results by provinding  directory with valid E32executables and check for the DBG flag to be true along with VID, SID, DEP with Nocheck
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestE32InputNoCheck::TestForRofsImageOutputforE32inputandNoCheckforAll1()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dbg=true", "--vid", "--sid", "--sidall", "--e32input", "S:/GT0415/cppunit/imgcheck_unittest/imgs/executables", "--nocheck" ,"--dep" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(9,argvect);
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
Test the SID and SIDALL wby providing alias image .
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestE32InputNoCheck::TestForRofsImageOutputforSIDAlias()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--sid", "--sidall","-a",   "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofseg.img"};
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
Test E32 File for DBG flag to be true in verbose mode
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestE32InputNoCheck::TestE32fileDbgFlag()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--e32input", "--dbg=true", "-a",   "S:/GT0415/cppunit/imgcheck_unittest/imgs/executables/HelloWorld.exe", "--verbose"};
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
Test the E32 input with an empty folder as an input
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestE32InputNoCheck::TestEmptyDirectory()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--e32input", "--dbg=true", "-a",   "S:/GT0415/cppunit/imgcheck_unittest/imgs/empty"};
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
Test E32 input with a valid directory for ALL DBG checks
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestE32InputNoCheck::TestDirectoryforALL()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--e32input", "--dbg=true", "-a",   "S:/GT0415/cppunit/imgcheck_unittest/imgs/executables"};
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
Test with invalid e32 input for DBG flag cehck.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestE32InputNoCheck::TestForInValidE32Input()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--e32input", "--dbg=true",    "S:/GT0415/cppunit/imgcheck_unittest/imgs/input/imgcheck.log"};
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

