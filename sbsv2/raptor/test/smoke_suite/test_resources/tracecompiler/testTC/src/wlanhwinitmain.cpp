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
* Description:  The class implementing HW specific initialization
*
*/


#include <iscapi.h>
#include "gendebug.h"
#include <IscNokiaDefinitions.h>
#include <pn_const.h>
#include <tisi.h>
#include <infoisi.h>
#include <permisi.h>
#include <f32file.h>
#include <stddef.h>

#include "bcmnvmem.h"
#include "lmac_firmware.h"
#include "plt_firmware.h"

#include "wlanhwinitmain.h"
#include "wlanhwinitpermparser.h"
#include "OstTraceDefinitions.h"
#ifdef OST_TRACE_COMPILER_IN_USE
#include "wlanhwinitmainTraces.h"
#endif

/** The default MAC address. */
const TMacAddr KWlanHwInitDefaultMacAddr = { { 0x00, 0xE0, 0xDE, 0xAD, 0xBE, 0xEF } };
// ISI constants
const TUint KWlanHwInitIsiBufferSize         = 1024;
const TUint16 KWlanHwInitIsiPermGroupId      = 313;
const TUint16 KWlanHwInitIsiPermIndex        = 0;
const TUint16 KWlanHwInitIsiPermOffset       = 0;
const TUint32 KWlanHwInitIsiPermDataSize     = (sizeof(WlanHalApi::SNvMem) - offsetof(WlanHalApi::SNvMem, PL_2G_hdb));

/**
* HW specific settings
*/
/* should be using TWlanTestPlatformSetting in wlanTestServer.h */
enum TWlanHwInitTestSetting
    {
    EWlanHwInitTestSettingMacAddressPerm,
    EWlanHwInitTestSettingMacAddressTemp,
    EWlanHwInitTestSettingTuningData,
    EWlanHwInitTestSettingTempTuningData
    };

const TUint KIsiRespMessagePadding = 128;

// ============================ MEMBER FUNCTIONS ===============================

CWlanHwInitMain::CWlanHwInitMain() :
	iMacAddressPerm( KWlanHwInitDefaultMacAddr ),
	iMacAddressTemp( KWlanHwInitDefaultMacAddr ),
	iPermParser( NULL ),
	iTransactionId( 0 ),
	ipNvsData ( 0 ),
	iFirmwareMC ( 0 )
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitMain:CWlanHwInitMain()" ) ) );
	OstTrace0( TRACE_NORMAL, CWLANHWINITMAIN_CWLANHWINITMAIN, "CWlanHwInitMain:CWlanHwInitMain()" );
}

void CWlanHwInitMain::ConstructL()
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitMain:ConstructL()" ) ) );
	OstTrace0( TRACE_NORMAL, CWLANHWINITMAIN_CONSTRUCTL, "CWlanHwInitMain:ConstructL()" );
	
	iPermParser = CWlanHwInitPermParser::NewL();
/**
* Initialize default NVS data.
*/
	TPtr8 nvsPtr( iPermParser->GetNvsBuffer() );
	
	//take only the nvmem part of the IDB. IDB = nvmem + firmware.
  TUint32* dataPtr = (TUint32*)normal_firmware;
  //first there is the magic number
  if (*dataPtr != KInitMagic) 
    {
	  TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser: Invalid magic number at start of init block (0x%x)"), *dataPtr ) );
	  OstTrace1( TRACE_IMPORTANT, DUP1_CWLANHWINITMAIN_CONSTRUCTL, "CWlanHwInitPermParser: Invalid magic number at start of init block (0x%x)", *dataPtr );  
	  User::Leave( KErrGeneral );
    }
  //then there is type  
  dataPtr++;
  const TUint32 type = *dataPtr;

  //and after type, there is the lenght of the data  
  dataPtr++;
  const TUint32 len = *dataPtr;

  if (type != KInitTypeNvMem)
    {
    TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitPermParser: Invalid type at start of init block (0x%x)"), type ) );  
    OstTrace1( TRACE_IMPORTANT, DUP2_CWLANHWINITMAIN_CONSTRUCTL, "CWlanHwInitPermParser: Invalid type at start of init block (0x%x)", type ); 
    User::Leave( KErrGeneral );
    }

    //after the length there is data
    dataPtr++;	
	nvsPtr.Append( reinterpret_cast<const TUint8*>(dataPtr), len );
	
/**
* Update device data from the CMT permanent storage.
*/
	
//	Discard the return value, we'll use the default value
//	if this fails.
	TRAPD( ret, GetMacAddressL( iMacAddressPerm ) );
	iMacAddressTemp = iMacAddressPerm;    
	iPermParser->SetMacAddress(iMacAddressTemp);

	TPtr8 tuningPtr( iPermParser->GetTuningBuffer() );
	TRAP( ret, GetTuningDataL( tuningPtr ) );
	if(ret != KErrNone)
	{
		iPermParser->GenerateDefaultTuningData();
	}
	
	iPermParser->UpdateNvsData(UPDATE_ALL);
}

