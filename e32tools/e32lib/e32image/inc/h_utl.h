// Copyright (c) 1995-2009 Nokia Corporation and/or its subsidiary(-ies).
// All rights reserved.
// This component and the accompanying materials are made available
// under the terms of "Eclipse Public License v1.0"
// which accompanies this distribution, and is available
// at the URL "http://www.eclipse.org/legal/epl-v10.html".
//
// Initial Contributors:
// Nokia Corporation - initial contribution.
//
// Contributors:
//
// Description:
//

#if !defined(__H_UTL_H__)
#define __H_UTL_H__
//
#include <stdio.h>

#ifdef __VC32__
 #ifdef __MSVCDOTNET__
  #include <iostream>
  #include <strstream>
  #include <fstream>
  using namespace std;
 #else //!__MSVCDOTNET__
  #include <iostream.h>
  #include <strstrea.h>
  #include <fstream.h>
 #endif //__MSVCDOTNET__
#else //!__VC32__
#ifdef __TOOLS2__ 
#include <fstream>
#include <iostream>
#include <sstream>
#include <iomanip>
using namespace std;
#else // !__TOOLS2__ OR __VC32__ OR __MSVCDOTNET__
  #include <iostream.h>
  #include <strstream.h>
  #include <fstream.h>
#endif
#endif 

#ifdef __LINUX__
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <ctype.h>


#define _close close
#define _filelength filelength
#define _lseek lseek
#define _read read
#define _snprintf snprintf
#define _vsnprintf vsnprintf

// linux case insensitive stromg comparisons have different names
#define stricmp  strcasecmp		
#define _stricmp strcasecmp		
#define strnicmp strncasecmp	

// to fix the linux problem: memcpy does not work with overlapped areas.
#define memcpy memmove

// hand-rolled strupr function for converting a string to all uppercase
char* strupr(char *a);

// return the length of a file
off_t filelength (int filedes);
#endif


#include <e32cmn.h>
#include <e32def.h>
#include <e32def_private.h>

#define ALIGN4K(a) ((a+0xfff)&0xfffff000)
#define ALIGN4(a) ((a+0x3)&0xfffffffc)


#ifdef HEAPCHK
#define NOIMAGE
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
void HeapCheck();
#endif
#define Print H.PrintString
//
const TInt KMaxStringLength=0x400;
//
class HFile
	{
public:
	static TBool Open(const TText * const aFileName, TInt32 * const aFileHandle);
	static TBool Read(const TInt32 aFileHandle, TAny * const aBuffer, const TUint32 aCount);
	static TBool Seek(const TInt32 aFileHandle, const TUint32 aOffset);
	static TUint32 GetPos(const TInt32 aFileHandle);
	static TAny Close(const TInt32 aFileHandle);
	static TUint32 GetLength(const TInt32 aFileHandle);
	static TUint32 GetLength(TText *aName);
	static TUint32 Read(TText *aName, TAny *someMem);
	};
//
//inline TAny* operator new(TUint /*aSize*/, TAny* aBase)
//	{return aBase;}

class HMem
	{
public:
	static TAny *Alloc(TAny * const aBaseAddress,const TUint32 aImageSize);
	static void Free(TAny * const aMem);
	static void Copy(TAny * const aDestAddr,const TAny * const aSourceAddr,const TUint32 aLength);
	static void Move(TAny * const aDestAddr,const TAny * const aSourceAddr,const TUint32 aLength);
	static void Set(TAny * const aDestAddr, const TUint8 aFillChar, const TUint32 aLength);
	static void FillZ(TAny * const aDestAddr, const TUint32 aLength);

	static TUint CheckSum(TUint *aPtr, TInt aSize);
	static TUint CheckSum8(TUint8 *aPtr, TInt aSize);
	static TUint CheckSumOdd8(TUint8 *aPtr, TInt aSize);
	static TUint CheckSumEven8(TUint8 *aPtr, TInt aSize);

	static void Crc32(TUint32& aCrc, const TAny* aPtr, TInt aLength);
	};
//
enum TPrintType {EAlways, EScreen, ELog, EWarning, EError, EPeError, ESevereError, EDiagnostic};
//
class HPrint
	{
public:
	~HPrint();
	void SetLogFile(TText *aFileName);
	void CloseLogFile();						//	Added to close intermediate log files.
	TInt PrintString(TPrintType aType,const char *aFmt,...);
public:
	TText iText[KMaxStringLength];
	TBool iVerbose;
private:
	ofstream iLogFile;
	};
//
extern HPrint H;
extern TBool PVerbose;
//
TAny *operator new(TUint aSize);
void operator delete(TAny *aPtr);
//
#ifdef __TOOLS2__
istringstream &operator>>(istringstream &is, TVersion &aVersion);
#else
istrstream &operator>>(istrstream &is, TVersion &aVersion);
#endif
//
TInt StringToTime(TInt64 &aTime, char *aString);

void ByteSwap(TUint &aVal);
void ByteSwap(TUint16 &aVal);
void ByteSwap(TUint *aPtr, TInt aSize);

extern TBool gLittleEndian;


/**
 Convert string to number.
*/
template <class T>
TInt Val(T& aVal, char* aStr)
	{

	T x;
	#ifdef __TOOLS2__
	istringstream val(aStr);
	#else
	istrstream val(aStr,strlen(aStr));
	#endif
	#if defined(__MSVCDOTNET__) || defined (__TOOLS2__) 
		val >> setbase(0);
	#endif //__MSVCDOTNET__                             
	val >> x;
	if (!val.eof() || val.fail())
		return KErrGeneral;
	aVal=x;
	return KErrNone;
	}

// Filename decompose routines
enum TDecomposeFlag
	{
	EUidPresent=1,
	EVerPresent=2
	};

class TFileNameInfo
	{
public:
	TFileNameInfo(const char* aFileName, TBool aLookForUid);
public:
	const char* iFileName;
	TInt iTotalLength;
	TInt iBaseLength;
	TInt iExtPos;
	TUint32 iUid3;
	TUint32 iModuleVersion;
	TUint32 iFlags;
	};

extern char* NormaliseFileName(const char* aName);
extern char* SplitFileName(const char* aName, TUint32& aUid, TUint32& aModuleVersion, TUint32& aFlags);
extern char* SplitFileName(const char* aName, TUint32& aModuleVersion, TUint32& aFlags);
extern TInt ParseCapabilitiesArg(SCapabilitySet& aCapabilities, const char *aText);
extern TInt ParseBoolArg(TBool& aValue, const char *aText);

#endif

