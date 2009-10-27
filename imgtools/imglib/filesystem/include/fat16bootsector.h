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
* FAT16 boot sector Class for FileSystem component
* @internalComponent
* @released
*
*/


#ifndef FAT16BOOTSECTOR_H
#define FAT16BOOTSECTOR_H

#include "fatbasebootsector.h"

/**
Class representing Boot Sector of FAT16 types of fat volume.

@internalComponent
@released
*/
class TFAT16BootSector : public TFATBaseBootSector
{

public:
	TFAT16BootSector();
	~TFAT16BootSector();
	unsigned char* FileSysType();
	void SetFileSysType();
	void SetRootDirEntries();
	void SetReservedSectors();
	void ComputeSectorsPerCluster(Long64 aPartitionSize);
	void ComputeFatSectors(Long64 aPartitionSize);
};

#endif //FAT16BOOTSECTOR_H

