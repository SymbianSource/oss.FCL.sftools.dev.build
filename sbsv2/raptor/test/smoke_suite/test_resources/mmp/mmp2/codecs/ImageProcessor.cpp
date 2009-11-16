/*
* Copyright (c) 1999-2009 Nokia Corporation and/or its subsidiary(-ies).
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


#include <icl/imageprocessor.h>
#include "ImageProcessorPriv.h"
#include "ImageUtils.h"
#include "ImageClientMain.h"

//Size of dynamically allocated buffers used by CPixelWriter & CMonochromePixelWriter
const TInt KPixelWriterBufferSize = 1024;
const TInt KPixelWriterBufferThreeQuarter = 768;

/**
Constructor for this class.
*/
EXPORT_C CImageProcessorExtension::CImageProcessorExtension()
:iOperation(EDecodeNormal)
	{
	}

/**
Destructor for this class.
*/
EXPORT_C CImageProcessorExtension::~CImageProcessorExtension()
	{
	}

/**
Sets the area of interest of the image to be decoded.

@param aRect
	   A reference to a TRect that specifies the location and size of the region to be decoded.

*/
EXPORT_C void CImageProcessorExtension::SetClippingRect(const TRect& aRect)
	{
	iClippingRect = aRect;
	}

/**
Sets the scaling coefficient for the decode.

@param aScalingCoeff
	   The scaling coefficient.

@see TImageConvScaler::SetScalingL
*/
EXPORT_C void CImageProcessorExtension::SetScaling(TInt aScalingCoeff)
	{
	iScalingCoeff = aScalingCoeff;
	}

/**
Sets the desired size of the destination image for the decode.

@param aDesiredSize
	   The desired size of the destination image.

@see TImageConvScaler::SetScalingL
*/
EXPORT_C void CImageProcessorExtension::SetScaling(const TSize& aDesiredSize)
	{
	iDesiredSize = aDesiredSize;
	}

/**
Sets the operation to be applied to the image.

@param aOperation
	   The operation to apply to the image.

@see TImageConvScaler::SetScalingL
*/
EXPORT_C void CImageProcessorExtension::SetOperation(TTransformOptions aOperation)
	{
	iOperation = aOperation;
	}

/**
Sets an initial one-off number of scanlines to be skipped.
This must be called prior to calling SetYPosIncrement(),
if it is to be used.

@param  aNumberOfScanlines
        The number of scanlines to skip.
        
@see CImageProcessor::SetYPosIncrement()
*/
EXPORT_C void CImageProcessorExtension::SetInitialScanlineSkipPadding(TInt aNumberOfScanlines)
	{
	iNumberOfScanlinesToSkip = aNumberOfScanlines;
	}

//
// ImageProcessorUtility
//

//
//	CColorImageProcessor
//

/**
 * @see CImageProcessor.
 * @internalComponent
 */
void CColorImageProcessor::CreateBlockBufferL(TInt aBlockArea)
	{
	delete[] iBlockBuffer;
	iBlockBuffer = NULL;

	if(aBlockArea)
		iBlockBuffer = new (ELeave) TRgb[aBlockArea];

	iBlockArea = aBlockArea;
	}

/**
 * Destructor.
 * @see CImageProcessor.
 * @internalComponent
 */
CColorImageProcessor::~CColorImageProcessor()
	{
	delete[] iBlockBuffer;
	}

/**
 * @see CImageProcessor.
 * @internalComponent
 */
TBool CColorImageProcessor::SetPixelRun(TRgb aColor,TInt aCount)
	{
	TBool returnValue = EFalse;

	while(aCount--)
		returnValue |= SetPixel(aColor);

	return returnValue;
	}

/**
 * @see CImageProcessor.
 * @internalComponent
 */
TBool CColorImageProcessor::SetPixels(TRgb* aColorBuffer,TInt aBufferLength)
	{
	TBool returnValue = EFalse;

	while(aBufferLength--)
		returnValue |= SetPixel(*aColorBuffer++);

	return returnValue;
	}

/**
 * @see CImageProcessor.
 * @internalComponent
 */
TBool CColorImageProcessor::SetMonoPixel(TInt aGray256)
	{
	return SetPixel(TRgb(aGray256,aGray256,aGray256));
	}

/**
 * @see CImageProcessor.
 * @internalComponent
 */
TBool CColorImageProcessor::SetMonoPixelRun(TInt aGray256,TInt aCount)
	{
	return SetPixelRun(TRgb(aGray256,aGray256,aGray256),aCount);
	}

/**
 * @see CImageProcessor.
 * @internalComponent
 */
TBool CColorImageProcessor::SetMonoPixels(TUint32* aGray256Buffer,TInt aBufferLength)
	{
	TBool returnValue = EFalse;

	while(aBufferLength--)
		{
		TUint32 gray256 = *aGray256Buffer++;
		returnValue = SetPixel(TRgb(gray256,gray256,gray256));
		}
	return returnValue;
	}

/**
 * @see CImageProcessor.
 * @internalComponent
 */
TBool CColorImageProcessor::SetMonoPixelBlock(TUint32* aGray256Buffer)
	{
	ASSERT(iBlockBuffer);

	TRgb* blockBufferPtr = iBlockBuffer;
	TRgb* blockBufferPtrLimit = blockBufferPtr+iBlockArea;

	while(blockBufferPtr<blockBufferPtrLimit)
		{
		TUint32 gray256 = *aGray256Buffer++;
		*blockBufferPtr++ = TRgb(gray256,gray256,gray256);
		}

	return SetPixelBlock(iBlockBuffer);
	}

//
//	CMonochromeImageProcessor
//

/**
 * @see CImageProcessor.
 */
void CMonochromeImageProcessor::CreateBlockBufferL(TInt aBlockArea)
	{
	delete[] iBlockBuffer;
	iBlockBuffer = NULL;

	iBlockBuffer = new (ELeave) TUint32[aBlockArea];
	iBlockArea = aBlockArea;
	}

/**
 * Destructor.
 * @see CImageProcessor.
 */
CMonochromeImageProcessor::~CMonochromeImageProcessor()
	{
	delete []iBlockBuffer;
	}

/**
 * @see CImageProcessor.
 */
TBool CMonochromeImageProcessor::SetMonoPixelRun(TInt aGray256,TInt aCount)
	{
	TBool returnValue = EFalse;

	while(aCount--)
		returnValue = SetMonoPixel(aGray256);

	return returnValue;
	}

/**
 * @see CImageProcessor.
 */
TBool CMonochromeImageProcessor::SetMonoPixels(TUint32* aGray256Buffer,TInt aBufferLength)
	{
	TBool returnValue = EFalse;

	while(aBufferLength--)
		returnValue = SetMonoPixel(*aGray256Buffer++);

	return returnValue;
	}

/**
 * @see CImageProcessor.
 */
TBool CMonochromeImageProcessor::SetPixel(TRgb aColor)
	{
	return SetMonoPixel(TColorConvertor::RgbToMonochrome(aColor));
	}

/**
 * @see CImageProcessor.
 */
TBool CMonochromeImageProcessor::SetPixelRun(TRgb aColor,TInt aCount)
	{
	return SetMonoPixelRun(TColorConvertor::RgbToMonochrome(aColor),aCount);
	}

/**
 * @see CImageProcessor.
 */
TBool CMonochromeImageProcessor::SetPixels(TRgb* aColorBuffer,TInt aBufferLength)
	{
	TBool returnValue = EFalse;

	while(aBufferLength--)
		returnValue = SetMonoPixel(TColorConvertor::RgbToMonochrome(*aColorBuffer++));

	return returnValue;
	}

/**
 * @see CImageProcessor.
 */
TBool CMonochromeImageProcessor::SetPixelBlock(TRgb* aColorBuffer)
	{
	ASSERT(iBlockBuffer);

	TUint32* blockBufferPtr = iBlockBuffer;
	TUint32* blockBufferPtrLimit = blockBufferPtr+iBlockArea;

	while(blockBufferPtr<blockBufferPtrLimit)
		*blockBufferPtr++ = TColorConvertor::RgbToMonochrome(*aColorBuffer++);

	return SetMonoPixelBlock(iBlockBuffer);
	}

//
// CPixelWriter
//

/**
 *
 * Static factory function to create CPixelWriter objects.
 *
 * @return  Pointer to a fully constructed CPixelWriter object. 
 */
CPixelWriter* CPixelWriter::NewL()
	{
	return new(ELeave) CPixelWriter;
	}

/**
 *
 * Default constructor for this class.
 */
CPixelWriter::CPixelWriter():
	iYInc(1)
	{}	
	
/**
 *
 * Destructor.
 */
CPixelWriter::~CPixelWriter()
	{
	Reset();
	ASSERT(iColorConv==NULL);
	ASSERT(iRgbBuffer==NULL);
	ASSERT(iIndexBuffer==NULL);
	}

/**
 *
 * @see CImageProcessor
 */
void CPixelWriter::PrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect)
	{
	DoPrepareL(aBitmap,aImageRect,NULL);
	}

/**
 *
 * @see CImageProcessor
 */
void CPixelWriter::PrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect,const TSize& aRgbBlockSize)
	{
	DoPrepareL(aBitmap,aImageRect,&aRgbBlockSize);
	}

/**
 *
 * @see CImageProcessor.
 */
void CPixelWriter::SetYPosIncrement(TInt aYInc)
	{
	iYInc = aYInc - iNumberOfScanlinesToSkip;
	}

/**
 *
 * @see CImageProcessor.
 */
void CPixelWriter::SetLineRepeat(TInt aLineRepeat)
	{
	ASSERT(aLineRepeat>=0);
	iLineRepeat = aLineRepeat;
	}

/**
 *
 * @see CImageProcessor.
 */
void CPixelWriter::SetPixelPadding(TInt aNumberOfPixels)
	{
	iPixelPadding = aNumberOfPixels;
	}

/**
 *
 * @see CImageProcessor.
 */
TBool CPixelWriter::SetPixel(TRgb aColor)
	{
	*iRgbBufferPtr++ = aColor;

	if (iRgbBufferPtr == iRgbBufferPtrLimit)
		return FlushPixels();

	return EFalse;
	}

