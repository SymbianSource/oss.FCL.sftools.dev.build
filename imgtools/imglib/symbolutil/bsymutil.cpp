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

#include "bsymutil.h"
#include <stdio.h>


MemoryWriter::MemoryWriter()
{
	iChar = new char[4*MaxSize];
	iOffset = 0;
	iTotalSize = 4*MaxSize;
	iStringTableStart = 0;
}
MemoryWriter::~MemoryWriter()
{
	delete[] iChar;
}
int MemoryWriter::WriteBytes(const char* pChar, int size)
{
	while(iOffset + size > iTotalSize)
	{
		ExtendMemory();
	}
	memcpy(iChar + iOffset, pChar, size);
	iOffset += size;
	return size;
}
TUint32 MemoryWriter::GetOffset()
{
	return iOffset;
}
char* MemoryWriter::GetDataPointer()
{
	return iChar;
}
bool MemoryWriter::ExtendMemory()
{
	char* pTmp = new char[iTotalSize + MaxSize];
	memcpy(pTmp, iChar, iOffset);
	delete[] iChar;
	iChar = pTmp;
	iTotalSize += MaxSize;
	return true;
}
bool MemoryWriter::SetOffset(TUint32 aOffset)
{
	while(aOffset > iTotalSize)
	{
		ExtendMemory();
	}
	iOffset = aOffset;
	return true;
}
void MemoryWriter::AddEmptyString()
{
	unsigned char len = 0;
	WriteBytes((char *)&len, 1);
}
TUint32 MemoryWriter::AddString(const string& aStr)
{
	TUint32 result = 0;
	if(aStr.empty())
		return result;
	result = iOffset - iStringTableStart;
	int len = aStr.length();
	if(len >= 255)
	{
		TUint16 wlen = len;
		unsigned char mark = 0xff;
		WriteBytes((char*)&mark, 1);
		WriteBytes((char*)&wlen, 2);
		WriteBytes(aStr.c_str(), len);
	}
	else
	{
		unsigned char clen = len;
		WriteBytes((char *)&clen, 1);
		WriteBytes(aStr.c_str(), len);
	}
	return result;
}
TUint32 MemoryWriter::AddScopeName(const string& aStr)
{
	TUint32 result = 0;
	if(aStr.empty())
		return result;
	if(aStr == iLastScopeName)
	{
		return iLastScopeNameOffset;
	}
	else
	{
		iLastScopeName = aStr;
		iLastScopeNameOffset = AddString(aStr);
	}
	return iLastScopeNameOffset;
}
void MemoryWriter::SetStringTableStart(TUint32 aOffset)
{
	iStringTableStart = aOffset;
}
TUint32 MemoryWriter::GetStringTableStart()
{
	return iStringTableStart;
}
