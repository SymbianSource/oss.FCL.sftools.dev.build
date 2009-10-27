/*
* Copyright (c) 2001-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* Global Variables Definition
*
*/


#include "r_global.h"

TUint32 TheRomMem=0;
TUint32 TheRomLinearAddress=0;
ImpTRomHeader *TheRomHeader=0;
TCpu CPU=ECpuUnknown;
TBool Unicode=ETrue;
TBool gLittleEndian=ETrue;
TUint TraceMask=0;
TBool TypeSafeLink=EFalse;
TInt gHeaderType=-1;
TInt gPagedRom=0;
TInt gCodePagingOverride=-1; 
TInt gDataPagingOverride=-1;
TBool gPlatSecEnforcement=0;
TBool gPlatSecDiagnostics=0;
TBool gPlatSecEnforceSysBin=0;
TBool gSortedRomFs=ETrue;
TBool gEnableCompress=EFalse;		// Default to uncompressed ROM image
TBool gFastCompress = EFalse;   // Default to compress most
TUint gCompressionMethod=0; // Default compression method

TBool gCompressUnpaged=EFalse; // Default to not compress un-paged part of ROM Image
TUint gCompressUnpagedMethod=0;// Default compression method for un-paged part of ROM Image

SCapabilitySet gPlatSecDisabledCaps={{0}}; 
SCapabilitySet gPlatSecAllCaps={{0}};
SDemandPagingConfig gDemandPagingConfig={0,0,0,{0}}; 
TBool gGenInc=EFalse;	// Default to no generate INC file.  DEF095619
TInt gLogLevel=0;  // Information is logged based on logging level.
					// The default is 0. So all the existing logs are generated as if gLogLevel == 0.
					// If any extra information is required, the log level must be appropriately supplied.
					// Currrently, file details in ROM (like, file name in ROM & host, file size, whether 
					// the file is hidden etc) are logged when gLogLevel >= 1.

TBool gEnableStdPathWarning=EFalse; // To generate warning if the destination path is not a standard path. Default is not to warn.

TBool gLowMem = EFalse;
TBool gUseCoreImage = EFalse;
TText* gImageFilename = 0;

TInt gBootstrapSize=0;			// To calculate uncompressed un-paged size CR1258
TInt gPageIndexTableSize=0;		// To calculate uncompressed un-paged size CR1258
