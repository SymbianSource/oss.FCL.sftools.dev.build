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
* Description:  The class for parsing the tuning data stored in PERM server
*
*/


#ifndef WLANHWINITPERMPARSER_H
#define WLANHWINITPERMPARSER_H

#include <e32base.h>
#include "wlanhwinitinterface.h"

// Initialization Data Block constants
const TUint32 KInitMagic = 0x19171513;
const TUint32 KInitTypeEnd = 0;
const TUint32 KInitTypeNvMem = 1;
const TUint32 KInitTypeCode = 2;

//These offsets are defined in Initialization Data Block document.
const TUint32 KNvMemTypeOffset = 4;
const TUint32 KNvMemLengthOffset = 8;
const TUint32 KNvMemValueOffset = 12;

const TUint32 KNvMemTypeOffset32 = 1;
const TUint32 KNvMemLengthOffset32 = 2;
const TUint32 KNvMemValueOffset32 = 3;

typedef TUint nvsUpdateList;
#define UPDATE_MAC_ADDR 		0x0080
#define UPDATE_ALL 				  0xFFFF

// Custom trace extraction content required for this component
typedef TUint8  TGroupId;
#define GROUPIDMASK             0x00ff0000
#define GROUPIDSHIFT            16
#define TRACEIDMASK             0x0000ffff
#define TRACEIDSHIFT            0
#define EXTRACT_GROUP_ID(aTraceName) static_cast<TGroupId>((aTraceName & GROUPIDMASK) >> GROUPIDSHIFT)


/**
* The class for parsing the tuning data stored in PERM server.
*
* @lib wlanhwinit.lib
* @since Series 60 3.1
*/
NONSHARABLE_CLASS( CWlanHwInitPermParser ) : public CBase
    {
    public:  // Constructors and destructor
        
        /**
        * Two-phased constructor.
        */
        static CWlanHwInitPermParser* NewL();
        
        /**
        * Destructor.
        */
        virtual ~CWlanHwInitPermParser();

        // New functions

        TPtr8 GetNvsBuffer();
        void CompareNvsBuffer();
        TPtr8 GetTuningBuffer();
        void UpdateNvsData(nvsUpdateList updateList);
        void GenerateDefaultTuningData();
        void SetMacAddress(const TMacAddr& pMacAddress);
        
        /**
        * Return the parsed tuning values from perm data.
        * @since Series 60 3.1
        * @param aData Parsed tuning values.
        * @return Status code.
        */
        TInt GetTuningValues(
            TDes8& aData );

        /**
        * Set tuning values to perm data.
        * @since Series 60 3.1
        * @param aData Tuning values to be stored.
        * @return Status code.
        */
        TInt SetTuningValues(TDesC8& aData, nvsUpdateList updateList);

    private:

        /**
        * C++ default constructor.
        */
        CWlanHwInitPermParser();

        /**
        * By default Symbian 2nd phase constructor is private.
        */
        void ConstructL();

    private:    // Data

        TMacAddr iMacAddress;
        /** The current tuning data. */
        HBufC8* iTuningData;
        HBufC8* iNvsData;
    };

#endif // WLANHWINITPERMPARSER_H
