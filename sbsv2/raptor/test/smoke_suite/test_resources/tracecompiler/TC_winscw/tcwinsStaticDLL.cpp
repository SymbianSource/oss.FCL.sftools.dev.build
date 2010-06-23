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


#include "tcwinsStaticDLL.h"
#include <e32uid.h>
#include "OstTraceDefinitions.h"
#ifdef OST_TRACE_COMPILER_IN_USE
#include "tcwinsStaticDLLTraces.h"
#endif


// construct/destruct


extern "C" void __ARM_switch8();

void sbs_test()
	{
	__ARM_switch8();
	}


EXPORT_C CMessenger* CMessenger::NewLC(CConsoleBase& aConsole, const TDesC& aString)
	{
	OstTrace0( TRACE_API, CMESSENGER_NEWL, "CMessenger::NewLC()" );
	OstTrace0( TRACE_NORMAL, DUP1_CMESSENGER_NEWL, "CMessenger::NewLC()" );  
	CMessenger* self=new (ELeave) CMessenger(aConsole);
	CleanupStack::PushL(self);
	self->ConstructL(aString);
	return self;
	}

CMessenger::~CMessenger() // destruct - virtual, so no export
	{
	OstTrace0( TRACE_API, DUP1_CMESSENGER_CMESSENGER, "CMessenger::~CMessenger()" );
	OstTrace0( TRACE_NORMAL, DUP2_CMESSENGER_CMESSENGER, "CMessenger::~CMessenger()" );  
	delete iString;
	}

EXPORT_C void CMessenger::ShowMessage()
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

