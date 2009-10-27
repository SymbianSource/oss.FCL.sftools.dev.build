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
#include "cmdlinehandlertest.h"

CPPUNIT_TEST_SUITE_REGISTRATION( CTestCmdHandler );

#include "depchecker.h"
#include "exceptionreporter.h"


/**
Test the cmdhandler output without providing any arguments.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestCmdHandler::TestWithEmptyArugument()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "test"};
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(0,argvect);
		if(val == EQuit)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		status = 0;
    }
	delete cmdInput;
	CPPUNIT_ASSERT(status != 0);
}


/**
Test the cmdhandler output by providing wrong option.
Note: Refer the code coverage output for percentage of check.
      Pass the unknown option. '-l'

@internalComponent
@released
*/
void CTestCmdHandler::TestWithWrongArugument()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker","-s=" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(2,argvect);
		if(val == ESuccess)
		{
			status = 0;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 1;
    }
	delete cmdInput;
	CPPUNIT_ASSERT(status != 0);
}


/**
Test the cmdhandler output by providing invalid image.
Note: Refer the code coverage output for percentage of check.
      Pass the invalid image. 'invalid.img'

@internalComponent
@released
*/
void CTestCmdHandler::TestWithInvalidImg()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker","S:/GT0415/cppunit/imgcheck_unittest/imgs/invalid.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(2,argvect);
		int x = 0;
		if(val == ESuccess)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
	CPPUNIT_ASSERT(status != 0);
}


/**
Test the cmdhandler output for getting the report flag.
Note: Refer the code coverage output for percentage of check.
      Pass the valid images.

@internalComponent
@released
*/
void CTestCmdHandler::TestWithGetReportFlag()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker","-a", "-q", "-x", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rom.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(5,argvect);
		unsigned int flag = cmdInput->ReportFlag();             
		if((flag & QuietMode) && (flag & KXmlReport) && (flag & KAll))
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
	CPPUNIT_ASSERT(status != 0);
}


/**
Test the cmdhandler output for getting the xml report name.
Note: Refer the code coverage output for percentage of check.
      Pass the valid images.

@internalComponent
@released
*/
void CTestCmdHandler::TestWithGetXmlReportName()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker","--all", "-o=test.xml", "--xml","--dep","--vid", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rom.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(7,argvect);
		String xmlName = cmdInput->XmlReportName();  
		if(xmlName == String("test.xml"))
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
	CPPUNIT_ASSERT(status != 0);
}


/**
Test the cmdhandler output by providing valid image without any options.
Note: Refer the code coverage output for percentage of check.
      Pass the valid image. 'rom.img'

@internalComponent
@released
*/
void CTestCmdHandler::TestWithValidImg()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker","S:/GT0415/cppunit/imgcheck_unittest/imgs/rom.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(2,argvect);
		if(val == ESuccess)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
	CPPUNIT_ASSERT(status != 0);
}


/**
Test the cmdhandler output by providing invalid option.
Note: Refer the code coverage output for percentage of check.
      Pass the invalid image. 'invalid.img'

@internalComponent
@released
*/
void CTestCmdHandler::TestWithInvalidOption()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker","---q","S:/GT0415/cppunit/imgcheck_unittest/imgs/rom.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == ESuccess)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}


/**
Test the cmdhandler output by help option.
Note: Refer the code coverage output for percentage of check.
      Pass the valid image. 'rom.img'

@internalComponent
@released
*/
void CTestCmdHandler::TestWithHelpOption()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker","-H" };	
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(2,argvect);
		if(val == EQuit)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
	CPPUNIT_ASSERT(status != 0);
}

/**
Test the cmdhandler output by passing vidlist long and suppress short options.
Note: Refer the code coverage output for percentage of check.
      Pass the valid image. 'rom.img'

@internalComponent
@released
*/
void CTestCmdHandler::TestWithVidlist_supressOption()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker","-x","--vidlist=0x70000001","-s=sid,dep","--vid","S:/GT0415/cppunit/imgcheck_unittest/imgs/rom.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(6,argvect);
		if(val == ESuccess)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
	CPPUNIT_ASSERT(status != 0);
}

/**
Test the cmdhandler output by passing vidlist short and suppress long option.
Note: Refer the code coverage output for percentage of check.
      Pass the valid image. 'rom.img'

@internalComponent
@released
*/
void CTestCmdHandler::TestWithVidlist_supressOption1()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker","--sid", "-x","--vidlist=1879048193","--SUPPRESS=dep","--all", "--vid","--output=tst","S:/GT0415/cppunit/imgcheck_unittest/imgs/rom.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(9,argvect);
		if(val == ESuccess)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
	CPPUNIT_ASSERT(status != 0);
}

/**
Test the cmdhandler output by passing all option.
Note: Refer the code coverage output for percentage of check.
      Pass the valid image. 'rom.img'

@internalComponent
@released
*/
void CTestCmdHandler::TestWithAllOption()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker","-x","--vidlist=0x70000001,0","--vid","--sid","--dep","--all","-o=c:\tst","S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img","S:/GT0415/cppunit/imgcheck_unittest/imgs/rom.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(10,argvect);
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output by provinding options but no input image.
Note: Refer the code coverage output for percentage of check.		

