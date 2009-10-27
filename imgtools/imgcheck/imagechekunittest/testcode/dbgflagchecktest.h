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
* DBGFLAGCHECKTEST class declaration.
*
*/


#ifndef DBGFLAGCHECKTEST_H
#define DBGFLAGCHECKTEST_H

#ifdef _MSC_VER 
	#pragma warning(disable: 4786) 
	#pragma warning(disable: 4503) 
#endif

#include <cppunit/extensions/HelperMacros.h>

#include "TestCase.h"
#include "TestSuite.h"
#include "TestCaller.h"


class CTestDbgFlagCheck : public CPPUNIT_NS::TestFixture
{
	CPPUNIT_TEST_SUITE( CTestDbgFlagCheck );
	CPPUNIT_TEST( TestForRomImageforDbganddepVal );
	CPPUNIT_TEST( TestForRomImageforAllCheck );
	CPPUNIT_TEST( TestForRofsImageforAllCheck );
	CPPUNIT_TEST( TestForExtnRofsImageforAllCheck1 );
	CPPUNIT_TEST( TestForExtnRofsImageforAllCheck );
	CPPUNIT_TEST( TestForRomImageOutputforDbgValTure );
	CPPUNIT_TEST( TestForRomImageOutputforDbgValTureXML );
	CPPUNIT_TEST( TestForRomImageOutputforDbgValTureXMLlong );
	CPPUNIT_TEST( TestForRomImageforDbgandvidVal );
	CPPUNIT_TEST( TestForRomImageforDbgandsidVal );
	CPPUNIT_TEST_SUITE_END();

protected:

	void TestForRofsImageOutputforDbg();
	void TestForRomImageOutputforDbgValTure();
	void TestForRomImageOutputforDbgValTureXML();
	void TestForRomImageOutputforDbgValTureXMLlong();
	void TestForRomImageforDbgandvidVal();
	void TestForRomImageforDbgandsidVal();
	void TestForRomImageforDbganddepVal();
	void TestForRomImageforAllCheck();
	void TestForRofsImageforAllCheck();
	void TestForExtnRofsImageforAllCheck();
	void TestForExtnRofsImageforAllCheck1();
};

#endif
