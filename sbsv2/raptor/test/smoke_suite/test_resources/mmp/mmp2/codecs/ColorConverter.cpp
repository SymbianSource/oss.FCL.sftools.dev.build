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


_LIT(KBitmapUtilPanicCategory, "TImageBitmapUtil");
GLDEF_C void Panic(TImageBitmapUtilPanic aError)
	{
	User::Panic(KBitmapUtilPanicCategory, aError);
	}

/**
@see TColorConvertor.
*/
class TGray2Convertor : public TColorConvertor
	{
public:
	virtual TInt ColorIndex(TRgb aColor) const { return RgbToMonochrome(aColor)>>7; }
	virtual TRgb Color(TInt aColorIndex) const { return TRgb::Gray2(aColorIndex); }
	virtual void ColorToIndex(TInt* aIndexBuffer,TRgb* aColorBuffer,TInt aCount) const
					{	
					TInt* end = aIndexBuffer+aCount;
					while(aIndexBuffer<end)
						*(aIndexBuffer++) = RgbToMonochrome(*(aColorBuffer++))>>7;
					}
	};

/**
@see TColorConvertor.
*/
class TGray4Convertor : public TColorConvertor
	{
public:
	virtual TInt ColorIndex(TRgb aColor) const { return RgbToMonochrome(aColor)>>6; }
	virtual TRgb Color(TInt aColorIndex) const { return TRgb::Gray4(aColorIndex); }
	virtual void ColorToIndex(TInt* aIndexBuffer,TRgb* aColorBuffer,TInt aCount) const
					{
					TInt* end = aIndexBuffer+aCount;
					while(aIndexBuffer<end)
						*(aIndexBuffer++) = RgbToMonochrome(*(aColorBuffer++))>>6;
					}
	};

/**
@see TColorConvertor.
*/
class TGray16Convertor : public TColorConvertor
	{
public:
	virtual TInt ColorIndex(TRgb aColor) const { return RgbToMonochrome(aColor)>>4; }
	virtual TRgb Color(TInt aColorIndex) const { return TRgb::Gray16(aColorIndex); }
	virtual void ColorToIndex(TInt* aIndexBuffer,TRgb* aColorBuffer,TInt aCount) const
					{	
					TInt* end = aIndexBuffer+aCount;
					while(aIndexBuffer<end)
						*(aIndexBuffer++) = RgbToMonochrome(*(aColorBuffer++))>>4;
					}
	};

/**
@see TColorConvertor.
*/
class TGray256Convertor : public TColorConvertor
	{
public:
	virtual TInt ColorIndex(TRgb aColor) const { return RgbToMonochrome(aColor); }
	virtual TRgb Color(TInt aColorIndex) const { return TRgb::Gray256(aColorIndex); }
	virtual void ColorToIndex(TInt* aIndexBuffer,TRgb* aColorBuffer,TInt aCount) const
					{	
					TInt* end = aIndexBuffer+aCount;
					while(aIndexBuffer<end)
						*(aIndexBuffer++) = RgbToMonochrome(*(aColorBuffer++));
					}
	};

/**
@see TColorConvertor.
*/
class TColor16Convertor : public TColorConvertor
	{
public:
	virtual TInt ColorIndex(TRgb aColor) const { return aColor.Color16(); }
	virtual TRgb Color(TInt aColorIndex) const { return TRgb::Color16(aColorIndex); }
	virtual void ColorToIndex(TInt* aIndexBuffer,TRgb* aColorBuffer,TInt aCount) const
					{	
					TInt* end = aIndexBuffer+aCount;
					while(aIndexBuffer<end)
						{
						*(aIndexBuffer++) = (aColorBuffer++)->Color16();
						}
					}
	};

/**
@see TColorConvertor.
*/
class TColor256Convertor : public TColorConvertor
	{
public:
	virtual TInt ColorIndex(TRgb aColor) const { return aColor.Color256(); }
	virtual TRgb Color(TInt aColorIndex) const { return TRgb::Color256(aColorIndex); }
	virtual void ColorToIndex(TInt* aIndexBuffer,TRgb* aColorBuffer,TInt aCount) const
					{	
					TInt* end = aIndexBuffer+aCount;
					while(aIndexBuffer<end)
						*(aIndexBuffer++) = (aColorBuffer++)->Color256();
					}
	};