/**
 *
 * @see CImageProcessor.
 */
TBool CPixelWriter::SetPixelRun(TRgb aColor,TInt aCount)
	{
	while(aCount)
		{
		TRgb* ptr = iRgbBufferPtr;
		TRgb* limit = ptr+aCount;
		if(limit>iRgbBufferPtrLimit)
			limit = iRgbBufferPtrLimit;

		TInt n = limit-ptr;
		aCount -= n;

		if(n&1)
			*ptr++ = aColor;
		if(n&2)
			{
			*ptr++ = aColor;
			*ptr++ = aColor;
			}
		if(n&4)
			{
			*ptr++ = aColor;
			*ptr++ = aColor;
			*ptr++ = aColor;
			*ptr++ = aColor;
			}
		while(ptr<limit)
			{
			*ptr++ = aColor;
			*ptr++ = aColor;
			*ptr++ = aColor;
			*ptr++ = aColor;
			*ptr++ = aColor;
			*ptr++ = aColor;
			*ptr++ = aColor;
			*ptr++ = aColor;
			}

		iRgbBufferPtr = ptr;

		if(ptr!=iRgbBufferPtrLimit)
			break;

		if(FlushPixels())
			return ETrue;
		}

	return EFalse;
	}

/**
 *
 * @see CImageProcessor.
 */
TBool CPixelWriter::SetPixels(TRgb* aColorBuffer, TInt aBufferLength)
	{
	if (aBufferLength >= KPixelWriterBufferThreeQuarter)
		{
		TRgb* rgbBuffer = iRgbBuffer;

		if (iRgbBufferPtr != rgbBuffer) 
			{
			// flush rest of the pixels 
			if(FlushPixels())
				{
				return ETrue;
				}
			}

		// use external buffer without copying data
		TBool rValue = EFalse;

		while (aBufferLength && !rValue)
			{
			TInt bufferLength = (aBufferLength>KPixelWriterBufferSize)?KPixelWriterBufferSize:aBufferLength;
			iRgbBuffer = aColorBuffer;
			iRgbBufferPtr = aColorBuffer+bufferLength;
			iRgbBufferPtrLimit = aColorBuffer+bufferLength;

			rValue = FlushPixels();
			aBufferLength -= bufferLength;
			aColorBuffer += bufferLength;
			}
		
		// restore pointers to inner buffer
		iRgbBuffer = rgbBuffer;
		iRgbBufferPtr = rgbBuffer;
		iRgbBufferPtrLimit = rgbBuffer+KPixelWriterBufferSize;
		
		return rValue;
		}

	while(aBufferLength)
		{
		TRgb* ptr = iRgbBufferPtr;
		TRgb* limit = ptr+aBufferLength;
		if(limit>iRgbBufferPtrLimit)
			limit = iRgbBufferPtrLimit;

		TInt n = limit-ptr;
		aBufferLength -= n;

		if(n&1)
			*ptr++ = *aColorBuffer++;
		if(n&2)
			{
			*ptr++ = *aColorBuffer++;
			*ptr++ = *aColorBuffer++;
			}
		while(ptr<limit)
			{
			*ptr++ = *aColorBuffer++;
			*ptr++ = *aColorBuffer++;
			*ptr++ = *aColorBuffer++;
			*ptr++ = *aColorBuffer++;
			}

		iRgbBufferPtr = ptr;

		if(ptr!=iRgbBufferPtrLimit)
			break;

		if(FlushPixels())
			return ETrue;
		}

	return EFalse;
	}

/**
 *
 * @see CImageProcessor.
 */
TBool CPixelWriter::SetPixelBlock(TRgb* aColorBuffer)
	{
	ASSERT(aColorBuffer);

	TUint32* indexBufferPtr = iIndexBuffer;
	if (iDisplayMode==EColor16M || iDisplayMode == EColor16MU || iDisplayMode == EColor16MA)
		{
		indexBufferPtr = reinterpret_cast<TUint32*>(aColorBuffer);
		}
	else
		{
		SetPixelBlockIndex(aColorBuffer);
		}

	TInt ySkip = 0;
	if(iNumberOfScanlinesToSkip > 0)
		{
		ySkip = iNumberOfScanlinesToSkip * iBlockSize.iWidth;
		indexBufferPtr += ySkip;
		ySkip = iNumberOfScanlinesToSkip;
		iNumberOfScanlinesToSkip = 0; // Only call this conditional once.
		}
	
	TInt imageWidth = iImageRegion.iBr.iX;
	TInt imageHeight = iImageRegion.iBr.iY;
	TInt endOfImage = iDrawBottomUp ? -1 : imageHeight;
	
	// The minimum number of pixels to render horizontally
	TInt minWidth = Min(iBlockSize.iWidth, imageWidth - iPos.iX);
	
	// The next vertical position.  Note that this is usually the height of the block, but 
	// in the case of the first block when clipping is required, this will be reduced by ySkip.
	TInt nextYPos = iDrawBottomUp ?	(iPos.iY - iBlockSize.iHeight) + ySkip :
									(iPos.iY + iBlockSize.iHeight) - ySkip;
	
	TInt endPosition = iDrawBottomUp ? Max(nextYPos, endOfImage) : Min(nextYPos, endOfImage);
	
	// Once the first block has been processed, iYInc is set to block height
	iYInc = iDrawBottomUp ? -iBlockSize.iHeight + ySkip : iBlockSize.iHeight - ySkip;
				
	// Skip unnecessary pixels (for cropping, or padding when rotated)
	indexBufferPtr += iPixelPadding;
	
	TPoint pos(iPos);
	iUtil.Begin();
	for(;iDrawBottomUp ? pos.iY > endPosition : pos.iY < endPosition; iDrawBottomUp ? pos.iY-- : pos.iY++)
		{
		iUtil.SetPos(pos);
		iUtil.SetPixels(indexBufferPtr, minWidth);
		indexBufferPtr += iBlockSize.iWidth; // next line in block
		}
	iUtil.End();

	iPos.iX += iBlockSize.iWidth;
	
	if (iPos.iX >= imageWidth)
		{
		return NewLine();
		}

	return EFalse;
	}

/**
 *
 * @see CImageProcessor.
 */
TBool CPixelWriter::FlushPixels()
	{
	TRgb* rgbBufferPtrLimit = iRgbBufferPtr;
	iRgbBufferPtr = iRgbBuffer;

	if(iPos.iY < iImageRegion.iTl.iY || iPos.iY >= iImageRegion.iBr.iY)
		return ETrue;

	iUtil.Begin();

	TBool finished = EFalse;
	for (TRgb* rgbBufferPtr = iRgbBuffer; rgbBufferPtr < rgbBufferPtrLimit; )
		{
		TInt pixelsToSkip = Min(rgbBufferPtrLimit - rgbBufferPtr,iPixelsToSkip);
		rgbBufferPtr += pixelsToSkip;
		iPixelsToSkip -= pixelsToSkip;

		if(iPixelsToSkip)
			break;

		TInt pixelsToFlush = Min(rgbBufferPtrLimit - rgbBufferPtr,iImageRegion.iBr.iX - iPos.iX);

		if(!pixelsToFlush)
			break;

		SetPixelBufferIndex(rgbBufferPtr,pixelsToFlush);
		rgbBufferPtr += pixelsToFlush;

		TBool fillDown = iYInc > 0;
		TPoint pos(iPos);
		TInt posYLimit;
		if(fillDown)
			posYLimit = Min(pos.iY + iLineRepeat + 1 ,iImageRegion.iBr.iY);
		else
			posYLimit = Max(pos.iY - iLineRepeat - 1 ,iImageRegion.iTl.iY-1);

		for(;fillDown ? pos.iY < posYLimit : pos.iY > posYLimit; fillDown ? pos.iY++ : pos.iY--)
			{
			if(!iUtil.SetPos(pos-iImageRegion.iTl))
				{
				iUtil.End();
				return ETrue;
				}
			iUtil.SetPixels(iIndexBuffer,pixelsToFlush);
			}

		iPos.iX += pixelsToFlush;
		if (iPos.iX >= iImageRegion.iBr.iX)
			{
			finished = NewLine();
			if(finished)
				break;
			}
		}

	iUtil.End();

	return finished;
	}

/**
 *
 * @see CImageProcessor.
 */
TBool CPixelWriter::SetPos(const TPoint& aPosition)
	{
	if(iImageRegion.Contains(aPosition))
		{
		FlushPixels();
		iPixelsToSkip = 0;
		iPos = aPosition;
		return ETrue;
		}

	return EFalse;
	}

void CPixelWriter::Reset()
	{
	delete iColorConv;
	iColorConv = NULL;

	delete[] iRgbBuffer;
	iRgbBuffer = NULL;

	delete[] iIndexBuffer;
	iIndexBuffer = NULL;

	iPos.SetXY(0,0);
	iPixelsToSkip = 0;
	iImageRegion.SetRect(0,0,0,0);
	iBlockSize.SetSize(0,0);
	
	iDrawBottomUp = EFalse;
	}

