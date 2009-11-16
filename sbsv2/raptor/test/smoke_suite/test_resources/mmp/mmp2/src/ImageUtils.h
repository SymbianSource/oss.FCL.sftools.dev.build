/*
* Copyright (c) 2002-2009 Nokia Corporation and/or its subsidiary(-ies).
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


#ifndef __ImageUtils_h
#define __ImageUtils_h

/*Template class CleanupResetAndDestroy
 *
 * Shamelessly copied from CleanupClose to clean up
 * the array of implementation information from the cleanup stack.
 */

template <class T>
class CleanupResetAndDestroy
	{
public:
	inline static void PushL(T& aRef);
private:
	static void ResetAndDestroy(TAny *aPtr);
	};
template <class T>
inline void CleanupResetAndDestroyPushL(T& aRef);


template <class T>
inline void CleanupResetAndDestroy<T>::PushL(T& aRef)
	{CleanupStack::PushL(TCleanupItem(&ResetAndDestroy,&aRef));}
template <class T>
void CleanupResetAndDestroy<T>::ResetAndDestroy(TAny *aPtr)
	{(STATIC_CAST(T*,aPtr))->ResetAndDestroy();}
template <class T>
inline void CleanupResetAndDestroyPushL(T& aRef)
	{CleanupResetAndDestroy<T>::PushL(aRef);}

//
// PtrReadUtil - utility class with methods for standard 
//            reading stuff from a TUint8* string
//

class PtrReadUtil
	{
public:
	// This calls decode from TUint8*
	static TInt8 ReadInt8(const TUint8* aPtr);
	static TUint8 ReadUint8(const TUint8* aPtr);
	static TInt16 ReadInt16(const TUint8* aPtr);
	static TInt16 ReadBigEndianInt16(const TUint8* aPtr);
	static TUint16 ReadUint16(const TUint8* aPtr);
	static TUint16 ReadBigEndianUint16(const TUint8* aPtr);
	static TInt32 ReadInt32(const TUint8* aPtr);
	static TInt32 ReadBigEndianInt32(const TUint8* aPtr);
	static TUint32 ReadUint32(const TUint8* aPtr);
	static TUint32 ReadBigEndianUint32(const TUint8* aPtr);
	// these calls also increment the pointer
	static TInt8 ReadInt8Inc(const TUint8*& aPtr);
	static TUint8 ReadUint8Inc(const TUint8*& aPtr);
	static TInt16 ReadInt16Inc(const TUint8*& aPtr);
	static TInt16 ReadBigEndianInt16Inc(const TUint8*& aPtr);
	static TUint16 ReadUint16Inc(const TUint8*& aPtr);
	static TUint16 ReadBigEndianUint16Inc(const TUint8*& aPtr);
	static TInt32 ReadInt32Inc(const TUint8*& aPtr);
	static TInt32 ReadBigEndianInt32Inc(const TUint8*& aPtr);
	static TUint32 ReadUint32Inc(const TUint8*& aPtr);
	static TUint32 ReadBigEndianUint32Inc(const TUint8*& aPtr);
	};

inline TUint8 PtrReadUtil::ReadUint8(const TUint8* aPtr)
	{
	return *aPtr ;
	}

inline TInt8 PtrReadUtil::ReadInt8(const TUint8* aPtr)
	{
	return TInt8(ReadUint8(aPtr));
	}

inline TUint16 PtrReadUtil::ReadUint16(const TUint8* aPtr)
	{
	return TUint16(aPtr[0] | (aPtr[1]<<8));
	}

inline TInt16 PtrReadUtil::ReadInt16(const TUint8* aPtr)
	{
	return TInt16(ReadUint16(aPtr));
	}

inline TUint32 PtrReadUtil::ReadUint32(const TUint8* aPtr)
	{
	return TUint32(aPtr[0] | (aPtr[1]<<8) | (aPtr[2]<<16) | (aPtr[3]<<24));
	}

inline TInt32 PtrReadUtil::ReadInt32(const TUint8* aPtr)
	{
	return TInt32(ReadUint32(aPtr));
	}

inline TUint16 PtrReadUtil::ReadBigEndianUint16(const TUint8* aPtr)
	{
	return TUint16((aPtr[0]<<8) | aPtr[1]);
	}

