/*
* Copyright (c) 2005-2005 Nokia Corporation and/or its subsidiary(-ies).
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
*   Header file mainly for TMacAddr definition
*
*/


#ifndef WLANHWINITTYPES_H
#define WLANHWINITTYPES_H


//  INCLUDES
#ifdef __PACKED
#undef __PACKED
#endif

#define __PACKED

/**
* Length of the MAC address
*/
const TUint8 KMacAddrLength = 6;

/**
* The one and only MAC address struct
*/
#pragma pack( 1 )
struct TMacAddr
    {
    /** the MAC address */
    TUint8 iMacAddress[KMacAddrLength];
    } __PACKED; // 6 bytes

/**
* Broadcast MAC Address.
*/
const TMacAddr KBroadcastMacAddr = {{ 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF }};

/**
* MAC address that all zeros
*/
const TMacAddr KZeroMacAddr = {{ 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 }};


#endif      // WLANHWINITTYPES_H   
            
// End of File