@internalComponent
@released
*/
void CTestCmdHandler::TestForValidateArgumentNoImage()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "-a", "--vidlist=0s20000001" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == ESuccess)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler by provinding quiet option when not generating the XML file.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestCmdHandler::TestForValidateArgument()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "-q", "-a", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(4,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler by provinding XML file name when not generating the XML report.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestCmdHandler::TestForValidateArgumentwithoutXMLoutput()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "-a", "-o=c:/report1", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(4,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler by provinding VID value but VID validation is suppressed.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestCmdHandler::TestForValidateArgumentwithVIDVALandVIDsuppressed()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "-s=vid", "--vidlist=0x70000001", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(4,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestCmdHandler::TestForValidateArgumentwithAllsuppressed()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "-s=dep,sid,vid", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestCmdHandler::TestForValidateArgumentwithValueExpected()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "-s", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestCmdHandler::TestForValidateArgumentwithValueUnExpected()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "-x=xyz", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestCmdHandler::TestForValidateArgumentwithValueExpectedareMore()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "-o=test,test1", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestCmdHandler::TestForwithoutInput()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(1,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestCmdHandler::TestVerbose()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "--verbose", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestCmdHandler::TestSIDALLOption()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "--sidall", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestCmdHandler::TestSIDALLandSuppressSIDOption()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "--sidall", "-s=sid", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(4,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestCmdHandler::TestUnknownOption()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "-j", "-b", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(4,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestCmdHandler::TestInvalidVidListOption()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "--vidlist=7000abcd", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding any image for invalid supression value.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestCmdHandler::TestInvalidSupressOption()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "--vid", "-s=abcd", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(4,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding enable option without any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestCmdHandler::TestEnableOption()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "--vid" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(2,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding vidlist with zero and any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestCmdHandler::TestVidListOptionwithZeroValue()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "--vidlist=0x0", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding vidlist with invalid value and any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestCmdHandler::TestVidListOptionwithinvalidValue()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "--vidlist=0xfffffffff", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding vidlist with invalid value and any image.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestCmdHandler::TestVidListOptionwithinvalidValue1()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "--vidlist=0x00ag,4294967299", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding dbg with invalid value and any image.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestCmdHandler::TestDbgOptionwithinvalidValue()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "--dbg=xyz", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding dbg with = but no value.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestCmdHandler::TestDbgOptionwithoutValue()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "--dbg=", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding e32input with = 
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestCmdHandler::Teste32inputOptionwithValue()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "--e32input=", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding e32input a image but not a E32 input.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestCmdHandler::Teste32inputOptionwithimg()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "--e32input", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding valid images along with e32input option
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestCmdHandler::Teste32inputOptionwithimg1()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rom.img", "--e32input" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(4,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding invalid e32input option.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestCmdHandler::Teste32inputOptionwithinvalidoption()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "S:/GT0415/cppunit/imgcheck_unittest/imgs/rofs1.img", "--e3input" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding invalid e32input option.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestCmdHandler::Teste32inputOptionwithinvalidoption1()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "S:/epoc32/release/armv5/udeb", "--e2input" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding = to -n otpions.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestCmdHandler::TestnocheckOptionwithinvalidoption()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "S:/epoc32/release/armv5/udeb", "-n=" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding = to --nocheck option.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestCmdHandler::TestnocheckOptionwithinvalidoption1()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "S:/epoc32/release/armv5/udeb", "--nocheck=" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding nocheck option with single '-'
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestCmdHandler::TestnocheckOptionwithinvalidoption2()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "S:/epoc32/release/armv5/udeb", "-nocheck" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding '--' to nocehck otpion
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestCmdHandler::TestnocheckOptionwithinvalidoption3()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "S:/epoc32/release/armv5/udeb", "--n" };
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding valid E32input but not enabling any validations.
Note: Refer the code coverage output for percentage of check.
		Pass the valid image.(rofs.img).

@internalComponent
@released
*/
void CTestCmdHandler::TestnocheckOptionwithNoChecksEnabled()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "--e32input", "S:/epoc32/release/armv5/udeb"};
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(3,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding valid E32input and ALL option but not enabling any validations
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestCmdHandler::TestnocheckOptionwithNoChecksEnabled1()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "--e32input", "S:/epoc32/release/armv5/udeb", "--all"};
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(4,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding E32input but no directory nor a E32 file.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestCmdHandler::TesttocheckOptionwithNoImgandE32input()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "--e32input"};
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(2,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}

/**
Test the cmdhandler output(xml) by provinding invalid option.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestCmdHandler::TesttocheckOptionPrefix()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "--"};
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(2,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}


/**
Test the cmdhandler output(xml) by provinding invalid option and no image.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestCmdHandler::TesttocheckInvalidOption()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "--sidalll"};
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(2,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}


/**
Test the cmdhandler output(xml) by provinding invalid option and no image.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestCmdHandler::TesttocheckInvalidOption1()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "--depp"};
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(2,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}


/**
Test the cmdhandler output(xml) by provinding invalid option and no image.
Note: Refer the code coverage output for percentage of check.

@internalComponent
@released
*/
void CTestCmdHandler::TesttocheckInvalidOption2()
{
	int status = 0;
	CmdLineHandler* cmdInput;
	try
	{
		char* argvect[] = { "imgchecker", "--e32inputt"};
		cmdInput = new CmdLineHandler();
		ReturnType val = cmdInput->ProcessCommandLine(2,argvect);
		if(val == EXIT_FAILURE)
		{
			status = 1;
		}
	}
    catch(ExceptionReporter& aExceptionReport)
	{
		aExceptionReport.Report();
		status = 0;
    }
	delete cmdInput;
}
