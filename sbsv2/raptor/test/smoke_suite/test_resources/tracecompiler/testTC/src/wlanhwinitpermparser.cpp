/*
* Copyright (c) 2002-2006 Nokia Corporation and/or its subsidiary(-ies).
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
* Description:  The class for parsing the tuning data stored in PERM server
*
*/


#include <stddef.h>
#include <es_sock.h>
#include "gendebug.h"
#include "wlanhwinitpermparser.h"
#include "bcmnvmem.h"
#include "lmac_firmware.h"
#include "plt_firmware.h"
#include "OstTraceDefinitions.h"
#ifdef OST_TRACE_COMPILER_IN_USE
#include "wlanhwinitpermparserTraces.h"
#endif


// ============================ MEMBER FUNCTIONS ===============================

CWlanHwInitPermParser::CWlanHwInitPermParser() :
    iTuningData(NULL),
    iNvsData(NULL)
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:CWlanHwInitPermParser()" ) ) );
	OstTrace0( TRACE_NORMAL, CWLANHWINITPERMPARSER_CWLANHWINITPERMPARSER, "CWlanHwInitPermParser:CWlanHwInitPermParser()" );	
}


void CWlanHwInitPermParser::ConstructL()
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:ConstructL()" ) ) );
	OstTrace0( TRACE_NORMAL, CWLANHWINITPERMPARSER_CONSTRUCTL, "CWlanHwInitPermParser:ConstructL()" );	
	iTuningData = HBufC8::NewL( (sizeof(WlanHalApi::SNvMem) - offsetof(WlanHalApi::SNvMem, PL_2G_hdb)) );   
	iNvsData = HBufC8::NewL( sizeof(WlanHalApi::SNvMem) );   
}


CWlanHwInitPermParser* CWlanHwInitPermParser::NewL()
{
	OstTrace0( TRACE_NORMAL, CWLANHWINITPERMPARSER_NEWL, "CWlanHwInitPermParser::NewL()" );
	CWlanHwInitPermParser* self = new( ELeave ) CWlanHwInitPermParser;

	CleanupStack::PushL( self );
	self->ConstructL();
	CleanupStack::Pop( self );

	return self;
}


CWlanHwInitPermParser::~CWlanHwInitPermParser()
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:~CWlanHwInitPermParser()" ) ) );
	OstTrace0( TRACE_NORMAL, DUP1_CWLANHWINITPERMPARSER_CWLANHWINITPERMPARSER, "CWlanHwInitPermParser:~CWlanHwInitPermParser()" );
	delete iTuningData;
	iTuningData = NULL;
	delete iNvsData;
	iNvsData = NULL;
}

void CWlanHwInitPermParser::CompareNvsBuffer()
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:CompareNvsBuffer()") ) );
	OstTrace0( TRACE_NORMAL, CWLANHWINITPERMPARSER_COMPARENVSBUFFER, "CWlanHwInitPermParser:CompareNvsBuffer()" );
	TUint8* pNvsBuffer = (TUint8*)iNvsData->Ptr();
	TUint8* normalFirmwareNvsBuffer = (TUint8*) (normal_firmware + KNvMemValueOffset32);
	TUint8* pltFirmwareNvsBuffer = (TUint8*) (plt_firmware + KNvMemValueOffset32);
	
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:CompareNvsBuffer() sizeof(WlanHalApi::SNvMem): %d"), sizeof(WlanHalApi::SNvMem) ) );
	OstTrace1( TRACE_NORMAL, DUP1_CWLANHWINITPERMPARSER_COMPARENVSBUFFER, "CWlanHwInitPermParser:CompareNvsBuffer() sizeof(WlanHalApi::SNvMem): %d", sizeof(WlanHalApi::SNvMem));
	
	/* checking the changes that have been made */
	for( TUint32 i = 0 ; i < sizeof(WlanHalApi::SNvMem) ; i++)
	{
		if(normalFirmwareNvsBuffer[i] != pNvsBuffer[i])
		{
			TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:Normal NVS changed[0x%04X]:orig 0x%02X, new 0x%02X"), i, normalFirmwareNvsBuffer[i], pNvsBuffer[i]) );
			OstTraceExt3( TRACE_NORMAL, DUP2_CWLANHWINITPERMPARSER_COMPARENVSBUFFER, "CWlanHwInitPermParser:Normal NVS changed[0x%x]:orig 0x%x, new 0x%x", i, normalFirmwareNvsBuffer[i], pNvsBuffer[i] );
		}
	}

	/* also for plt firmware */
	for( TUint32 i = 0 ; i < sizeof(WlanHalApi::SNvMem) ; i++)
	{
		if(pltFirmwareNvsBuffer[i] != pNvsBuffer[i])
		{
			TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:PLT NVS changed[0x%04X]:orig 0x%02X, new 0x%02X"), i, pltFirmwareNvsBuffer[i], pNvsBuffer[i]) );
			OstTraceExt3( TRACE_NORMAL, DUP3_CWLANHWINITPERMPARSER_COMPARENVSBUFFER, "CWlanHwInitPermParser:PLT NVS changed[0x%x]:orig 0x%x, new 0x%x", i, pltFirmwareNvsBuffer[i], pNvsBuffer[i] );		
		}
	}	
}

