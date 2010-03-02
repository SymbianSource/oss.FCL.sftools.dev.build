/*
* Copyright (c) 2002-2010 Nokia Corporation and/or its subsidiary(-ies).
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
* Description:  The implementation of CWlanHwInit class
*
*/


#include "gendebug.h"
#include "wlanhwinit.h"
#include "wlanhwinitmain.h"
#include "OstTraceDefinitions.h"
#ifdef OST_TRACE_COMPILER_IN_USE
#include "wlanhwinitTraces.h"
#endif


// ============================ MEMBER FUNCTIONS ===============================

CWlanHwInit::CWlanHwInit() :
    iMain( NULL )
    {
    TraceDump( INFO_LEVEL, ( _L( "CWlanHwInit::CWlanHwInit()" ) ) );
    OstTrace0( TRACE_NORMAL, CWLANHWINIT_CWLANHWINIT, "CWlanHwInit::CWlanHwInit()" ); 
    }

void CWlanHwInit::ConstructL()
    {
    TraceDump( INFO_LEVEL, ( _L( "CWlanHwInit::ConstructL()" ) ) );
    OstTrace0( TRACE_NORMAL, CWLANHWINIT_CONSTRUCTL, "CWlanHwInit::ConstructL()" );   
    iMain = CWlanHwInitMain::NewL();
    }

EXPORT_C CWlanHwInit* CWlanHwInit::NewL()
    {
    OstTrace0( TRACE_BORDER, CWLANHWINIT_NEWL, "CWlanHwInit::NewL()" );
    OstTrace0( TRACE_NORMAL, DUP1_CWLANHWINIT_NEWL, "CWlanHwInit::NewL()" );  
    CWlanHwInit* self = new( ELeave ) CWlanHwInit;
    CleanupStack::PushL( self );
    self->ConstructL();
    CleanupStack::Pop( self );
    return self;
    }
    
EXPORT_C CWlanHwInit::~CWlanHwInit()
    {
    TraceDump( INFO_LEVEL, ( _L( "CWlanHwInit::~CWlanHwInit()" ) ) );
    OstTrace0( TRACE_BORDER, DUP1_CWLANHWINIT_CWLANHWINIT, "CWlanHwInit::~CWlanHwInit()" );
    OstTrace0( TRACE_NORMAL, DUP2_CWLANHWINIT_CWLANHWINIT, "CWlanHwInit::~CWlanHwInit()" );  
    delete iMain;
    iMain = NULL;
    }

// -----------------------------------------------------------------------------
// CWlanHwInit::GetHwInitData
// -----------------------------------------------------------------------------
//
EXPORT_C void CWlanHwInit::GetHwInitData(
    const TUint8** aInitData,
    TUint& aInitLength,
    const TUint8** aFwData,
    TUint& aFwLength )
    {
    TraceDump( INFO_LEVEL, ( _L( "CWlanHwInit::GetHwInitData()" ) ) );
    OstTrace0( TRACE_BORDER, DUP1_CWLANHWINIT_GETHWINITDATA, "CWlanHwInit::GetHwInitData()" );
    OstTrace0( TRACE_NORMAL, CWLANHWINIT_GETHWINITDATA, "CWlanHwInit::GetHwInitData()" );
    
    //BOB10d initialization data block is in one piece (NVS + FW)
    //InitData is not needed
    *aInitData = NULL;
    aInitLength = 0;

    iMain->GetHwInitData( aInitData, aInitLength, aFwData, aFwLength );
    
    TraceDump( INFO_LEVEL, ( _L( "CWlanHwInit::GetHwInitData() aInitData: 0x%x, aInitLength: %d, aFwData: 0x%x, aFwLength: %d " ),aInitData,  aInitLength, aFwData, aFwLength  ) );
    OstTrace1( TRACE_NORMAL, DUP2_CWLANHWINIT_GETHWINITDATA, "CWlanHwInit::GetHwInitData() aInitData: 0x%x", aInitData );
    OstTrace1( TRACE_NORMAL, DUP3_CWLANHWINIT_GETHWINITDATA, "CWlanHwInit::GetHwInitData() aInitLength: %d", aInitLength );
    OstTrace1( TRACE_NORMAL, DUP4_CWLANHWINIT_GETHWINITDATA, "CWlanHwInit::GetHwInitData() aFwData 0x%x", aFwData );
    OstTrace1( TRACE_NORMAL, DUP5_CWLANHWINIT_GETHWINITDATA, "CWlanHwInit::GetHwInitData() aFwLength: %d", aFwLength ); 
    }