CWlanHwInitMain* CWlanHwInitMain::NewL()
{
    OstTrace0( TRACE_NORMAL, CWLANHWINITMAIN_NEWL, "CWlanHwInitMain::NewL()" );
	CWlanHwInitMain* self = new( ELeave ) CWlanHwInitMain;
	CleanupStack::PushL( self );
	self->ConstructL();
	CleanupStack::Pop( self );
	return self;
}
    
CWlanHwInitMain::~CWlanHwInitMain()
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitMain:~CWlanHwInitMain()" ) ) );
	OstTrace0( TRACE_NORMAL, DUP1_CWLANHWINITMAIN_CWLANHWINITMAIN, "CWlanHwInitMain:~CWlanHwInitMain()" );
	
	delete iPermParser;
	iPermParser = NULL;
	delete ipNvsData;
	ipNvsData = NULL; 
	delete iFirmwareMC;
	iFirmwareMC = NULL; 
}

// -----------------------------------------------------------------------------
// CWlanHwInitMain::GetMacAddressL
// -----------------------------------------------------------------------------
//
void CWlanHwInitMain::GetMacAddressL(TMacAddr& aMacAddress)
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitMain:GetMacAddressL()" ) ) );   
	OstTrace0( TRACE_NORMAL, CWLANHWINITMAIN_GETMACADDRESSL, "CWlanHwInitMain:GetMacAddressL()" );
	
	TUint8 readReq[ISI_HEADER_SIZE + SIZE_INFO_WLAN_INFO_READ_REQ];
	memset( readReq, 0, sizeof( readReq));
	TPtr8 readPtr( readReq, ISI_HEADER_SIZE + SIZE_INFO_WLAN_INFO_READ_REQ);
	
	TIsiSend readMac( readPtr);
	
	readMac.Set8bit( ISI_HEADER_OFFSET_RESOURCEID, PN_PHONE_INFO);
	readMac.Set8bit( ISI_HEADER_OFFSET_TRANSID, ++iTransactionId);
	readMac.Set8bit( ISI_HEADER_OFFSET_MESSAGEID, INFO_WLAN_INFO_READ_REQ);
	readMac.Set16bit( ISI_HEADER_SIZE + INFO_WLAN_INFO_READ_REQ_OFFSET_FILLERBYTE1, 0);
	readMac.Complete();
	
	TUint8 readResp[ISI_HEADER_SIZE + SIZE_INFO_WLAN_INFO_READ_RESP];
	memset( readResp, 0, sizeof( readResp));
	TPtr8 respPtr( readResp, ISI_HEADER_SIZE + SIZE_INFO_WLAN_INFO_READ_RESP );
	
	SendIsiMessageL( readPtr, respPtr );
	
	TIsiReceiveC macResp( respPtr);
	
	if ( ( macResp.Get8bit( ISI_HEADER_OFFSET_RESOURCEID) != PN_PHONE_INFO ) || (macResp.Get8bit(ISI_HEADER_OFFSET_MESSAGEID) != INFO_WLAN_INFO_READ_RESP) )
	{
		TraceDump( ERROR_LEVEL, ( _L( "CWlanHwInitMain:GetMacAddressL() - invalid message received" ) ) );
		TraceDump( ERROR_LEVEL, ( _L( "CWlanHwInitMain:GetMacAddressL() - resource = %02X, message id = %02X" ),
		macResp.Get8bit( ISI_HEADER_OFFSET_RESOURCEID), macResp.Get8bit( ISI_HEADER_OFFSET_MESSAGEID) ) );
		OstTrace0( TRACE_IMPORTANT, DUP1_CWLANHWINITMAIN_GETMACADDRESSL, "CWlanHwInitMain:GetMacAddressL() - invalid message received" );
		OstTrace1( TRACE_IMPORTANT, DUP2_CWLANHWINITMAIN_GETMACADDRESSL, "CWlanHwInitMain::GetMacAddressL - resource = 0x%x", macResp.Get8bit( ISI_HEADER_OFFSET_RESOURCEID) );
		OstTrace1( TRACE_IMPORTANT, DUP3_CWLANHWINITMAIN_GETMACADDRESSL, "CWlanHwInitMain::GetMacAddressL - message id = 0x%x", macResp.Get8bit( ISI_HEADER_OFFSET_MESSAGEID) );
		
		User::Leave( KErrGeneral );
	}

	if ( macResp.Get8bit( ISI_HEADER_SIZE + INFO_WLAN_INFO_READ_RESP_OFFSET_STATUS) != INFO_OK )
	{
		TraceDump( ERROR_LEVEL, ( _L( "CWlanHwInitMain:GetMacAddressL() - request failed, status = %02X" ),
		macResp.Get8bit( ISI_HEADER_SIZE + INFO_WLAN_INFO_READ_RESP_OFFSET_STATUS) ) );
		OstTrace1( TRACE_IMPORTANT, DUP4_CWLANHWINITMAIN_GETMACADDRESSL, "CWlanHwInitMain:GetMacAddressL() - request failed, status = 0x%x", macResp.Get8bit( ISI_HEADER_SIZE + INFO_WLAN_INFO_READ_RESP_OFFSET_STATUS) );	
		User::Leave( KErrGeneral );
	}    
	
	TMacAddr tempMac;
	
	memcpy( &tempMac.iMacAddress, macResp.GetData( ISI_HEADER_SIZE + INFO_WLAN_INFO_READ_RESP_OFFSET_ADDRESS, INFO_WLAN_MAC_ADDR_LEN).Ptr(), INFO_WLAN_MAC_ADDR_LEN);
	for( TInt i=0; i<INFO_WLAN_MAC_ADDR_LEN; i++)
		{
		aMacAddress.iMacAddress[INFO_WLAN_MAC_ADDR_LEN - i - 1] = tempMac.iMacAddress[i];
		}
	
}

