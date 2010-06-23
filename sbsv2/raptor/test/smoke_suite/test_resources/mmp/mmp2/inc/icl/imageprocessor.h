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


#ifndef ___IMAGEPROCESSOR_H__
#define ___IMAGEPROCESSOR_H__

#include <gdi.h>
#include <fbs.h>

/**
@internalTechnology
*/
enum TImageBitmapUtilPanic
	{
	ECorrupt
	};

/**
@publishedAll
@released

Interface to colour conversion classes for various display modes.
Manages the mapping between RGB/Greyscale values and the index
into the color palette for the given display mode.
*/
class TColorConvertor
	{
public:
	IMPORT_C static	TColorConvertor* NewL(TDisplayMode aDisplayMode);

	/**
	Returns the colour index corresponding to the supplied RGB value.
	Operates in the context of the current display mode.

	This is a virtual function that each derived class must implement.

	@param  aColor
	        The colour in RGB format.
	
	@return The colour index.
	*/
	virtual TInt ColorIndex(TRgb aColor) const = 0;

	/**
	Returns the RGB value corresponding to the supplied colour index.
	Operates in the context of the current display mode.

	This is a virtual function that each derived class must implement.

	@param  aColorIndex
	        The colour in RGB format.

	@return The RGB value.
	*/
	virtual TRgb Color(TInt aColorIndex) const = 0;

	/**
	Gets an array of colour indices from a corresponding array of RGB values.
	Operates in the context of the current display mode.

	This is a virtual function that each derived class must implement.

	@param  aIndexBuffer
	        A pointer to the first element in destination array.
	@param  aColorBuffer
	        A pointer to the first element in the source array.
	@param  aCount
	        The number of elements to get.
	*/
	virtual void ColorToIndex(TInt* aIndexBuffer,TRgb* aColorBuffer,TInt aCount) const = 0;

	inline static TInt RgbToMonochrome(TRgb aRgb);
	};


/**
@publishedAll
@released

Bitmap utility class.
*/
class TImageBitmapUtil
	{
public:
	IMPORT_C TImageBitmapUtil();
	IMPORT_C void Begin();
	IMPORT_C TBool Begin(const TPoint& aPosition);
	IMPORT_C void End();
	IMPORT_C void SetBitmapL(CFbsBitmap* aBitmap);
	IMPORT_C void SetPixel(TUint32 aPixelIndex);
	IMPORT_C void SetPixels(TUint32* aPixelIndex,TInt aNumberOfPixels);
	IMPORT_C TBool SetPos(const TPoint& aPosition);
	
private:
	union TDataPointer
		{
		TUint32* iWordPos;
		TUint8* iBytePos;
		};
private:
	CFbsBitmap* iBitmap;
	TSize iSize;
	TPoint iPosition;
	TDataPointer iData;
	TDataPointer iBase;
	TInt iBpp;
	TInt iBppShift;
	TInt iPixelShift;
	TInt iPixelsPerWord;
	TInt iBitShift;
	TInt iScanlineWordLength;
	TUint32 iMask;
	TBool iWordAccess;
	};


class CImageProcessor;
class CImageProcessorExtension;

/**
@publishedAll
@released

Utility class providing static factory functions for creating instances of
CImageProcessor derived classes.
*/
class ImageProcessorUtility
	{
public:
	IMPORT_C static TInt ReductionFactor(const TSize& aOriginalSize,const TSize& aReducedSize);
	IMPORT_C static CImageProcessor* NewImageProcessorL(const CFbsBitmap& aBitmap,const TSize& aImageSize,TDisplayMode aImageDisplayMode, TBool aDisableErrorDiffusion);
	IMPORT_C static CImageProcessor* NewImageProcessorL(const CFbsBitmap& aBitmap,TInt aReductionFactor,TDisplayMode aImageDisplayMode, TBool aDisableErrorDiffusion);
	IMPORT_C static CImageProcessorExtension* ImageProcessorUtility::NewImageProcessorExtensionL(const CFbsBitmap& aBitmap,TInt aReductionFactor,TDisplayMode aImageDisplayMode, TBool aDisableErrorDiffusion);
	
private:
	TBool static UseErrorDiffuser(const TDisplayMode& aBitmapDisplayMode, const TDisplayMode& aImageDisplayMode);
	TBool static IsMonochrome(const TDisplayMode& aBitmapDisplayMode, const TDisplayMode& aImageDisplayMode);
	};



