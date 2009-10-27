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
* TESTE32INPUTNOCHECK.H
* TESTE32INPUTNOCHECK class declaration.
*
*/


#ifndef E32INPUTNOCHECKTEST_H
#define E32INPUTNOCHECKTEST_H

#ifdef _MSC_VER 
	#pragma warning(disable: 4786) 
	#pragma warning(disable: 4503) 
#endif

#include <cppunit/extensions/HelperMacros.h>

#include "TestCase.h"
#include "TestSuite.h"
#include "TestCaller.h"


class CTestE32InputNoCheck : public CPPUNIT_NS::TestFixture
{
	CPPUNIT_TEST_SUITE( CTestE32InputNoCheck );
	CPPUNIT_TEST( TestForRofsImageOutputforE32inputDbg );
	CPPUNIT_TEST( TestForRofsImageOutputforE32inputDbgTrue );
	CPPUNIT_TEST( TestForRofsImageOutputforE32inputDbgTrueandVID );
	CPPUNIT_TEST( TestForRofsImageOutputforE32inputDbgTrueandVIDSID );
	CPPUNIT_TEST( TestForRofsImageOutputforE32inputandNoCheck );
	CPPUNIT_TEST( TestForRofsImageOutputforE32inputandNoCheckforAll );
	CPPUNIT_TEST( TestForRofsImageOutputforE32inputandNoCheckforAll1 );
	CPPUNIT_TEST( TestForRofsImageOutputforSIDAlias );
	CPPUNIT_TEST( TestE32fileDbgFlag );
	CPPUNIT_TEST( TestEmptyDirectory );
	CPPUNIT_TEST( TestDirectoryforALL );
	CPPUNIT_TEST( TestForInValidE32Input );
	CPPUNIT_TEST_SUITE_END();

protected:

	void TestForRofsImageOutputforE32inputDbg();
	void TestForRofsImageOutputforE32inputDbgTrue();
	void TestForRofsImageOutputforE32inputDbgTrueandVID();
	void TestForRofsImageOutputforE32inputDbgTrueandVIDSID();
	void TestForRofsImageOutputforE32inputandNoCheck();
	void TestForRofsImageOutputforE32inputandNoCheckforAll();
	void TestForRofsImageOutputforE32inputandNoCheckforAll1();
	void TestForRofsImageOutputforSIDAlias();
	void TestE32fileDbgFlag();
	void TestEmptyDirectory();
	void TestDirectoryforALL();
	void TestForInValidE32Input();
};

#endif