void CPixelWriter::DoPrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect,const TSize* aBlockSize)
	{
	if( (aImageRect.iTl.iX<0) || (aImageRect.iTl.iY<0) || (aImageRect.Size().iWidth>aBitmap.SizeInPixels().iWidth) || (aImageRect.Size().iHeight>aBitmap.SizeInPixels().iHeight) )
		{
		User::Leave(KErrArgument);
		}

	Reset();
	
	iDisplayMode = aBitmap.DisplayMode();

	iImageRegion = aImageRect;

	ASSERT(iColorConv==NULL);
	iColorConv = TColorConvertor::NewL(aBitmap.DisplayMode());
	iUtil.SetBitmapL(&aBitmap);

	if (aBlockSize)
		{
		if (aBlockSize->iWidth <= 0 || aBlockSize->iHeight <= 0)
			{
			User::Leave(KErrArgument);
			}

		iBlockSize = *aBlockSize;
		iBlockArea = iBlockSize.iWidth * iBlockSize.iHeight;
		
		ASSERT(iIndexBuffer == NULL);
		iIndexBuffer = new(ELeave) TUint32[iBlockArea];

		iIndexBufferPtrLimit = iIndexBuffer + iBlockArea;
		CreateBlockBufferL(iBlockArea);
		
		switch(iOperation)
			{
			case EDecodeRotate180:
			case EDecodeRotate270:
			case EDecodeHorizontalFlip:
			case EDecodeVerticalFlipRotate90:
				iDrawBottomUp = ETrue;
				break;
			default:
				iDrawBottomUp = EFalse;
			}
		
		iYInc = iDrawBottomUp ? -iBlockSize.iHeight : iBlockSize.iHeight;
		iStartPosition.SetXY(iImageRegion.iTl.iX, iDrawBottomUp ? iImageRegion.iBr.iY - 1 : 0);
		iEndPosition.SetXY(iImageRegion.iBr.iX, iDrawBottomUp ?
							iImageRegion.iTl.iY - 1 : iImageRegion.iBr.iY);
		iPos = iStartPosition;
		}
	else
		{
		iPos = iImageRegion.iTl;
		iStartPosition = iPos;
		iEndPosition = aImageRect.iBr;
		
		ASSERT(iRgbBuffer == NULL);
		iRgbBuffer = new(ELeave) TRgb[KPixelWriterBufferSize];

		iRgbBufferPtr = iRgbBuffer;
		iRgbBufferPtrLimit = iRgbBuffer + KPixelWriterBufferSize;

		ASSERT(iIndexBuffer == NULL);
		iIndexBuffer = new(ELeave) TUint32[KPixelWriterBufferSize];

		iIndexBufferPtrLimit = iIndexBuffer + KPixelWriterBufferSize;
		}
	}

TBool CPixelWriter::NewLine()
	{
	iPos.iX = iStartPosition.iX;
	iPos.iY += iYInc;

	if(iPos.iY < iStartPosition.iY || iPos.iY >= iEndPosition.iY)
		{
		return ETrue;
		}
	
	iPixelsToSkip = iPixelPadding;
	return EFalse;
	}

void CPixelWriter::SetPixelBufferIndex(TRgb* aColorBuffer,TInt aCount)
	{
	iColorConv->ColorToIndex(REINTERPRET_CAST(TInt*,iIndexBuffer),aColorBuffer,aCount);
	}

void CPixelWriter::SetPixelBlockIndex(TRgb* aColorBuffer)
	{
	iColorConv->ColorToIndex(REINTERPRET_CAST(TInt*,iIndexBuffer),aColorBuffer,iIndexBufferPtrLimit-iIndexBuffer);
	}

//
//	CMonochromePixelWriter
//

/**
 *
 * Static factory function to create CMonochromePixelWriter objects.
 *
 * @return  Pointer to a fully constructed CMonochromePixelWriter object. 
 */
CMonochromePixelWriter* CMonochromePixelWriter::NewL()
	{
	return new(ELeave) CMonochromePixelWriter;
	}

/**
 *
 * Default constructor for this class.
 */
CMonochromePixelWriter::CMonochromePixelWriter():
	iYInc(1)
	{}

/**
 *
 * Destructor
 */
CMonochromePixelWriter::~CMonochromePixelWriter()
	{
	Reset();
	}

/**
 *
 * @see CImageProcessor
 */
void CMonochromePixelWriter::PrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect)
	{
	DoPrepareL(aBitmap,aImageRect,NULL);
	}

/**
 *
 * @see CImageProcessor
 */
void CMonochromePixelWriter::PrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect,const TSize& aRgbBlockSize)
	{
	DoPrepareL(aBitmap,aImageRect,&aRgbBlockSize);
	}

/**
 *
 * @see CImageProcessor.
 */
void CMonochromePixelWriter::SetYPosIncrement(TInt aYInc)
	{
	iYInc = aYInc - iNumberOfScanlinesToSkip;
	}

/**
 *
 * @see CImageProcessor.
 */
void CMonochromePixelWriter::SetPixelPadding(TInt aNumberOfPixels)
	{
	iPixelPadding = aNumberOfPixels;
	}

/**
 *
 * @see CImageProcessor.
 */
void CMonochromePixelWriter::SetLineRepeat(TInt aLineRepeat)
	{
	ASSERT(aLineRepeat>=0);
	iLineRepeat = aLineRepeat;
	}

/**
 *
 * @see CImageProcessor.
 */
TBool CMonochromePixelWriter::SetMonoPixel(TInt aGray256)
	{
	*iGray256BufferPtr++ = aGray256;

	if (iGray256BufferPtr != iGray256BufferPtrLimit)
		return EFalse;

	return FlushPixels();
	}

/**
 *
 * @see CImageProcessor.
 */
TBool CMonochromePixelWriter::SetMonoPixelRun(TInt aGray256,TInt aCount)
	{
	while(aCount)
		{
		TUint32* ptr = iGray256BufferPtr;
		TUint32* limit = ptr+aCount;
		if(limit>iGray256BufferPtrLimit)
			limit = iGray256BufferPtrLimit;

		TInt n = limit-ptr;
		aCount -= n;

		if(n&1)
			*ptr++ = aGray256;
		if(n&2)
			{
			*ptr++ = aGray256;
			*ptr++ = aGray256;
			}
		if(n&4)
			{
			*ptr++ = aGray256;
			*ptr++ = aGray256;
			*ptr++ = aGray256;
			*ptr++ = aGray256;
			}
		while(ptr<limit)
			{
			*ptr++ = aGray256;
			*ptr++ = aGray256;
			*ptr++ = aGray256;
			*ptr++ = aGray256;
			*ptr++ = aGray256;
			*ptr++ = aGray256;
			*ptr++ = aGray256;
			*ptr++ = aGray256;
			}

		iGray256BufferPtr = ptr;

		if(ptr!=iGray256BufferPtrLimit)
			break;

		if(FlushPixels())
			return ETrue;
		}

	return EFalse;
	}

/**
 *
 * @see CImageProcessor.
 */
TBool CMonochromePixelWriter::SetMonoPixels(TUint32* aGray256Buffer,TInt aBufferLength)
	{

	if (aBufferLength >= KPixelWriterBufferThreeQuarter)
		{
		TUint32* gray256Buffer = iGray256Buffer;

		if (iGray256BufferPtr != gray256Buffer) 
			{
			// flush rest of the pixels 
			if(FlushPixels())
				{
				return ETrue;
				}
			}

		// use external buffer without copying data
		TBool rValue = EFalse;
		
		while (aBufferLength && !rValue)
			{
			TInt bufferLength = (aBufferLength>KPixelWriterBufferSize)?KPixelWriterBufferSize:aBufferLength;
			iGray256Buffer = aGray256Buffer;
			iGray256BufferPtr = aGray256Buffer+bufferLength;
			iGray256BufferPtrLimit = aGray256Buffer+bufferLength;

			rValue = FlushPixels();
			aBufferLength -= bufferLength;
			aGray256Buffer += bufferLength;
			}
		
		// restore pointers to inner buffer
		iGray256Buffer = gray256Buffer;
		iGray256BufferPtr = gray256Buffer;
		iGray256BufferPtrLimit = gray256Buffer+KPixelWriterBufferSize;
		
		return rValue;
		}

	while(aBufferLength)
		{
		TUint32* ptr = iGray256BufferPtr;
		TUint32* limit = ptr+aBufferLength;
		if(limit>iGray256BufferPtrLimit)
			limit = iGray256BufferPtrLimit;

		TInt n = limit-ptr;
		aBufferLength -= n;

		if(n&1)
			*ptr++ = *aGray256Buffer++;
		if(n&2)
			{
			*ptr++ = *aGray256Buffer++;
			*ptr++ = *aGray256Buffer++;
			}
		while(ptr<limit)
			{
			*ptr++ = *aGray256Buffer++;
			*ptr++ = *aGray256Buffer++;
			*ptr++ = *aGray256Buffer++;
			*ptr++ = *aGray256Buffer++;
			}

		iGray256BufferPtr = ptr;

		if(ptr!=iGray256BufferPtrLimit)
			break;

		if(FlushPixels())
			return ETrue;
		}

	return EFalse;
	}

/**
 *
 * @see CImageProcessor.
 */
TBool CMonochromePixelWriter::SetMonoPixelBlock(TUint32* aGray256Buffer)
	{
	SetPixelBlockIndex(aGray256Buffer);
	
	TUint32* indexBufferPtr = iIndexBuffer;

	TInt ySkip = 0;
	if(iNumberOfScanlinesToSkip > 0)
		{
		ySkip = iNumberOfScanlinesToSkip * iBlockSize.iWidth;
		indexBufferPtr += ySkip;
		ySkip = iNumberOfScanlinesToSkip;
		iNumberOfScanlinesToSkip = 0; // Only call this conditional once.
		}
	
	TInt imageWidth = iImageRegion.iBr.iX;
	TInt imageHeight = iImageRegion.iBr.iY;
	TInt endOfImage = iDrawBottomUp ? -1 : imageHeight;
	
	// The minimum number of pixels to render horizontally
	TInt minWidth = Min(iBlockSize.iWidth, imageWidth - iPos.iX);
	
	// The next vertical position.  Note that this is usually the height of the block, but 
	// in the case of the first block when clipping is required, this will be reduced by ySkip.
	TInt nextYPos = iDrawBottomUp ?	(iPos.iY - iBlockSize.iHeight) + ySkip :
										(iPos.iY + iBlockSize.iHeight) - ySkip;
	
	TInt endPosition = iDrawBottomUp ? Max(nextYPos, endOfImage) : Min(nextYPos, endOfImage);
	
	// Once the first block has been processed, iYInc is set to block height
	iYInc = iDrawBottomUp ? -iBlockSize.iHeight + ySkip : iBlockSize.iHeight - ySkip;
				
	// Skip unnecessary pixels (for cropping, or padding when rotated)
	indexBufferPtr += iPixelPadding;
	
	TPoint pos(iPos);
	iUtil.Begin();
	for(;iDrawBottomUp ? pos.iY > endPosition : pos.iY < endPosition; iDrawBottomUp ? pos.iY-- : pos.iY++)
		{
		iUtil.SetPos(pos);
		iUtil.SetPixels(indexBufferPtr, minWidth);
		indexBufferPtr += iBlockSize.iWidth; // next line in block
		}
	iUtil.End();

	iPos.iX += iBlockSize.iWidth;
	
	if (iPos.iX >= imageWidth)
		{
		return NewLine();
		}

	return EFalse;
	}

