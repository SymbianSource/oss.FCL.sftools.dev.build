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
* MISCCHECKS class declaration.
*
*/


#ifndef MISCCHECKS_H
#define MISCCHECKS_H

#ifdef _MSC_VER 
	#pragma warning(disable: 4786) 
	#pragma warning(disable: 4503) 
#endif

#include <cppunit/extensions/HelperMacros.h>

#include "TestCase.h"
#include "TestSuite.h"
#include "TestCaller.h"


class CTestMisc : public CPPUNIT_NS::TestFixture
{
	CPPUNIT_TEST_SUITE( CTestMisc );
	CPPUNIT_TEST( TestForValidE32Input );
	CPPUNIT_TEST( TestForVidDep );
	CPPUNIT_TEST( TestForValidELFInput );
	CPPUNIT_TEST( TestForValidExtnRomimage );
	CPPUNIT_TEST( TestForEnableandSuppress );
	CPPUNIT_TEST( TestForValidSid );
	CPPUNIT_TEST_SUITE_END();

protected:

	void TestForValidE32Input();
	void TestForVidDep();
	void TestForValidELFInput();
	void TestForValidExtnRomimage();
	void TestForEnableandSuppress();
	void TestForValidSid();
};

#endif
