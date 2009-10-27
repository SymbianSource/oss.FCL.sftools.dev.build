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
* Base file system class for FileSystem component
* @internalComponent
* @released
*
*/


#ifndef FIlESYSTEMCLASS_H
#define FIlESYSTEMCLASS_H

#include "cluster.h"
#include "fat16bootsector.h"
#include "fat32bootsector.h"
#include "filesysteminterface.h"

#include<map>
#include <fstream>



//default root cluster number 
const int KDefaultRootCluster=2;
const int KDefaultSectorSizeinBytes=512;
const int KDefaultRootDirEntrySize=32;



typedef	TClustersPerEntryMap::iterator Iterator;
/**
Class representing base class  of all FAT type 

@internalComponent
@released
*/
class CFileSystem
{
protected:
	//Pointer to dynamically allocated array for containing the boot sector values of a FAT volume
	unsigned char* iData;
	//cluster size in bytes
	unsigned long int iClusterSize;
	//number of sectors occupied by a root directory
	unsigned long iRootDirSectors;	
	//total number of clusters in data segment
	unsigned long int iTotalClusters;
	unsigned int iBytesPerSector;

public:
	//constructor
	CFileSystem();
	// virtual destructor
	virtual ~CFileSystem();
	virtual void CreateBootSector(Long64 aPartitionSize,ConfigurableFatAttributes* aConfigurableFatAttributes)=0 ;
	virtual void WriteBootSector(ofstream& aOutPutStream)=0 ;
	virtual void CreateFatTable(ofstream& aOutPutStream)=0;
	virtual void ComputeClusterSizeInBytes()=0;
	virtual void ComputeRootDirSectors()=0;
	virtual void ComputeTotalClusters(Long64 aPartitionSize)=0;
	virtual void Execute(Long64 aPartitionSize,EntryList aNodeList,ofstream& aOutPutStream,
						ConfigurableFatAttributes* aConfigurableFatAttributes)=0;
	unsigned long int  GetTotalCluster() const;
	unsigned long GetRootDirSectors() const;
	unsigned long int GetClusterSize() const;
	unsigned int GetBytesPerSector() const;
};

#endif //FIlESYSTEMCLASS_H
