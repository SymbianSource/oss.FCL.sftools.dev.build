/*
* Copyright (c) 2006-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* Directory class exports the functions required to construct either 
* single entry (constructor) or to construct directory structure.
* Also initializes the date and time attributes for all newly created
* entries.
* @internalComponent
* @released
*
*/


#include "errorhandler.h"
#include "directory.h"
#include "constants.h"

/**
Constructor:
1. To Initialize the date and time variable
2. Also to initialize other variable's

@internalComponent
@released

@param aEntryName - the entry name
*/

FILESYSTEM_API CDirectory::CDirectory(char* aEntryName):
						iEntryName(aEntryName),
						iAttribute(0),
						iNtReserved(KNTReserverdByte),
						iCreationTimeMsecs(KCreateTimeInMsecs),
						iClusterNumberHi(0),
						iClusterNumberLow(0),
						iFileSize (0) 
{
	InitializeTime();
}

/**
Destructor: 
1. To delete all the entries available in the form of directory structure
2. Also to delete the current entry

@internalComponent
@released 
*/

FILESYSTEM_API CDirectory::~CDirectory()
{
	while(iDirectoryList.size() > 0)
	{
		delete iDirectoryList.front();
		iDirectoryList.pop_front();
	}
}

/**
Function to initialize the time attributes of an entry

@internalComponent
@released 
*/

void CDirectory::InitializeTime()
{
	time_t rawtime;
	time ( &rawtime );
	iDateAndTime = localtime ( &rawtime );
	iDate.iCurrentDate.Day = iDateAndTime->tm_mday;
	iDate.iCurrentDate.Month = iDateAndTime->tm_mon+1; //As per FAT spec
	iDate.iCurrentDate.Year = iDateAndTime->tm_year - 80;//As per FAT spec
	iTime.iCurrentTime.Hour = iDateAndTime->tm_hour;
	iTime.iCurrentTime.Minute = iDateAndTime->tm_min;
	iTime.iCurrentTime.Seconds = iDateAndTime->tm_sec / 2;//As per FAT spec

	iCreationDate = iDate.iImageDate;
	iCreatedTime = iTime.iImageTime;
	iLastAccessDate = iDate.iImageDate;
	iLastWriteDate = iDate.iImageDate;
	iLastWriteTime = iTime.iImageTime;
}

/**
Function to initialize the entry name

@internalComponent
@released

@param aEntryName - entry name need to be initialized
*/
FILESYSTEM_API void CDirectory::SetEntryName(String aEntryName)
{
	iEntryName = aEntryName;
}

/**
Function to return the entry name

@internalComponent
@released

@return iEntryName - the entry name
*/

FILESYSTEM_API String CDirectory::GetEntryName() const
{
	return iEntryName;
}

/**
Function to initialize the file path

@internalComponent
@released

@param aFilePath - where the current entry contents actually stored
*/
FILESYSTEM_API void CDirectory::SetFilePath(char* aFilePath)
{
	iFilePath.assign(aFilePath);
}

/**
Function to return the file path

@internalComponent
@released

@return iFilePath - the file path
*/
FILESYSTEM_API String CDirectory::GetFilePath() const
{
	return iFilePath;
}

/**
Function to set the entry attribute

@internalComponent
@released

@param aAttribute - entry attribute
*/
FILESYSTEM_API void CDirectory::SetEntryAttribute(char aAttribute)
{
	iAttribute = aAttribute;
}

/**
Function to return the entry attribute

@internalComponent
@released

@return iAttribute - the entry attribute
*/
FILESYSTEM_API char CDirectory::GetEntryAttribute() const
{
	return iAttribute;
}


/**
Function to initialize the file size, this function is called only if the entry is of
type File.

@internalComponent
@released

@param aFileSize - the current entry file size
*/
FILESYSTEM_API void CDirectory::SetFileSize(unsigned int aFileSize)
{
	iFileSize = aFileSize;
}

/**
Function to return the entry file size, this function is called only if the entry is of
type File.

@internalComponent
@released

@return iFileSize - the file size
*/
FILESYSTEM_API unsigned int CDirectory::GetFileSize() const
{
	return iFileSize;
}

/**
Function to check whether this is a file 

@internalComponent
@released 

@return iFileFlag - the File Flag
*/
bool CDirectory::IsFile() const 
{
	return (iAttribute & EAttrDirectory) == 0  ;
}

/**
Function to return the entries Nt Reserved byte

@internalComponent
@released 

@return iNtReserverd - the Nt Reserved byte
*/
char CDirectory::GetNtReservedByte() const
{
	return iNtReserved;
}

/**
Function to return the entry Creation time in milli-seconds.

@internalComponent
@released

@return iCreatedTimeMsecs - created time in Milli-seconds
*/
char CDirectory::GetCreationTimeMsecs() const
{
	return iCreationTimeMsecs;
}

/**
Function to return the entry Created time

@internalComponent
@released

@retun iCreatedTime - created time
*/
unsigned short int CDirectory::GetCreatedTime() const
{
	return iCreatedTime;
}

/**
Function to return the entry Created date

@internalComponent
@released

@return iCreationDate - created date
*/
unsigned short int CDirectory::GetCreationDate() const
{
	return iCreationDate;
}

/**
Function to return the entry last accessed date

@internalComponent
@released

@return iLastAccessDate - last access date
*/
unsigned short int CDirectory::GetLastAccessDate() const
{
	return iLastAccessDate;
}

/**
Function to set high word cluster number

@internalComponent
@released

@param aHiClusterNumber - high word of current cluster number
*/
void CDirectory::SetClusterNumberHi(unsigned short int aHiClusterNumber)
{
	iClusterNumberHi = aHiClusterNumber;
}

/**
Function to return high word cluster number

@internalComponent
@released

@return iClusterNumberHi - high word of cluster number
*/
unsigned short int CDirectory::GetClusterNumberHi() const
{
	return iClusterNumberHi;
}

/**
Function to set low word cluster number

@internalComponent
@released 

@param aLowClusterNumber - low word of current cluster number
*/
void CDirectory::SetClusterNumberLow(unsigned short int aLowClusterNumber)
{
	iClusterNumberLow = aLowClusterNumber;
}

/**
Function to return low word cluster number

@internalComponent
@released 

@return iClusterNumberLow - low word of cluster number
*/
unsigned short int CDirectory::GetClusterNumberLow() const
{
	return iClusterNumberLow;
}

/**
Function to return last write date

@internalComponent
@released 

@return iLastWriteDate - last write date
*/
unsigned short int CDirectory::GetLastWriteDate() const
{
	return iLastWriteDate;
}

/**
Function to return last write time

@internalComponent
@released

@return iLastWriteTime - last write time
*/
unsigned short int CDirectory::GetLastWriteTime() const
{
	return iLastWriteTime;
}

/**
Function to return sub directory/file list

@internalComponent
@released

@return iDirectoryList -  entry list
*/
FILESYSTEM_API EntryList* CDirectory::GetEntryList()
{
	return &iDirectoryList;
}

/**
Function to insert a entry into Directory list. Also this function can be used 
extensively to construct tree form of directory structure.

@internalComponent
@released

@param aEntry - the entry to be inserted
*/
FILESYSTEM_API void CDirectory::InsertIntoEntryList(CDirectory* aEntry)
{
	iDirectoryList.push_back(aEntry);
}
