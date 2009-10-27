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
#include "dbgflagchecktest.h"

CPPUNIT_TEST_SUITE_REGISTRATION( CTestDbgFlagCheck );

#include "depchecker.h"
#include "exceptionreporter.h"


/**
Test the dbgflagchecker output(cmdline) by provinding any image.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestDbgFlagCheck::TestForRofsImageOutputforDbg()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dbg", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
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
	ExceptionImplementation::DeleteInstance();
	delete cmdInput;
}


/**
Test the dbgflagchecker output(cmdline) by provinding any image for Dbg value TRUE.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestDbgFlagCheck::TestForRomImageOutputforDbgValTure()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dbg=true", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rom.img"};
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
Test the dbgflagchecker output(XML) by provinding any image with Dbg value TRUE and quite mode.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestDbgFlagCheck::TestForRomImageOutputforDbgValTureXML()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dbg=true", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rom.img", "-x", "--quiet"};
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
Test the dbgflagchecker output(XML) by provinding any image with Dbg value TRUE and quite mode.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestDbgFlagCheck::TestForRomImageOutputforDbgValTureXMLlong()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dbg=true", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rom.img", "--xml", "--quiet"};
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
Test the dbgflagchecker output(cmdline) by provinding any image for Dbg value true and VID check.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestDbgFlagCheck::TestForRomImageforDbgandvidVal()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dbg=true", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rom.img", "--vid"};
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
Test the dbgflagchecker output(cmdline) by provinding any image Dbg value true and SID check.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestDbgFlagCheck::TestForRomImageforDbgandsidVal()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dbg=true", "S:/GT0415/cppunit/imgcheck_unittest/imgs/alias.img", "--sid", "--sidall"};
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
Test the dbgflagchecker output(cmdline) by provinding any image Dbg value TRUE and DEP check.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestDbgFlagCheck::TestForRomImageforDbganddepVal()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dbg=true", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img", "--dep"};
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
	ExceptionImplementation::DeleteInstance();	
	delete cmdInput;
}

/**
Test the dbgflagchecker output(cmdline) by provinding any image for Dbg value TRUE and ALL checks.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestDbgFlagCheck::TestForRomImageforAllCheck()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dbg=true", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img", "--dep", "--vid", "--sid", "--all"};
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(7,argvect);
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
Test the dbgflagchecker output(cmdline) by provinding any image for Dbg value TRUE and ALL checks with verbose.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestDbgFlagCheck::TestForRofsImageforAllCheck()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dbg=true", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img", "--dep", "--vid", "--sid", "--all", "--verbose"};
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
Test the dbgflagchecker output(cmdline) by provinding any Extension image for Dbg value TRUE and VID and SID checks..
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestDbgFlagCheck::TestForExtnRofsImageforAllCheck()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dbg=true", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofseg.img", "S:/GT0415/cppunit/imgcheck_unittest/imgs/extrofs.img",  "--verbose", "--vid", "--sid", "--all"};
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
Test the dbgflagchecker output(cmdline) by provinding multiple rofs image for Dbg value FALSE.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestDbgFlagCheck::TestForExtnRofsImageforAllCheck1()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--dbg=false", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img"};
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
	ExceptionImplementation::DeleteInstance();
	delete cmdInput;
}
