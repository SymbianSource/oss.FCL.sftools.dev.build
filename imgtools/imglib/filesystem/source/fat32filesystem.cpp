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
* CFat32FileSystem is the concrete class which is responsible for 
* creating a FAT32 image. This class constitutes the method to 
* create boot sector, FAT Table and data region of a FAT32 Image
* @internalComponent
* @released
*
*/

#include"fat32filesystem.h"

/**
Initializes the boot sector of a FAT 32 volume

@internalComponent
@released

@param aPartitionSize partition size in bytes
@param aConfigurableFatAttributes ConfigurableFatAttributes
*/
void CFat32FileSystem::CreateBootSector(Long64 aPartitionSize,ConfigurableFatAttributes* aConfigurableFatAttributes)
{
	//initializes the boot sector values
	iFAT32BootSector.SetOEMName();
	unsigned char* OEMName =  iFAT32BootSector.OEMName();
	iFAT32BootSector.SetJumpInstruction();
	unsigned char* JmpBoot = iFAT32BootSector.JumpInstruction();
	iFAT32BootSector.SetBytesPerSector(aConfigurableFatAttributes->iDriveSectorSize);
	unsigned short BytesPerSector = (unsigned short)iFAT32BootSector.BytesPerSector();
	iFAT32BootSector.ComputeSectorsPerCluster(aPartitionSize);
	unsigned char SectorsPerCluster = iFAT32BootSector.SectorsPerCluster();
	iFAT32BootSector.SetReservedSectors();
	unsigned short ReservedSectors =  iFAT32BootSector.ReservedSectors();
	iFAT32BootSector.SetNumberOfFats(aConfigurableFatAttributes->iDriveNoOfFATs);
	unsigned char NumFats = iFAT32BootSector.NumberOfFats();
	iFAT32BootSector.SetRootDirEntries();
	unsigned short RootDirEntries = iFAT32BootSector.RootDirEntries();
	iFAT32BootSector.ComputeTotalSectors(aPartitionSize);
	unsigned short LowSectors = iFAT32BootSector.LowSectorsCount();
	iFAT32BootSector.SetMedia();
	unsigned char Media = iFAT32BootSector.Media();
	iFAT32BootSector.ComputeFatSectors(aPartitionSize);
	unsigned short FatSectors = iFAT32BootSector.FatSectors();
	iFAT32BootSector.SetSectorsPerTrack();
	unsigned short SectorPerTrack = iFAT32BootSector.SectorsPerTrack();
	iFAT32BootSector.SetNumberOfHeads();
	unsigned short NumberOfHeads = iFAT32BootSector.NumberOfHeads();
	iFAT32BootSector.SetHiddenSectors();
	unsigned int HiddenSectors = iFAT32BootSector.HiddenSectors();
	unsigned int HighSectorsCount = iFAT32BootSector.HighSectorsCount();
	unsigned int FatSectors32 = iFAT32BootSector.FatSectors32();
	iFAT32BootSector.SetExtFlags();
	unsigned short ExtFlags = iFAT32BootSector.ExtFlags();
	iFAT32BootSector.SetFileSystemVersion();
	unsigned short FileSystemVersion = iFAT32BootSector.FileSystemVersion();
	iFAT32BootSector.SetRootCluster();
	unsigned int RootCluster =  iFAT32BootSector.RootCluster();
	iFAT32BootSector.SetFSInfo();
	unsigned short FSInfo  = iFAT32BootSector.FSInfo();
	iFAT32BootSector.SetBackUpBootSector();
	unsigned short BackUpBootSector = iFAT32BootSector.BackUpBootSector();
	iFAT32BootSector.SetFutureReserved();
	unsigned char* FutureReserved = iFAT32BootSector.FutureReserved();
	iFAT32BootSector.SetBootSectorDriveNumber();
	unsigned char BootSectorDriveNumber = iFAT32BootSector.BootSectorDriveNumber();
	iFAT32BootSector.SetReservedByte();
	unsigned char ReservedByte = iFAT32BootSector.ReservedByte();
	iFAT32BootSector.SetBootSignature();
	unsigned char BootSignature = iFAT32BootSector.BootSignature();
	iFAT32BootSector.SetVolumeId();
	unsigned int VolumeId = iFAT32BootSector.VolumeId();
	iFAT32BootSector.SetVolumeLab(aConfigurableFatAttributes->iDriveVolumeLabel);
	unsigned char* VolumeLab = iFAT32BootSector.VolumeLab();
	iFAT32BootSector.SetFileSysType();
	unsigned char* FileSystemType = iFAT32BootSector.FileSysType();

	//copying of boot sector values in to the array
	iData = new unsigned char[BytesPerSector];
	unsigned int pos = 0;
	memcpy(&iData[pos],JmpBoot,3);
	pos += 3;
	memcpy(&iData[pos],OEMName,8);
	pos += 8;
	memcpy(&iData[pos],&BytesPerSector,2);
	pos += 2;
	memcpy(&iData[pos],&SectorsPerCluster,1);
	pos += 1;
	memcpy(&iData[pos],&ReservedSectors,2);
	pos += 2;
	memcpy(&iData[pos],&NumFats,1);
	pos += 1;
	memcpy(&iData[pos],&RootDirEntries,2);
	pos += 2;
	memcpy(&iData[pos],&LowSectors,2);
	pos += 2;
	memcpy(&iData[pos],&Media,1);
	pos += 1;
	memcpy(&iData[pos],&FatSectors,2);
	pos += 2;
	memcpy(&iData[pos],&SectorPerTrack,2);
	pos += 2;
	memcpy(&iData[pos],&NumberOfHeads,2);
	pos += 2;
	memcpy(&iData[pos],&HiddenSectors,4);
	pos += 4;
	memcpy(&iData[pos],&HighSectorsCount,4);
	pos += 4;
	memcpy(&iData[pos],&FatSectors32,4);
	pos += 4;
	memcpy(&iData[pos],&ExtFlags,2);
	pos += 2;
	memcpy(&iData[pos],&FileSystemVersion,2);
	pos += 2;
	memcpy(&iData[pos],&RootCluster,4);
	pos += 4;
	memcpy(&iData[pos],&FSInfo,2);
	pos += 2;
	memcpy(&iData[pos],&BackUpBootSector,2);
	pos += 2;
	memcpy(&iData[pos],FutureReserved,12);
	pos += 12;
	memcpy(&iData[pos],&BootSectorDriveNumber,1);
	pos += 1;
	memcpy(&iData[pos],&ReservedByte,1);
	pos += 1;
	memcpy(&iData[pos],&BootSignature,1);
	pos += 1;
	memcpy(&iData[pos],&VolumeId,4);
	pos += 4;
	memcpy(&iData[pos],VolumeLab,11);
	pos += 11;
	memcpy(&iData[pos],FileSystemType,8);
	pos += 8;
	while(pos < BytesPerSector)
	{
		iData[pos] = 0x00;
		pos++;
	}
	// Set sector [510] as 0xAA and [511] as 0x55 to mark the end of boot sector
	iData[KSizeOfFatBootSector-2] = 0x55;
	iData[KSizeOfFatBootSector-1] = 0xAA;
	// It is perfectly ok for the last two bytes of the boot sector to also 
	// have the signature 0xAA55.
	iData[BytesPerSector-2] = 0x55;
	iData[BytesPerSector-1] = 0xAA;
	ComputeClusterSizeInBytes();
	ComputeRootDirSectors();
	ComputeBytesPerSector();
	MessageHandler::ReportMessage (INFORMATION,BOOTSECTORCREATEMSG, "FAT32");
}

