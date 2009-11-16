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
*
*/


#ifndef __IMAGECLIENTMAIN_H__
#define __IMAGECLIENTMAIN_H__

#include <e32std.h>

enum TIclPanic
	{
	ENoSourceBitmap = 0,
	ENoDestinationBitmap = 1,
	EResetDestinationBitmap = 2,
	EConvertCalledWhileBusy = 3,
	EIllegalContinueConvert = 4,
	EDifferentDestinationBitmap = 5,
	EDifferentDestinationMask = 6,
	EModifiedDestination = 7,
	EBitmapHasZeroDimension = 8,
	ENoBitmapMask = 9,
	EFrameNumberOutOfRange = 10,
	EUndefinedSourceType = 11,
	ECommentsNotSupported = 12,
	EHeaderProcessingNotComplete = 13,
	ECommentNumberOutOfRange = 14,
	EBadDisplayMode = 15,
	EUnknownHeaderState = 16,
	ENonNullDescriptorPassed = 17,
	EUndefinedMIMEType = 18,
	EIllegalImageSubType = 19,
	EIllegalImageType = 20,
	EIllegalEncoderRestart = 21,
	EChangeOptionWhileDecoding = 22,
	EDecoderNotCreated = 23,
	EFeatureNotYetImplemented = 24,
	ERelaySubThreadPanicTimedOut = 25,
	EInvalidThreadState = 26,
	EInvalidFunctionLeave = 27,
	EInvalidState = 28,
	EDriveNotSupported = 29,
	EReservedCall = 30,
	EInvalidIndex = 31,
	EInvalidValue = 32,
#if defined(SYMBIAN_ENABLE_ENCODER_ASYNC_WRITES)
	EBufPoolNoMoreBuffers = 33,
	EBufPoolInvalidBuffer = 34,
	EAsyncWrtrQOverflow = 35,
#endif
	ENullImageConvExtension = 36,
	ENonNullImageConvExtension = 37,
	EInvalidFwExtensionCall = 38,
	EExtensionAlreadySet = 39,
	EInvalidFwExtensionUid = 40,
	EFwExtensionBusy = 41
	};

GLDEF_C void Panic(TIclPanic aError);

#endif // __IMAGECLIENTMAIN_H__