// ---------------------------------------------------------
// CWlanHwInitMain::GetTuningDataL
// ---------------------------------------------------------
//
void CWlanHwInitMain::GetTuningDataL(TDes8& aTuningData)
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitMain:GetTuningDataL()" ) ) );
	OstTrace0( TRACE_NORMAL, CWLANHWINITMAIN_GETTUNINGDATAL, "CWlanHwInitMain:GetTuningDataL()" );
	
	TUint8 readBuf[ ISI_HEADER_SIZE + SIZE_PERM_PM_RECORD_READ_REQ];
	memset( &readBuf, 0, sizeof( readBuf));
	TPtr8 readReq( readBuf, ISI_HEADER_SIZE + SIZE_PERM_PM_RECORD_READ_REQ);
	
	TIsiSend sendReq( readReq);
	
	sendReq.Set8bit( ISI_HEADER_OFFSET_RESOURCEID, PN_PERMANENT_DATA);
	sendReq.Set8bit( ISI_HEADER_OFFSET_TRANSID, ++iTransactionId);
	sendReq.Set8bit( ISI_HEADER_OFFSET_MESSAGEID, PERM_PM_RECORD_READ_REQ);
	
	sendReq.Set16bit( ISI_HEADER_SIZE + PERM_PM_RECORD_READ_REQ_OFFSET_GROUPID, KWlanHwInitIsiPermGroupId);
	sendReq.Set16bit( ISI_HEADER_SIZE + PERM_PM_RECORD_READ_REQ_OFFSET_INDEX, KWlanHwInitIsiPermIndex);
	sendReq.Set32bit( ISI_HEADER_SIZE + PERM_PM_RECORD_READ_REQ_OFFSET_OFFSET, KWlanHwInitIsiPermOffset);
	sendReq.Set32bit( ISI_HEADER_SIZE + PERM_PM_RECORD_READ_REQ_OFFSET_SIZE, KWlanHwInitIsiPermDataSize);
	sendReq.Complete();
	
	HBufC8* respBuf = HBufC8::NewL( KWlanHwInitIsiBufferSize);
	CleanupStack::PushL( respBuf );
	respBuf->Des().FillZ();
	
	TPtr8 readResp( respBuf->Des());
	
	SendIsiMessageL( readReq, readResp);
	
	TIsiReceiveC recv( respBuf->Des());
	
	if ( ( recv.Get8bit( ISI_HEADER_OFFSET_RESOURCEID) != PN_PERMANENT_DATA ) || ( recv.Get8bit( ISI_HEADER_OFFSET_MESSAGEID) != PERM_PM_RECORD_READ_RESP ) )
	{
		TraceDump( ERROR_LEVEL, ( _L( "CWlanHwInitMain:GetTuningDataL() - invalid message received" ) ) );
		TraceDump( ERROR_LEVEL, ( _L( "CWlanHwInitMain:GetTuningDataL() - resource = %02X, message id = %02X" ),
		recv.Get8bit( ISI_HEADER_OFFSET_RESOURCEID), recv.Get8bit( ISI_HEADER_OFFSET_MESSAGEID) ) );
		OstTrace0( TRACE_IMPORTANT, DUP1_CWLANHWINITMAIN_GETTUNINGDATAL, "CWlanHwInitMain:GetTuningDataL() - invalid message received" );
		OstTrace1( TRACE_IMPORTANT, DUP8_CWLANHWINITMAIN_GETTUNINGDATAL, "CWlanHwInitMain:GetTuningDataL() - resource = %x", recv.Get8bit( ISI_HEADER_OFFSET_RESOURCEID) );
		OstTrace1( TRACE_IMPORTANT, DUP9_CWLANHWINITMAIN_GETTUNINGDATAL, "CWlanHwInitMain:GetTuningDataL() - message id = %x", recv.Get8bit( ISI_HEADER_OFFSET_MESSAGEID) );
	}

	if ( recv.Get8bit( ISI_HEADER_SIZE + PERM_PM_RECORD_READ_RESP_OFFSET_PMMSTATUS) != PMM_OK )
	{
		TraceDump( ERROR_LEVEL, ( _L( "CWlanHwInitMain:GetTuningDataL() - request failed, status = %02X" ),
		recv.Get8bit( ISI_HEADER_SIZE + PERM_PM_RECORD_READ_RESP_OFFSET_PMMSTATUS) ) );
		OstTrace1( TRACE_IMPORTANT, DUP2_CWLANHWINITMAIN_GETTUNINGDATAL, "CWlanHwInitMain:GetTuningDataL() - request failed, status = 0x%x", recv.Get8bit( ISI_HEADER_SIZE + PERM_PM_RECORD_READ_RESP_OFFSET_PMMSTATUS) );	
		User::Leave( KErrGeneral );
	}       
	
	if( recv.Get8bit( ISI_HEADER_SIZE + PERM_PM_RECORD_READ_RESP_OFFSET_NUMBEROFSUBBLOCKS) != 1)
	{
		TraceDump( ERROR_LEVEL, ( _L( "CWlanHwInitMain:GetTuningDataL() - request failed, subblocks %d" ),
		recv.Get8bit( ISI_HEADER_SIZE + PERM_PM_RECORD_READ_RESP_OFFSET_NUMBEROFSUBBLOCKS) ) );
		OstTrace1( TRACE_IMPORTANT, DUP3_CWLANHWINITMAIN_GETTUNINGDATAL, "CWlanHwInitMain:GetTuningDataL() - request failed, subblocks %d", recv.Get8bit( ISI_HEADER_SIZE + PERM_PM_RECORD_READ_RESP_OFFSET_NUMBEROFSUBBLOCKS) );		
		User::Leave( KErrNotFound );
	}
	
	if( recv.Get8bit( ISI_HEADER_SIZE + SIZE_PERM_PM_RECORD_READ_RESP + PERM_SB_PM_DATA_OFFSET_SUBBLOCKID) != PERM_SB_PM_DATA)
	{
		TraceDump( ERROR_LEVEL, ( _L( "CWlanHwInitMain:GetTuningDataL() - request failed, subblock id %d" ),
		recv.Get8bit( ISI_HEADER_SIZE + SIZE_PERM_PM_RECORD_READ_RESP + PERM_SB_PM_DATA_OFFSET_SUBBLOCKID) ) );
		OstTrace1( TRACE_IMPORTANT, DUP4_CWLANHWINITMAIN_GETTUNINGDATAL, "CWlanHwInitMain:GetTuningDataL() - request failed, subblock id %d", recv.Get8bit( ISI_HEADER_SIZE + SIZE_PERM_PM_RECORD_READ_RESP + PERM_SB_PM_DATA_OFFSET_SUBBLOCKID) );		
		User::Leave( KErrNotFound );
	}
	
	TUint32 size = recv.Get32bit( ISI_HEADER_SIZE + SIZE_PERM_PM_RECORD_READ_RESP + PERM_SB_PM_DATA_OFFSET_SIZE);
	
	if( size != KWlanHwInitIsiPermDataSize)
	{
		TraceDump( ERROR_LEVEL, ( _L( "CWlanHwInitIsaWlanPermReadIsiMsg::GetTuningData() - payload too big" ) ) );
		TraceDump( ERROR_LEVEL, ( _L( "CWlanHwInitIsaWlanPermReadIsiMsg::GetTuningData() - actual size = %u" ), size ) );
		TraceDump( ERROR_LEVEL, ( _L( "CWlanHwInitIsaWlanPermReadIsiMsg::GetTuningData() - expected size = %u" ), KWlanHwInitIsiPermDataSize ) );
		OstTrace0( TRACE_IMPORTANT, DUP5_CWLANHWINITMAIN_GETTUNINGDATAL, "CWlanHwInitIsaWlanPermReadIsiMsg::GetTuningData() - payload too big" );	
		OstTrace1( TRACE_IMPORTANT, DUP6_CWLANHWINITMAIN_GETTUNINGDATAL, "CWlanHwInitIsaWlanPermReadIsiMsg::GetTuningData() - actual size = %u", size );
		OstTrace1( TRACE_IMPORTANT, DUP7_CWLANHWINITMAIN_GETTUNINGDATAL, "CWlanHwInitIsaWlanPermReadIsiMsg::GetTuningData() - expected size = %u", KWlanHwInitIsiPermDataSize );		
		User::Leave( KErrTooBig ); 
	}
	
	aTuningData.Append( recv.GetData( ISI_HEADER_SIZE + SIZE_PERM_PM_RECORD_READ_RESP + PERM_SB_PM_DATA_OFFSET_DATA, size));
	
	CleanupStack::PopAndDestroy( respBuf);
}

