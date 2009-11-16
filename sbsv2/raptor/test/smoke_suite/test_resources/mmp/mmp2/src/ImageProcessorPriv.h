/*
* Copyright (c) 1998-2009 Nokia Corporation and/or its subsidiary(-ies).
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


#ifndef ___IMAGEPROCESSORPRIV_H__
#define ___IMAGEPROCESSORPRIV_H__

#include <icl/imageprocessor.h>
#include "fwextconstants.h"

//The size of the index lookup table
const TInt KIndexLookupSize = 256;

class CColorImageProcessor; // declared here
/**
 * @internalComponent
 *
 * @see CImageProcessor.
 *
 */
NONSHARABLE_CLASS( CColorImageProcessor ): public CImageProcessorExtension
	{
public:
	virtual ~CColorImageProcessor();
	// From CImageProcessor (Default implementations)
	TBool SetPixelRun(TRgb aColor,TInt aCount);
	TBool SetPixels(TRgb* aColorBuffer,TInt aBufferLength);
	TBool SetMonoPixel(TInt aGray256);
	TBool SetMonoPixelRun(TInt aGray256,TInt aCount);
	TBool SetMonoPixels(TUint32* aGray256Buffer,TInt aBufferLength);
	TBool SetMonoPixelBlock(TUint32* aGray256Buffer);
protected:
	// New - to facilitate default implementation of SetMonoPixelBlock()
	void CreateBlockBufferL(TInt aBlockArea);
protected:
	// Used by default implementation of SetMonoPixelBlock()
	TRgb*	iBlockBuffer;
	TInt	iBlockArea;
	};

class CMonochromeImageProcessor; // declared here
/**
 * @internalComponent
 *
 * @see CImageProcessor.
 *
 */
NONSHARABLE_CLASS( CMonochromeImageProcessor ): public CImageProcessorExtension
	{
public:
	virtual ~CMonochromeImageProcessor();
	// From CImageProcessor (Default implementations)
	TBool SetPixel(TRgb aColor);
	TBool SetPixelRun(TRgb aColor,TInt aCount);
	TBool SetPixels(TRgb* aColorBuffer,TInt aBufferLength);
	TBool SetPixelBlock(TRgb* aColorBuffer);
	TBool SetMonoPixelRun(TInt aGray256,TInt aCount);
	TBool SetMonoPixels(TUint32* aGray256Buffer,TInt aBufferLength);
protected:
	// New - to facilitate default implementation of SetPixelBlock()
	void CreateBlockBufferL(TInt aBlockArea);
protected:
	// Used by default implementation of SetPixelBlock()
	TUint32* iBlockBuffer;
	TInt	 iBlockArea;
	};

class CPixelWriter; // declared here
/**
 * @internalComponent
 *
 * @see CColorImageProcessor.
 *
 */
NONSHARABLE_CLASS( CPixelWriter ): public CColorImageProcessor
	{
public:
	static CPixelWriter* NewL();
	virtual ~CPixelWriter();
	// From CImageProcessor
	void PrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect);
	void PrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect,const TSize& aRgbBlockSize);
	void SetYPosIncrement(TInt aYInc);
	void SetLineRepeat(TInt aLineRepeat);
	void SetPixelPadding(TInt aNumberOfPixels);
	TBool SetPixel(TRgb aColor);
	TBool SetPixelRun(TRgb aColor,TInt aCount);
	TBool SetPixels(TRgb* aColorBuffer, TInt aBufferLength);
	TBool SetPixelBlock(TRgb* aColorBuffer);
	TBool SetPos(const TPoint& aPosition);
	TBool FlushPixels();
protected:
	// New
	CPixelWriter();
	virtual void Reset();
	virtual void DoPrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect,const TSize* aBlockSize);
	virtual void SetPixelBufferIndex(TRgb* aColorBuffer,TInt aCount);	//Used by FlushPixels to convert buffered 'SetPixel's
	virtual void SetPixelBlockIndex(TRgb* aColorBuffer);	//Used by SetPixelBlock
	virtual TBool NewLine();
protected:
	TInt iYInc;
	TInt iLineRepeat;
	TInt iPixelPadding;
	TInt iPixelsToSkip;
	TPoint iPos;
	TRect iImageRegion;
	TSize iBlockSize;
	TInt iBlockArea;
	TImageBitmapUtil iUtil;
	TColorConvertor* iColorConv;
	TRgb* iRgbBuffer;
	TRgb* iRgbBufferPtr;
	TRgb* iRgbBufferPtrLimit;
	TUint32* iIndexBuffer;
	TUint32* iIndexBufferPtrLimit;
	TDisplayMode iDisplayMode;
	TBool iDrawBottomUp;
	};