/**
 *
 * @see CImageProcessor.
 */
TBool CMonochromePixelWriter::FlushPixels()
	{
	TUint32* gray256BufferPtrLimit = iGray256BufferPtr;
	iGray256BufferPtr = iGray256Buffer;

	if(iPos.iY < iImageRegion.iTl.iY || iPos.iY >= iImageRegion.iBr.iY)
		return ETrue;

	iUtil.Begin();

	TBool finished = EFalse;
	for (TUint32* gray256BufferPtr = iGray256Buffer; gray256BufferPtr < gray256BufferPtrLimit; )
		{
		TInt pixelsToSkip = Min(gray256BufferPtrLimit - gray256BufferPtr,iPixelsToSkip);
		gray256BufferPtr += pixelsToSkip;
		iPixelsToSkip -= pixelsToSkip;

		if(iPixelsToSkip)
			break;

		TInt pixelsToFlush = Min(gray256BufferPtrLimit - gray256BufferPtr,iImageRegion.iBr.iX - iPos.iX);

		if(!pixelsToFlush)
			break;

		SetPixelBufferIndex(gray256BufferPtr,pixelsToFlush);
		gray256BufferPtr += pixelsToFlush;

		TBool fillDown = iYInc > 0;
		TPoint pos(iPos);
		TInt posYLimit;
		if(fillDown)
			posYLimit = Min(pos.iY + iLineRepeat + 1 ,iImageRegion.iBr.iY);
		else
			posYLimit = Max(pos.iY - iLineRepeat - 1 ,iImageRegion.iTl.iY-1);

		for(;fillDown ? pos.iY < posYLimit : pos.iY > posYLimit; fillDown ? pos.iY++ : pos.iY--)
			{
			if(!iUtil.SetPos(pos-iImageRegion.iTl))
				{
				iUtil.End();
				return ETrue;
				}
			iUtil.SetPixels(iIndexBuffer,pixelsToFlush);
			}

		iPos.iX += pixelsToFlush;
		if (iPos.iX >= iImageRegion.iBr.iX)
			{
			finished = NewLine();
			if(finished)
				break;
			}
		}

	iUtil.End();

	return finished;
	}

/**
 *
 * @see CImageProcessor.
 */
TBool CMonochromePixelWriter::SetPos(const TPoint& aPosition)
	{
	if(iImageRegion.Contains(aPosition))
		{
		FlushPixels();
		iPixelsToSkip = 0;
		iPos = aPosition;
		return ETrue;
		}

	return EFalse;
	}

void CMonochromePixelWriter::Reset()
	{
	delete iColorConv;
	iColorConv = NULL;

	delete[] iGray256Buffer;
	iGray256Buffer = NULL;

	delete[] iIndexBuffer;
	iIndexBuffer = NULL;

	iPos.SetXY(0,0);
	iPixelsToSkip = 0;
	iImageRegion.SetRect(0,0,0,0);
	iBlockSize.SetSize(0,0);
	
	iDrawBottomUp = EFalse;
	}

void CMonochromePixelWriter::DoPrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect,const TSize* aBlockSize)
	{
	if( (aImageRect.iTl.iX<0) || (aImageRect.iTl.iY<0) || (aImageRect.Size().iWidth>aBitmap.SizeInPixels().iWidth) || (aImageRect.Size().iHeight>aBitmap.SizeInPixels().iHeight) )
		{
		User::Leave(KErrArgument);
		}

	Reset();

	iImageRegion = aImageRect;

	iColorConv = TColorConvertor::NewL(aBitmap.DisplayMode());
	iUtil.SetBitmapL(&aBitmap);

	if (aBlockSize)
		{
		if (aBlockSize->iWidth <= 0 || aBlockSize->iHeight <= 0)
			{
			User::Leave(KErrArgument);
			}

		iBlockSize = *aBlockSize;
		iBlockArea = iBlockSize.iWidth * iBlockSize.iHeight;
		
		ASSERT(iIndexBuffer == NULL);
		iIndexBuffer = new(ELeave) TUint32[iBlockArea];

		iIndexBufferPtrLimit = iIndexBuffer + iBlockArea;
		CreateBlockBufferL(iBlockArea);
		
		switch(iOperation)
			{
			case EDecodeRotate180:
			case EDecodeRotate270:
			case EDecodeHorizontalFlip:
			case EDecodeVerticalFlipRotate90:
				iDrawBottomUp = ETrue;
				break;
			default:
				iDrawBottomUp = EFalse;		
			}
		
		iYInc = iDrawBottomUp ? -iBlockSize.iHeight : iBlockSize.iHeight;
		iStartPosition.SetXY(iImageRegion.iTl.iX, iDrawBottomUp ? iImageRegion.iBr.iY - 1 : 0);
		iEndPosition.SetXY(iImageRegion.iBr.iX, iDrawBottomUp ?
							iImageRegion.iTl.iY - 1 : iImageRegion.iBr.iY);
		iPos = iStartPosition;
		}
	else
		{
		iPos = iImageRegion.iTl;
		iStartPosition = iPos;
		iEndPosition = aImageRect.iBr;

		ASSERT(iGray256Buffer == NULL);
		iGray256Buffer = new(ELeave) TUint32[KPixelWriterBufferSize];

		iGray256BufferPtr = iGray256Buffer;
		iGray256BufferPtrLimit = iGray256Buffer + KPixelWriterBufferSize;

		ASSERT(iIndexBuffer == NULL);
		iIndexBuffer = new(ELeave) TUint32[KPixelWriterBufferSize];

		iIndexBufferPtrLimit = iIndexBuffer + KPixelWriterBufferSize;
		}
	
	for(TInt i=0; i<256; i++)
		{
		iIndexLookup[i] = iColorConv->ColorIndex(TRgb(i,i,i));	
		}
	}

TBool CMonochromePixelWriter::NewLine()
	{
	iPos.iX = iStartPosition.iX;
	iPos.iY += iYInc;

	if(iPos.iY < iStartPosition.iY || iPos.iY >= iEndPosition.iY)
		{
		return ETrue;
		}
	
	iPixelsToSkip = iPixelPadding;
	return EFalse;
	}

void CMonochromePixelWriter::SetPixelBlockIndex(TUint32* aGray256Buffer)
	{
	CMonochromePixelWriter::SetPixelBufferIndex(aGray256Buffer,iBlockArea);
	}

void CMonochromePixelWriter::SetPixelBufferIndex(TUint32* aGray256Buffer,TInt aCount)
	{
	TUint32* indexBufferPtr = iIndexBuffer;
	TUint32* indexBufferPtrLimit = indexBufferPtr+aCount;
	TUint32* indexLookup = iIndexLookup;

	if(aCount&1)
		*indexBufferPtr++ = indexLookup[*aGray256Buffer++];
	if(aCount&2)
		{
		*indexBufferPtr++ = indexLookup[*aGray256Buffer++];
		*indexBufferPtr++ = indexLookup[*aGray256Buffer++];
		}
	while (indexBufferPtr < indexBufferPtrLimit)
		{
		*indexBufferPtr++ = indexLookup[*aGray256Buffer++];
		*indexBufferPtr++ = indexLookup[*aGray256Buffer++];
		*indexBufferPtr++ = indexLookup[*aGray256Buffer++];
		*indexBufferPtr++ = indexLookup[*aGray256Buffer++];
		}
	}

//
// CErrorDiffuser::TColorError
//

inline CErrorDiffuser::TColorError::TColorError():
	iRedError(0),
	iGreenError(0),
	iBlueError(0)
	{}

inline CErrorDiffuser::TColorError::TColorError(TInt aRedError,TInt aGreenError,TInt aBlueError):
	iRedError(aRedError),
	iGreenError(aGreenError),
	iBlueError(aBlueError)
	{}

inline void CErrorDiffuser::TColorError::AdjustColor(TRgb& aColor) const
	{
	TInt red = ColorCcomponent::ClampColorComponent((iRedError >> 4) + aColor.Red());
	TInt green = ColorCcomponent::ClampColorComponent((iGreenError >> 4) + aColor.Green());
	TInt blue = ColorCcomponent::ClampColorComponent((iBlueError >> 4) + aColor.Blue());
	aColor = TRgb(red,green,blue);
	}

inline void CErrorDiffuser::TColorError::SetError(TRgb aIdealColor,TRgb aActualColor)
	{
	iRedError = aIdealColor.Red() - aActualColor.Red();
	iGreenError = aIdealColor.Green() - aActualColor.Green();
	iBlueError = aIdealColor.Blue() - aActualColor.Blue();
	}

inline CErrorDiffuser::TColorError CErrorDiffuser::TColorError::operator+(const TColorError& aColorError) const
	{
	TInt redError = iRedError + aColorError.iRedError;
	TInt greenError = iGreenError + aColorError.iGreenError;
	TInt blueError = iBlueError + aColorError.iBlueError;
	return TColorError(redError,greenError,blueError);
	}

inline CErrorDiffuser::TColorError CErrorDiffuser::TColorError::operator-(const TColorError& aColorError) const
	{
	TInt redError = iRedError - aColorError.iRedError;
	TInt greenError = iGreenError - aColorError.iGreenError;
	TInt blueError = iBlueError - aColorError.iBlueError;
	return TColorError(redError,greenError,blueError);
	}

inline CErrorDiffuser::TColorError CErrorDiffuser::TColorError::operator<<(TInt aShift) const
	{
	TInt redError = iRedError << aShift;
	TInt greenError = iGreenError << aShift;
	TInt blueError = iBlueError << aShift;
	return TColorError(redError,greenError,blueError);
	}

inline CErrorDiffuser::TColorError& CErrorDiffuser::TColorError::operator+=(const TColorError& aColorError)
	{
	iRedError += aColorError.iRedError;
	iGreenError += aColorError.iGreenError;
	iBlueError += aColorError.iBlueError;
	return *this;
	}

CErrorDiffuser::CErrorDiffuser()
	{
	}

