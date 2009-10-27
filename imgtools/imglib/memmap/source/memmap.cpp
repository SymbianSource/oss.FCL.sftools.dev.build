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


#include "memmap.h"

/**
Constructor: Memmap class
Initilize the parameters to data members.

@internalComponent
@released

@param aFillFlg	- Flag to enable the initialisation of memory map
@param aOutputFile - Name of the output file
*/
Memmap::Memmap( int aFillFlg, String aOutputFile )
: iOutFileName(aOutputFile), iData(0), iMaxMapSize(0), iStartOffset(0), iFillFlg(aFillFlg)
{
	iUtils = new MemmapUtils();
}

/**
Constructor: Memmap class
Initilize the parameters to data members.

@internalComponent
@released

@param aFillFlg	- Flag to enable the initialisation of memory map
*/
Memmap::Memmap( int aFillFlg )
: iData(0), iMaxMapSize(0), iStartOffset(0), iFillFlg(aFillFlg)
{
	iUtils = new MemmapUtils();
}


/**
Destructor: Memmap class
Deallocates the memory for data members

@internalComponent
@released
*/
Memmap::~Memmap( )
{
	if(iData)
	{
		CloseMemoryMap();
	}

	if(iUtils)
	{
		delete iUtils;
	}
}

/**
SetOutputFile: To set the output image file

@internalComponent
@released

@param aOutputFile  - Name of the output image file
*/
void Memmap::SetOutputFile( String aOutputFile )
{
	iOutFileName = aOutputFile;
}

/**
SetMaxMapSize: To set the maximum size of the memory map

@internalComponent
@released

@param aMaxSize  - Size of the memory map
*/
void Memmap::SetMaxMapSize( unsigned long aMaxSize )
{ 
	iMaxMapSize = aMaxSize; 
};

/**
GetMapSize: To get the size of the memory map

@internalComponent
@released
*/
unsigned long Memmap::GetMapSize( )
{ 
	return iMaxMapSize; 
}

/**
operator[]: To access the memory map contents

@internalComponent
@released

@param aIndex - Offset of the memory map location
*/
char& Memmap::operator[]( unsigned long aIndex )
{ 
	return iData[aIndex]; 
}

/**
CreateMemoryMap: 
 Opens the memory map file
 Initialises the map size member
 Create the memory map pointer
 Fill the memory map with the specified value

@internalComponent
@released

@param aStartOffset - Start offset of the memory map location
@param aFillVal - Value to be filled in the memory map
*/
int Memmap::CreateMemoryMap( unsigned long aStartOffset, unsigned char aFillVal )
{
	if((!iMaxMapSize) || (aStartOffset > iMaxMapSize))
	{
		return KStatFalse;
	}
	else if(iUtils->IsMapFileOpen() && iData)
	{
		iStartOffset = aStartOffset;
		return KStatTrue;
	}

	if(iUtils->IsMapFileOpen() == KStatFalse)
	{
		if(iUtils->OpenMapFile() == KStatFalse)
		{
			return KStatFalse;
		}
	}

	if(iUtils->CreateFileMapObject(iMaxMapSize) == KStatFalse)
	{
		return KStatFalse;
	}

	iData = (char*)(iUtils->OpenMemMapPointer(0,iMaxMapSize));
	if( !iData )
	{
		return KStatFalse;
	}

	iStartOffset = aStartOffset;
	
	if(iFillFlg)
	{
		return FillMemMap( aFillVal );
	}

	return KStatTrue;
}

/**
CloseMemoryMap: Close the memory map and the associated objects

@internalComponent
@released

@param aCloseFile - Flag to close the memory map file
*/
void Memmap::CloseMemoryMap( int aCloseFile )
{
	// Close map view pointer
	if(!iUtils->CloseMemMapPointer((void*)iData, iMaxMapSize))
	{
		Print(ELog, "Failed to unmap the memory map object");
	}
	iData = 0;

	iUtils->CloseFileMapObject();

	// Close map file
	if(aCloseFile)
	{
		iUtils->CloseMapFile();
	}
}

/**
GetMemoryMapPointer: Get the stating address of the memory map

@internalComponent
@released
*/
char *Memmap::GetMemoryMapPointer( )
{
	if(iData)
		return (iData + iStartOffset);

	return KStatFalse;
}

/**
WriteToOutputFile: Writes the memory map contents to the output file

@internalComponent
@released
*/
void Memmap::WriteToOutputFile( )
{
	Ofstream ofs;

	if(!iData)
	{
		Print(EAlways, "Memory map has not been created");
	}

	if(iOutFileName.empty())
	{
		Print(EAlways, "Output file has not been set");
		return;
	}

	ofs.open(((const char*)iOutFileName.data()), std::ios::binary);
	if(!ofs.is_open())
	{
		Print(EAlways, "Cannot open output file %s", (char*)iOutFileName.data());
		return;
	}

	ofs.write((const char*)(iData + iStartOffset), (iMaxMapSize - iStartOffset));

	ofs.close();

	return;
}

/**
FillMemMap: Fills the memory map with the specified value

@internalComponent
@released

@param aFillVal - Value to be filled
*/
int Memmap::FillMemMap( unsigned char aFillVal )
{
	if(iData)
	{
		// Fill the value
		memset(iData, aFillVal, iMaxMapSize);

		// Unmap the file
		if(iUtils->CloseMemMapPointer((void*)iData, iMaxMapSize) == KStatFalse)
		{
			return KStatFalse;
		}

		// Map it again
		iData = (char*)(iUtils->OpenMemMapPointer(0,iMaxMapSize));
		if(!iData)
		{
			return KStatFalse;
		}
	}

	return KStatTrue;
}