inline TInt16 PtrReadUtil::ReadBigEndianInt16(const TUint8* aPtr)
	{
	return TInt16(ReadBigEndianUint16(aPtr));
	}

inline TUint32 PtrReadUtil::ReadBigEndianUint32(const TUint8* aPtr)
	{
	return TUint32((aPtr[0]<<24) | (aPtr[1]<<16) | (aPtr[2]<<8) | aPtr[3]);
	}

inline TInt32 PtrReadUtil::ReadBigEndianInt32(const TUint8* aPtr)
	{
	return TInt32(ReadBigEndianInt32(aPtr));
	}

inline TInt8 PtrReadUtil::ReadInt8Inc(const TUint8*& aPtr)
	{
	TInt8 result = ReadInt8(aPtr);
	aPtr += 1;
	return result;
	}

inline TUint8 PtrReadUtil::ReadUint8Inc(const TUint8*& aPtr)
	{
	TUint8 result = ReadUint8(aPtr);
	aPtr += 1;
	return result;
	}

inline TInt16 PtrReadUtil::ReadInt16Inc(const TUint8*& aPtr)
	{
	TInt16 result = ReadInt16(aPtr);
	aPtr += 2;
	return result;
	}

inline TUint16 PtrReadUtil::ReadUint16Inc(const TUint8*& aPtr)
	{
	TUint16 result = ReadUint16(aPtr);
	aPtr += 2;
	return result;
	}

inline TInt16 PtrReadUtil::ReadBigEndianInt16Inc(const TUint8*& aPtr)
	{
	TInt16 result = ReadBigEndianInt16(aPtr);
	aPtr += 2;
	return result;
	}

inline TUint16 PtrReadUtil::ReadBigEndianUint16Inc(const TUint8*& aPtr)
	{
	TUint16 result = ReadBigEndianUint16(aPtr);
	aPtr += 2;
	return result;
	}

inline TInt32 PtrReadUtil::ReadInt32Inc(const TUint8*& aPtr)
	{
	TInt32 result = ReadInt32(aPtr);
	aPtr += 4;
	return result;
	}

inline TUint32 PtrReadUtil::ReadUint32Inc(const TUint8*& aPtr)
	{
	TUint32 result = ReadUint32(aPtr);
	aPtr += 4;
	return result;
	}

inline TInt32 PtrReadUtil::ReadBigEndianInt32Inc(const TUint8*& aPtr)
	{
	TInt32 result = ReadBigEndianInt32(aPtr);
	aPtr += 4;
	return result;
	}

inline TUint32 PtrReadUtil::ReadBigEndianUint32Inc(const TUint8*& aPtr)
	{
	TUint32 result = ReadBigEndianUint32(aPtr);
	aPtr += 4;
	return result;
	}

class PtrWriteUtil
	{
public:
	static void WriteInt8(TUint8* aPtr, TInt aData);
	static void WriteInt16(TUint8* aPtr, TInt aData);
	static void WriteInt32(TUint8* aPtr, TInt aData);
	// Big endian version
	static void WriteBigEndianInt32(TUint8* aPtr, TInt32 aData);
	static void WriteBigEndianInt16(TUint8* aPtr, TInt aData);
	};

inline void PtrWriteUtil::WriteInt8(TUint8* aPtr, TInt aData)
	{
	aPtr[0] = TUint8(aData);
	}

inline void PtrWriteUtil::WriteInt16(TUint8* aPtr, TInt aData)
	{
	aPtr[0] = TUint8(aData);
	aPtr[1] = TUint8(aData>>8);
	}

inline void PtrWriteUtil::WriteInt32(TUint8* aPtr, TInt aData)
	{
	aPtr[0] = TUint8(aData);
	aPtr[1] = TUint8(aData>>8);
	aPtr[2] = TUint8(aData>>16);
	aPtr[3] = TUint8(aData>>24);
	}

inline void PtrWriteUtil::WriteBigEndianInt32(TUint8* aPtr, TInt32 aData)
	{
	aPtr[0] = TUint8(aData>>24);
	aPtr[1] = TUint8(aData>>16);
	aPtr[2] = TUint8(aData>>8);
	aPtr[3] = TUint8(aData);
	}

