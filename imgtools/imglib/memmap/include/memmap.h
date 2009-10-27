/*
* Copyright (c) 2008-2009 Nokia Corporation and/or its subsidiary(-ies).
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


#if !defined(__MEMMAP_H__)
#define __MEMMAP_H__

#include "memmaputils.h"

/** 
class Memmap

@internalComponent
@released
*/
class Memmap
{
private:
	// Output image file name
	String iOutFileName;
	// Map pointer
	char *iData;
	// Maximum size of the memory map
	unsigned long iMaxMapSize;
	// Start offset of the memory map
	unsigned long iStartOffset;

	// Flag to fill the map after creating
	int iFillFlg;

	// Interface to platform utility functions
	MemmapUtils *iUtils;

	// Fill the memory map
	int FillMemMap( unsigned char fillVal = 0 );
public:

	Memmap( int aFillFlg, String aOutputFile );
	Memmap( int aFillFlg = 1);
	~Memmap( );

	// Create memory map
	int CreateMemoryMap( unsigned long aStartOffset = 0, unsigned char aFillVal = 0 );
	// Close the memory map
	void CloseMemoryMap( int aCloseFile = 1 );
	// Dump the memory map into a file
	void WriteToOutputFile( );

	// Set the output image file name
	void SetOutputFile( String aOutputFile );
	// Set the maximum memory map size
	void SetMaxMapSize( unsigned long aMaxSize );
	// Get the memory map pointer
	char* GetMemoryMapPointer( );
	// Get the map size
	unsigned long GetMapSize( );

	// Operator [] for accessing memory map
	char& operator[]( unsigned long aIndex );
};

#endif //__MEMMAP_H__
