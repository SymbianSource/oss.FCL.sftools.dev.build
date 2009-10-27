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
* CMDLINEHANDLERTEST.CPP
* Unittest cases for command line handler file.
* Note : Tested by passing different images.
*
*/


/**
 @file
 @internalComponent
 @released
*/
#include <cppunit/config/SourcePrefix.h>
#include "imagecheckertest.h"

CPPUNIT_TEST_SUITE_REGISTRATION( CTestImageChecker );

#include "depchecker.h"
#include "exceptionreporter.h"


/**
Test the imagechecker output(cmdline) by provinding any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestImageChecker::TestForRofsImageOutput()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;

	try
	{
		char* argvect[] = { "imgchecker", "--verbose", "-s=dep", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
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
Test the imagechecker output(xml) by provinding any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestImageChecker::TestForRomRofsImageOutputXml()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;
	try
	{
		char* argvect[] = { "imgchecker", "-q", "-x", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rom.img", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
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
Test the imagechecker output(xml) by provinding any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestImageChecker::TestForRomRofsImageOutputALL()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;
	try
	{
		char* argvect[] = { "imgchecker", "-o=S:\\GT0415\\cppunit\\imgcheck_unittest\\imgs\\test", "-x", "--all","-s=vid", "--sid", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rom.img", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
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
Test the imagechecker output(xml) by provinding any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestImageChecker::TestForRomRofsImageOutputwithVIDVAL()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;
	try
	{
		char* argvect[] = { "imgchecker", "-v", "-o=S:/GT0415/cppunit/imgcheck_unittest/imgs/test2", "-x", "-a","--vidlist=0x70000001", "--vid", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rom.img", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
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
Test the imagechecker output(xml) by provinding any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestImageChecker::TestForRomRofsImageOutputwithDepSuppressed()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;
	try
	{
		char* argvect[] = { "imgchecker", "-o=test", "-x", "-a","--vidlist=0X700EF001", "--vid", "--sid", "--suppress=dep", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rom.img", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
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
Test the imagechecker output(xml) by provinding any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestImageChecker::TestForExtnRomRofsImageOutput()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;
	try
	{
		char* argvect[] = { "imgchecker", "-o=test", "-x", "-a","--vidlist=0x70000001", "--vid", "--sid", "-s=vid", "S:/GT0415/cppunit/imgcheck_unittest/imgs/extrom.img", "S:/GT0415/cppunit/imgcheck_unittest/imgs/extrom1.img", "S:/GT0415/cppunit/imgcheck_unittest/imgs/extrofs.img", "S:/GT0415/cppunit/imgcheck_unittest/imgs/extrofs1.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(12,argvect);
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
Test the imagechecker output(xml) by provinding any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestImageChecker::TestForInvalidImageOutput()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;
	try
	{
		char* argvect[] = { "imgchecker", "S:/GT0415/cppunit/imgcheck_unittest/imgs/invalid.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(2,argvect);
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
Test the imagechecker output(xml) by provinding any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestImageChecker::TestForHiddenRomRofsImageOutput()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;
	try
	{
		char* argvect[] = { "imgchecker", "-x", "-a", "S:/GT0415/cppunit/imgcheck_unittest/imgs/hideexe_staticdll_rofs1.img", "S:/GT0415/cppunit/imgcheck_unittest/imgs/hideexe_staticdll_rom.img", "S:/GT0415/cppunit/imgcheck_unittest/imgs/hideexe_staticdll_rofs.img", "S:/GT0415/cppunit/imgcheck_unittest/imgs/hideexe_staticdll_rofs1.img" };
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
	ExceptionImplementation::DeleteInstance();
}

/**
Test the imagechecker output(xml) by provinding any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestImageChecker::TestForRofsImagewithMissingDeps()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;
	try
	{
		char* argvect[] = { "imgchecker", "-x", "--dep", "--verbose", "S:/GT0415/cppunit/imgcheck_unittest/imgs/missingdll_rofs1.img" };
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
}


/**
Test the imagechecker output(xml) by provinding any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestImageChecker::TestForHiddenDLLRomRofsImageOutput()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;
	try
	{
		char* argvect[] = { "imgchecker", "-x", "--dep", "-v", "S:/GT0415/cppunit/imgcheck_unittest/imgs/hidedll-rom.img" };
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
}

/**
Test the imagechecker output(xml) by provinding any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestImageChecker::TestForRomImagewithSIDALLOutput()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	ImgCheckManager* imgCheckerPtr;
	try
	{
		char* argvect[] = { "imgchecker", "-x", "-q", "--sidall", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
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
}