// ---------------------------------------------------------
// CWlanHwInitPermParser::GetNvsBuffer
// ---------------------------------------------------------
//
TPtr8 CWlanHwInitPermParser::GetNvsBuffer()
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:GetNvsBuffer()" ) ) );
	OstTrace0( TRACE_NORMAL, CWLANHWINITPERMPARSER_GETNVSBUFFER, "CWlanHwInitPermParser:GetNvsBuffer()" );
	return iNvsData->Des();
}

// ---------------------------------------------------------
// CWlanHwInitPermParser::GetTuningBuffer
// ---------------------------------------------------------
//
TPtr8 CWlanHwInitPermParser::GetTuningBuffer()
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:GetTuningBuffer()" ) ) );
	OstTrace0( TRACE_NORMAL, CWLANHWINITPERMPARSER_GETTUNINGBUFFER, "CWlanHwInitPermParser:GetTuningBuffer()" );
	return iTuningData->Des();
}


// ---------------------------------------------------------
// CWlanHwInitPermParser::UpdateNvsData
// ---------------------------------------------------------
//
void CWlanHwInitPermParser::UpdateNvsData(nvsUpdateList updateList)
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:UpdateNvsData()" ) ) );
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:updateList 0x%X"), updateList ) );
	OstTrace0( TRACE_NORMAL, CWLANHWINITPERMPARSER_UPDATENVSDATA, "CWlanHwInitPermParser:UpdateNvsData()" );
	OstTrace1( TRACE_NORMAL, DUP1_CWLANHWINITPERMPARSER_UPDATENVSDATA, "CWlanHwInitPermParser:updateList 0x%x", updateList );
	
	WlanHalApi::SNvMem* pNvsStruct = (WlanHalApi::SNvMem*)iNvsData->Ptr();

	if( (sizeof(WlanHalApi::SNvMem) - offsetof(WlanHalApi::SNvMem, PL_2G_hdb)) == iTuningData->Length() ) //only use if the tuning data is the same size as the structure...
	{
		if(updateList == UPDATE_ALL)
		{
			TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:UpdateNvsData:UPDATE_ALL" ) ) );
			OstTrace0( TRACE_NORMAL, DUP2_CWLANHWINITPERMPARSER_UPDATENVSDATA, "CWlanHwInitPermParser:UpdateNvsData:UPDATE_ALL" );
			//void * memcpy ( void * destination, const void * source, size_t num );
			memcpy( (&pNvsStruct->PL_2G_hdb), iTuningData->Ptr(), iTuningData->Length() );		
		}
	}
	else
	{
			TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:size mismatch data-%d, structure-%d"), iTuningData->Length(), sizeof(WlanHalApi::SNvMem)) );
			OstTraceExt2( TRACE_NORMAL, DUP3_CWLANHWINITPERMPARSER_UPDATENVSDATA, "CWlanHwInitPermParser:size mismatch data-%d, structure-%d", iTuningData->Length(), sizeof(WlanHalApi::SNvMem) );			
	}

	if(updateList & UPDATE_MAC_ADDR)
	{
		//Update Mac address
		TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:UPDATE_MAC_ADDR" ) ) );
		TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:Current Mac Addr - %02X:%02X:%02X:%02X:%02X:%02X"),  pNvsStruct->whamac[0], pNvsStruct->whamac[1], pNvsStruct->whamac[2], pNvsStruct->whamac[3], pNvsStruct->whamac[4], pNvsStruct->whamac[5] ) );
		TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:Mac Addr to use - %02X:%02X:%02X:%02X:%02X:%02X"), iMacAddress.iMacAddress[0], iMacAddress.iMacAddress[1], iMacAddress.iMacAddress[2], iMacAddress.iMacAddress[3], iMacAddress.iMacAddress[4], iMacAddress.iMacAddress[5]) );
		OstTrace0( TRACE_NORMAL, DUP4_CWLANHWINITPERMPARSER_UPDATENVSDATA, "CWlanHwInitPermParser:UPDATE_MAC_ADDR" );
		TBuf<80> buf;
		buf.AppendFormat(_L("CWlanHwInitPermParser:Current Mac Addr - %02X:%02X:%02X:%02X:%02X:%02X"),  pNvsStruct->whamac[0], pNvsStruct->whamac[1], pNvsStruct->whamac[2], pNvsStruct->whamac[3], pNvsStruct->whamac[4], pNvsStruct->whamac[5] );
		TPtrC16 currentMacPtr((TUint16*)buf.Ptr(), buf.Size());
		OstTraceExt1( TRACE_NORMAL, DUP5_CWLANHWINITPERMPARSER_UPDATENVSDATA, "%S", currentMacPtr );		
		buf.Zero();
		buf.AppendFormat(_L("CWlanHwInitPermParser:Mac Addr to use - %02X:%02X:%02X:%02X:%02X:%02X"), iMacAddress.iMacAddress[0], iMacAddress.iMacAddress[1], iMacAddress.iMacAddress[2], iMacAddress.iMacAddress[3], iMacAddress.iMacAddress[4], iMacAddress.iMacAddress[5] );
		TPtrC16 newMacPtr((TUint16*)buf.Ptr(), buf.Size());
		OstTraceExt1( TRACE_NORMAL, DUP6_CWLANHWINITPERMPARSER_UPDATENVSDATA, "%S", newMacPtr );
		
		/* Copy the MAC address */
		for( TUint32 i = 0 ; i < KMacAddrLength ; i++)
		{
			pNvsStruct->whamac[i] = iMacAddress.iMacAddress[i];
		}
		TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:Final Mac Addr - %02X:%02X:%02X:%02X:%02X:%02X"),  pNvsStruct->whamac[0], pNvsStruct->whamac[1], pNvsStruct->whamac[2], pNvsStruct->whamac[3], pNvsStruct->whamac[4], pNvsStruct->whamac[5] ) );
		buf.Zero();
		buf.AppendFormat(_L("CWlanHwInitPermParser:Final Mac Addr - %02X:%02X:%02X:%02X:%02X:%02X"), pNvsStruct->whamac[0], pNvsStruct->whamac[1], pNvsStruct->whamac[2], pNvsStruct->whamac[3], pNvsStruct->whamac[4], pNvsStruct->whamac[5] );
		TPtrC16 finalMacPtr((TUint16*)buf.Ptr(), buf.Size());
		OstTraceExt1( TRACE_NORMAL, DUP7_CWLANHWINITPERMPARSER_UPDATENVSDATA, "%S", finalMacPtr );
	}

	CompareNvsBuffer();
}


