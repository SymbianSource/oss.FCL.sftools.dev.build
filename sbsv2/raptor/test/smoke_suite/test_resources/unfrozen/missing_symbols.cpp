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
* This program creates a dll.
*
*/


#include "unfrozensymbols.h"
#include <e32uid.h>

#include "../inc/macrotests.h"

extern "C" {
EXPORT_C TInt test_dll(void)
{
	return 0;
}
}

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

//*This is commented out to provide a source file with a missing export for    *
//*test: dll_armv5_winscw_freeze.py (parts b & c)                              *
//
//EXPORT_C void CMessenger::ShowMessage()
//	{
//	_LIT(KFormat1,"%S\n");
//	iConsole.Printf(KFormat1, iString); // notify completion
//	}

EXPORT_C void CMessenger::ShowMessage2()
	{
	_LIT(KFormat1,"%S\n");
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