class CMonochromePixelWriter; // declared here
/**
 * @internalComponent
 *
 * @see CMonochromeImageProcessor.
 *
 */
NONSHARABLE_CLASS( CMonochromePixelWriter ): public CMonochromeImageProcessor
	{
public:
	static CMonochromePixelWriter* NewL();
	virtual ~CMonochromePixelWriter();
	// From CImageProcessor
	void PrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect);
	void PrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect,const TSize& aRgbBlockSize);
	void SetYPosIncrement(TInt aYInc);
	void SetLineRepeat(TInt aLineRepeat);
	void SetPixelPadding(TInt aNumberOfPixels);
	TBool SetMonoPixel(TInt aGray256);
	TBool SetMonoPixelRun(TInt aGray256,TInt aCount);
	TBool SetMonoPixels(TUint32* aGray256Buffer,TInt aBufferLength);
	TBool SetMonoPixelBlock(TUint32* aGray256Buffer);
	TBool SetPos(const TPoint& aPosition);
	TBool FlushPixels();
protected:
	// New
	CMonochromePixelWriter();
	virtual void Reset();
	virtual void DoPrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect,const TSize* aBlockSize);
	virtual void SetPixelBufferIndex(TUint32* aGray256Buffer,TInt aCount);	//Used by FlushPixels to convert buffered 'SetPixel's
	virtual void SetPixelBlockIndex(TUint32* aGray256Buffer);	//Used by SetPixelBlock
	virtual TBool NewLine();
protected:
	TInt iYInc;
	TInt iLineRepeat;
	TInt iPixelPadding;
	TInt iPixelsToSkip;
	TPoint iPos;
	TRect iImageRegion;
	TSize iBlockSize;
	TInt iBlockArea;
	TImageBitmapUtil iUtil;
	TColorConvertor* iColorConv;
	TUint32* iGray256Buffer;
	TUint32* iGray256BufferPtr;
	TUint32* iGray256BufferPtrLimit;
	TUint32* iIndexBuffer;
	TUint32* iIndexBufferPtrLimit;
	TUint32 iIndexLookup[KIndexLookupSize];
	TBool iDrawBottomUp;
	};

class CErrorDiffuser; // declared here
/**
 * @internalComponent
 *
 * @see CPixelWriter.
 *
 */
NONSHARABLE_CLASS( CErrorDiffuser ): public CPixelWriter
	{
public:
	IMPORT_C static CErrorDiffuser* NewL();
	virtual ~CErrorDiffuser();
protected:
	CErrorDiffuser();
private:
	class TColorError
		{
	public:
		inline void AdjustColor(TRgb& aColor) const;
	public:
		inline TColorError();
		inline TColorError(TInt aRedError,TInt aGreenError,TInt aBlueError);
		inline void SetError(TRgb aIdealColor,TRgb aActualColor);
		inline TColorError operator+(const TColorError& aColorError) const;
		inline TColorError operator-(const TColorError& aColorError) const;
		inline TColorError operator<<(TInt aShift) const;
		inline TColorError& operator+=(const TColorError& aColorError);
	public:
		TInt iRedError;
		TInt iGreenError;
		TInt iBlueError;
		};
private:
	// From CPixelWriter
	void Reset();
	void DoPrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect,const TSize* aBlockSize);
	void SetPixelBufferIndex(TRgb* aColorBuffer,TInt aCount);
	void SetPixelBlockIndex(TRgb* aColorBuffer);
	void SetPixelBufferColor64KIndex(TRgb* aColorBuffer,TInt aCount);
	// optimized version of ClampColorComponent
	inline TInt ClipColorComponent(TInt value);
	
private:
	TColorError* iScanlineErrorBuffer;
	TColorError* iEdgeErrorBuffer;
	TColorError iNextError;
	TPoint iLastPos;
	// for fast 64K mode
	TInt8* iRedErrorLookupTable;
	TInt8* iGreenErrorLookupTable;
	TInt iNextRedError;
	TInt iNextGreenError;
	TInt iNextBlueError;
	};

class CMonochromeErrorDiffuser; // declared here
/**
 * @internalComponent
 *
 * @see CMonochromePixelWriter.
 *
 */