// -----------------------------------------------------------------------------
// CWlanHwInit::GetMacAddress
// -----------------------------------------------------------------------------
//
EXPORT_C TInt CWlanHwInit::GetMacAddress(
    TMacAddr& aMacAddress )
    {
    TraceDump( INFO_LEVEL, ( _L( "CWlanHwInit::GetMacAddress()" ) ) );
    OstTrace0( TRACE_BORDER, CWLANHWINIT_GETMACADDRESS, "CWlanHwInit::GetMacAddress()" );
    OstTrace0( TRACE_NORMAL, DUP1_CWLANHWINIT_GETMACADDRESS, "CWlanHwInit::GetMacAddress()" ); 
    return iMain->GetMacAddress( aMacAddress );
    }

// -----------------------------------------------------------------------------
// CWlanHwInit::GetHwTestInitData
// -----------------------------------------------------------------------------
//
EXPORT_C void CWlanHwInit::GetHwTestInitData(
    const TUint8** aInitData,
    TUint& aInitLength,
    const TUint8** aFwData,
    TUint& aFwLength )
    {
    TraceDump( INFO_LEVEL, ( _L( "CWlanHwInit::GetHwTestInitData()" ) ) );
    OstTrace0( TRACE_BORDER, CWLANHWINIT_GETHWTESTINITDATA, "CWlanHwInit::GetHwTestInitData()" );
    OstTrace0( TRACE_NORMAL, DUP1_CWLANHWINIT_GETHWTESTINITDATA, "CWlanHwInit::GetHwTestInitData()" );
    
    //BOB10d initialization data block is in one piece (NVS + FW)
    //InitData is not needed
    *aInitData = NULL;
    aInitLength = 0;
    
    iMain->GetHwTestInitData( aInitData, aInitLength, aFwData, aFwLength );

    TraceDump( INFO_LEVEL, ( _L( "CWlanHwInit::GetHwTestInitData() aInitData: 0x%x, aInitLength: %d, aFwData: 0x%x, aFwLength: %d " ),aInitData,  aInitLength, aFwData, aFwLength  ) );
    OstTrace1( TRACE_NORMAL, DUP2_CWLANHWINIT_GETHWTESTINITDATA, "CWlanHwInit::GetHwTestInitData() aInitData: 0x%x", aInitData );
    OstTrace1( TRACE_NORMAL, DUP3_CWLANHWINIT_GETHWTESTINITDATA, "CWlanHwInit::GetHwTestInitData() aInitLength: %d", aInitLength );
    OstTrace1( TRACE_NORMAL, DUP4_CWLANHWINIT_GETHWTESTINITDATA, "CWlanHwInit::GetHwTestInitData() aFwData: 0x%x", aFwData );
    OstTrace1( TRACE_NORMAL, DUP5_CWLANHWINIT_GETHWTESTINITDATA, "CWlanHwInit::GetHwTestInitData() aFwLength: %d", aFwLength ); 
    }

// -----------------------------------------------------------------------------
// CWlanHwInit::GetHwTestData
// -----------------------------------------------------------------------------
//
EXPORT_C TInt CWlanHwInit::GetHwTestData(
    TUint aId,
    TDes8& aData )
    {
    TraceDump( INFO_LEVEL, ( _L( "CWlanHwInit::GetHwTestData()" ) ) );
    OstTrace0( TRACE_BORDER, DUP1_CWLANHWINIT_GETHWTESTDATA, "CWlanHwInit::GetHwTestData()" );   
    OstTrace0( TRACE_NORMAL, CWLANHWINIT_GETHWTESTDATA, "CWlanHwInit::GetHwTestData()" );  
    return iMain->GetHwTestData( aId, aData );
    }

// -----------------------------------------------------------------------------
// CWlanHwInit::SetHwTestData
// -----------------------------------------------------------------------------
//
EXPORT_C TInt CWlanHwInit::SetHwTestData(
    TUint aId,
    TDesC8& aData )
    {
    TraceDump( INFO_LEVEL, ( _L( "CWlanHwInit::SetHwTestData()" ) ) );
    OstTrace0( TRACE_BORDER, DUP1_CWLANHWINIT_SETHWTESTDATA, "CWlanHwInit::SetHwTestData()" ); 
    OstTrace0( TRACE_NORMAL, CWLANHWINIT_SETHWTESTDATA, "CWlanHwInit::SetHwTestData()" );
    return iMain->SetHwTestData( aId, aData );
    }
