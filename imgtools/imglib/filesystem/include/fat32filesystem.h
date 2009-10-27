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
* FAT32 file system Class for FileSystem component
* @internalComponent
* @released
*
*/


#ifndef FAT32FILESYSTEM_H
#define FAT32FILESYSTEM_H

#include "filesystemclass.h"
#include "errorhandler.h"
#include "dirregion.h"
#include "filesysteminterface.h"

// constant values to initialize FSInfo data structure
const unsigned int KFSIleadSign=0x41615252;
const unsigned int KFSIStrutSign=0x61417272;
const unsigned int KFSIFreeCount=0xFFFFFFFF;
const unsigned int KFSITrailSign=0xAA550000;

//sector number containing copy of FAT Table and Boot sector
const unsigned int KBootBackupSector=6;
const unsigned int KFatBackupSector=7;

/**
Class representing FSINFO DataStrcuture

@internalComponent
@released
*/
class FSInfo
{

public: 
	void SetFSInfo();
public:
	//lead signature use to validate a FSInfo structure
	unsigned int FSI_LeadSign;
	//field for future expansion
	unsigned char FSI_Reserved[KFSIFutureExpansion];
	//another signature
	unsigned int FSI_StrucSig;
	//contains the last known free cluster count on the  volume
	unsigned int FSI_Free_Count;
	//indicates the cluster number at which the driver should start looking for free clusters
	unsigned int FSI_Nxt_Free;
	//reserved for future expansion
	unsigned int FSI_Reserved2[KFSIKFSIFutureExpansion2];
	//use to validate that this is an fact an FSInfo sector
	unsigned int FSI_TrailSig;

};

// Use to initialize the FSInfo data structure
inline void FSInfo::SetFSInfo()
{
	FSI_LeadSign=KFSIleadSign;
	for(int i=0;i<KFSIFutureExpansion;i++)
		FSI_Reserved[i]=0;
	FSI_StrucSig=KFSIStrutSign;
	FSI_Free_Count=KFSIFreeCount;
	FSI_Nxt_Free=KFSIFreeCount;
	for(int j=0;j<KFSIKFSIFutureExpansion2;j++)
		FSI_Reserved2[j]=0;
	FSI_TrailSig=KFSITrailSign;
}
/**
Class representing concrete class representing FAT32 type 
@internalComponent
@released
*/
class CFat32FileSystem : public CFileSystem
{
public:
	CFat32FileSystem(){};
	~CFat32FileSystem();

public:
	void CreateBootSector(Long64 aPartitionSize,ConfigurableFatAttributes* aConfigurableFatAttributes);
	void WriteBootSector(ofstream& aOutPutStream);
	void CreateFatTable(ofstream& aOutPutStream);
	void CreateFSinfoSector(ofstream& aOutPutStream);
	void RestReservedSectors(ofstream& aOutPutStream);
	void ComputeClusterSizeInBytes();
	void ComputeRootDirSectors();
	void ComputeBytesPerSector();
	void ComputeTotalClusters(Long64 aPartitionSize);
	void Execute(Long64 aPartitionSize,EntryList aNodeList,
				ofstream& aOutPutStream,ConfigurableFatAttributes* aConfigurableFatAttributes);
	void ErrorExceptionClean();

private:
	TFAT32BootSector iFAT32BootSector;
	//use to contain the data structure used to create a FAT Table
	TClustersPerEntryMap* iClustersPerEntry;
	FSInfo iFSInfo; //FSInfo data structure
	//Pointer to dynamic array representing the content of FSInfo data structure
	unsigned char* FSinfoData;
};

#endif //FAT32FILESYSTEM_H