NONSHARABLE_CLASS( CMonochromeErrorDiffuser ): public CMonochromePixelWriter
	{
public:
	static CMonochromeErrorDiffuser* NewL();
	virtual ~CMonochromeErrorDiffuser();
protected:
	CMonochromeErrorDiffuser();
private:
	// From CMonochromePixelWriter
	void Reset();
	void DoPrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect,const TSize* aBlockSize);
	void SetPixelBufferIndex(TUint32* aGray256Buffer,TInt aCount);
	void SetPixelBlockIndex(TUint32* aGray256Buffer);
private:
	TInt* iScanlineErrorBuffer;
	TInt* iEdgeErrorBuffer;
	TInt iNextError;
	TPoint iLastPos;
	};

class CThumbnailProcessor; // declared here
/**
 * @internalComponent
 *
 * @see CColorImageProcessor.
 *
 */
NONSHARABLE_CLASS( CThumbnailProcessor ): public CColorImageProcessor
	{
public:
	static CThumbnailProcessor* NewL(CImageProcessorExtension* aImageProc,TInt aReductionFactor);
	virtual ~CThumbnailProcessor();
	// From CImageProcessor
	void PrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect);
	void PrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect,const TSize& aRgbBlockSize);
	void SetYPosIncrement(TInt aYInc);
	void SetLineRepeat(TInt aLineRepeat);
	void SetPixelPadding(TInt aNumberOfPixels);
	TBool SetPixel(TRgb aColor);
	TBool SetPixelBlock(TRgb* aColorBuffer);
	TBool SetPos(const TPoint& aPosition);
	TBool FlushPixels();
private:
	// New
	CThumbnailProcessor(CImageProcessorExtension* aImageProc,TInt aReductionFactor);
	void PrepareCommonL(const TRect& aImageRect);
	void DoFlushPixels();
	TBool NewLine();
private:
	class TColorSum
		{
	public:
		TInt iRed;
		TInt iGreen;
		TInt iBlue;
		TInt iCount;
		};
private:
	CImageProcessorExtension* iImageProc;
	TPoint iPos;
	TBool iPositionChanged;
	TInt iPixelPadding;
	TInt iEndOfLineX;
	TInt iYInc;
	TRect iImageRegion;
	TSize iOriginalBlockSize;
	TInt iReductionFactor;
	TRect iReducedImageRegion;
	TSize iReducedBlockSize;
	TRgb* iReducedPixelBuffer;
	TColorSum* iReducedSumBuffer;
	TBool iDrawBottomUp;
	};

class CMonochromeThumbnailProcessor; // declared here
/**
 * @internalComponent
 *
 * @see CMonochromeImageProcessor.
 *
 */
NONSHARABLE_CLASS( CMonochromeThumbnailProcessor ): public CMonochromeImageProcessor
	{
public:
	static CMonochromeThumbnailProcessor* NewL(CImageProcessorExtension* aImageProc,TInt aReductionFactor);
	virtual ~CMonochromeThumbnailProcessor();
	// From CImageProcessor
	void PrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect);
	void PrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect,const TSize& aRgbBlockSize);
	void SetYPosIncrement(TInt aYInc);
	void SetLineRepeat(TInt aLineRepeat);
	void SetPixelPadding(TInt aNumberOfPixels);
	TBool SetMonoPixel(TInt aGray256);
	TBool SetMonoPixelRun(TInt aGray256,TInt aCount);
	TBool SetMonoPixelBlock(TUint32* aGray256Buffer);
	TBool SetPos(const TPoint& aPosition);
	TBool FlushPixels();
private:
	// New
	CMonochromeThumbnailProcessor(CImageProcessorExtension* aImageProc,TInt aReductionFactor);
	void PrepareCommonL(const TRect& aImageRect);
	void DoFlushPixels();
	TBool NewLine();
private:
	class TMonochromeSum
		{
	public:
		TInt iLevel;
		TInt iCount;
		};
private:
	CImageProcessorExtension* iImageProc;
	TPoint iPos;
	TBool iPositionChanged;
	TInt iPixelPadding;
	TInt iEndOfLineX;
	TInt iYInc;
	TRect iImageRegion;
	TSize iOriginalBlockSize;
	TInt iReductionFactor;
	TRect iReducedImageRegion;
	TSize iReducedBlockSize;
	TUint32* iReducedPixelBuffer;
	TMonochromeSum* iReducedSumBuffer;
	TBool iDrawBottomUp;
	};

#endif // ___IMAGEPROCESSORPRIV_H__



