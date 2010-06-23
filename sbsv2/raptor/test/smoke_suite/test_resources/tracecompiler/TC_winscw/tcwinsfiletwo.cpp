/*
* Copyright (c) 2000-2010 Nokia Corporation and/or its subsidiary(-ies).
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


#include "tcwinsfiletwo.h"
#include <e32uid.h>
#include "OstTraceDefinitions.h"
#ifdef OST_TRACE_COMPILER_IN_USE
#include "tcwinsfiletwoTraces.h"
#endif


// construct/destruct


extern "C" void __ARM_switch8();

EXPORT_C CMessenger2* CMessenger2::NewLC(CConsoleBase& aConsole, const TDesC& aString)
	{
	OstTrace0( TRACE_NORMAL, DUP1_CMESSENGER2_NEWL, "CMessenger2::NewLC()" );  
	CMessenger2* self=new (ELeave) CMessenger2(aConsole);
	CleanupStack::PushL(self);
	self->ConstructL(aString);
	return self;
	}

CMessenger2::~CMessenger2() // destruct - virtual, so no export
	{
	OstTrace0( TRACE_API, DUP1_CMESSENGER2_CMESSENGER2, "CMessenger2::~CMessenger2()" );
	delete iString;
	}

EXPORT_C void CMessenger2::ShowMessage()
	{
	_LIT(KFormat1,"%S\n");
	iConsole.Printf(KFormat1, iString); // notify completion
	}

// constructor support
// don't export these, because used only by functions in this DLL, eg our NewLC()

CMessenger2::CMessenger2(CConsoleBase& aConsole) // first-phase C++ constructor
	: iConsole(aConsole)
	{
	}

void CMessenger2::ConstructL(const TDesC& aString) // second-phase constructor
	{
	iString=aString.AllocL(); // copy given string into own descriptor
    }