/**
@publishedAll
@released

Interface to image processing classes used by CImageDecoder plugins. This is not a application client API.
*/
class CImageProcessor : public CBase
	{
public:
	// Setup

	/**
	Initialises internal data structures prior to conversion.

	This is a virtual function that each derived class must implement.

	@param  aBitmap
	        A reference to a fully constucted bitmap with the required
	        display mode and size.
	@param  aImageRect
	        The region of the image to convert.
	*/
	virtual void PrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect) = 0;

	/**
	Initialises internal data structures prior to the manipulation of the specified pixel block.

	This overloaded version allows specification of a block size
	for those formats which support blocked pixel data eg. JPEG

	This is a virtual function that each derived class must implement.

	@param  aBitmap
	        A reference to a fully constucted bitmap with the required
	        display mode and size.
	@param  aImageRect
	        The region of the image to convert.
	@param  aRgbBlockSize
	        The size of the block to use.
	*/
	virtual void PrepareL(CFbsBitmap& aBitmap,const TRect& aImageRect,const TSize& aRgbBlockSize) = 0;

	/**
	Sets the number of pixels by which to increment the current position in
	the Y-axis. This is used when rendering images supporting interlacing.
	eg GIF

	This is a virtual function that each derived class must implement.

	@param  aYInc
	        The number of pixels.
	*/
	virtual void SetYPosIncrement(TInt aYInc) = 0;

	/**
	Sets the number times the current line should be repeated. The lines
	are repeated in the same direction as set by SetYPosIncrement(). This
	is used to fill blank lines when rendering interlaced images. eg GIF.
	@param aLineRepeat The number of times the current line should be repeated
	*/
	virtual void SetLineRepeat(TInt aLineRepeat) = 0;

	/**
	Sets the pixel padding to the value specified by aNumberOfPixels.

	This is a virtual function that each derived class must implement.

	@param  aNumberOfPixels
	        The number of pixels to use for padding.
	*/
	virtual void SetPixelPadding(TInt aNumberOfPixels) = 0;

	// Color pixel writing

	/**
	Sets the pixel at the current position to aColor.

	This is a virtual function that each derived class must implement.
	
	@post    
	The current position is updated.

	@param  aColor
	        The RGB value to set the current pixel to.

	@return A boolean indicating if the operation was successful. ETrue if the operation succeeded, 
            otherwise EFalse.
    */
	virtual TBool SetPixel(TRgb aColor) = 0;

	/**
	Sets aCount number of pixels to the value given by aColor, starting at
	the current position.

	This is a virtual function that each derived class must implement.

	@post    
	On success, the current position is updated.

	@param  aColor
	        The RGB value to set the pixels to.
	@param  aCount
	        The number of pixels to set.

	@return A boolean indicating if the operation was successful. ETrue if the operation succeeded, 
	        otherwise EFalse.
	*/
	virtual TBool SetPixelRun(TRgb aColor,TInt aCount) = 0;

	/**
	Updates the bitmap with colour information from the array of colour values.

	Uses the array of colour values supplied by aColorBuffer, whose length
	is specified by aBufferLength, to update successive pixels with values in the
	buffer, starting at the current	position.

	This is a virtual function that each derived class must implement.
	
	@post   
	The current position is updated.

	@param  aColorBuffer
	        A pointer to the first element in the array.
	@param  aBufferLength
	        The number of elements in the array.

	@return A boolean indicating if the operation was successful. ETrue if the operation succeeded, 
	        otherwise EFalse.
	*/
	virtual TBool SetPixels(TRgb* aColorBuffer,TInt aBufferLength) = 0;

    /**
    Sets the current pixel block using the data supplied in aColorBuffer.

	Note:
	For use with image types that support blocking of pixels eg JPEG.

	This is a virtual function that each derived class must implement.

	@param  aColorBuffer
	        A pointer to a buffer representing a block of pixel color values.

	@return A boolean indicating if the operation was successful. ETrue if the operation succeeded, 
	        otherwise EFalse.
	*/
	virtual TBool SetPixelBlock(TRgb* aColorBuffer) = 0;

	// Monochrome pixel writing

	/**
	Sets the pixel at the current position to aGray256.

	This is a virtual function that each derived class must implement.

    @post   
	The current position is updated.

	@param  aGray256
	        The greyscale value to set the current pixel to.

	@return A boolean indicating if the operation was successful. ETrue if the operation succeeded, 
	        otherwise EFalse.
	*/
	virtual TBool SetMonoPixel(TInt aGray256) = 0;

	/**
	Sets the number of pixels specified by aCount to the value given by aGray256, starting at
	the current position.

	This is a virtual function that each derived class must implement.
	
	@post   
	The current position is updated.

	@param  aGray256
	        The greyscale value to set the pixels to.
	@param  aCount
	        The number of pixels to set.

	@return A boolean indicating if the operation was successful. ETrue if the operation succeeded, 
	        otherwise EFalse.
	*/
	virtual TBool SetMonoPixelRun(TInt aGray256,TInt aCount) = 0;

	/**
	Updates the bitmap with greyscale information from the array of greyscale values.

	The array of values supplied by aGray256Buffer, whose length
	is specified in aBufferLength, is used to update successive pixels with the
	greyscales values.

	This is a virtual function that each derived class must implement.

	@post
	The current position is updated.

	@param  aGray256Buffer
	        A pointer to the first element in the array of greyscale values.
	@param  aBufferLength
	        The number of elements in the array.

	@return A boolean indicating if the operation was successful. ETrue if the operation succeeded, 
	        otherwise EFalse.
	*/
	virtual TBool SetMonoPixels(TUint32* aGray256Buffer,TInt aBufferLength) = 0;

    /**
    Sets a specified number of pixels to the specified greyscale value.

	For image types which support blocking of pixels eg JPEG, the current
	pixel block is set using the data supplied in aGray256Buffer.

	This is a virtual function that each derived class must implement.

	@param  aGray256Buffer
	        A pointer to a buffer representing a block of pixel color values.

	@return A boolean indicating if the operation was successful. ETrue if the operation succeeded, 
	        otherwise EFalse.
	*/
	virtual TBool SetMonoPixelBlock(TUint32* aGray256Buffer) = 0;

	// Processor flow control

	/**
	Sets the current position in the bitmap to aPosition.

	This is a virtual function that each derived class must implement.

	@param  aPosition
	        A reference to TPoint object defining the position to move to.

	@return	A boolean indicating if the operation was successful. ETrue if the operation succeeded, 
	        otherwise EFalse.
	*/
	virtual TBool SetPos(const TPoint& aPosition) = 0;

	/**
	Commits the changes made to the current bitmap by flushing the buffer.

	This is a virtual function that each derived class must implement.

	@post
	The current position is updated.

	@return	A boolean indicating if the operation was successful. ETrue if the operation succeeded, 
	        otherwise EFalse.
    */
	virtual TBool FlushPixels() = 0;
	
