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
* Description:  Defines the abstract interface for HW specific initialization
*
*/


#ifndef WLANHWINITINTERFACE_H
#define WLANHWINITINTERFACE_H

#include <e32base.h>
#include "wlanhwinittypes.h"

/**
 * This is the abstract base class used for HW specific initialization.
 *
 * @since Series 60 3.1
 */
class MWlanHwInitInterface
    {
    public:  // Constructors and destructor

        // New functions

        /**
         * Get pointer to hardware specific initialization data.
         * @since Series 60 3.1
         * @param aInitData Pointer to initialization data, NULL if none.
         * @param aInitLength Length of initialization data.
         * @param aFwData Pointer to firmware data, NULL if none.
         * @param aFwLength Length of firmware data.
         */
        virtual void GetHwInitData(
            const TUint8** aInitData,
            TUint& aInitLength,
            const TUint8** aFwData,
            TUint& aFwLength ) = 0;

        /**
         * Get device MAC address.
         * @since Series 60 3.1
         * @param aMacAddress MAC address of the device.
         * @return A Symbian error code.
         * @note If a special MAC address 00:00:00:00:00:00 is returned,
         * the WLAN engine assumes the device to be a variant without
         * WLAN support and will not start the up.
         */
        virtual TInt GetMacAddress(
            TMacAddr& aMacAddress ) = 0;

        /**
         * Methods for production testing.
         */

        /**
         * Get pointer to hardware specific initialization data for production testing.
         * @since Series 60 3.1
         * @param aInitData Pointer to initialization data, NULL if none.
         * @param aInitLength Length of initialization data.
         * @param aFwData Pointer to firmware data, NULL if none.
         * @param aFwLength Length of firmware data.
         */
        virtual void GetHwTestInitData(
            const TUint8** aInitData,
            TUint& aInitLength,
            const TUint8** aFwData,
            TUint& aFwLength ) = 0;

        /**
         * Get hardware specific production testing data.
         * @since Series 60 3.1
         * @param aId Id of the parameter to read.
         * @param aData Buffer for read data.
         * @return A Symbian error code.
         */
        virtual TInt GetHwTestData(
            TUint aId,
            TDes8& aData ) = 0;

        /**
         * Set hardware specific production testing data.
         * @since Series 60 3.1
         * @param aId Id of the parameter to store.
         * @param aData Data to be stored.
         * @return A Symbian error code.
         */
        virtual TInt SetHwTestData(
            TUint aId,
            TDesC8& aData ) = 0;
    };

#endif // WLANHWINITINTERFACE_H