inline void PtrWriteUtil::WriteBigEndianInt16(TUint8* aPtr, TInt aData)
	{
	aPtr[0] = TUint8(aData>>8);
	aPtr[1] = TUint8(aData);
	}

class ColorCcomponent
	{
public:
	static TInt ClampColorComponent(TInt value);
	};

inline TInt ColorCcomponent::ClampColorComponent(TInt value)
	{
	return (value < 0) ? 0 : (value > 255) ? 255 : value;
	}


//
// The following routines have been copied from Graphics subsystem.
// They deal with alpha to premultiplied alpha and viceversa conversions.
// The original files are: blendingalgorithms.h and blendingalgorithms.inl
//

const TUint32 KRBMask = 0x00ff00ff;
const TUint32 KAGMask = 0xff00ff00;
const TUint32 KGMask  = 0x0000ff00;
const TUint32 KAMask  = 0xff000000;
const TUint32 KRBBias = 0x00800080;
const TUint32 KGBias  = 0x00008000;


/**
Premultiplies the color channel values with the Alpha channel value.
Alpha value remains unchanged. An approximation is used in the operation where the division
by 255 is approximated by a shift-by-8-bits operation (i.e. division by 256).
@param	aPixel	The 32 bit pixel value to be pre-multiplied.
@return	The PMA value.
@internalTechnology
@released
*/
inline TUint32 NonPMA2PMAPixel(TUint32 aPixel)
	{
	TUint8 tA = (TUint8)(aPixel >> 24);
	if (tA==0)
		{ 
		return 0;
		}
	if (tA==0xff) 
		{
		return aPixel;
		}

	// Use a bias value of 128 rather than 255, but also add 1/256 of the numerator 
	// before dividing the sum by 256.

	TUint32 scaledRB = (aPixel & KRBMask) * tA + KRBBias;
	scaledRB = (scaledRB + ( (scaledRB >> 8) & KRBMask) ) >> 8;
	TUint32 scaledG = (aPixel & KGMask ) * tA + KGBias;
	scaledG = (scaledG + (scaledG >> 8)) >> 8;
	
	return (aPixel & KAMask) | (scaledRB & KRBMask) | (scaledG & KGMask);
	}


/**
Divives the PMA pixel color channels with the Alpha value, to convert them to non-PMA format.
Alpha value remains unchanged.
@param	aPixel	the premultiplied 32 bit pixel value.
@param	aNormTable	The lookup table used to do the normalisation (the table converts the division
					to multiplication operation).
					The table is usually obtainable by a call to the method:
					PtrTo16BitNormalisationTable, which is defined in lookuptable.dll(.lib).
					The lookup table for normalised alpha is compluted using this equation: 
					Table[index] = (255*256) / index (where index is an 8 bit value).
@return The NON-PMA 32 bit pixel value.
@internalTechnology
@released
*/
inline TUint32 PMA2NonPMAPixel(TUint32 aPixel, const TUint16* aNormTable)
	{
	TUint8 alpha = (TUint8)(aPixel >> 24);
	if (alpha==0)
		{ 
		return 0;
		}
	if (alpha==0xff) 
		{
		return aPixel;
		}
	TUint16 norm = aNormTable[alpha];
	TUint32 norm_rb = (((aPixel & KRBMask) * norm) >> 8) & KRBMask;
	TUint32 norm_g =  (((aPixel & KGMask ) * norm) >> 8) & KGMask;
	
	return ((aPixel & KAMask) | norm_rb | norm_g);
	}


/**
In-place version of NonPMA2PMAPixel.
@see NonPMA2PMAPixel
@internalTechnology
@released
*/
inline void Convert2PMA(TUint32& aInOutValue)
	{
	aInOutValue = NonPMA2PMAPixel(aInOutValue);
	}


/**
In-place version of PMA2NonPMAPixel
@see PMA2NonPMAPixel
@internalTechnology
@released
*/
inline void Convert2NonPMA(TUint32& aInOutValue, const TUint16* aNormTable)
	{
	aInOutValue = PMA2NonPMAPixel(aInOutValue, aNormTable);
	}


#endif  // __ImageUtils_h
