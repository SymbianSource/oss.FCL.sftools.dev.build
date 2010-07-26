/*
* Copyright (c) 2006-2010 Nokia Corporation and/or its subsidiary(-ies).
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
* e32test\dll\t_oeexport.cpp*
*/


/**

Overview:

	Tests it is possible to retrieve the 0th ordinal from exes and dlls

	that are marked as having named symbol export data.  This is loaded

	as non-XIP so loader fixups of 0th ordinal imports can be tested



API Information:

	RProcess, RLibrary



Details:

	- 	Test reading 0th ordinal from a dll which has a E32EpocExpSymInfoHdr 

		struct at the 0th ordinal and verify the contents of the header

	-	Test attempts to get the 0th ordinal from a dll without the named symbol 

		data returns NULL

	-	Test reading the named symbol data from an exe that contains a

		E32EpocExpSymInfoHdr struct at the 0th ordinal and verify the contents

	-	Test import fixups has correctly fixed up the 0th ordinal of the static

		dependencies to this stdexe

	-	Test NULL is returned when attempting to read the 0th ordinal of

		an exe that doesn't contain a E32EpocExpSymInfoHdr



Platforms/Drives/Compatibility:

	All



Assumptions/Requirement/Pre-requisites:



	

Failures and causes:

	

	

Base Port information:



*/



#include <t_oedll.h>

#ifndef __SYMBIAN_STDCPP_SUPPORT__
#error __SYMBIAN_STDCPP_SUPPORT__ should be defined for all STD* TARGETTYPE builds
#endif


TInt E32Main()

	{

	return KErrNone;

	}