CErrorDiffuser::~CErrorDiffuser()
	{
	Reset();
	}

void CErrorDiffuser::DoPrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect,const TSize* aBlockSize)
	{
	CPixelWriter::DoPrepareL(aBitmap,aImageRect,aBlockSize);

	TInt scanlineErrorBufferLength = iImageRegion.iBr.iX+2;

	if (iBlockArea > 0)
		{
		ASSERT(iEdgeErrorBuffer == NULL);
		iEdgeErrorBuffer = new(ELeave) TColorError[iBlockSize.iHeight];

		scanlineErrorBufferLength += iBlockSize.iWidth;
		}

	ASSERT(iScanlineErrorBuffer == NULL);
	iScanlineErrorBuffer = new(ELeave) TColorError[scanlineErrorBufferLength];

	if (iDisplayMode == EColor64K) 
		{
			ASSERT(iRedErrorLookupTable == NULL);
			iRedErrorLookupTable = new(ELeave) TInt8[256];
			ASSERT(iGreenErrorLookupTable == NULL);
			iGreenErrorLookupTable = new(ELeave) TInt8[256];
			
			for (TInt i=0;i<256;i++) 
				{
					TInt tmp = i & 0xf8;
					iRedErrorLookupTable[i] = i - (tmp | (tmp >> 5));
					tmp = i & 0xfc;
					iGreenErrorLookupTable[i] = i - (tmp | (tmp >> 6));
				}
		}
	}

void CErrorDiffuser::SetPixelBufferIndex(TRgb* aColorBuffer,TInt aCount)
	{
	// use optimized function for EColor64K mode
	if (iDisplayMode == EColor64K) 
		{
		SetPixelBufferColor64KIndex(aColorBuffer, aCount);
		return;
		}

	TInt clearX = iPos.iX;

	TInt yDiff = iPos.iY - iLastPos.iY;
	if(yDiff != 0)									// On a new line?
		{
		new(&iNextError) TColorError;
		clearX = iImageRegion.iBr.iX;				// To clear to end of line

		if(yDiff == -1 || yDiff == 1)				// Now on ajacent line?
			{
			clearX -= iLastPos.iX;					// Clear end of previous line
			if(clearX)
				{
				Mem::FillZ(iScanlineErrorBuffer + iLastPos.iX + 2, clearX * sizeof(TColorError));
				}
			clearX = iPos.iX;						// To clear up to current position
			}
		iLastPos.iX = iImageRegion.iTl.iX;			// Start of this line
		}

	clearX -= iLastPos.iX;
	if(clearX > 0)									// Treat any skipped pixels as if they produced no error
		{
		new(&iNextError) TColorError;
		Mem::FillZ(iScanlineErrorBuffer + iLastPos.iX + 2, clearX * sizeof(TColorError));
		}

	iLastPos.iY = iPos.iY;
	iLastPos.iX = iPos.iX+aCount;

	TUint32* indexBufferPtr = iIndexBuffer;
	TUint32* indexBufferPtrLimit = indexBufferPtr+aCount;
	TColorError* scanlineErrorBufferPtr = iScanlineErrorBuffer + iPos.iX;
	TColorError error;
	TRgb color;

	while(indexBufferPtr<indexBufferPtrLimit)
		{
		color = *aColorBuffer++;

		iNextError.AdjustColor(color);
		TUint32 index = iColorConv->ColorIndex(color);
		*indexBufferPtr++ = index;

		error.SetError(color, iColorConv->Color(index));

		iNextError = (error << 3) - error; // Set right error for this pixel

		*scanlineErrorBufferPtr++ += error + (error << 1); // Set left-down error for this pixel

		*scanlineErrorBufferPtr += error + (error << 2); // Set down error for this pixel

		iNextError += *(scanlineErrorBufferPtr+1);

		*(scanlineErrorBufferPtr+1) = error; // Set right-down error for this pixel
		}
	}

// faster function (see listing) then Bitmap Util ClampColorComponent
inline TInt CErrorDiffuser::ClipColorComponent(TInt value)
    {
    if (TUint(value) > 0xFF)
        {
        value = value < 0 ? 0 : 0xFF;
        }
    return value;
    }

void CErrorDiffuser::SetPixelBufferColor64KIndex(TRgb* aColorBuffer,TInt aCount)
	{
	TInt clearX = iPos.iX;

	TInt yDiff = iPos.iY - iLastPos.iY;
	if(yDiff != 0)									// On a new line?
		{
		iNextRedError = 0;
		iNextGreenError = 0;
		iNextBlueError = 0;
		clearX = iImageRegion.iBr.iX;				// To clear to end of line

		if(yDiff == -1 || yDiff == 1)				// Now on ajacent line?
			{
			clearX -= iLastPos.iX;					// Clear end of previous line
			if(clearX > 0) 
				{
				Mem::FillZ(iScanlineErrorBuffer + iLastPos.iX + 2, clearX * sizeof(TColorError));
				}
			clearX = iPos.iX;						// To clear up to current position
			}
		iLastPos.iX = iImageRegion.iTl.iX;			// Start of this line
		}

	clearX -= iLastPos.iX;
	if(clearX > 0)									// Treat any skipped pixels as if they produced no error
		{
		iNextRedError = 0;
		iNextGreenError = 0;
		iNextBlueError = 0;
		Mem::FillZ(iScanlineErrorBuffer + iLastPos.iX + 2, clearX * sizeof(TColorError));
		}

	iLastPos.iY = iPos.iY;
	iLastPos.iX = iPos.iX+aCount;

	TUint32* indexBufferPtr = iIndexBuffer;
	TUint32* indexBufferPtrLimit = indexBufferPtr+aCount;

	TColorError* scanlineErrorBufferPtr = iScanlineErrorBuffer + iPos.iX;

	TInt redError = iNextRedError;
	TInt greenError = iNextGreenError;
	TInt blueError = iNextBlueError;
	
	while(indexBufferPtr<indexBufferPtrLimit)
		{
		// red			
		register TInt red = aColorBuffer->Red();
		red = ClipColorComponent(red + (redError >> 4));

		register TInt error = iRedErrorLookupTable[red];
		
		// Set right error for red component
		scanlineErrorBufferPtr->iRedError += error + (error << 1); // Set left-down error for this pixel
		(scanlineErrorBufferPtr+1)->iRedError += error + (error << 2); // Set down error for this pixel
		redError = (scanlineErrorBufferPtr+2)->iRedError + (error << 3) - error; // Set right error for this pixel
		(scanlineErrorBufferPtr+2)->iRedError = error; // Set right-down error for this pixel

		// green			
		register TInt green = aColorBuffer->Green();
			
		green = ClipColorComponent(green + (greenError >> 4));

		error = iGreenErrorLookupTable[green];
		
		// Set right error for green component
		scanlineErrorBufferPtr->iGreenError += error + (error << 1); // Set left-down error for this pixel
		(scanlineErrorBufferPtr+1)->iGreenError += error + (error << 2); // Set down error for this pixel
		greenError = (scanlineErrorBufferPtr+2)->iGreenError + (error << 3) - error; // Set right error for this pixel
		(scanlineErrorBufferPtr+2)->iGreenError = error; // Set right-down error for this pixel

		// blue			
		register TInt blue = aColorBuffer->Blue();
			
		blue = ClipColorComponent(blue + (blueError >> 4));
		
		*indexBufferPtr++ = ((red & 0xf8) << 8) | ((green & 0xfc) << 3) | ((blue & 0xf8) >> 3);
		
		error = iRedErrorLookupTable[blue];// use the same lookup table for blue color

		// Set right error for blue component
		scanlineErrorBufferPtr->iBlueError += error + (error << 1); // Set left-down error for this pixel
		(scanlineErrorBufferPtr+1)->iBlueError += error + (error << 2); // Set down error for this pixel
		blueError = (scanlineErrorBufferPtr+2)->iBlueError + (error << 3) - error; // Set right error for this pixel
		(scanlineErrorBufferPtr+2)->iBlueError = error; // Set right-down error for this pixel

		scanlineErrorBufferPtr++;
		aColorBuffer++;
		}

		iNextRedError = redError;
		iNextGreenError = greenError;
		iNextBlueError = blueError;


	}

void CErrorDiffuser::SetPixelBlockIndex(TRgb* aColorBuffer)
	{
	if(iPos.iY!=iLastPos.iY)
		{
		Mem::FillZ(iEdgeErrorBuffer,sizeof(TColorError) * iBlockSize.iHeight);
		}

	TUint32* indexBufferPtr = iIndexBuffer;

	TColorError error;
	TColorError* edgeErrorBuffer = iEdgeErrorBuffer;

	for (TInt row = 0; row < iBlockSize.iHeight; row++)
		{
		TColorError* errorValue = iScanlineErrorBuffer + iPos.iX;
		TColorError nextError = *edgeErrorBuffer + *errorValue;
		*edgeErrorBuffer = error;

		for (TInt col = 0; col < iBlockSize.iWidth; col++)
			{
			TRgb bufferColor = *aColorBuffer++;
			nextError.AdjustColor(bufferColor);

			TUint32 index = iColorConv->ColorIndex(bufferColor);
			*indexBufferPtr++ = index;

			error.SetError(bufferColor,iColorConv->Color(index));

			if (col > 0)
				*(errorValue - 1) += error + (error << 1); // Set left-down error for this pixel
			else
				*errorValue = error + (error << 1);

			*errorValue += error + (error << 2); // Set down error for this pixel
			errorValue++;

			nextError = (error << 3) - error; // Set right error for this pixel

			if (col < iBlockSize.iWidth)
				{
				nextError += *errorValue;
				*errorValue = error; // Set right-down error for this pixel
				}

			}

		*edgeErrorBuffer++ += nextError;
		}

	iLastPos.iY = iPos.iY;
	iLastPos.iX = iPos.iX+iBlockSize.iWidth;
	}

void CErrorDiffuser::Reset()
	{
	CPixelWriter::Reset();

	delete[] iScanlineErrorBuffer;
	iScanlineErrorBuffer = NULL;

	delete[] iEdgeErrorBuffer;
	iEdgeErrorBuffer = NULL;
	
	delete iRedErrorLookupTable;
	iRedErrorLookupTable = NULL;
	
	delete iGreenErrorLookupTable;
	iGreenErrorLookupTable = NULL;

	}

