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
* This file contains the definition of class TFATBaseBootSector. 
* TFATBaseBootSector is the base class for the boot sector class 
* of different FAT file system type.This contains the data member 
* representing the common fields in each FAT image type
* @internalComponent
* @released
*
*/

#include "fatbasebootsector.h"

/**
Constructor of the base boot sector class

@internalComponent
@released
*/
TFATBaseBootSector::TFATBaseBootSector()
{
}

/**
Destructor of the base boot sector class

@internalComponent
@released
*/
TFATBaseBootSector::~TFATBaseBootSector()
{
}

/**
Function Sets the OEM name generally, Indication of what system 
formats the volume

@internalComponent
@released
*/
void TFATBaseBootSector::SetOEMName()
	{
		strcpy( reinterpret_cast<char*>(iOEMName),KDefaultOEMName);
	}

/**
Function to get the OEM name

@internalComponent
@released

@return OEM Name
*/
unsigned char* TFATBaseBootSector::OEMName() 
	{
		return iOEMName;
	}

/**
Function to set the jump instructions

@internalComponent
@released
*/
void TFATBaseBootSector::SetJumpInstruction()
{
	iJmpBoot[0]= 0xEB;
	iJmpBoot[1]= 0x5A;
	iJmpBoot[2]= 0x90;
}

/**
Function to get the jump instructions

@internalComponent
@released

@return jump boot instruction
*/
unsigned char* TFATBaseBootSector::JumpInstruction()  
{
	return iJmpBoot;
}


/**
Function to set the bytes per sector.  

@internalComponent
@released

@param aDriveSectorSize Sector size in bytes 
*/
void TFATBaseBootSector::SetBytesPerSector(unsigned int aDriveSectorSize)
{
	// Take the default value if SectorSize is not provided by the user. 
	if (aDriveSectorSize != 0)
	{
		unsigned short int acceptableValues[] = {512,1024,2048,4096};
		unsigned short int acceptableValuesCount = 4;
		bool validSectorSize = false;
		for (unsigned int count=0; count<acceptableValuesCount; count++)
		{
			if(aDriveSectorSize == acceptableValues[count])
			{
				validSectorSize = true;
				break;
			}
		}
		// If invalid value for Sector Size is provided, consider the default value.
		if (validSectorSize)
		{
			iBytesPerSector=aDriveSectorSize;
			return;
		}
		else
		{
			cout<<"Warning: Invalid Sector Size value. Default value is considered.\n";
		}
	}
	iBytesPerSector=KDefaultBytesPerSector;	
}

/**
Return the bytes per sector

@internalComponent
@released

@return bytes per sector, hard coded as 512 here.
*/
unsigned int TFATBaseBootSector::BytesPerSector() const
{
	return iBytesPerSector;
}

/**
Sets the number of Fats on the volume

@internalComponent
@released

@param aDriveNoOfFATs Number of fats
*/
void TFATBaseBootSector::SetNumberOfFats(unsigned int aDriveNoOfFATs) 
{
	// Take the default value if No of FATs is not provided by the user. 
	if (aDriveNoOfFATs != 0)
	{
		// If invalid value for No of FATs is provided, generate a warning and take the default value. 
		if ((aDriveNoOfFATs>255) || (aDriveNoOfFATs<1))
		{
			cout<<"Warning: No of FATs should be between 0 and 256. Default value is considered.\n";
			iNumberOfFats= KDefaultNumFats;
			return;
		}
		iNumberOfFats= aDriveNoOfFATs;
	}
	else
	{
		iNumberOfFats= KDefaultNumFats;
	}
}


/**
Total sectors on the volume,This count includes the total count of all sectors 
in all four regions of the volume.iTatalSectors is a 16 bit field and iTotalSectors32
is a 32 bit field.Hence if the total sectors are more than 2^16(0x10000 in hex) 
then iTotalSectors32 is set otherwise it is zero.

@internalComponent
@released

@param aPartitionSize Partition size in bytes
*/
void TFATBaseBootSector::ComputeTotalSectors(Long64 aPartitionSize)
{
	int Log2OfBytesPerSector = Log2(iBytesPerSector);
	unsigned long TotalSectors64 = (unsigned long)(aPartitionSize >> Log2OfBytesPerSector);
	if(TotalSectors64 >= 0x10000)
	{
			iTotalSectors = 0;
			iTotalSectors32 = (unsigned int) TotalSectors64;
	}
	else
	{
			iTotalSectors = (unsigned short)TotalSectors64;
			iTotalSectors32=0;
	}
}

