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
* FAT16 file system Class for FileSystem component
* @internalComponent
* @released
*
*/


#ifndef FAT16FILESYSTEM_H
#define FAT16FILESYSTEM_H

#include "filesystemclass.h"
#include "errorhandler.h"
#include "dirregion.h"
#include"filesysteminterface.h"

/**
Class representing concrete class representing FAT16 type 

@internalComponent
@released
*/

class CFat16FileSystem : public CFileSystem
{
private:
	TFAT16BootSector iFAT16BootSector;
	//use to contain the data structure used to create a FAT Table
	TClustersPerEntryMap* iClustersPerEntry;

public:
	CFat16FileSystem (){};
	~CFat16FileSystem(){};
	void CreateBootSector(Long64 aPartitionSize,ConfigurableFatAttributes* aConfigurableFatAttributes);
	void WriteBootSector(ofstream& aOutPutStream);
	void CreateFatTable(ofstream& aOutPutStream);
	void ComputeClusterSizeInBytes();
	void ComputeRootDirSectors();
	void ComputeBytesPerSector();
	void ComputeTotalClusters(Long64 aPartitionSize);
	void Execute(Long64 aPartitionSize,EntryList aNodeList,
				 ofstream& aOutPutStream,ConfigurableFatAttributes* aConfigurableFatAttributes);
	void ErrorExceptionClean();
};
#endif //FAT16FILESYSTEM_H
