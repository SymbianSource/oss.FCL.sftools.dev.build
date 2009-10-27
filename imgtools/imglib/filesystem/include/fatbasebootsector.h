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
* FAT base boot sector class for FileSystem component
* @internalComponent
* @released
*
*/


#ifndef FATBPBSECTOR_H
#define FATBPBSECTOR_H

#include "errorhandler.h"
#include <string>
#include <time.h>

using namespace std;

/**
Class representing common fields of Boot Sector of all three fat system volume type.

@internalComponent
@released
*/
class TFATBaseBootSector

{
protected:
	//jump instruction to boot code
	unsigned char iJmpBoot[3];
	unsigned char iOEMName[8] ;
	unsigned short iBytesPerSector;
	unsigned int  iHiddenSectors;
	unsigned char iMedia; //Media Type
	unsigned char iNumberOfFats;
	unsigned short  iNumHeads; //number of heads for interrupt 0x13
	unsigned short  iSectorsPerTrack; //sector per track for interrupt ox13
	unsigned short iTotalSectors; //16 bit total count of sectors on the volume
	unsigned int iTotalSectors32; //32 bit total count of sectors on the volume
	unsigned char iPhysicalDriveNumber;
	unsigned char iReservedByte;
	unsigned char iBootSign; //extended boot signature
	unsigned int  iVolumeId;
	unsigned char iVolumeLabel[KMaxVolumeLabel];
	unsigned short iRootDirEntries;
	unsigned short iReservedSectors;
	unsigned char  iSectorsPerCluster;
	unsigned int  iFatSectors; //count of sectors occupied by FAT in FAT16 volume
	unsigned int  iFatSectors32; //count of sectors occupied by FAT in FAT32 volume
	unsigned char iFileSysType[KFileSysTypeLength];
public:	
	TFATBaseBootSector();
	virtual ~TFATBaseBootSector();
	//Get methods
	unsigned char* JumpInstruction() ;
	unsigned char* OEMName() ;
	unsigned int BytesPerSector() const;
	unsigned int FatSectors32() const;
	unsigned short FatSectors() const;
	unsigned char NumberOfFats() const;
	unsigned short ReservedSectors() const;
	unsigned short RootDirEntries() const;
	unsigned char  SectorsPerCluster() const;
	unsigned int TotalSectors(Long64 aPartitionSize) const;
	unsigned short LowSectorsCount() const;
	unsigned int HighSectorsCount() const;
	unsigned char Media() const;
	unsigned short SectorsPerTrack() const;
	unsigned short NumberOfHeads() const;
	unsigned int HiddenSectors() const;
	unsigned char BootSectorDriveNumber() const;
	unsigned char ReservedByte() const;
	unsigned char BootSignature() const;
	unsigned char* VolumeLab() ;
	unsigned int VolumeId() const;
	//utility functions
	int Log2(int aNum);
	//Set methods
	void SetJumpInstruction();
	void SetOEMName();
	void SetBytesPerSector(unsigned int aDriveSectorSize);
	void SetNumberOfFats(unsigned int aDriveNoOfFATs);
	void ComputeTotalSectors(Long64 aPartitionSize);
	void SetMedia();
	void SetSectorsPerTrack();
	void SetNumberOfHeads();
	void SetHiddenSectors();
	void SetBootSectorDriveNumber();
	void SetReservedByte();
	void SetBootSignature();
	void SetVolumeId();
	void SetVolumeLab(String aVolumeLable);
	//virtual methods
	virtual void SetRootDirEntries()=0;
	virtual void SetFileSysType()=0;
	virtual void SetReservedSectors()=0;
	virtual void ComputeSectorsPerCluster(Long64 aPartitionSize)=0;
	virtual void ComputeFatSectors(Long64 aPartitionSize)=0;	
};

#endif //FATBPBSECTOR_H