// ---------------------------------------------------------
// CWlanHwInitMain::SetTuningDataL
// ---------------------------------------------------------
//
void CWlanHwInitMain::SetTuningDataL(TDesC8& aTuningData)
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitMain:SetTuningDataL()" ) ) );
	OstTrace0( TRACE_NORMAL, CWLANHWINITMAIN_SETTUNINGDATAL, "CWlanHwInitMain:SetTuningDataL()" );
	
	HBufC8* writeBuf = HBufC8::NewL( KWlanHwInitIsiBufferSize);
	CleanupStack::PushL( writeBuf );
	writeBuf->Des().FillZ();

	TPtr8 writeReq( writeBuf->Des());

	TIsiSend writeSend( writeReq);

	writeSend.Set8bit( ISI_HEADER_OFFSET_RESOURCEID, PN_PERMANENT_DATA);
	writeSend.Set8bit( ISI_HEADER_OFFSET_TRANSID, ++iTransactionId);
	writeSend.Set8bit( ISI_HEADER_OFFSET_MESSAGEID, PERM_PM_RECORD_WRITE_REQ);

	writeSend.Set16bit( ISI_HEADER_SIZE + PERM_PM_RECORD_WRITE_REQ_OFFSET_GROUPID, KWlanHwInitIsiPermGroupId);
	writeSend.Set16bit( ISI_HEADER_SIZE + PERM_PM_RECORD_WRITE_REQ_OFFSET_INDEX, KWlanHwInitIsiPermIndex);
	writeSend.Set32bit( ISI_HEADER_SIZE + PERM_PM_RECORD_WRITE_REQ_OFFSET_SIZE, KWlanHwInitIsiPermDataSize);
	writeSend.CopyData( ISI_HEADER_SIZE + PERM_PM_RECORD_WRITE_REQ_OFFSET_DATA, aTuningData);
	writeSend.Complete();

	TUint8 respBuf[ISI_HEADER_SIZE + SIZE_PERM_PM_RECORD_WRITE_RESP + KIsiRespMessagePadding];
	memset( &respBuf, 0, sizeof( respBuf));
	TPtr8 writeResp( respBuf, ISI_HEADER_SIZE + SIZE_PERM_PM_RECORD_WRITE_RESP + KIsiRespMessagePadding);

	SendIsiMessageL( writeReq, writeResp );

	TIsiReceiveC resp( writeResp);

	if ( ( resp.Get8bit( ISI_HEADER_OFFSET_RESOURCEID) != PN_PERMANENT_DATA ) || ( resp.Get8bit( ISI_HEADER_OFFSET_MESSAGEID) != PERM_PM_RECORD_WRITE_RESP ) )
	{
		TraceDump( ERROR_LEVEL, ( _L( "CWlanHwInitMain:SetTuningDataL() - invalid message received" ) ) );
		TraceDump( ERROR_LEVEL, ( _L( "CWlanHwInitMain:SetTuningDataL() - resource = %02X, message id = %02X" ), 
					resp.Get8bit( ISI_HEADER_OFFSET_RESOURCEID),
					resp.Get8bit( ISI_HEADER_OFFSET_MESSAGEID) ) );
		OstTrace0( TRACE_IMPORTANT, DUP1_CWLANHWINITMAIN_SETTUNINGDATAL, "CWlanHwInitMain:SetTuningDataL() - invalid message received" );
		OstTrace1( TRACE_IMPORTANT, DUP2_CWLANHWINITMAIN_SETTUNINGDATAL, "CWlanHwInitMain:SetTuningDataL() - resource = %x", resp.Get8bit( ISI_HEADER_OFFSET_RESOURCEID) );
		OstTrace1( TRACE_IMPORTANT, DUP3_CWLANHWINITMAIN_SETTUNINGDATAL, "CWlanHwInitMain:SetTuningDataL() - message id = 0x%x", resp.Get8bit( ISI_HEADER_OFFSET_MESSAGEID) );		
	}

	if ( resp.Get8bit( ISI_HEADER_SIZE + PERM_PM_RECORD_WRITE_RESP_OFFSET_PMMSTATUS) != PMM_OK )
	{
		TraceDump( ERROR_LEVEL, ( _L( "CWlanHwInitMain:SetTuningDataL() - request failed, status = %02X" ),
					resp.Get8bit( ISI_HEADER_SIZE + PERM_PM_RECORD_WRITE_RESP_OFFSET_PMMSTATUS) ) );
		OstTrace1( TRACE_IMPORTANT, DUP4_CWLANHWINITMAIN_SETTUNINGDATAL, "CWlanHwInitMain:SetTuningDataL() - request failed, status = 0x%x", resp.Get8bit( ISI_HEADER_SIZE + PERM_PM_RECORD_WRITE_RESP_OFFSET_PMMSTATUS) );
		
		User::Leave( KErrGeneral );
	}

	CleanupStack::PopAndDestroy( writeBuf );
}