/**
Set the media descriptor,0xF8 is the standard for fixed (non removable) media.

@internalComponent
@released
*/
void TFATBaseBootSector::SetMedia()
{
	iMedia=KBPBMedia;
}

/**
This methods gets the media descriptor

@internalComponent
@released

@return media descriptor
*/
unsigned char TFATBaseBootSector::Media() const
{
	return iMedia;
}

/**
Set the number of hidden sectors in the volume,Count of hidden sector
preceding the partition.

@internalComponent
@released
*/
void TFATBaseBootSector::SetHiddenSectors()
{
	iHiddenSectors=KDefaultHiddenSectors;
}

/**
Gets the number of hidden sectors in the volume

@internalComponent
@released

@return the number of hidden sectors in a given FAT Volume
*/
unsigned int TFATBaseBootSector::HiddenSectors() const
{
	return iHiddenSectors;
}

/**
Set the sectors per track preceding the partition.

@internalComponent
@released
*/
void TFATBaseBootSector::SetSectorsPerTrack()
{
	iSectorsPerTrack=KDefaultSectorsPerTrack;// default value for flash memory
}

/**
Gets the number sectors per track in the volume

@internalComponent
@released

@return the number of sectors per track in a given FAT Volume
*/
unsigned short TFATBaseBootSector::SectorsPerTrack() const
{
	 return iSectorsPerTrack;
}

/**
Set the number of heads

@internalComponent
@released
*/
void TFATBaseBootSector::SetNumberOfHeads()
{
	iNumHeads=KDefaultNumHeads;// default value for flash memory
}

/**
Gets the the number of heads

@internalComponent
@released

@return number of heads in a given FAT Volume
*/
unsigned short TFATBaseBootSector::NumberOfHeads() const
{
	return iNumHeads;// default value for flash memory
}

/**
Set the Physical drive number,not used in Symbian OS

@internalComponent
@released
*/
void TFATBaseBootSector::SetBootSectorDriveNumber()
{
	iPhysicalDriveNumber=KDefaultDriveNumber;
}

/**
Function to return drive number

@internalComponent
@released

@return Physical drive number, not used in Symbian OS
*/
unsigned char TFATBaseBootSector::BootSectorDriveNumber() const
{
	return iPhysicalDriveNumber;
}

/**
Set the reserved byte value

@internalComponent
@released
*/
void TFATBaseBootSector::SetReservedByte()
{
	iReservedByte=KDefaultReservedByte;
}

/**
Get the value of reserved byte in boot sector

@internalComponent
@released

@return Returns the reserved byte value
*/
unsigned char TFATBaseBootSector::ReservedByte() const
{
	return iReservedByte;
}

/**
Set the extended boot signature

@internalComponent
@released

*/
void TFATBaseBootSector::SetBootSignature() 
{
	iBootSign=KDefaultBootSignature;
}

/**
Gets the extended boot signature

@internalComponent
@released

@return boot signature
*/
unsigned char TFATBaseBootSector::BootSignature() const
{
	return iBootSign;
}

/**
Set the unique volume serial number,This ID is usually generated by 
simply combining the current date and time in to 32 bit value.

@internalComponent
@released
*/
void TFATBaseBootSector::SetVolumeId()
{	
	time_t rawtime;
	time(&rawtime);
	iVolumeId=rawtime;
}

/**
Returns the volume id 

@internalComponent
@released

@return volume id field of the boot sector 
*/
unsigned int TFATBaseBootSector::VolumeId() const
{
return iVolumeId ;
}

