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
* Constants used by FileSystem component
* @internalComponent
* @released
* This file contains common constants used by FileSystem component
*
*/


#ifndef CONSTANTS_H
#define CONSTANTS_H

/*
 * mingw.inl is included to avoid the below mentioned error throwned by mingw compiler.
 * "stl_construct.h: error: no matching function for call to `operator new(unsigned int, void*)'"
 */
#include "mingw.inl"
#include "utils.h"

//This constant is used to track the FileSystem component version information.
const int KFileSystemMajorVersion = 1;
const int KFileSystemMinorVersion = 1;

#define KDefaultVolumeLabel "NO NAME    "
#define KDefaultOEMName "SYMBIAN "

const int KSectorsPerBootSector = 1;

/* Total number of reserved clusters which is always two as cluster 0 and 1 
 * are never used by data segment for file or directory writing
 */
const int KReservedClusters = 2;

//Offset just after the end of boot sector w.r.t to the start of a FAT Volume
const int KBootSectorOffset = 512;

//size of the first reserved field in FSInfo data structure
const int KFSIFutureExpansion=480;

//size of the second reserved field in FSInfo data structure
const int KFSIKFSIFutureExpansion2=12;

//size of reserved field in FAT32 media
const int KMaxSizeFutureExpansion=12;

//size of volume label in boot sector 
const int KMaxVolumeLabel=11;
const int KBPBMedia =0xF8;
const unsigned short  KDefaultBytesPerSector=512;

// default sector per clusters for FAT16 image
const unsigned char KDefaultSectorsPerCluster=2;

// default sector per clusters for FAT32 image
const unsigned char KDefaultSectorsPerCluster32=1;

//default number of FAT tables
const unsigned char KDefaultNumFats =2;

// default number of root directories entries for FAT32 image
const unsigned short KDefaultRootDirEntries=512;

const unsigned short KFat32RootDirEntries=0;
const unsigned int KSizeOfFatBootSector=512;
const unsigned char  KDefaultReservedByte=0x00;

//size of the string defining the FileSystem type
const unsigned int KFileSysTypeLength=8;
const unsigned int KBootSectorSignature=0xAA55;
const unsigned int KDefaultRootDirClusterNumber=0x0002;
const unsigned char KDefaultDriveNumber=0x80;

//Default extended boot signature to be specified in boot sector
const unsigned char KDefaultBootSignature=0x29;
const unsigned short KDefaultVersion=0;	
const unsigned int KDefaultHiddenSectors= 0;
const unsigned short KDefaultSectorsPerTrack=0;
const unsigned short KDefaultNumHeads=0;

//default value of flags to be specified in FAT32 boot sector
const unsigned short KDefaultExtFlags=0;

//sector number containing the FSInfo data structure in FAT32 volume
const unsigned short KDefaultFSInfoSector=1;

//sector number to be occupied by backup boot sector in FAT32 volume
const unsigned short KDefaultBkUpBootSec=6;
const unsigned short KDefaultFat32ReservedSectors=32;
const unsigned short KDefaultFat16ReservedSectors=1;

//constant used in FAT table entries
const unsigned short EOF16 = 0xffff;
const unsigned short KFat16FirstEntry = 0xfff8;
const unsigned int EOF32 = 0x0fffffff;
const unsigned int KFat32FirstEntry =0x0ffffff8;
const unsigned short KEmptyFATCluster=0;

//minimum and maximum number of FAT32 cluster
const unsigned int KMinimumFat32Clusters= 65525;
/* Since Sector size as taken as 512 bytes(Mostly followed), total clusters supported 
 * by FAT32 is limited to 67092480 otherwise it is 268435456. Here 67092480 clusters 
 * will cover up to 2047.9999GB of user input partition size.
 */
const unsigned int KMaximumFat32Clusters= 67092480; 


//minimum and maximum number of FAT16 cluster
const unsigned int KMinimumFat16Clusters= 4085;
const unsigned int KMaximumFat16Clusters=65524;

//Partition range constants
const Long64 K16MB = 0x1000000;
const Long64 K64MB = 0x4000000;
const Long64 K128MB =0x8000000;
const Long64 K256MB =0x10000000;
const Long64 K260MB =0x10400000;
const Long64 K512MB =0x20000000;
const Long64 K1GB =0x40000000;
const Long64 K2GB =0x80000000;
#ifdef _MSC_VER
	const Long64 K8GB =0x200000000;
	const Long64 K16GB =0x400000000;
	const Long64 K32GB =0x800000000;
#else
	const Long64 K8GB =0x200000000LL;
	const Long64 K16GB =0x400000000LL;
	const Long64 K32GB =0x800000000LL;
#endif

//Bytes per sector selection constants
const short int K1SectorsPerCluster = 0x01;
const short int K2SectorsPerCluster = 0x02;
const short int K4SectorsPerCluster = 0x04;
const short int K8SectorsPerCluster = 0x08;
const short int K16SectorsPerCluster = 0x10;
const short int K32SectorsPerCluster = 0x20;
const short int K64SectorsPerCluster = 0x40;

const int KParentDirClusterNumber = 0x0;
const int KCurrentDirClusterNumber = 0x01;
const short int KFat32RootEntryNumber = 0x02;
const short int KFat16RootEntryNumber = 0x01;
const short int KRootClusterNumber = 0x02;

const short int KDirectoryEntrySize = 0x20;
const short int KZeroFileSize = 0x00;
const short int KEntryNameSize = 0x3c;
const short int KFilePathMaxSize = 0xFF;
const short int KWriteOnce = 0x01;
 
const long int KHighWordMask = 0x0000FFFF;
const short int KBitShift16 = 0x10;
const short int KNTReserverdByte = 0x00;

const short int KPaddingCharCnt = 0x02;

const char KSpace = 0x20;
const char KDot = 0x2E;
const char KTilde = 0x7E;
const char KTildeNumber = 0x31;
const char KCreateTimeInMsecs = 0x00;

const unsigned char KLongNamePaddingChar = 0xFF;
const char KNullPaddingChar = 0x00;

const char KDirSubComponent = 0x00;//Dir sub component constant
const char KLongNameCharSeperator = 0x00;//Long sub component Name characters separated by 0x00


#endif //CONSTANTS_H