/**
@see TColorConvertor.
*/
class TColor4KConvertor : public TColorConvertor
	{
public:
	virtual TInt ColorIndex(TRgb aColor) const { return aColor._Color4K(); }
	virtual TRgb Color(TInt aColorIndex) const { return TRgb::Color4K(aColorIndex); }
	virtual void ColorToIndex(TInt* aIndexBuffer,TRgb* aColorBuffer,TInt aCount) const
					{	
					TInt* end = aIndexBuffer+aCount;
					while(aIndexBuffer<end)
						{
						*(aIndexBuffer++) = (aColorBuffer++)->_Color4K();
						}
					}
	};

/**
@see TColorConvertor.
*/
class TColor64KConvertor : public TColorConvertor
	{
public:
	virtual TInt ColorIndex(TRgb aColor) const { return aColor._Color64K(); }
	virtual TRgb Color(TInt aColorIndex) const { return TRgb::Color64K(aColorIndex); }
	virtual void ColorToIndex(TInt* aIndexBuffer,TRgb* aColorBuffer,TInt aCount) const
					{
					TInt* end = aIndexBuffer+aCount;
					while(aIndexBuffer<end)
						{
						*(aIndexBuffer++) = (aColorBuffer++)->_Color64K();
						}
					}
	};

/**
@see TColorConvertor.
*/
class TColor16MConvertor : public TColorConvertor
	{
public:
	virtual TInt ColorIndex(TRgb aColor) const { return aColor.Internal(); }
	virtual TRgb Color(TInt aColorIndex) const { return TRgb::Color16M(aColorIndex); }
	virtual void ColorToIndex(TInt* aIndexBuffer,TRgb* aColorBuffer,TInt aCount) const
					{
					Mem::Copy(aIndexBuffer,aColorBuffer,aCount*sizeof(TRgb));
					}
	};

/**
@see TColorConvertor.
*/
class TColor16MUConvertor : public TColorConvertor
	{
public:
	virtual TInt ColorIndex(TRgb aColor) const { return aColor._Color16MU(); }
	virtual TRgb Color(TInt aColorIndex) const { return TRgb::Color16MU(aColorIndex); }
	virtual void ColorToIndex(TInt* aIndexBuffer,TRgb* aColorBuffer,TInt aCount) const
					{
					// do a Mem::Copy as this ensures that top byte (which
					// in a 16MA context is interpreted as the alpha value)
					// is 0xFF (opaque) instead of 0x00 (transparent)
					Mem::Copy(aIndexBuffer,aColorBuffer,aCount*sizeof(TRgb));
					}
	};

/**
@see TColorConvertor.
*/
class TColor16MAConvertor : public TColorConvertor
	{
public:
	virtual TInt ColorIndex(TRgb aColor) const { return aColor._Color16MA(); }
	virtual TRgb Color(TInt aColorIndex) const { return TRgb::Color16MA(aColorIndex); }
	virtual void ColorToIndex(TInt* aIndexBuffer,TRgb* aColorBuffer,TInt aCount) const
					{
					Mem::Copy(aIndexBuffer,aColorBuffer,aCount*sizeof(TRgb));
					}
	};
	
TColorConvertor* CreateColorConvertorL(TDisplayMode aDisplayMode)
	{
	switch (aDisplayMode)
		{
	case EGray2:		return new(ELeave) TGray2Convertor;
	case EGray4:		return new(ELeave) TGray4Convertor;
	case EGray16:		return new(ELeave) TGray16Convertor;
	case EGray256:		return new(ELeave) TGray256Convertor;
	case EColor16:		return new(ELeave) TColor16Convertor;
	case EColor256:		return new(ELeave) TColor256Convertor;
	case EColor4K:		return new(ELeave) TColor4KConvertor;
	case EColor64K:		return new(ELeave) TColor64KConvertor;
	case EColor16M:		return new(ELeave) TColor16MConvertor;
	case EColor16MU:	return new(ELeave) TColor16MUConvertor;
	case EColor16MA:	return new(ELeave) TColor16MAConvertor;
	default:		
		User::Leave(KErrNotSupported);
		return NULL; //Keep the compiler happy!!
		};	
	}
	