/**
Writes the boot sector of a FAT 32 volume

@internalComponent
@released

@param aOutPutStream handle for the image file
*/
void CFat32FileSystem::WriteBootSector(ofstream& aOutPutStream)
{
	MessageHandler::ReportMessage (INFORMATION,BOOTSECTORWRITEMSG, "FAT32");
	aOutPutStream.write(reinterpret_cast<char*>(&iData[0]),iFAT32BootSector.BytesPerSector());
	aOutPutStream.flush();
}

/**
Creates and writes the FAT Table sector of a FAT 32 volume

@internalComponent
@released

@param aClustersPerEntryMap iDatastructure containing the mapping of clusters allocated to the file.
@param aOutPutStream handle for the image file
*/
void CFat32FileSystem::CreateFatTable(ofstream& aOutPutStream)
{
	//data is written from cluster 2
	unsigned int clusterCounter = 2;
	unsigned int FATSizeInBytes = (iFAT32BootSector.FatSectors32()) * (iFAT32BootSector.BytesPerSector());
	// Each FAT32 entries occupies 4 bytes, hence divided by 4
	unsigned int totalFatEntries = FATSizeInBytes / 4;
	//contains the address of FAT Table 	
	unsigned int *FatTable = new unsigned int[totalFatEntries];

	/**Say cluster 5 starts at 5 and occupies clusters 7 and 9. The FAT table should have the 
	value 7 at	cluster location 5, the value 9 at cluster 7 and 'eof' value at cluster 9.
	Below algorithm serves this algorithm
	*/
	int previousCluster;
	FatTable[0] = KFat32FirstEntry;
	FatTable[1] =  EOF32;
	Iterator itr = iClustersPerEntry->begin();
	while(itr !=  iClustersPerEntry->end())
	{
		previousCluster = itr->second;
		if(iClustersPerEntry->count(itr->first) > 1)
		{
			for(unsigned int i = 1; i < iClustersPerEntry->count(itr->first); i++)
			{
				FatTable[previousCluster] = (++itr)->second;
				previousCluster = itr->second;
				++clusterCounter;
			}
		}
		FatTable[previousCluster] = EOF32;
		itr++;
		++clusterCounter;
	}
	// Each FAT32 entries occupies 4 bytes, hence multiply by 4
	std::string aFatString(reinterpret_cast<char*>(FatTable),clusterCounter*4);
	delete[] FatTable;
	if(clusterCounter < totalFatEntries)
	{
		// Each FAT32 entries occupies 4 bytes, hence multiply by 4
		aFatString.append((totalFatEntries - clusterCounter)*4, 0);
	}
	MessageHandler::ReportMessage (INFORMATION,FATTABLEWRITEMSG,
								   "FAT32");
	//Write FAT table multiple times depending on the value of No of FATS set.
	unsigned int noOfFats = iFAT32BootSector.NumberOfFats();
	for(unsigned int i=0; i<noOfFats; i++)
	{
		aOutPutStream.write(aFatString.c_str(),aFatString.length());
	}
	aFatString.erase();
	aOutPutStream.flush();
}