private:
	// Future proofing
	IMPORT_C virtual void ReservedVirtual1();
	IMPORT_C virtual void ReservedVirtual2();
	IMPORT_C virtual void ReservedVirtual3();
	IMPORT_C virtual void ReservedVirtual4();
	};

/**
@publishedAll
@released

Flag used to determine the type of transformation which is the result of 
single or multiple transformation operations requested via calls to
COperationExtension::AddOperationL.

8 unique orientations:

@code
normal  90      180     270
00 10   01 00   11 01   10 11
01 11   11 10   10 00   00 01

V flip  90      180     270
10 00   11 10   =Hflip  =Hflip+90
11 01   01 00

H flip  90      180     270
01 11   00 01   =Vflip  =Vflip+90
00 10   10 11
@endcode

@see COperationExtension::AddOperationL
*/
enum TTransformOptions
	{
	/** Normal Decode
	*/
	EDecodeNormal = 0x11011000,

	/** Rotate 90 degrees.
	*/
	EDecodeRotate90	= 0x10110001,

	/** Rotate 180 degrees.
	*/
	EDecodeRotate180 = 0x00100111,

	/** Rotate 270 degrees.
	*/
	EDecodeRotate270 = 0x01001110,
	
	/** Horizontal flip.
	*/
	EDecodeHorizontalFlip = 0x10001101,
	
	/** Horizontal flip and rotate 90 degrees.
	*/
	EDecodeHorizontalFlipRotate90 = 0x11100100,

	/** Vertical flip.
	*/
	EDecodeVerticalFlip	= 0x01110010,

	/** Vertical flip and rotate 90 degrees.
	*/
	EDecodeVerticalFlipRotate90 = 0x00011011
	};


/**
@publishedAll
@released

Class that provides support for Framework Extensions.

@see CImageProcessor
@see CImageReadCodec
@see CImageDecoderPlugin
*/
class CImageProcessorExtension : public CImageProcessor
	{
public:
	IMPORT_C virtual ~CImageProcessorExtension();
	IMPORT_C void SetClippingRect(const TRect& aRect);
	IMPORT_C void SetScaling(TInt aScalingCoeff);
	IMPORT_C void SetScaling(const TSize& aDesiredSize);
	IMPORT_C void SetOperation(TTransformOptions aOperation);
	IMPORT_C void SetInitialScanlineSkipPadding(TInt aNumberOfScanlines);

protected:
	IMPORT_C CImageProcessorExtension();

protected:
	/** Clipping rectangle */
	TRect iClippingRect;
	/** Scaling coefficient */
	TInt iScalingCoeff;
	/** Desired size after scaling */
	TSize iDesiredSize;
	/** Operations to apply to image */
	TTransformOptions iOperation;
	/** Position in destination at which start rendering */
	TPoint iStartPosition;
	/** Position in destination at which rendering is complete */
	TPoint iEndPosition;
	/** An initial one-off number of scanlines to be skipped */
	TInt iNumberOfScanlinesToSkip;
	};
   
inline TInt TColorConvertor::RgbToMonochrome(TRgb aRgb)
	{
	TInt value = aRgb.Internal();
	TInt r = value&0xFF0000;
	TInt g = value&0xFF00;
	value  = (value&0xFF)<<16;	// blue<<16
	value += r<<1;     		// + (red<<16)*2
	value += g<<(16+2-8);	// + (green<<16)*4
	value += g<<(16+0-8);	// + (green<<16)
	return value>>(16+3);	// total/8
	}

#endif //___IMAGEPROCESSOR_H__