//
// CMonochromeErrorDiffuser
//


/**
 *
 * Static factory function to create CMonochromeErrorDiffuser objects.
 *
 * @return  Pointer to a fully constructed CMonochromeErrorDiffuser object. 
 */
CMonochromeErrorDiffuser* CMonochromeErrorDiffuser::NewL()
	{
	return new(ELeave) CMonochromeErrorDiffuser;
	}

CMonochromeErrorDiffuser::CMonochromeErrorDiffuser()
	{}

CMonochromeErrorDiffuser::~CMonochromeErrorDiffuser()
	{
	Reset();
	}

void CMonochromeErrorDiffuser::DoPrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect,const TSize* aBlockSize)
	{
	CMonochromePixelWriter::DoPrepareL(aBitmap,aImageRect,aBlockSize);

	TInt scanlineErrorBufferLength = iImageRegion.iBr.iX+2;

	if (iBlockArea > 0)
		{
		ASSERT(iEdgeErrorBuffer == NULL);
		iEdgeErrorBuffer = new(ELeave) TInt[iBlockSize.iHeight];

		Mem::FillZ(iEdgeErrorBuffer,sizeof(TInt) * iBlockSize.iHeight);
		scanlineErrorBufferLength += iBlockSize.iWidth;
		}

	ASSERT(iScanlineErrorBuffer == NULL);
	iScanlineErrorBuffer = new(ELeave) TInt[scanlineErrorBufferLength];

	Mem::FillZ(iScanlineErrorBuffer,sizeof(TInt) * scanlineErrorBufferLength);
	}

void CMonochromeErrorDiffuser::SetPixelBufferIndex(TUint32* aGray256Buffer,TInt aCount)
	{
	TInt clearX = iPos.iX;

	TInt yDiff = iPos.iY - iLastPos.iY;
	if(yDiff != 0)									// On a new line?
		{
		iNextError = 0;
		clearX = iImageRegion.iBr.iX;				// To clear to end of line

		if(yDiff == -1 || yDiff == 1)				// Now on ajacent line?
			{
			clearX -= iLastPos.iX;					// Clear end of previous line
			if(clearX)
				Mem::FillZ(iScanlineErrorBuffer + iLastPos.iX + 2, clearX * sizeof(TInt));
			clearX = iPos.iX;						// To clear up to current position
			}
		iLastPos.iX = iImageRegion.iTl.iX;			// Start of this line
		}

	clearX -= iLastPos.iX;
	if(clearX > 0)									// Treat any skipped pixels as if they produced no error
		{
		iNextError = 0;
		Mem::FillZ(iScanlineErrorBuffer + iLastPos.iX + 2, clearX * sizeof(TInt));
		}

	iLastPos.iY = iPos.iY;
	iLastPos.iX = iPos.iX+aCount;

	TUint32* indexBufferPtr = iIndexBuffer;
	TUint32* indexBufferPtrLimit = indexBufferPtr+aCount;

	TInt* scanlineErrorBufferPtr = iScanlineErrorBuffer + iPos.iX;
	TInt nextError = iNextError;

	while(indexBufferPtr<indexBufferPtrLimit)
		{
		TInt gray256 = *aGray256Buffer++;

		TInt error = gray256 + (nextError >> 4);
		TUint32 index = iIndexLookup[ColorCcomponent::ClampColorComponent(error)];
		*indexBufferPtr++ = index;

		error -= TColorConvertor::RgbToMonochrome(iColorConv->Color(index));

		nextError = (error << 3) - error; // Set right error for this pixel

		*scanlineErrorBufferPtr++ += error + (error << 1); // Set left-down error for this pixel

		*scanlineErrorBufferPtr += error + (error << 2); // Set down error for this pixel

		nextError += *(scanlineErrorBufferPtr+1);

		*(scanlineErrorBufferPtr+1) = error; // Set right-down error for this pixel
		}

	iNextError = nextError;
	}

void CMonochromeErrorDiffuser::SetPixelBlockIndex(TUint32* aGray256Buffer)
	{
	if(iPos.iY!=iLastPos.iY)
		{
		Mem::FillZ(iEdgeErrorBuffer,sizeof(TInt) * iBlockSize.iHeight);
		}

	TUint32* indexBufferPtr = iIndexBuffer;

	TInt error = 0;
	TInt* edgeErrorBuffer = iEdgeErrorBuffer;

	for (TInt row = 0; row < iBlockSize.iHeight; row++)
		{
		TInt* errorValue = iScanlineErrorBuffer + iPos.iX;
		TInt nextError = *edgeErrorBuffer + *errorValue;
		*edgeErrorBuffer = error;

		for (TInt col = 0; col < iBlockSize.iWidth; col++)
			{
			TInt gray256 = *aGray256Buffer++;

			error = gray256 + (nextError >> 4); // Same as /16
			
			TUint32 index = iIndexLookup[ColorCcomponent::ClampColorComponent(error)];
			*indexBufferPtr++ = index;

			error -= TColorConvertor::RgbToMonochrome(iColorConv->Color(index));

			if (col > 0)
				*(errorValue - 1) += error + (error << 1); // Set left-down error for this pixel
			else
				*errorValue = error + (error << 1);

			*errorValue += error + (error << 2); // Set down error for this pixel
			errorValue++;

			nextError = (error << 3) - error; // Set right error for this pixel

			if (col < iBlockSize.iWidth)
				{
				nextError += *errorValue;
				*errorValue = error; // Set right-down error for this pixel
				}
			}

		*edgeErrorBuffer++ += nextError;
		}

	iLastPos.iY = iPos.iY;
	iLastPos.iX = iPos.iX+iBlockSize.iWidth;
	}

void CMonochromeErrorDiffuser::Reset()
	{
	CMonochromePixelWriter::Reset();

	delete[] iScanlineErrorBuffer;
	iScanlineErrorBuffer = NULL;

	delete[] iEdgeErrorBuffer;
	iEdgeErrorBuffer = NULL;
	}

//
// CThumbnailProcessor
//

/**
 *
 * Static factory function to create CThumbnailProcessor objects.
 *
 * @param	"aImageProc"
 *          A pointer to an externally constructed CImageProcessorExtension object.
 *          This will be deleted when the CThumbnailProcessor object is deleted.
 * @param	"aReductionFactor"
 *          The reduction factor to use.
 * @return  Pointer to a fully constructed CThumbnailProcessor object. 
 */
CThumbnailProcessor* CThumbnailProcessor::NewL(CImageProcessorExtension* aImageProc,TInt aReductionFactor)
	{
	return new(ELeave) CThumbnailProcessor(aImageProc,aReductionFactor);
	}

CThumbnailProcessor::CThumbnailProcessor(CImageProcessorExtension* aImageProc,TInt aReductionFactor):
	iImageProc(aImageProc),
	iYInc(1),
	iReductionFactor(aReductionFactor)
		{}

CThumbnailProcessor::~CThumbnailProcessor()
	{
	delete iImageProc;
	delete[] iReducedPixelBuffer;
	delete[] iReducedSumBuffer;
	}

void CThumbnailProcessor::PrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect)
	{
	PrepareCommonL(aImageRect);
	iYInc = 1;

	TInt bufferSize = (iImageRegion.iBr.iX + (1<<iReductionFactor) -1 ) >> iReductionFactor;

	ASSERT(iReducedSumBuffer == NULL);
	iReducedSumBuffer = new(ELeave) TColorSum[bufferSize];
	Mem::FillZ(iReducedSumBuffer,bufferSize * sizeof(TColorSum));

	iImageProc->PrepareL(aBitmap,iReducedImageRegion);

	ASSERT(iReducedPixelBuffer == NULL);
	iReducedPixelBuffer = new(ELeave) TRgb[iReducedImageRegion.iBr.iX];
	}

void CThumbnailProcessor::PrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect,const TSize& aRgbBlockSize)
	{
	PrepareCommonL(aImageRect);

	CreateBlockBufferL(aRgbBlockSize.iWidth*aRgbBlockSize.iHeight);

	iOriginalBlockSize = aRgbBlockSize;
	iYInc = iDrawBottomUp ? -iOriginalBlockSize.iHeight : iOriginalBlockSize.iHeight;

	iReducedBlockSize = aRgbBlockSize;
	iReducedBlockSize.iWidth >>= iReductionFactor;
	iReducedBlockSize.iHeight >>= iReductionFactor;

	iImageProc->SetInitialScanlineSkipPadding(iNumberOfScanlinesToSkip >> iReductionFactor);
	iImageProc->SetPixelPadding(iPixelPadding >> iReductionFactor);
	iImageProc->PrepareL(aBitmap,iReducedImageRegion,iReducedBlockSize);

	ASSERT(iReducedPixelBuffer == NULL);
	iReducedPixelBuffer = new(ELeave) TRgb[iReducedBlockSize.iWidth * iReducedBlockSize.iHeight];
	}

void CThumbnailProcessor::PrepareCommonL(const TRect& aImageRect)
	{
	ASSERT(iReductionFactor > 0);
	iImageRegion = aImageRect;

	TInt roundUp = (1<<iReductionFactor)-1;
	iReducedImageRegion.iTl.iX = aImageRect.iTl.iX >> iReductionFactor;
	iReducedImageRegion.iTl.iY = aImageRect.iTl.iY >> iReductionFactor;
	
	TSize size = aImageRect.Size();
	size.iWidth = (size.iWidth + roundUp) >> iReductionFactor;
	size.iHeight = (size.iHeight + roundUp) >> iReductionFactor;
	iReducedImageRegion.iBr = iReducedImageRegion.iTl + size;

	switch(iOperation)
		{
		case EDecodeRotate180:
		case EDecodeRotate270:
		case EDecodeHorizontalFlip:
		case EDecodeVerticalFlipRotate90:
			iDrawBottomUp = ETrue;
			iImageProc->SetOperation(iOperation);
			break;
		default:
			iDrawBottomUp = EFalse;
		}
	iStartPosition.SetXY(iImageRegion.iTl.iX, iDrawBottomUp ? aImageRect.iBr.iY - 1 : 0);
	iEndPosition.SetXY(aImageRect.iBr.iX, iDrawBottomUp ? aImageRect.iTl.iY - 1 : aImageRect.iBr.iY);
	iPos = iStartPosition;

	iPositionChanged = ETrue;

	iEndOfLineX = iEndPosition.iX + iPixelPadding;

	delete[] iReducedPixelBuffer;
	iReducedPixelBuffer = NULL;

	delete[] iReducedSumBuffer;
	iReducedSumBuffer = NULL;
	}