/**
FSINfo iData structure specific to FAT32

@internalComponent
@released

@param aOutPutStream handle for the image file
*/
void CFat32FileSystem::CreateFSinfoSector(ofstream& aOutPutStream)
{
	int counter = 0;
	unsigned int bytesPerSector = iFAT32BootSector.BytesPerSector();
	FSinfoData = new unsigned char[bytesPerSector];
	iFSInfo.SetFSInfo();
	memcpy(&FSinfoData[counter], &iFSInfo.FSI_LeadSign,4);
	counter += 4;
	memcpy(&FSinfoData[counter], &iFSInfo.FSI_Reserved,480);
	counter += 480;
	memcpy(&FSinfoData[counter], &iFSInfo.FSI_StrucSig,4);
	counter += 4;
	memcpy(&FSinfoData[counter], &iFSInfo.FSI_Free_Count,4);
	counter += 4;
	memcpy(&FSinfoData[counter], &iFSInfo.FSI_Nxt_Free,4);
	counter += 4;
	memcpy(&FSinfoData[counter], &iFSInfo.FSI_Reserved2,12);
	counter += 12;
	memcpy(&FSinfoData[counter], &iFSInfo.FSI_TrailSig,4);
	counter += 4;
	counter += (bytesPerSector-KSizeOfFatBootSector);
	aOutPutStream.write(reinterpret_cast<char*>(&FSinfoData[0]),counter);
	aOutPutStream.flush();	
}

/**
 Initializes the left over reserved sectors of FAT32 image other than boot sector and FSinfo iData sector(sector 0 and 1)

 @internalComponent
 @released

 @param aOutPutStream handle to file stream		
*/
void CFat32FileSystem::RestReservedSectors(ofstream& aOutPutStream)
{
	unsigned int bytesPerSector = iFAT32BootSector.BytesPerSector();
	unsigned char* nullsector = new unsigned char[bytesPerSector];
	for(unsigned int counter = 0; counter < bytesPerSector ; counter++)
	{
		nullsector[counter] = 0;
	}
	nullsector[KSizeOfFatBootSector-2] = 0x55;
	nullsector[KSizeOfFatBootSector-1] = 0xAA;
	for(unsigned int sectorcount = 2; sectorcount < (unsigned int)(iFAT32BootSector.ReservedSectors()) - 1; sectorcount++)
	{
		// Sector no 6 and 7 contains the duplicate copy of boot sector and FSInfo sector in a FAT32 Image
		if(sectorcount == KBootBackupSector)
		{
			aOutPutStream.write(reinterpret_cast<char*>(&iData[0]),bytesPerSector);		
			aOutPutStream.flush();
		}
		if(sectorcount == KFatBackupSector)
		{
			aOutPutStream.write(reinterpret_cast<char*>(&FSinfoData[0]),bytesPerSector);		
			aOutPutStream.flush();
		}
		else
		{
			aOutPutStream.write(reinterpret_cast<char*>(&nullsector[0]),bytesPerSector);		
			aOutPutStream.flush();
		}
	}
	delete[] nullsector;
	nullsector = NULL;
}

