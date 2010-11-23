/*
* Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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

#ifndef __BSYMUTIL_H__
#define __BSYMUTIL_H__

#include <e32std.h>
#include <vector>
#include <string>

using namespace std;

const int BSYM_PAGE_SIZE = 4096;

const int MaxSize = 4*1024*1024;
const TUint16 BsymMajorVer = 3;
const TUint16 BsymMinorVer = 0;
struct TBsymHeader {
	char iMagic[4]; // 'B','S','Y','M' always big-endian
	char iMajorVer[2]; // always big-endian, currently 3
	char iMinorVer[2]; // always big-endian, currently 0.
	char iEndiannessFlag;
	char iCompressionFlag;
	char iReservered[2];
	TUint32 iDbgUnitOffset;
	TUint32 iDbgUnitCount;
	TUint32 iSymbolOffset;
	TUint32 iSymbolCount;
	TUint32 iStringTableOffset;
	TUint32 iStringTableBytes;
	TUint32 iCompressedSize;
	TUint32 iUncompressSize;
	TUint32 iCompressInfoOffset;
};
struct TDbgUnitEntry {
	TUint32 iCodeAddress;
	TUint32 iCodeSymbolCount;
	TUint32 iDataAddress;
	TUint32 iDataSymbolCount;
	TUint32 iBssAddress;
	TUint32 iBssSymbolCount;
	TUint32 iPCNameOffset;
	TUint32 iDevNameOffset;
	TUint32 iStartSymbolIndex;
	TDbgUnitEntry()
	{
		iCodeAddress =0;
		iCodeSymbolCount =0;
		iDataAddress =0;
		iDataSymbolCount =0;
		iBssAddress =0;
		iBssSymbolCount =0;
		iPCNameOffset =0;
		iDevNameOffset =0;
		iStartSymbolIndex =0;
	}
	void Reset()
	{
		iCodeAddress =0;
		iCodeSymbolCount =0;
		iDataAddress =0;
		iDataSymbolCount =0;
		iBssAddress =0;
		iBssSymbolCount =0;
		iPCNameOffset =0;
		iDevNameOffset =0;
		iStartSymbolIndex =0;
	}
};
struct TDbgUnitPCEntry {
	TDbgUnitEntry iDbgUnitEntry;
	string iPCName;
	string iDevName;
};
struct TSymbolEntry {
	TUint32 iAddress;
	TUint32 iLength;
	TUint32 iScopeNameOffset;
	TUint32 iNameOffset;
	TUint32 iSecNameOffset;
	TSymbolEntry()
	{
		iAddress =0;
		iLength =0;
		iScopeNameOffset =0;
		iNameOffset =0;
		iSecNameOffset =0;
	}
};

struct TSymbolPCEntry {
	TSymbolEntry iSymbolEntry;
	string iScopeName;
	string iName;
	string iSecName;
};

struct TPageInfo {
	TUint32 iPageStartOffset;
	TUint32 iPageDataSize;
};

struct TCompressedHeaderInfo
{
	TUint32 iPageSize;
	TUint32 iTotalPageNumber;
	TPageInfo iPages[1];
};

typedef vector<TDbgUnitPCEntry> TDbgUnitEntrySet;
typedef vector<TSymbolPCEntry> TSymbolPCEntrySet;
typedef vector<string> StringList;

struct MapFileInfo
{
	TDbgUnitPCEntry iDbgUnitPCEntry;
	TSymbolPCEntrySet iSymbolPCEntrySet;
};

typedef vector<MapFileInfo> MapFileInfoSet;
class ByteOrderUtil
{
public:
	static bool IsLittleEndian()
	{
		union {
			unsigned int a;
			unsigned char b;
		} c;
		c.a = 1;
		return (c.b == 1);
	}
};

class MemoryWriter
{
public:
	MemoryWriter();
	~MemoryWriter();
	int WriteBytes(const char* pChar, int size);
	TUint32 GetOffset();
	char* GetDataPointer();
	bool ExtendMemory();
	bool SetOffset(TUint32 aOffset);
	void AddEmptyString();
	TUint32 AddString(const string& aStr);
	TUint32 AddScopeName(const string& aStr);
	void SetStringTableStart(TUint32 aOffset);
	TUint32 GetStringTableStart();
private:
	char* iChar;
	TUint32 iOffset;
	TUint32 iStringTableStart;
	string iLastScopeName;
	TUint32 iLastScopeNameOffset;
	TUint32 iTotalSize;
};
#endif
