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
* IMAGECHECKERTEST class declaration.
*
*/


#ifndef IMAGECHECKERTEST_H
#define IMAGECHECKERTEST_H

#ifdef _MSC_VER 
	#pragma warning(disable: 4786) 
	#pragma warning(disable: 4503) 
#endif

#include <cppunit/extensions/HelperMacros.h>

#include "TestCase.h"
#include "TestSuite.h"
#include "TestCaller.h"


class CTestImageChecker : public CPPUNIT_NS::TestFixture
{
	CPPUNIT_TEST_SUITE( CTestImageChecker );
	CPPUNIT_TEST( TestForHiddenRomRofsImageOutput );
	CPPUNIT_TEST( TestForRofsImageOutput );
	CPPUNIT_TEST( TestForRomRofsImageOutputXml );
	CPPUNIT_TEST( TestForRomRofsImageOutputALL );
	CPPUNIT_TEST( TestForRomRofsImageOutputwithVIDVAL );
	CPPUNIT_TEST( TestForRomRofsImageOutputwithDepSuppressed );
	CPPUNIT_TEST( TestForExtnRomRofsImageOutput );
	CPPUNIT_TEST( TestForInvalidImageOutput );
	CPPUNIT_TEST( TestForRofsImagewithMissingDeps );
	CPPUNIT_TEST( TestForHiddenDLLRomRofsImageOutput );
	CPPUNIT_TEST( TestForRomImagewithSIDALLOutput );
	CPPUNIT_TEST_SUITE_END();

protected:

	void TestForRofsImageOutput();
	void TestForRomRofsImageOutputXml();
	void TestForRomRofsImageOutputALL();
	void TestForRomRofsImageOutputwithVIDVAL();	
	void TestForRomRofsImageOutputwithDepSuppressed();
	void TestForExtnRomRofsImageOutput();
	void TestForInvalidImageOutput();
	void TestForHiddenRomRofsImageOutput();
	void TestForRofsImagewithMissingDeps();
	void TestForHiddenDLLRomRofsImageOutput();
	void TestForRomImagewithSIDALLOutput();
};

#endif