// ---------------------------------------------------------
// CWlanHwInitMain::GetHwTestData
// ---------------------------------------------------------
//
TInt CWlanHwInitMain::GetHwTestData(TUint aId, TDes8& aData)
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitMain:GetHwTestData()" ) ) );
	OstTrace0( TRACE_NORMAL, CWLANHWINITMAIN_GETHWTESTDATA, "CWlanHwInitMain:GetHwTestData()" );	
	
	switch ( aId )
	{
		case EWlanHwInitTestSettingMacAddressPerm:
			aData.Copy( &iMacAddressPerm.iMacAddress[0], KMacAddrLength );
		break;

		case EWlanHwInitTestSettingMacAddressTemp:
			aData.Copy( &iMacAddressTemp.iMacAddress[0], KMacAddrLength );
		break;

		case EWlanHwInitTestSettingTuningData:            
			iPermParser->GetTuningValues( aData );
		break;

		case EWlanHwInitTestSettingTempTuningData:
		default:
			TraceDump( ERROR_LEVEL, ( _L( "CWlanHwInitMain:GetHwTestData() - not supported (%d)" ), aId ) );
			OstTrace1( TRACE_IMPORTANT, DUP1_CWLANHWINITMAIN_GETHWTESTDATA, "CWlanHwInitMain:GetHwTestData() - not supported (%d)", aId );			
			return KErrNotSupported;
	}
	
	return KErrNone;
}