void CWlanHwInitPermParser::GenerateDefaultTuningData(void)
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:GenerateDefaultTuningData()" ) ) );    
	OstTrace0( TRACE_NORMAL, CWLANHWINITPERMPARSER_GENERATEDEFAULTTUNINGDATA, "CWlanHwInitPermParser:GenerateDefaultTuningData()" );
	
	//use nvs file to create default tuning data
	TPtr8 tuningPtr( GetTuningBuffer() );
	WlanHalApi::SNvMem* pNvsStruct = (WlanHalApi::SNvMem*)iNvsData->Ptr();
	
	tuningPtr.Copy(&pNvsStruct->PL_2G_hdb, (sizeof(WlanHalApi::SNvMem) - offsetof(WlanHalApi::SNvMem, PL_2G_hdb)));	
}

void CWlanHwInitPermParser::SetMacAddress(const TMacAddr& pMacAddress)
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:SetMacAddress()" ) ) );
	OstTrace0( TRACE_NORMAL, CWLANHWINITPERMPARSER_SETMACADDRESS, "CWlanHwInitPermParser:SetMacAddress()" );
	
	memcpy(iMacAddress.iMacAddress, pMacAddress.iMacAddress, KMacAddrLength);
}

// ---------------------------------------------------------
// CWlanHwInitPermParser::GetTuningValues
// ---------------------------------------------------------
//
TInt CWlanHwInitPermParser::GetTuningValues(TDes8& aData)
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:GetTuningValues()" ) ) );    
	OstTrace0( TRACE_NORMAL, CWLANHWINITPERMPARSER_GETTUNINGVALUES, "CWlanHwInitPermParser:GetTuningValues()" );
	
	aData.Copy(GetTuningBuffer());

	return KErrNone;
}


// ---------------------------------------------------------
// CWlanHwInitPermParser::SetTuningValues
// ---------------------------------------------------------
//
TInt CWlanHwInitPermParser::SetTuningValues(TDesC8& aData, nvsUpdateList updateList)
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:SetTuningValues()" ) ) );
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:updateList 0x%X"), updateList ) );
	OstTrace0( TRACE_NORMAL, CWLANHWINITPERMPARSER_SETTUNINGVALUES, "CWlanHwInitPermParser:SetTuningValues()" );
	OstTrace1( TRACE_NORMAL, DUP1_CWLANHWINITPERMPARSER_SETTUNINGVALUES, "CWlanHwInitPermParser:updateList 0x%x", updateList );
	
	TPtr8 tuningPtr( GetTuningBuffer() );
	TUint8* pStoredTuningData = (TUint8*)tuningPtr.Ptr();
		
	if(updateList & UPDATE_ALL)
	{
		TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser:UPDATE_ALL" ) ) );
		OstTrace0( TRACE_NORMAL, DUP2_CWLANHWINITPERMPARSER_SETTUNINGVALUES, "CWlanHwInitPermParser:UPDATE_ALL" );		
		//void * memcpy ( void * destination, const void * source, size_t num );						
		memcpy( pStoredTuningData, aData.Ptr(), (sizeof(WlanHalApi::SNvMem) - offsetof(WlanHalApi::SNvMem, PL_2G_hdb) ) );		
	}

	return KErrNone;
}
