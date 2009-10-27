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
* This class represents the boot sector of a FAT32 image. 
* This class is derived from basebootsector class which is constitutes 
* the common boot sector fields for FAT16 and FAT32 class. 
* @internalComponent
* @released
*
*/

#include "fat32bootsector.h"

/**
Constructor of the fat16 boot sector class

@internalComponent
@released
*/
TFAT32BootSector::TFAT32BootSector()
{
}

/**
Destructor of the fat16 boot sector class

@internalComponent
@released
*/
TFAT32BootSector::~TFAT32BootSector()
{
}
/**
Set the file system type

@internalComponent
@released
*/
void TFAT32BootSector::SetFileSysType()
{
	strcpy(reinterpret_cast<char*>(iFileSysType),"FAT32   ");
}


//Number of entries allowed in the root directory, specific to Fat12/16, zero for FAT32
void TFAT32BootSector::SetRootDirEntries()
{
	iRootDirEntries = KFat32RootDirEntries;;		
}


//Sets the number of reserved sectors on the volume
void TFAT32BootSector::SetReservedSectors()
{
	iReservedSectors = KDefaultFat32ReservedSectors;
}

/**
Set the sectors per cluster ratio

@internalComponent
@released

@param aPartitionSize partition size in bytes
*/
void TFAT32BootSector::ComputeSectorsPerCluster(Long64 aPartitionSize)
{
	if (aPartitionSize > K32GB)
	{
		iSectorsPerCluster = K64SectorsPerCluster;	
	}
	else if(aPartitionSize > K16GB)
	{
		iSectorsPerCluster = K32SectorsPerCluster;
	}
	else if(aPartitionSize > K8GB)
	{
		iSectorsPerCluster = K16SectorsPerCluster;
	}
	else if ( aPartitionSize > K260MB)
	{
		iSectorsPerCluster = K8SectorsPerCluster;	
	}
	else 
	{
		iSectorsPerCluster = K1SectorsPerCluster;
	}
}
	
/**
Set the sectors per cluster ratio


To refer this mathematical computation, Please see:
Microsoft Extensible Firmware Initiative FAT32 File System 
Specification document

@internalComponent
@released

@param aPartitionSize partition size in bytes
*/
void TFAT32BootSector::ComputeFatSectors(Long64 aPartitionSize)
{
	int iRootDirSectors = ((iRootDirEntries*32) + (iBytesPerSector - 1)) / iBytesPerSector;
	int Log2OfBytesPerSector = Log2(iBytesPerSector);
	Long64 TotalSectors64 = aPartitionSize >> Log2OfBytesPerSector;
	Long64 tmpval1 = TotalSectors64 - (iReservedSectors + iRootDirSectors);
	Long64 tmpval2 =(256 * iSectorsPerCluster) + iNumberOfFats;
	tmpval2 = tmpval2 / 2;
	Long64 FatSectors = (tmpval1 + (tmpval2 - 1)) / tmpval2;
	iFatSectors = 0;
	iFatSectors32 = (unsigned int)FatSectors;
}
/**
Sets the Fat flags

@internalComponent
@released
*/
void TFAT32BootSector::SetExtFlags()
{
	iExtFlags = KDefaultExtFlags;
}

/**
Returns the Fat flags

@internalComponent
@released

@return fat flags
*/
unsigned short TFAT32BootSector::ExtFlags()
{
	return iExtFlags;
}

/**
Sets the version number of the file system

@internalComponent
@released
*/
void TFAT32BootSector::SetFileSystemVersion()
{
	iFileSystemVersion = KDefaultVersion;
}

/**
Returns the version number of the file system

@internalComponent
@released

@return file system version
*/
unsigned short TFAT32BootSector::FileSystemVersion()
{
	return iFileSystemVersion;
}

/**
Sets the cluster number of the root directory

@internalComponent
@released
*/
void TFAT32BootSector::SetRootCluster()
{
	iRootCluster = KDefaultRootDirClusterNumber;
}

/**
Returns the cluster number of the root directory

@internalComponent
@released

@return cluster number allocated to root directory,usually 2.
*/
unsigned int TFAT32BootSector::RootCluster()
{
	return iRootCluster;
}

/**
Set the sector number containing the FSIInfo structure

@internalComponent
@released
*/
void TFAT32BootSector::SetFSInfo()
{
	iFSInfo = KDefaultFSInfoSector;
}

/**
Returns  the sector number containing the FSIInfo structure

@internalComponent
@released

@return FSInfo structure
*/
unsigned short TFAT32BootSector::FSInfo()
{
	return iFSInfo;
}

/**
Set the backup boot sector

@internalComponent
@released
*/
void TFAT32BootSector::SetBackUpBootSector()
{
	iBackUpBootSector = KDefaultBkUpBootSec;
}

/**
Returns the backup boot sector

@internalComponent
@released

@return backup boot sector
*/
unsigned  short TFAT32BootSector::BackUpBootSector()
{
	return iBackUpBootSector;
}

/**
Reserved for future expansion. Code that formats FAT32 volumes should always 
set all of the bytes of this field to 0.

@internalComponent
@released
*/
void TFAT32BootSector::SetFutureReserved()
{
	for(int i = 0;i < KMaxSizeFutureExpansion;i++)
	iFutureReserved[i] = 0;
}

/**
Returns field value reserved for future expansion

@internalComponent
@released

@return zero as this field is initialized to null value here
*/
unsigned char* TFAT32BootSector::FutureReserved()
{
	return iFutureReserved;
}


/**Returns the file system type

@internalComponent
@released

@return file system type
*/
unsigned char* TFAT32BootSector::FileSysType()
{
	return iFileSysType;
}
