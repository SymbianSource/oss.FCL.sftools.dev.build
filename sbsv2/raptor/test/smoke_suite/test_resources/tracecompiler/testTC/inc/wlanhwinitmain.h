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
* Description:  Defines the class implementing HW specific initialization
*
*/


#ifndef WLANHWINITMAIN_H
#define WLANHWINITMAIN_H

#include <e32base.h>
#include "wlanhwinittypes.h"
#include "wlanhwinitinterface.h"

// FORWARD DECLARATIONS
class CIsiMsg;
class CWlanHwInitPermParser;

// CLASS DECLARATION
/**
* This class implements the actual HW specific initialization functionality.
*
* @lib wlanhwinit.lib
* @since Series 60 3.1
*/
NONSHARABLE_CLASS( CWlanHwInitMain ) : public CBase, public MWlanHwInitInterface
    {
    public:  // Constructors and destructor
        
        /**
        * Two-phased constructor.
        */
        static CWlanHwInitMain* NewL();
        
        /**
        * Destructor.
        */
        virtual ~CWlanHwInitMain();

        // Functions from base classes

        /**
        * From MWlanHwInitInterface Get pointer to hardware specific initialization data.
        * @since Series 60 3.1
        * @param aInitData Pointer to initialization data, NULL if none.
        * @param aInitLength Length of initialization data.
        * @param aFwData Pointer to firmware data, NULL if none.
        * @param aFwLength Length of firmware data.
        */
        void GetHwInitData(const TUint8** aInitData, TUint& aInitLength, const TUint8** aFwData, TUint& aFwLength);

        /**
        * From MWlanHwInitInterface Get device MAC address.
        * @since Series 60 3.1
        * @param aMacAddress MAC address of the device.
        * @return A Symbian error code.
        */
        TInt GetMacAddress(TMacAddr& aMacAddress);

        /**
        * Methods for production testing.
        */

        /**
        * From MWlanHwInitInterface Get pointer to hardware specific initialization data
        * for production testing.
        * @since Series 60 3.1
        * @param aInitData Pointer to initialization data, NULL if none.
        * @param aInitLength Length of initialization data.
        * @param aFwData Pointer to firmware data, NULL if none.
        * @param aFwLength Length of firmware data.
        */
        void GetHwTestInitData(const TUint8** aInitData, TUint& aInitLength, const TUint8** aFwData, TUint& aFwLength);

        /**
        * From MWlanHwInitInterface Get hardware specific production testing data.
        * @since Series 60 3.1
        * @param aId Id of the parameter to read.
        * @param aData Buffer for read data.
        * @return A Symbian error code.
        */
        TInt GetHwTestData(TUint aId, TDes8& aData);

        /**
        * From MWlanHwInitInterface Set hardware specific production testing data.
        * @since Series 60 3.1
        * @param aId Id of the parameter to store.
        * @param aData Data to be stored.
        * @return A Symbian error code.
        */
        TInt SetHwTestData(TUint aId, TDesC8& aData);

    private:

        /**
        * C++ default constructor.
        */
        CWlanHwInitMain();

        /**
        * By default Symbian 2nd phase constructor is private.
        */
        void ConstructL();

        /**
        * Read the MAC address of the device from permanent storage.
        * @param aMacAddress Mac address.        
        */
        void GetMacAddressL(TMacAddr& aMacAddress);

        /**
        * Read the tuning data from permanent storage.
        * @param aTuningData Tuning data.
        */
        void GetTuningDataL(TDes8& aTuningData);

        /**
        * Set the tuning data to permanent storage.
        * @param aTuningData Tuning data.
        */
        void SetTuningDataL(TDesC8& aTuningData);

        /**
        * Send an ISI message and wait for the reply.
        * @param aRequest Request to be sent.
        * @param aReply Received reply.
        */        
        void SendIsiMessageL(TDes8& aRequest, TDes8& aReply);
        
        /**
        * Checks if a firmware file can be found from
        * the memory card.
        * return False if not found or error occured, True if 
        * the firmware was successfully read.
        * The firmware is loaded only once.
        */
        TBool IsMMCFirmwareFound();

    private:    // Data

        /** Permanent MAC address. */
        TMacAddr iMacAddressPerm;

        /** Temporary MAC address. */
        TMacAddr iMacAddressTemp;

        /** Parser for tuning data. */
        CWlanHwInitPermParser* iPermParser;

        /** Transaction Id used for ISI messages. */
        TUint8 iTransactionId;
        
        /** Pointer for NVS data */
        TUint8* ipNvsData;
        
        /** Buffer for possible firmware loaded from MC. */
        HBufC8* iFirmwareMC;
        
    };

#endif // WLANHWINITMAIN_H