/**
Set the volume's label

@internalComponent
@released

@param aVolumeLable Data Drive Volume Label
*/
void TFATBaseBootSector::SetVolumeLab(string aVolumeLable)
{
	// Set the default value of VolumeLable(i.e. "NO NAME    ") if not provided
	// by the user.
	if (aVolumeLable.empty())	
	{
		strcpy(reinterpret_cast<char*>(iVolumeLabel),KDefaultVolumeLabel);
	}
	else 
	{
		// If the volume label provided is greater than 11 characters then consider only 
		// the first 11 characters and generate a warning.
		int volumeMaxLangth= 11;
		int volumeLabelSize= aVolumeLable.size();
		if (volumeLabelSize > volumeMaxLangth)
		{
			cout<<"Warning: Size overflow for Data Drive Volume Label. Truncating to 11-bytes.\n";	
			aVolumeLable.resize(volumeMaxLangth);
			strcpy(reinterpret_cast<char*>(iVolumeLabel),aVolumeLable.c_str());
			return;
		}
		
		// If the VolumeLable provided is less than 11-characters then pad the 
		// remaining bytes with white-spaces.		
		if (volumeLabelSize < KMaxVolumeLabel)
		{
			while(volumeLabelSize < 11)
			{
				aVolumeLable.append(" ");
				volumeLabelSize = aVolumeLable.size();
			}	
		}
		strcpy(reinterpret_cast<char*>(iVolumeLabel),aVolumeLable.c_str());
	}
}

/**
returns  the volume's label

@internalComponent
@released

*/
unsigned char* TFATBaseBootSector::VolumeLab() 
{
	return iVolumeLabel;
}

/**
Returns the number of reserved sectors on the volume

@internalComponent
@released

@return iReservedSectors
*/
unsigned short TFATBaseBootSector::ReservedSectors() const
{
	return iReservedSectors;
}

/**
Returns the number of Fats on the volume

@internalComponent
@released

@return iNumberOfFats
*/
unsigned char TFATBaseBootSector::NumberOfFats() const
{
	return iNumberOfFats;
}

/**
Returns the number of entries allowed in the root directory, specific to Fat12/16, zero for FAT32

@internalComponent
@released

@return iRootDirEntries
*/
unsigned short TFATBaseBootSector::RootDirEntries() const
{
	return iRootDirEntries;
}

/**
Returns the total sectors on the volume, 

@internalComponent
@released

@return iTotalSectors 
*/
unsigned int TFATBaseBootSector::TotalSectors(Long64 aPartitionSize) const
{
	if((aPartitionSize/iBytesPerSector)>= 0x10000)	
	return iTotalSectors32;
	else 
	return iTotalSectors;
}

/**
Returns base 2 Logarithm of a number 

@internalComponent
@released

@param aNum number whose logarithm is to be taken
@return log base 2 of the number passed
*/
int TFATBaseBootSector::Log2(int aNum) 
{
	int res=-1;
	while(aNum)
		{
		res++;
		aNum>>=1;
		}
	return(res);
}

/**
Returns the sectors per cluster ratio

@internalComponent
@released

@return iSectorsPerCluster
*/
unsigned char TFATBaseBootSector::SectorsPerCluster() const
{
	return iSectorsPerCluster;
}

/**
Returns the 16 bit count of total sectors on the volume 

@internalComponent
@released

@return iTotalSectors 
*/
unsigned short TFATBaseBootSector::LowSectorsCount() const
{
	return iTotalSectors;
}

/**
Returns the 32 bit count of total sectors on the volume 

@internalComponent
@released

@return iTotalSectors 
*/
unsigned int TFATBaseBootSector::HighSectorsCount() const
{
	return iTotalSectors32;
}

/**
Returns sectors used for the Fat table, zero for FAT32

@internalComponent
@released

@return iFatSectors
*/
unsigned short TFATBaseBootSector::FatSectors() const
{
	return (unsigned short)iFatSectors;
}

/**
Returns sectors used for the Fat table in FAT32

@internalComponent
@released

@return iFatSectors32
*/
unsigned int TFATBaseBootSector::FatSectors32() const
{
	return iFatSectors32;
}