/**
compute the cluster size in bytes,iClusterSize

@internalComponent
@released
*/
void CFat32FileSystem::ComputeClusterSizeInBytes()
{
	iClusterSize = iFAT32BootSector.SectorsPerCluster()*iFAT32BootSector.BytesPerSector();
}

/**
Compute the count of sectors occupied by the root directory,iRootDirSectors.

@internalComponent
@released
*/
void CFat32FileSystem::ComputeRootDirSectors()
{
	iRootDirSectors = (iFAT32BootSector.RootDirEntries() * (KDefaultRootDirEntrySize) + 
		              (iFAT32BootSector.BytesPerSector() - 1)) / iFAT32BootSector.BytesPerSector();
}

/*
Initialize the Bytes per Sector variable value.

@internalComponent
@released
*/
void CFat32FileSystem::ComputeBytesPerSector()
{
	iBytesPerSector = iFAT32BootSector.BytesPerSector();
}

/*
Sets the total number of clusters in iData segment of the FAT volume


@internalComponent
@released

@aPartitionSize partition size in bytes
*/
void CFat32FileSystem::ComputeTotalClusters(Long64 aPartitionSize)
{
	unsigned int totalDataSectors = iFAT32BootSector.TotalSectors(aPartitionSize) - 
									((iFAT32BootSector.NumberOfFats() * 
									iFAT32BootSector.FatSectors32()) + 
									iRootDirSectors+iFAT32BootSector.ReservedSectors());

 	iTotalClusters = totalDataSectors / iFAT32BootSector.SectorsPerCluster();
	if(iTotalClusters < KMinimumFat32Clusters)
	{
		throw ErrorHandler(BOOTSECTORERROR,"Low Partition Size",__FILE__, __LINE__);
	}
	else if(iTotalClusters > KMaximumFat32Clusters)
	{
		throw ErrorHandler(BOOTSECTORERROR,"high Partition Size",__FILE__, __LINE__);
	}
}
/**
This methods encapsulates the function call to write a complete FAT32 Image

@internalComponent
@released

@param aPartitionSize partition size in bytes
@param aNodeList Directory structure 
@param aOutPutStream output stream for writing file image
@param aImageFileName image file name 
@param aLogFileName log file name 
@param aConfigurableFatAttributes ConfigurableFatAttributes
*/

void CFat32FileSystem::Execute(Long64 aPartitionSize,EntryList aNodeList,
							   ofstream& aOutPutStream,ConfigurableFatAttributes* aConfigurableFatAttributes)
{
	CDirRegion* dirRegionPtr = NULL;
	try
	{
		CreateBootSector(aPartitionSize,aConfigurableFatAttributes);
		ComputeTotalClusters(aPartitionSize);
		WriteBootSector(aOutPutStream);
		dirRegionPtr = new CDirRegion(aNodeList,this);
		dirRegionPtr->Execute();
		iClustersPerEntry = dirRegionPtr->GetClustersPerEntryMap();
		CreateFSinfoSector(aOutPutStream);
		RestReservedSectors(aOutPutStream);
		CreateFatTable(aOutPutStream);
		dirRegionPtr->WriteClustersIntoFile(aOutPutStream);
		delete dirRegionPtr;
		dirRegionPtr = NULL;
	}
	catch(ErrorHandler &aError)
	{
		delete dirRegionPtr;
		dirRegionPtr = NULL;
		throw ErrorHandler(aError.iMessageIndex,(char*)aError.iSubMessage.c_str(),(char*)aError.iFileName.c_str(),aError.iLineNumber);
	}
	/**
	Irrespective of successful or unsuccessful data drive image generation ROFSBUILD
	may try to generate images for successive ".oby" file input.
	During this course unhandled exceptions may cause leaving some memory on heap 
	unused. so the unhandled exceptions handling is used to free the memory allocated 
	on heap. 
	*/
	catch(...)
	{
		delete dirRegionPtr;
		dirRegionPtr = NULL;
		throw ErrorHandler(UNKNOWNERROR, __FILE__, __LINE__);
	}
}

/**
Destructor of class CFat32FileSystem

@internalComponent
@released
*/
CFat32FileSystem::~CFat32FileSystem()
{
	delete[] FSinfoData;
};
