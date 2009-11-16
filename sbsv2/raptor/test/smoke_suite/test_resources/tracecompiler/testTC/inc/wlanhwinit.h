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
* Description:  Defines the class implementing MWlanHwInitInterface interface
*
*/


#ifndef WLANHWINIT_H
#define WLANHWINIT_H

#include "wlanhwinitinterface.h"

class CWlanHwInitMain;

// CLASS DECLARATION
/**
* This class implements the MWlanHwInitInterface interface.
*
* @since Series 60 3.1
*/
NONSHARABLE_CLASS( CWlanHwInit ) : public CBase, public MWlanHwInitInterface
    {
    public:  // Constructors and destructor
        
        /**
         * Two-phased constructor.
         */
        IMPORT_C static CWlanHwInit* NewL();
        
        /**
         * Destructor.
         */
        IMPORT_C virtual ~CWlanHwInit();
        
        // Functions from base classes

        /**
         * From MWlanHwInitInterface Get pointer to hardware specific initialization data.
         * @since Series 60 3.1
         * @param aInitData Pointer to initialization data, NULL if none.
         * @param aInitLength Length of initialization data.
         * @param aFwData Pointer to firmware data, NULL if none.
         * @param aFwLength Length of firmware data.
         */
        IMPORT_C void GetHwInitData(
            const TUint8** aInitData,
            TUint& aInitLength,
            const TUint8** aFwData,
            TUint& aFwLength );

        /**
         * From MWlanHwInitInterface Get device MAC address.
         * @since Series 60 3.1
         * @param aMacAddress MAC address of the device.
         * @return A Symbian error code.
         */
        IMPORT_C TInt GetMacAddress(
            TMacAddr& aMacAddress );

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
        IMPORT_C void GetHwTestInitData(
            const TUint8** aInitData,
            TUint& aInitLength,
            const TUint8** aFwData,
            TUint& aFwLength );

        /**
         * From MWlanHwInitInterface Get hardware specific production testing data.
         * @since Series 60 3.1
         * @param aId Id of the parameter to read.
         * @param aData Buffer for read data.
         * @return A Symbian error code.
         */
        IMPORT_C TInt GetHwTestData(
            TUint aId,
            TDes8& aData );

        /**
         * From MWlanHwInitInterface Set hardware specific production testing data.
         * @since Series 60 3.1
         * @param aId Id of the parameter to store.
         * @param aData Data to be stored.
         * @return A Symbian error code.
         */
        IMPORT_C TInt SetHwTestData(
            TUint aId,
            TDesC8& aData );

    private:

        /**
         * C++ default constructor.
         */
        CWlanHwInit();

        /**
         * By default Symbian 2nd phase constructor is private.
         */
        void ConstructL();

    private:    // Data

        /** The main implemenation of HW specific functionality. */
        CWlanHwInitMain* iMain;
    };

#endif // WLANHWINIT_H
