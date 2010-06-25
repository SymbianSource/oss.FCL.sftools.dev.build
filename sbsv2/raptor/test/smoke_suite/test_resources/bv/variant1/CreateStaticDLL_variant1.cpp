/*
* Copyright (c) 2000-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* CreateStaticDLL.cpp
* This program creates a dll.
*
*/


#include "CreateStaticDLL_variant1.h"
#include <e32uid.h>

// construct/destruct

EXPORT_C CMessenger* CMessenger::NewLC(CConsoleBase& aConsole, const TDesC& aString)
	{
	CMessenger* self=new (ELeave) CMessenger(aConsole);
	CleanupStack::PushL(self);
	self->ConstructL(aString);
	return self;
	}

CMessenger::~CMessenger() // destruct - virtual, so no export
	{
	delete iString;
	}

EXPORT_C void CMessenger::ShowMessage()
	{
#ifdef A_3
// use a builtin macro to test a cpp defect
#ifdef __FILE__
	_LIT(KFormat1,"A_3 %S\n");
#endif
#else
// use a builtin macro to test a cpp defect
#ifdef __LINE__
	_LIT(KFormat1,"not A_3 %S\n");
#endif
#endif
	iConsole.Printf(KFormat1, iString); // notify completion
	}

// constructor support
// don't export these, because used only by functions in this DLL, eg our NewLC()

CMessenger::CMessenger(CConsoleBase& aConsole) // first-phase C++ constructor
	: iConsole(aConsole)
	{
	}

void CMessenger::ConstructL(const TDesC& aString) // second-phase constructor
	{
	iString=aString.AllocL(); // copy given string into own descriptor
    }