// ---------------------------------------------------------
// CWlanHwInitMain::SetHwTestData
// ---------------------------------------------------------
//
TInt CWlanHwInitMain::SetHwTestData(TUint aId, TDesC8& aData)
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitMain:SetHwTestData()" ) ) );
	OstTrace0( TRACE_NORMAL, CWLANHWINITMAIN_SETHWTESTDATA, "CWlanHwInitMain:SetHwTestData()" );	
	TInt ret( KErrNone );
	
	switch ( aId )
	{
		case EWlanHwInitTestSettingMacAddressTemp:
		    OstTrace0( TRACE_NORMAL, DUP1_CWLANHWINITMAIN_SETHWTESTDATA, "CWlanHwInitMain:SetHwTestData() EWlanHwInitTestSettingMacAddressTemp" );		    
			Mem::Copy( &iMacAddressTemp.iMacAddress[0], aData.Ptr(), KMacAddrLength );
			iPermParser->SetMacAddress(iMacAddressTemp);
			iPermParser->UpdateNvsData(UPDATE_MAC_ADDR);
		break;

		case EWlanHwInitTestSettingTuningData:
		{
			OstTrace0( TRACE_NORMAL, DUP2_CWLANHWINITMAIN_SETHWTESTDATA, "CWlanHwInitMain::SetHwTestData() EWlanHwInitTestSettingTuningData" );
			iPermParser->SetTuningValues(aData, UPDATE_ALL);
			TPtrC8 cmtDataPtr( iPermParser->GetTuningBuffer() );
			TRAP( ret, SetTuningDataL(cmtDataPtr) );
			iPermParser->UpdateNvsData(UPDATE_ALL);
		}
      break;

		case EWlanHwInitTestSettingTempTuningData:
		{
		    TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitMain:SetHwTestData() EWlanHwInitTestSettingTempTuningData" ) ) );
		    OstTrace0( TRACE_NORMAL, DUP3_CWLANHWINITMAIN_SETHWTESTDATA, "CWlanHwInitMain::SetHwTestData() EWlanHwInitTestSettingTempTuningData" );
		    iPermParser->SetTuningValues(aData, UPDATE_ALL);
		    iPermParser->UpdateNvsData(UPDATE_ALL);
		}
		break;
		
		case EWlanHwInitTestSettingMacAddressPerm:
		default:
			TraceDump( ERROR_LEVEL, ( _L( "CWlanHwInitMain:SetHwTestData() - no such id (%d)!" ), aId ) );
			OstTrace1( TRACE_IMPORTANT, DUP4_CWLANHWINITMAIN_SETHWTESTDATA, "CWlanHwInitMain:SetHwTestData() - no such id (%d)", aId );
			ret = KErrNotSupported;
	    break;
	}
	
	return ret;
}


TBool CWlanHwInitMain::IsMMCFirmwareFound()
    {
#ifdef LOAD_FW_FROM_MMC
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitMain::IsMMCFirmwareFound()" ) ) );
	OstTrace0( TRACE_NORMAL, CWLANHWINITMAIN_ISMMCFIRMWAREFOUND, "CWlanHwInitMain::IsMMCFirmwareFound()" );
	
	_LIT(KSearchPath,"E:\\firmware\\*.*");
	_LIT(KFilePath,"E:\\firmware\\");
	  
	// Check if the firmware is already loaded,
	// free the memory and continue
	  
	  if (iFirmwareMC)
	  {
	  	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitMain: Memory for MMC Firmware already reserved" ) ) );
	  	OstTrace0( TRACE_NORMAL, DUP1_CWLANHWINITMAIN_ISMMCFIRMWAREFOUND, "CWlanHwInitMain: Memory for MMC Firmware already reserved" );
	  	return ETrue;
	  }
	  
	  // Init store	  
	  RFs fs;
	  RFile file;
	  CDir* dirList;
	  TInt fileSize = -1;
	  TBuf<60> fileName;
	  fileName = KFilePath;
	  
    
	  // Connect to the file system	
	  if ( fs.Connect() != KErrNone)
	  {
	  	return EFalse;
	  }
	  
	  // If returns an error, the folder is not found
	  // -> return false;	  
	  if (fs.GetDir(KSearchPath,
          		     KEntryAttMaskSupported,
          		     ESortByName,
                	 dirList) != KErrNone )
	  {
	  	fs.Close();
	  	delete dirList;
	  	return EFalse;
	  }
                
 	  // If no file is not found, return false.    
	  if (dirList->Count() == 0)
	  {
	  	fs.Close();	  	
	  	delete dirList;
	  	return EFalse;
	  }         
      
    // Take the first file in the list, further files
    // are not handled           
	  fileName.Append ((*dirList)[0].iName);  // Assume there is enough space, otherwise panics...
	  
	  // Try to open the firmware file
	  if ( file.Open(fs, fileName, EFileStream != KErrNone))
	  {
	  	delete dirList;
	  	fs.Close();
	  	return EFalse;
	  }
	   
	  // Get the size of the file 
	  if (file.Size(fileSize) != KErrNone)
	  {
	  	delete dirList;
	  	file.Close();
	  	fs.Close();
	  	return EFalse;
	  	
	  }
    
    // Reserve memory from heap for it
    TRAPD(err, iFirmwareMC = HBufC8::NewL(fileSize));
    
    if (err != KErrNone)
    {
    	delete dirList;
    	file.Close();
      fs.Close();
    	return EFalse;
    }

    // Get a pointer and read the contents
    // of the file.
	  TPtr8 pBuf = iFirmwareMC->Des();
	  if (file.Read(pBuf) != KErrNone)
	  {
	  	delete dirList;
    	file.Close();
      fs.Close();
    	return EFalse;
	  }
	  
	  // Successful	  
	  file.Close();
    fs.Close();
    delete dirList;

	  return ETrue;	

#else
	return EFalse;
#endif // LOAD_FW_FROM_MMC	
		}

