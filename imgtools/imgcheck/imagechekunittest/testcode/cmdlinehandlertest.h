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
* CMDLINEHANDLERTEST class declaration.
*
*/


#ifndef CMDLINEHANDLERTEST_H
#define CMDLINEHANDLERTEST_H

#ifdef _MSC_VER 
	#pragma warning(disable: 4786) 
	#pragma warning(disable: 4503) 
#endif

#include <cppunit/extensions/HelperMacros.h>

#include "TestCase.h"
#include "TestSuite.h"
#include "TestCaller.h"


class CTestCmdHandler : public CPPUNIT_NS::TestFixture
{
	CPPUNIT_TEST_SUITE( CTestCmdHandler );
	CPPUNIT_TEST( TestWithEmptyArugument );
	CPPUNIT_TEST( TestWithWrongArugument );
	CPPUNIT_TEST( TestWithInvalidImg );
	CPPUNIT_TEST( TestWithGetReportFlag );
	CPPUNIT_TEST( TestWithGetXmlReportName );
	CPPUNIT_TEST( TestWithValidImg );
	CPPUNIT_TEST( TestWithHelpOption );
	CPPUNIT_TEST( TestWithInvalidOption );
	CPPUNIT_TEST( TestWithVidlist_supressOption );
	CPPUNIT_TEST( TestWithVidlist_supressOption1 );
	CPPUNIT_TEST( TestWithAllOption );
	CPPUNIT_TEST( TestForValidateArgumentNoImage );
	CPPUNIT_TEST( TestForValidateArgument );
	CPPUNIT_TEST( TestForValidateArgumentwithoutXMLoutput );
	CPPUNIT_TEST( TestForValidateArgumentwithVIDVALandVIDsuppressed );
	CPPUNIT_TEST( TestForValidateArgumentwithAllsuppressed );
	CPPUNIT_TEST( TestForValidateArgumentwithValueExpected );
	CPPUNIT_TEST( TestForValidateArgumentwithValueUnExpected );
	CPPUNIT_TEST( TestForwithoutInput );
	CPPUNIT_TEST( TestForValidateArgumentwithValueExpectedareMore );
	CPPUNIT_TEST( TestVerbose );
	CPPUNIT_TEST( TestSIDALLOption );
	CPPUNIT_TEST( TestSIDALLandSuppressSIDOption );
	CPPUNIT_TEST( TestUnknownOption );
	CPPUNIT_TEST( TestInvalidVidListOption );
	CPPUNIT_TEST( TestInvalidSupressOption );
	CPPUNIT_TEST( TestEnableOption );
	CPPUNIT_TEST( TestVidListOptionwithZeroValue );
	CPPUNIT_TEST( TestVidListOptionwithinvalidValue );
	CPPUNIT_TEST( TestVidListOptionwithinvalidValue1 );
	CPPUNIT_TEST( TestDbgOptionwithinvalidValue );
	CPPUNIT_TEST( TestDbgOptionwithoutValue );
	CPPUNIT_TEST( Teste32inputOptionwithValue );
	CPPUNIT_TEST( Teste32inputOptionwithimg );
	CPPUNIT_TEST( Teste32inputOptionwithimg1 );
	CPPUNIT_TEST( Teste32inputOptionwithinvalidoption );
	CPPUNIT_TEST( Teste32inputOptionwithinvalidoption1 );
	CPPUNIT_TEST( TestnocheckOptionwithinvalidoption );
	CPPUNIT_TEST( TestnocheckOptionwithinvalidoption1 );
	CPPUNIT_TEST( TestnocheckOptionwithinvalidoption2 );
	CPPUNIT_TEST( TestnocheckOptionwithinvalidoption3 );
	CPPUNIT_TEST( TestnocheckOptionwithNoChecksEnabled );
	CPPUNIT_TEST( TestnocheckOptionwithNoChecksEnabled1 );
	CPPUNIT_TEST( TesttocheckOptionwithNoImgandE32input );
	CPPUNIT_TEST( TesttocheckOptionPrefix );
	CPPUNIT_TEST( TesttocheckInvalidOption );
	CPPUNIT_TEST( TesttocheckInvalidOption1 );
	CPPUNIT_TEST( TesttocheckInvalidOption2 );
	CPPUNIT_TEST_SUITE_END();

	protected:

		void TestWithEmptyArugument();
		void TestWithWrongArugument();
		void TestWithInvalidImg();
		void TestWithGetReportFlag();
		void TestWithGetXmlReportName();
		void TestWithValidImg();
		void TestWithHelpOption();
		void TestWithInvalidOption();
		void TestWithVidlist_supressOption();
		void TestWithVidlist_supressOption1();
		void TestWithAllOption();
		void TestForValidateArgumentNoImage();
		void TestForValidateArgument();
		void TestForValidateArgumentwithoutXMLoutput();
		void TestForValidateArgumentwithVIDVALandVIDsuppressed();
		void TestForValidateArgumentwithAllsuppressed();
		void TestForValidateArgumentwithValueExpected();
		void TestForValidateArgumentwithValueUnExpected();
		void TestForwithoutInput();
		void TestForValidateArgumentwithValueExpectedareMore();
		void TestVerbose();
		void TestSIDALLOption();
		void TestSIDALLandSuppressSIDOption();
		void TestUnknownOption();
		void TestInvalidVidListOption();
		void TestInvalidSupressOption();
		void TestEnableOption();
		void TestVidListOptionwithZeroValue();
		void TestVidListOptionwithinvalidValue();
		void TestVidListOptionwithinvalidValue1();
		void TestDbgOptionwithinvalidValue();
		void TestDbgOptionwithoutValue();
		void Teste32inputOptionwithValue();
		void Teste32inputOptionwithimg();
		void Teste32inputOptionwithimg1();
		void Teste32inputOptionwithinvalidoption();
		void Teste32inputOptionwithinvalidoption1();
		void TestnocheckOptionwithinvalidoption();
		void TestnocheckOptionwithinvalidoption1();
		void TestnocheckOptionwithinvalidoption2();
		void TestnocheckOptionwithinvalidoption3();
		void TestnocheckOptionwithNoChecksEnabled();
		void TestnocheckOptionwithNoChecksEnabled1();
		void TesttocheckOptionwithNoImgandE32input();
		void TesttocheckOptionPrefix();
		void TesttocheckInvalidOption();
		void TesttocheckInvalidOption1();
		void TesttocheckInvalidOption2();
};

#endif
