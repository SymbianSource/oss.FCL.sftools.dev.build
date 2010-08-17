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
#ifndef __FAT_DEFINES_HEADER__
#define __FAT_DEFINES_HEADER__
#include <e32std.h>
struct TFATBootSector {
	TUint8 BS_jmpBoot[3];
	TUint8 BS_OEMName[8];
	TUint8 BPB_BytsPerSec[2];
	TUint8 BPB_SecPerClus;
	TUint8 BPB_RsvdSecCnt[2];
	TUint8 BPB_NumFATs;
	TUint8 BPB_RootEntCnt[2];
	TUint8 BPB_TotSec16[2];
	TUint8 BPB_Media;
	TUint8 BPB_FATSz16[2];
	TUint8 BPB_SecPerTrk[2];
	TUint8 BPB_NumHeads[2];
	TUint8 BPB_HiddSec[4];
	TUint8 BPB_TotSec32[4];	
};
struct TFAT32BSExt {
	TUint8 BPB_FATSz32[4];
	TUint8 BPB_ExtFlags[2];
	TUint8 BPB_FSVer[2];
	TUint8 BPB_RootClus[4];
	TUint8 BPB_FSInfo[2];
	TUint8 BPB_BkBootSec[2];
	TUint8 BPB_Reserved[12];
};

struct TFATHeader {
	TUint8 BS_DrvNum ;
	TUint8 BS_Reserved1;
	TUint8 BS_BootSig;
	TUint8 BS_VolID[4];
	TUint8 BS_VolLab[11];
	TUint8 BS_FilSysType[8];
};

struct TFAT32FSInfoSector {
	TUint8 FSI_LeadSig[4];
	TUint8 FSI_Reserved1[480];
	TUint8 FSI_StrucSig[4];
	TUint8 FSI_Free_Count[4];
	TUint8 FSI_Nxt_Free[4];
	TUint8 FSI_Reserved2[12];
	TUint8 FSI_TrailSig[4];
};
struct TShortDirEntry {
    TUint8 DIR_Name[11];
    TUint8 DIR_Attr ;
    TUint8 DIR_NTRes ;
    TUint8 DIR_CrtTimeTenth ;
    TUint8 DIR_CrtTime[2] ;
    TUint8 DIR_CrtDate[2] ;
    TUint8 DIR_LstAccDate[2] ;
    TUint8 DIR_FstClusHI[2] ;
    TUint8 DIR_WrtTime[2] ;
    TUint8 DIR_WrtDate[2];
    TUint8 DIR_FstClusLO[2];
    TUint8 DIR_FileSize[4] ;    
};

struct TLongDirEntry {
    TUint8 LDIR_Ord ;
    TUint8 LDIR_Name1[10] ;
    TUint8 LDIR_Attr ;
    TUint8 LDIR_Type ;
    TUint8 LDIR_Chksum ;
    TUint8 LDIR_Name2[12] ;
    TUint8 LDIR_FstClusLO[2] ; 
    TUint8 LDIR_Name3[4] ;
};
const TUint8 ATTR_READ_ONLY = 0x01 ;
const TUint8 ATTR_HIDDEN = 0x02;
const TUint8 ATTR_SYSTEM = 0x04;
const TUint8 ATTR_VOLUME_ID = 0x08;
const TUint8 ATTR_DIRECTORY = 0x10;
const TUint8 ATTR_ARCHIVE = 0x20;
const TUint8 ATTR_LONG_NAME = ATTR_READ_ONLY | ATTR_HIDDEN | ATTR_SYSTEM | ATTR_VOLUME_ID;

//Time format, should be written as a integer in FAT image
struct FatTime
{
	TUint16 Seconds:5;
	TUint16 Minute:6;
	TUint16 Hour:5;
};

//Date format, should be written as a integer in FAT image
struct FatDate
{
	TUint16 Day:5;
	TUint16 Month:4;
	TUint16 Year:7;
};

//This union convention used to convert bit fields into integer
union TDateInteger
{
	FatDate iCurrentDate;
	TUint16 iImageDate;
};

//This union convention used to convert bit fields into integer
union TTimeInteger
{	
	FatTime iCurrentTime;
	TUint16 iImageTime;
};
struct ConfigurableFatAttributes
{
    char iDriveVolumeLabel[12];
    TInt64 iImageSize ;
    TUint16 iDriveSectorSize;
    TUint32 iDriveClusterSize;
    TUint8 iDriveNoOfFATs;    
    ConfigurableFatAttributes():iImageSize(0),iDriveSectorSize(512),iDriveClusterSize(0),iDriveNoOfFATs(2){
        memcpy(iDriveVolumeLabel,"NO NAME    \0",12);
    }
};
#endif
