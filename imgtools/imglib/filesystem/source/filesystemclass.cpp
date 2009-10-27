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
* This base class defines the common functions, should be available
* for the derived classes (FAT16 and FAT32 boot sector classes).
* @internalComponent
* @released
*
*/

#include"filesystemclass.h"

/**
constructor for CFileSystem class

@internalComponent
@released
*/
CFileSystem::CFileSystem()
{
}

/**
virtual destructor for CFileSystem class

@internalComponent
@released
*/
CFileSystem::~CFileSystem()
{
	delete[] iData;
}

/**
get total number of clusters in data segment of FAT image

@internalComponent
@released

@return iTotalClusters total number of clusters
*/ 
unsigned long int  CFileSystem::GetTotalCluster() const
{
	return iTotalClusters;
}	

/**
Return total number of sectors occupied in root directory

@internalComponent
@released

@return iRootDirSectors total number of root directory sectors
*/ 
unsigned long int CFileSystem::GetRootDirSectors() const
{
	return iRootDirSectors;
}	

/**
Returns cluster size in bytes

@internalComponent
@released

@return iClusterSize cluster size in bytes
*/
unsigned long int  CFileSystem::GetClusterSize() const
{
	return iClusterSize;
}

/**
Function to get the sector size in bytes

@internalComponent
@released

@return iBytesPerSector cluster size in bytes
*/
unsigned int CFileSystem::GetBytesPerSector() const
{
	return iBytesPerSector;
}
