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
* FAT32 boot sector Class for FileSystem component
* @internalComponent
* @released
*
*/


#ifndef FAT32BOOTSECTOR_H
#define FAT32BOOTSECTOR_H

#include "fatbasebootsector.h"

/**
Class representing Boot Sector of FAT32 types of fat volume.

@internalComponent
@released
*/
class TFAT32BootSector: public TFATBaseBootSector
{
public:
	TFAT32BootSector();
	~TFAT32BootSector();
	void SetRootDirEntries();
	void SetFileSysType();
	void SetReservedSectors();
	void ComputeSectorsPerCluster(Long64 aPartitionSize);
	void ComputeFatSectors(Long64 aPartitionSize);	
	void SetExtFlags();
	unsigned short ExtFlags();
	void SetFileSystemVersion();
	unsigned short FileSystemVersion();
	void SetRootCluster();
	unsigned int RootCluster();
	void SetFSInfo();
	unsigned short FSInfo();
	void SetBackUpBootSector();
	unsigned short BackUpBootSector();
	void SetFutureReserved();
	unsigned char* FutureReserved();
	unsigned char* FileSysType();

protected:
	unsigned short iExtFlags;
	unsigned short iFileSystemVersion; //revision number
	unsigned int iRootCluster;
	unsigned short iFSInfo; //FSINFo structure sector number
	unsigned short iBackUpBootSector; //Sector area of the reserved area of the volume
	unsigned char iFutureReserved[KMaxSizeFutureExpansion];
};



#endif //FAT32BOOTSECTOR_H