// ---------------------------------------------------------
// CWlanHwInitMain::GetHwInitData
// ---------------------------------------------------------
//
void CWlanHwInitMain::GetHwInitData(const TUint8** ppConfigData, TUint& configLength, const TUint8** ppNvsData, TUint& nvsLength )
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitMain:GetHwInitData()" ) ) );
	OstTrace0( TRACE_NORMAL, CWLANHWINITMAIN_GETHWINITDATA, "CWlanHwInitMain:GetHwInitData()" );
	
	// Temporary pointer for firmware
	const TUint8* fwPtr;
	TUint fwSize = 0;	
		
	// Parse NVS
	iPermParser->CompareNvsBuffer();
	TPtr8 nvsPtr( iPermParser->GetNvsBuffer() );
	
	// Check if firmware can be found from the MMC	
#ifdef LOAD_FW_FROM_MMC  // Enable MMC loading here
  if (IsMMCFirmwareFound())
      {
      TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitMain::GetHwInitData():MMC Firmware loaded" ) ) );	
  	  OstTrace0( TRACE_NORMAL, DUP1_CWLANHWINITMAIN_GETHWINITDATA, "CWlanHwInitMain::GetHwInitData():MMC Firmware loaded" );
  	  fwPtr = reinterpret_cast<const TUint8*>( iFirmwareMC->Ptr() );
  	  fwSize = iFirmwareMC->Length();  	  	
      }
  else
	  {
	  TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitMain::GetHwInitData():Hardcoded Firmware loaded" ) ) );		
      OstTrace0( TRACE_NORMAL, DUP2_CWLANHWINITMAIN_GETHWINITDATA, "CWlanHwInitMain::GetHwInitData():Hardcoded Firmware loaded" );
      fwPtr = reinterpret_cast<const TUint8*>( normal_firmware );
      fwSize = (sizeof( normal_firmware ));
	  }	
#else
  fwPtr = reinterpret_cast<const TUint8*>( normal_firmware );
  fwSize = (sizeof( normal_firmware ));
#endif	
	
	nvsLength = fwSize; 
	
	// Reserve memory if it has not yet already been reserved
	if (ipNvsData == NULL)
	{
		ipNvsData = (TUint8*)User::Alloc(nvsLength);    
		if (!ipNvsData)
		{
			// Out of memory
			ASSERT(0);
		}	
	}	
	
	// Copy NVS data to correct position
	//first copy the whole firmware
	Mem::Copy(ipNvsData, fwPtr, nvsLength);
		
	// Length of NVS
	*reinterpret_cast<TUint32*>(&ipNvsData[KNvMemLengthOffset]) = nvsPtr.Length();
	
	// Copy NVS data to the NVS offset
	Mem::Copy( (ipNvsData + KNvMemValueOffset), nvsPtr.Ptr(), nvsPtr.Length());
			
	*ppNvsData = ipNvsData;
}


// ---------------------------------------------------------
// CWlanHwInitMain::GetMacAddress
// Status : Draft
// ---------------------------------------------------------
//
TInt CWlanHwInitMain::GetMacAddress(TMacAddr& aMacAddress)
{
	aMacAddress = iMacAddressPerm;
	return KErrNone;
}

// ---------------------------------------------------------
// CWlanHwInitMain::GetHwTestInitData
// Status : Draft
// ---------------------------------------------------------
//    
void CWlanHwInitMain::GetHwTestInitData(const TUint8** aInitData, TUint& aInitLength, const TUint8** aFwData, TUint& aFwLength)
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitMain:GetHwTestInitData()" ) ) );
	OstTrace0( TRACE_NORMAL, CWLANHWINITMAIN_GETHWTESTINITDATA, "CWlanHwInitMain:GetHwTestInitData()" );

	// Temporary pointer for firmware
	const TUint8* fwPtr;
	TUint fwSize = 0;	
		
	// Parse NVS
	iPermParser->CompareNvsBuffer();
	TPtr8 nvsPtr( iPermParser->GetNvsBuffer() );

	// Check if firmware can be found from the MMC	
#ifdef LOAD_FW_FROM_MMC  // Enable MMC loading here
  if (IsMMCFirmwareFound())
      {
      TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitMain::GetHwTestInitData():MMC Firmware loaded" ) ) );	
  	  OstTrace0( TRACE_NORMAL, DUP1_CWLANHWINITMAIN_GETHWTESTINITDATA, "CWlanHwInitMain::GetHwTestInitData():MMC Firmware loaded" );
  	  fwPtr = reinterpret_cast<const TUint8*>( iFirmwareMC->Ptr() );
  	  fwSize = iFirmwareMC->Length();  	  	
      }
  else
      {
      TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitMain::GetHwTestInitData():Hardcoded Firmware loaded" ) ) );		
      OstTrace0( TRACE_NORMAL, DUP2_CWLANHWINITMAIN_GETHWTESTINITDATA, "CWlanHwInitMain::GetHwTestInitData():Hardcoded Firmware loaded" );
      fwPtr = reinterpret_cast<const TUint8*>( plt_firmware );
      fwSize = (sizeof( plt_firmware ));
      }	