TBool CThumbnailProcessor::SetPixel(TRgb aColor)
	{
	TInt x = iPos.iX;

	if (x < iImageRegion.iBr.iX)
		{
		TColorSum* sumPtr = iReducedSumBuffer + (x >> iReductionFactor);
		sumPtr->iRed += aColor.Red();
		sumPtr->iGreen += aColor.Green();
		sumPtr->iBlue += aColor.Blue();
		sumPtr->iCount++;
		}

	x++;
	iPos.iX = x;

	if (x == iEndOfLineX)
		return NewLine();

	return EFalse;
	}

TBool CThumbnailProcessor::NewLine()
	{
	TInt newY = iPos.iY + iYInc;

	TBool finished = (newY < iStartPosition.iY || newY >= iEndPosition.iY);
	TBool outsideOfBuffer = ((newY ^ iPos.iY) >> iReductionFactor) != 0;

	if(finished || outsideOfBuffer)
		{
		DoFlushPixels();
		}

	iPos.iX = iStartPosition.iX;
	iPos.iY = newY;

	if(iPositionChanged && outsideOfBuffer)
		{
		iImageProc->SetPos(TPoint(iPos.iX >> iReductionFactor,iPos.iY >> iReductionFactor));
		iPositionChanged = EFalse;
		}

	return finished;
	}

TBool CThumbnailProcessor::SetPixelBlock(TRgb* aColorBuffer)
	{
	if ((iPos.iX >> iReductionFactor) < iReducedImageRegion.iBr.iX)
		{
		ASSERT(aColorBuffer);

		if(iPositionChanged)
			{
			iImageProc->SetPos(TPoint(iPos.iX >> iReductionFactor,iPos.iY >> iReductionFactor));
			iPositionChanged = EFalse;
			}

		TInt xOuterStop = iReducedBlockSize.iWidth<<iReductionFactor;
		TInt yOuterStop = iReducedBlockSize.iHeight<<iReductionFactor;

		TInt outerStep = 1<<iReductionFactor;
		TInt divisionFactor = 2*iReductionFactor;

		TRgb* reducedPixelBuffer = iReducedPixelBuffer;

		for (TInt yOuter = 0; yOuter < yOuterStop; yOuter += outerStep)
			{
			for (TInt xOuter = 0; xOuter < xOuterStop; xOuter += outerStep)
				{
				TRgb* colorBuffer = &aColorBuffer[yOuter * iOriginalBlockSize.iWidth + xOuter];
				TInt red = 0;
				TInt green = 0;
				TInt blue = 0;

				for (TInt yInner = 0; yInner < outerStep; yInner++)
					{
					for (TInt xInner = 0; xInner < outerStep; xInner++)
						{
						red += colorBuffer[xInner].Red();
						green += colorBuffer[xInner].Green();
						blue += colorBuffer[xInner].Blue();
						}
					colorBuffer += iOriginalBlockSize.iWidth;
					}

				red >>= divisionFactor;
				green >>= divisionFactor;
				blue >>= divisionFactor;

				*reducedPixelBuffer++ = TRgb(red,green,blue);
				}
			}

		iImageProc->SetPixelBlock(iReducedPixelBuffer);
		}

	iPos.iX += iOriginalBlockSize.iWidth;
	if (iPos.iX >= iEndOfLineX)
		{
		iPos.iX = iStartPosition.iX;
		iPos.iY += iYInc;
		if(iPos.iY < iStartPosition.iY || iPos.iY >= iEndPosition.iY)
			{
			return ETrue;
			}
		}

	return EFalse;

	}

TBool CThumbnailProcessor::FlushPixels()
	{
	DoFlushPixels();
	iImageProc->FlushPixels();

	iPositionChanged = ETrue;

	if(iPos.iY < iStartPosition.iY || iPos.iY >= iEndPosition.iY)
		{
		return ETrue;
		}

	return EFalse;
	}

void CThumbnailProcessor::DoFlushPixels()
	{
	if(!iReducedSumBuffer)
		return;

	TColorSum* reducedSumPtr = iReducedSumBuffer + iReducedImageRegion.iTl.iX;
	TColorSum* reducedSumPtrLimit = iReducedSumBuffer + iReducedImageRegion.iBr.iX;

	while(reducedSumPtr < reducedSumPtrLimit)
		{

		while(reducedSumPtr->iCount==0)
			{
			reducedSumPtr++;
			if(reducedSumPtr==reducedSumPtrLimit)
				return;
			}

		if(iPositionChanged)
			iImageProc->SetPos(TPoint(reducedSumPtr - iReducedSumBuffer,iPos.iY >> iReductionFactor));

		TRgb* reducedPixelBufferPtr = iReducedPixelBuffer;
		TInt fullCountFactor = 2*iReductionFactor;

		while(reducedSumPtr < reducedSumPtrLimit)
			{
			TInt count = reducedSumPtr->iCount;
			TUint32 red;
			TUint32 green;
			TUint32 blue;

			if(count == (1<<fullCountFactor))
				{
				red = reducedSumPtr->iRed >> fullCountFactor;
				green = reducedSumPtr->iGreen >> fullCountFactor;
				blue = reducedSumPtr->iBlue >> fullCountFactor;
				}
			else if(count!=0)
				{
				red = reducedSumPtr->iRed / count;
				green = reducedSumPtr->iGreen / count;
				blue = reducedSumPtr->iBlue / count;
				}
			else
				break;

			*reducedPixelBufferPtr++ = TRgb(red,green,blue);

			reducedSumPtr++;
			}

		TInt numPixels = reducedPixelBufferPtr-iReducedPixelBuffer;
		iImageProc->SetPixels(iReducedPixelBuffer,numPixels);

		Mem::FillZ(reducedSumPtr-numPixels,numPixels * sizeof(TColorSum));
		}

	}

TBool CThumbnailProcessor::SetPos(const TPoint& aPosition)
	{
	if(iImageRegion.Contains(aPosition)==EFalse)
		return EFalse;

	if((aPosition.iY ^ iPos.iY) >> iReductionFactor)
		DoFlushPixels();

	iPositionChanged = ETrue;
	iPos = aPosition;

	return ETrue;
	}

void CThumbnailProcessor::SetYPosIncrement(TInt aYInc)
	{
	iYInc = aYInc;

	TInt reducedYInc = aYInc >> iReductionFactor;
	if(reducedYInc==0)
		reducedYInc = 1;

	iImageProc->SetYPosIncrement(reducedYInc);
	}

void CThumbnailProcessor::SetLineRepeat(TInt aLineRepeat)
	{
	TInt reducedLineRepeat = aLineRepeat >> iReductionFactor;
	iImageProc->SetLineRepeat(reducedLineRepeat);
	}

void CThumbnailProcessor::SetPixelPadding(TInt aNumberOfPixels)
	{
	iPixelPadding = aNumberOfPixels;
	iEndOfLineX = iEndPosition.iX + iPixelPadding;
	}

//
// CMonochromeThumbnailProcessor
//

/**
 *
 * Static factory function to create CMonochromeThumbnailProcessor objects.
 *
 * @param	"aImageProc"
 *          A pointer to an externally constructed CImageProcessorExtension object.
 *          This will be deleted when the CMonochromeThumbnailProcessor object is deleted.
 * @param	aReductionFactor"
 *          The reduction factor to use.
 * @return  Pointer to a fully constructed CMonochromeThumbnailProcessor object. 
 */
CMonochromeThumbnailProcessor* CMonochromeThumbnailProcessor::NewL(CImageProcessorExtension* aImageProc,TInt aReductionFactor)
	{
	return new(ELeave) CMonochromeThumbnailProcessor(aImageProc,aReductionFactor);
	}

CMonochromeThumbnailProcessor::CMonochromeThumbnailProcessor(CImageProcessorExtension* aImageProc,TInt aReductionFactor):
	iImageProc(aImageProc),
	iYInc(1),
	iReductionFactor(aReductionFactor)
		{}

CMonochromeThumbnailProcessor::~CMonochromeThumbnailProcessor()
	{
	delete iImageProc;
	delete[] iReducedPixelBuffer;
	delete[] iReducedSumBuffer;
	}

void CMonochromeThumbnailProcessor::PrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect)
	{
	PrepareCommonL(aImageRect);
	iYInc = 1;
	
	TInt bufferSize = (iImageRegion.iBr.iX + (1<<iReductionFactor) -1 ) >> iReductionFactor;

	ASSERT(iReducedSumBuffer == NULL);
	iReducedSumBuffer = new(ELeave) TMonochromeSum[bufferSize];
	Mem::FillZ(iReducedSumBuffer,bufferSize * sizeof(TMonochromeSum));

	iImageProc->PrepareL(aBitmap,iReducedImageRegion);

	ASSERT(iReducedPixelBuffer == NULL);
	iReducedPixelBuffer = new(ELeave) TUint32[iReducedImageRegion.iBr.iX];
	}

void CMonochromeThumbnailProcessor::PrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect,const TSize& aRgbBlockSize)
	{
	PrepareCommonL(aImageRect);

	CreateBlockBufferL(aRgbBlockSize.iWidth*aRgbBlockSize.iHeight);

	iOriginalBlockSize = aRgbBlockSize;
	iYInc = iDrawBottomUp ? -iOriginalBlockSize.iHeight : iOriginalBlockSize.iHeight;


	iReducedBlockSize = aRgbBlockSize;
	iReducedBlockSize.iWidth >>= iReductionFactor;
	iReducedBlockSize.iHeight >>= iReductionFactor;

	iImageProc->SetInitialScanlineSkipPadding(iNumberOfScanlinesToSkip >> iReductionFactor);
	iImageProc->SetPixelPadding(iPixelPadding >> iReductionFactor);
	iImageProc->PrepareL(aBitmap,iReducedImageRegion,iReducedBlockSize);

	ASSERT(iReducedPixelBuffer == NULL);
	iReducedPixelBuffer = new(ELeave) TUint32[iReducedBlockSize.iWidth * iReducedBlockSize.iHeight];
	}

