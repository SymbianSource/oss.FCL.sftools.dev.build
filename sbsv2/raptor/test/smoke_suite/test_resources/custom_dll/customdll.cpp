/*
* Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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
* This program creates a custom dll.
*
*/


#include "customdll.h"
#include <e32uid.h>

// construct/destruct

#if !defined(__ARMCC_4__) and !defined(__X86__)
extern "C" void __ARM_switch8();

void sbs_test()
	{
	__ARM_switch8();
	}
#endif

EXPORT_C CCustomDll* CCustomDll::NewLC(CConsoleBase& aConsole, const TDesC& aString)
	{
	CCustomDll* self=new (ELeave) CCustomDll(aConsole);
	CleanupStack::PushL(self);
	self->ConstructL(aString);
	return self;
	}

CCustomDll::~CCustomDll() // destruct - virtual, so no export
	{
	delete iString;
	}

EXPORT_C void CCustomDll::ShowMessage()
	{
	_LIT(KFormat1,"%S\n");
	iConsole.Printf(KFormat1, iString); // notify completion
	}

// constructor support
// don't export these, because used only by functions in this DLL, eg our NewLC()

CCustomDll::CCustomDll(CConsoleBase& aConsole) // first-phase C++ constructor
	: iConsole(aConsole)
	{
	}

void CCustomDll::ConstructL(const TDesC& aString) // second-phase constructor
	{
	iString=aString.AllocL(); // copy given string into own descriptor
    }