#else
  fwPtr = reinterpret_cast<const TUint8*>( plt_firmware );
  fwSize = (sizeof( plt_firmware ));
#endif	
		
	aFwLength = fwSize; 
	
	// Reserve memory if it has not yet already been reserved
	if (ipNvsData == NULL)
	{
		ipNvsData = (TUint8*)User::Alloc(aFwLength);     
		if (!ipNvsData)
		{
			// Out of memory
			ASSERT(0);
		}	
	}	
	
	// Copy NVS data to correct position
	//first copy the whole firmware
	Mem::Copy(ipNvsData, fwPtr, aFwLength);
		
	// Length of NVS
	*reinterpret_cast<TUint32*>(&ipNvsData[KNvMemLengthOffset]) = nvsPtr.Length();
	
	// Copy NVS data to the NVS offset
	Mem::Copy( (ipNvsData + KNvMemValueOffset), nvsPtr.Ptr(), nvsPtr.Length());
			
	*aFwData = ipNvsData;
}

// ---------------------------------------------------------
// CWlanHwInitMain::SendIsiMessageL
// ---------------------------------------------------------
//
void CWlanHwInitMain::SendIsiMessageL(TDes8& aRequest, TDes8& aReply)
{
	TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitMain:SendIsiMessageL()" ) ) );
	OstTrace0( TRACE_NORMAL, CWLANHWINITMAIN_SENDISIMESSAGEL, "CWlanHwInitMain:SendIsiMessageL()" );
	
	RIscApi iscapi;
	TRequestStatus status;
	const TUint16 channelId = EIscNokiaStartup;

	iscapi.Open( channelId, status );// codescanner::open IscApi::Open doesn't have return value. Error codes are passed in status parameter.
	User::WaitForRequest( status );
	if ( status.Int() != KErrNone )
	{
		TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitMain:SendIsiMessageL() - RIscApi.Open() failed with %d" ), status.Int() ) );
		OstTrace1( TRACE_IMPORTANT, DUP1_CWLANHWINITMAIN_SENDISIMESSAGEL, "CWlanHwInitMain:SendIsiMessageL() - RIscApi.Open() failed with %d", status.Int() );
		User::Leave( status.Int() );
	}
	CleanupClosePushL( iscapi );

	TInt ret = iscapi.Send( aRequest );
	if ( ret != KErrNone )
	{
		TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitMain:SendIsiMessageL() - RIscApi.Send() failed with %d" ), ret ) );
		OstTrace1( TRACE_IMPORTANT, DUP2_CWLANHWINITMAIN_SENDISIMESSAGEL, "CWlanHwInitMain:SendIsiMessageL() - RIscApi.Send() failed with %d", ret );
		User::Leave( ret );
	}

	TUint16 neededLength = 0;

	TraceDump( INFO_LEVEL,( _L( "CWlanHwInitMain:aReply Size() %d" ),aReply.Size() ) );
	TraceDump( INFO_LEVEL,( _L( "CWlanHwInitMain:aReply MaxLength() %d" ),aReply.MaxLength() ) );
	TraceDump( INFO_LEVEL,( _L( "CWlanHwInitMain:aReply MaxSize() %d" ),aReply.MaxSize() ) );
	OstTrace1( TRACE_NORMAL, DUP3_CWLANHWINITMAIN_SENDISIMESSAGEL, "CWlanHwInitMain:aReply Size() %d", aReply.Size() );
	OstTrace1( TRACE_NORMAL, DUP4_CWLANHWINITMAIN_SENDISIMESSAGEL, "CWlanHwInitMain:aReply MaxLength() %d", aReply.MaxLength() );
	OstTrace1( TRACE_NORMAL, DUP5_CWLANHWINITMAIN_SENDISIMESSAGEL, "CWlanHwInitMain:aReply MaxSize() %d", aReply.MaxSize() );
	
	iscapi.Receive( status, aReply, neededLength );
	User::WaitForRequest( status );
	if ( status.Int() != KErrNone )
	{
		TraceDump( INFO_LEVEL, ( _L( "CWlanHwInitMain:SendIsiMessageL() - RIscApi.Receive() failed with %d" ), status.Int() ) );
		TraceDump( INFO_LEVEL,( _L( "CWlanHwInitMain:neededLength %d" ),neededLength ) );
		OstTrace1( TRACE_IMPORTANT, DUP6_CWLANHWINITMAIN_SENDISIMESSAGEL, "CWlanHwInitMain:SendIsiMessageL() - RIscApi.Receive() failed with %d", status.Int() );
		OstTrace1( TRACE_IMPORTANT, DUP7_CWLANHWINITMAIN_SENDISIMESSAGEL, "CWlanHwInitMain:neededLength %d", neededLength );		
		User::Leave( status.Int() );
	}

	CleanupStack::PopAndDestroy( &iscapi );
}
