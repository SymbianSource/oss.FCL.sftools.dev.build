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
* This class represents the boot sector of a FAT16 image. 
* This class is derived from basebootsector class which is constitutes 
* the common boot sector fields for FAT16 and FAT32 class. 	
* @internalComponent
* @released
*
*/

#include "fat16bootsector.h"

/**
Constructor of the fat16 boot sector class

@internalComponent
@released
*/
TFAT16BootSector::TFAT16BootSector()
{
}

/**
Destructor of the fat16 boot sector class

@internalComponent
@released
*/
TFAT16BootSector::~TFAT16BootSector()
{
}

/**
Set the file system type

@internalComponent
@released
*/
void TFAT16BootSector::SetFileSysType()
{
	strcpy(reinterpret_cast<char*>(iFileSysType),"FAT16   ");
}	
/**
returns the file system type
@return file system type 

@internalComponent
@released
*/
unsigned char* TFAT16BootSector::FileSysType()
{
	return iFileSysType;
}

/**
Number of entries allowed in the root directory,specific to Fat12/16,
zero for FAT32

@internalComponent
@released
*/
void TFAT16BootSector::SetRootDirEntries()
{
	iRootDirEntries = KDefaultRootDirEntries;;		
}

/**
Sets the number of reserved sectors on the volume

@internalComponent
@released
*/
void TFAT16BootSector::SetReservedSectors()
{
	iReservedSectors = KDefaultFat16ReservedSectors;
}

/**
Computes the sectors per cluster ratio
To refer this mathematical computation, Please see:
Microsoft Extensible Firmware Initiative FAT32 File 
System Specification document

@internalComponent
@released

@param aPartitionSize partition size in bytes
*/
void TFAT16BootSector::ComputeSectorsPerCluster(Long64 aPartitionSize)
{
	
	if(aPartitionSize > K1GB)
	{
		iSectorsPerCluster = K64SectorsPerCluster;
	}
	else if(aPartitionSize > K512MB)
	{
		iSectorsPerCluster = K32SectorsPerCluster;
	}
	else if(aPartitionSize > K256MB)
	{
		iSectorsPerCluster = K16SectorsPerCluster;
	}
	else if(aPartitionSize > K128MB)
	{
		iSectorsPerCluster = K8SectorsPerCluster;
	}
	else if(aPartitionSize > K16MB)
	{
		iSectorsPerCluster = K4SectorsPerCluster;
	}
	else 
	{
		iSectorsPerCluster = K2SectorsPerCluster;
	}
}

/**
Sectors used for the Fat table
To refer this mathematical formulae, Please see:
Microsoft Extensible Firmware Initiative FAT32 File System Specification 
document

@internalComponent
@released

@param aPartitionSize partition size
*/
void TFAT16BootSector::ComputeFatSectors(Long64 aPartitionSize)
{
	int iRootDirSectors = ((iRootDirEntries * 32) + (iBytesPerSector - 1)) / iBytesPerSector;
	int Log2OfBytesPerSector = Log2(iBytesPerSector);
	unsigned long TotalSectors64 = (unsigned long)(aPartitionSize >> Log2OfBytesPerSector);
	unsigned int tmpval1 = TotalSectors64 - (iReservedSectors + iRootDirSectors);
	unsigned int tmpval2 =(256 * iSectorsPerCluster) + iNumberOfFats;
	unsigned int FatSectors =(tmpval1 + (tmpval2 - 1)) / tmpval2;
	iFatSectors = (unsigned short)FatSectors;	
	iFatSectors32 = 0;
}