void CMonochromeThumbnailProcessor::PrepareCommonL(const TRect& aImageRect)
	{
	ASSERT(iReductionFactor > 0);
	iImageRegion = aImageRect;

	TInt roundUp = (1<<iReductionFactor)-1;
	iReducedImageRegion.iTl.iX = aImageRect.iTl.iX >> iReductionFactor;
	iReducedImageRegion.iTl.iY = aImageRect.iTl.iY >> iReductionFactor;

	TSize size = aImageRect.Size();
	size.iWidth = (size.iWidth + roundUp) >> iReductionFactor;
	size.iHeight = (size.iHeight + roundUp) >> iReductionFactor;
	iReducedImageRegion.iBr = iReducedImageRegion.iTl + size;
	
	switch(iOperation)
		{
		case EDecodeRotate180:
		case EDecodeRotate270:
		case EDecodeHorizontalFlip:
		case EDecodeVerticalFlipRotate90:
			iDrawBottomUp = ETrue;
			iImageProc->SetOperation(iOperation);
			break;
		default:
			iDrawBottomUp = EFalse;
		}
	iStartPosition.SetXY(iImageRegion.iTl.iX, iDrawBottomUp ? aImageRect.iBr.iY - 1 : 0);
	iEndPosition.SetXY(aImageRect.iBr.iX, iDrawBottomUp ? aImageRect.iTl.iY - 1 : aImageRect.iBr.iY);
	iPos = iStartPosition;
	
	iPositionChanged = ETrue;

	iEndOfLineX = iEndPosition.iX + iPixelPadding;

	delete[] iReducedPixelBuffer;
	iReducedPixelBuffer = NULL;

	delete iReducedSumBuffer;
	iReducedSumBuffer = NULL;
	}

TBool CMonochromeThumbnailProcessor::SetMonoPixel(TInt aGray256)
	{
	TInt x = iPos.iX;

	if (x < iImageRegion.iBr.iX)
		{
		TMonochromeSum* sumPtr = iReducedSumBuffer + (x >> iReductionFactor);
		sumPtr->iLevel += aGray256;
		sumPtr->iCount++;
		}

	x++;
	iPos.iX = x;

	if (x == iEndOfLineX)
		return NewLine();

	return EFalse;
	}

TBool CMonochromeThumbnailProcessor::SetMonoPixelRun(TInt aGray256,TInt aCount)
	{
	while (aCount != 0)
		{
		TInt x		= iPos.iX;
		TInt xLimit = x+aCount;

		iPos.iX = xLimit;

		if (xLimit > iImageRegion.iBr.iX)
			xLimit = iImageRegion.iBr.iX;

		if (xLimit > x)
			{
			TInt numPixels = xLimit-x;

			TInt reductionFactor = iReductionFactor;
			TInt reductionCount = 1<<reductionFactor;	//number of horizontal pixel in a TMonochromeSum

			TMonochromeSum* sumPtr = iReducedSumBuffer + (x >> reductionFactor);

			TInt n = reductionCount-(x&(reductionCount-1));	//number of pixels to complete current TMonochromeSum

			if(numPixels > n)
				{
				sumPtr->iCount += n;					//Complete first TMonochromeSum in run
				sumPtr->iLevel += n * aGray256;
				sumPtr++;
				numPixels -= n;

				while(numPixels > reductionCount)			//Complete middle TMonochromeSum(s) in run
					{
					sumPtr->iCount += reductionCount;
					sumPtr->iLevel += aGray256 << reductionFactor;
					sumPtr++;
					numPixels -= reductionCount;
					}
				}

			sumPtr->iCount += numPixels;				//Update last/only TMonochromeSum in run
			sumPtr->iLevel += numPixels * aGray256;
			}

		if (iPos.iX < iEndOfLineX)
			break;

		aCount = iPos.iX - iEndOfLineX;

		if(NewLine())
			return ETrue;
		}

	return EFalse;
	}

TBool CMonochromeThumbnailProcessor::NewLine()
	{
	TInt newY = iPos.iY + iYInc;

	TBool finished = (newY < iStartPosition.iY || newY >= iEndPosition.iY);
	TBool outsideOfBuffer = ((newY ^ iPos.iY) >> iReductionFactor) != 0;

	if(finished || outsideOfBuffer)
		{
		DoFlushPixels();
		}

	iPos.iX = iStartPosition.iX;
	iPos.iY = newY;

	if(iPositionChanged && outsideOfBuffer)
		{
		iImageProc->SetPos(TPoint(iPos.iX >> iReductionFactor,iPos.iY >> iReductionFactor));
		iPositionChanged = EFalse;
		}

	return finished;
	}

TBool CMonochromeThumbnailProcessor::SetMonoPixelBlock(TUint32* aGray256Buffer)
	{
	if ((iPos.iX >> iReductionFactor) < iReducedImageRegion.iBr.iX)
		{
		ASSERT(aGray256Buffer);

		if(iPositionChanged)
			{
			iImageProc->SetPos(TPoint(iPos.iX >> iReductionFactor,iPos.iY >> iReductionFactor));
			iPositionChanged = EFalse;
			}

		TInt xOuterStop = iReducedBlockSize.iWidth<<iReductionFactor;
		TInt yOuterStop = iReducedBlockSize.iHeight<<iReductionFactor;

		TInt outerStep = 1<<iReductionFactor;
		TInt divisionFactor = 2*iReductionFactor;

		TUint32* reducedPixelBuffer = iReducedPixelBuffer;

		for (TInt yOuter = 0; yOuter < yOuterStop; yOuter += outerStep)
			{
			for (TInt xOuter = 0; xOuter < xOuterStop; xOuter += outerStep)
				{
				TUint32* gray256Buffer = &aGray256Buffer[yOuter * iOriginalBlockSize.iWidth + xOuter];
				TInt level = 0;

				for (TInt yInner = 0; yInner < outerStep; yInner++)
					{
					for (TInt xInner = 0; xInner < outerStep; xInner++)
						level += gray256Buffer[xInner];

					gray256Buffer += iOriginalBlockSize.iWidth;
					}

				level >>= divisionFactor;
				*reducedPixelBuffer++ = level;
				}
			}

		iImageProc->SetMonoPixelBlock(iReducedPixelBuffer);
		}

	iPos.iX += iOriginalBlockSize.iWidth;
	if (iPos.iX >= iEndOfLineX)
		{
		iPos.iX = iStartPosition.iX;
		iPos.iY += iYInc;
		if(iPos.iY < iStartPosition.iY || iPos.iY >= iEndPosition.iY)
			{
			return ETrue;
			}
		}

	return EFalse;

	}

TBool CMonochromeThumbnailProcessor::FlushPixels()
	{
	DoFlushPixels();
	iImageProc->FlushPixels();

	iPositionChanged = ETrue;

		if(iPos.iY < iStartPosition.iY || iPos.iY >= iEndPosition.iY)
			{
			return ETrue;
			}

	return EFalse;
	}

void CMonochromeThumbnailProcessor::DoFlushPixels()
	{
	if(!iReducedSumBuffer)
		return;

	TMonochromeSum* reducedSumPtr = iReducedSumBuffer + iReducedImageRegion.iTl.iX;
	TMonochromeSum* reducedSumPtrLimit = iReducedSumBuffer + iReducedImageRegion.iBr.iX;

	while(reducedSumPtr < reducedSumPtrLimit)
		{

		while(reducedSumPtr->iCount==0)
			{
			reducedSumPtr++;
			if(reducedSumPtr==reducedSumPtrLimit)
				return;
			}

		if(iPositionChanged)
			iImageProc->SetPos(TPoint(reducedSumPtr - iReducedSumBuffer,iPos.iY >> iReductionFactor));

		TUint32* reducedPixelBufferPtr = iReducedPixelBuffer;
		TInt fullCountFactor = 2*iReductionFactor;
		TInt fullCount = 1<<fullCountFactor;

		do
			{
			TInt level = reducedSumPtr->iLevel;
			TInt count = reducedSumPtr->iCount;

			if(count==fullCount)
				level >>= fullCountFactor;
			else if(count!=0)
				level /= count;
			else
				break;

			*reducedPixelBufferPtr++ = level;

			reducedSumPtr++;
			}
		while(reducedSumPtr < reducedSumPtrLimit);

		TInt numPixels = reducedPixelBufferPtr-iReducedPixelBuffer;
		iImageProc->SetMonoPixels(iReducedPixelBuffer,numPixels);

		Mem::FillZ(reducedSumPtr-numPixels,numPixels * sizeof(TMonochromeSum));
		}

	}

TBool CMonochromeThumbnailProcessor::SetPos(const TPoint& aPosition)
	{
	if(iImageRegion.Contains(aPosition)==EFalse)
		return EFalse;

	if((aPosition.iY ^ iPos.iY) >> iReductionFactor)
		DoFlushPixels();

	iPositionChanged = ETrue;
	iPos = aPosition;

	return ETrue;
	}

void CMonochromeThumbnailProcessor::SetYPosIncrement(TInt aYInc)
	{
	iYInc = aYInc;

	TInt reducedYInc = aYInc >> iReductionFactor;
	if(reducedYInc==0)
		reducedYInc = 1;

	iImageProc->SetYPosIncrement(reducedYInc);
	}

void CMonochromeThumbnailProcessor::SetLineRepeat(TInt aLineRepeat)
	{
	TInt reducedLineRepeat = aLineRepeat >> iReductionFactor;
	iImageProc->SetLineRepeat(reducedLineRepeat);
	}

void CMonochromeThumbnailProcessor::SetPixelPadding(TInt aNumberOfPixels)
	{
	iPixelPadding = aNumberOfPixels;
	iEndOfLineX = iEndPosition.iX + iPixelPadding;
	}

