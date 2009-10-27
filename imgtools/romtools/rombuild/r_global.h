/*
* Copyright (c) 1995-2009 Nokia Corporation and/or its subsidiary(-ies).
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
*
*/


#if !defined(__R_GLOBAL_H__)
#define __R_GLOBAL_H__

#define DEBUG_TRACE
#ifdef DEBUG_TRACE
#define TRACE(m,s)	( (void) ((TraceMask&(m)) && ((s),0)) )
#define STRACE(m,s) if (TraceMask&(m)) s
#define TDIR		0x00000001
#define TTIMING		0x00000002
#define TIMPORT		0x00000004
#define TROMNODE	0x00000008
#define TCOLLAPSE1	0x00000010
#define TCOLLAPSE2	0x00000020
#define TCOLLAPSE3	0x00000040
#define TCOLLAPSE4	0x00000080
#define TAREA       0x00000200
#define TSCRATCH	0x100
#else
#define TRACE(m,s)
#endif

#define DEFAULT_LOG_LEVEL 0x0

#define LOG_LEVEL_FILE_DETAILS	    0x00000001 // Destination file name (loglevel1)
#define LOG_LEVEL_FILE_ATTRIBUTES   0x00000002 // File attributes (loglevel2)
#define LOG_LEVEL_COMPRESSION_INFO  0x00000004 // Compression information (loglevel3)
#define LOG_LEVEL_SMP_INFO          0x00000008 // SMP-unsafe components (loglevel4)

#include <e32std.h>
#include "e32image.h"
#include "r_obey.h"

// in r_global.cpp
extern TRomLoaderHeader *TheRomLoaderHeader;
extern ImpTRomHeader *TheRomHeader;
extern TRomBuilderEntry *TheRootDirectory;
extern TUint32 TheRomMem;
extern TUint32 TheRomRootDir;
extern TBool Unicode;
extern TBool gSortedRomFs;
extern TBool gEnableCompress;
extern TBool gFastCompress;

extern TUint gCompressionMethod;

extern TBool gCompressUnpaged;
extern TUint gCompressUnpagedMethod;

extern TUint32 TheRomLinearAddress;
extern TInt NumberOfVariants;
extern TInt NumRootDirs;
extern TUint TraceMask;
extern TBool TypeSafeLink;
extern TUint32 LastValidAddress;
extern TCpu CPU;
extern TInt gHeaderType;
extern TInt gPagedRom;
extern TInt gCodePagingOverride;
extern TInt gDataPagingOverride;
extern TBool gPlatSecEnforceSysBin;
extern TBool gPlatSecEnforcement;
extern TBool gPlatSecDiagnostics;
extern SCapabilitySet gPlatSecDisabledCaps;
extern SCapabilitySet gPlatSecAllCaps;
extern SDemandPagingConfig gDemandPagingConfig;
extern TBool gGenInc;						// DEF095619
extern TBool gEnableStdPathWarning;
extern TInt gLogLevel;
extern TBool gLowMem;
extern TBool gUseCoreImage;
extern TText *gImageFilename;
extern TInt gBootstrapSize;			// To calculate uncompressed un-paged size CR1258
extern TInt gPageIndexTableSize;	// To calculate uncompressed un-paged size CR1258
#endif
