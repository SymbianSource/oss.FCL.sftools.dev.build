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
* CFat16FileSystem is the concrete class which is responsible for 
* creating a FAT16 image. This class constitutes the method to 
* create boot sector, FAT Table and data region of a FAT16 Image
* @internalComponent
* @released
*
*/

#include"fat16filesystem.h"


/**
Initializes the boot sector of a FAT 16 volume

@internalComponent
@released

@param aPartitionSize partition size in bytes
@param aConfigurableFatAttributes ConfigurableFatAttributes
*/
void CFat16FileSystem::CreateBootSector(Long64 aPartitionSize,ConfigurableFatAttributes* aConfigurableFatAttributes)
{
 	iFAT16BootSector.SetOEMName();
	unsigned char* OEMName = iFAT16BootSector.OEMName();
	iFAT16BootSector.SetJumpInstruction();
	unsigned char* JmpBoot = iFAT16BootSector.JumpInstruction();
	iFAT16BootSector.SetBytesPerSector(aConfigurableFatAttributes->iDriveSectorSize);
	unsigned short BytesPerSector = (unsigned short)iFAT16BootSector.BytesPerSector();
	iFAT16BootSector.ComputeSectorsPerCluster(aPartitionSize);
	unsigned char SectorsPerCluster = iFAT16BootSector.SectorsPerCluster();
	iFAT16BootSector.SetReservedSectors();
	unsigned short ReservedSectors = iFAT16BootSector.ReservedSectors();
	iFAT16BootSector.SetNumberOfFats(aConfigurableFatAttributes->iDriveNoOfFATs);
	unsigned char NumFats = iFAT16BootSector.NumberOfFats();
	iFAT16BootSector.SetRootDirEntries();
	unsigned short RootDirEntries = iFAT16BootSector.RootDirEntries();
	iFAT16BootSector.ComputeTotalSectors(aPartitionSize);
	unsigned short LowSectors = iFAT16BootSector.LowSectorsCount();
	iFAT16BootSector.SetMedia();
	unsigned char Media = iFAT16BootSector.Media();
	iFAT16BootSector.ComputeFatSectors(aPartitionSize);
	unsigned short FatSectors = iFAT16BootSector.FatSectors();
	iFAT16BootSector.SetSectorsPerTrack();
	unsigned short SectorPerTrack = iFAT16BootSector.SectorsPerTrack();
	iFAT16BootSector.SetNumberOfHeads();
	unsigned short NumberOfHeads = iFAT16BootSector.NumberOfHeads();
	iFAT16BootSector.SetHiddenSectors();
	unsigned int HiddenSectors = iFAT16BootSector.HiddenSectors();
	unsigned int HighSectorsCount = iFAT16BootSector.HighSectorsCount();
	iFAT16BootSector.SetBootSectorDriveNumber();
	unsigned char BootSectorDriveNumber = iFAT16BootSector.BootSectorDriveNumber();
	iFAT16BootSector.SetReservedByte();
	unsigned char ReservedByte = iFAT16BootSector.ReservedByte();
	iFAT16BootSector.SetBootSignature();
	unsigned char BootSignature = iFAT16BootSector.BootSignature();
	iFAT16BootSector.SetVolumeId();
	unsigned int VolumeId = iFAT16BootSector.VolumeId();
	iFAT16BootSector.SetVolumeLab(aConfigurableFatAttributes->iDriveVolumeLabel);
	unsigned char* VolumeLab = iFAT16BootSector.VolumeLab();
	iFAT16BootSector.SetFileSysType();
	unsigned char* FileSysType = iFAT16BootSector.FileSysType();
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
	memcpy(&iData[pos],FileSysType,8);
	pos += 8;
	while(pos < BytesPerSector)
	{
		iData[pos] = 0;
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
	MessageHandler::ReportMessage (INFORMATION,BOOTSECTORCREATEMSG, "FAT16");
}

/**
Writes the boot sector of a FAT 16 volume
@param aOutPutStream handle to file stream	

@internalComponent
@released
*/
void CFat16FileSystem::WriteBootSector(ofstream& aOutPutStream)
{
	MessageHandler::ReportMessage (INFORMATION,BOOTSECTORWRITEMSG,"FAT16");
	aOutPutStream.write(reinterpret_cast<char*>(&iData[0]),iFAT16BootSector.BytesPerSector());
	aOutPutStream.flush();
}
/**
Creates the FAT Table

@internalComponent
@released

@param ofstream
*/
void CFat16FileSystem::CreateFatTable(ofstream& aOutPutStream)
{
	int FATSizeInBytes = (iFAT16BootSector.FatSectors()) * (iFAT16BootSector.BytesPerSector());
	// Each FAT16 entries occupies 2 bytes, hence divided by 2
	unsigned int totalFatEntries = FATSizeInBytes / 2;
	unsigned short *FatTable = new unsigned short[totalFatEntries];
	unsigned short int clusterCounter = 1;
	int previousCluster;
	FatTable[0] = KFat16FirstEntry;
	/**Say cluster 5 starts at 5 and occupies clusters 7 and 9. The FAT table should have the 
	value 7 at	cluster location 5, the value 9 at cluster 7 and 'eof' value at cluster 9.
	Below algorithm serves this algorithm
	*/
	Iterator itr = iClustersPerEntry->begin();
	while(itr != iClustersPerEntry->end())
	{
		previousCluster = itr->second;
		if(iClustersPerEntry->count(itr->first) > 1)
		{
			for(unsigned int i = 1; i < iClustersPerEntry->count(itr->first); i++)
			{
				FatTable[previousCluster] = (unsigned short)(++itr)->second;
				previousCluster = itr->second;
				++clusterCounter;
			}
		}
		FatTable[previousCluster] = EOF16;
		itr++;
		++clusterCounter;
	}
	// Each FAT16 entries occupies 2 bytes, hence multiply by 2
	std::string aFatString(reinterpret_cast<char*>(FatTable),clusterCounter*2);
	delete[] FatTable;
	if(clusterCounter < totalFatEntries)
	{
		// Each FAT16 entries occupies 2 bytes, hence multiply by 2
		aFatString.append((totalFatEntries - clusterCounter)*2, 0);
	}
	MessageHandler::ReportMessage (INFORMATION,FATTABLEWRITEMSG,
								   "FAT16");
	
	// Write FAT table multiple times depending upon the No of FATS set.
	unsigned int noOfFats = iFAT16BootSector.NumberOfFats();
	for(unsigned int i=0; i<noOfFats; i++)
	{
		aOutPutStream.write(aFatString.c_str(),aFatString.length());
	}
	
	aFatString.erase();
	aOutPutStream.flush();
}

/**
set the cluster size in bytes,iClusterSize

@internalComponent
@released
*/
void CFat16FileSystem::ComputeClusterSizeInBytes()
{
	iClusterSize = (iFAT16BootSector.SectorsPerCluster()) * (iFAT16BootSector.BytesPerSector());
}

/**
set the count of sectors occupied by the root directory,iRootDirSectors.

@internalComponent
@released
*/
void CFat16FileSystem::ComputeRootDirSectors()
{
	iRootDirSectors = (iFAT16BootSector.RootDirEntries() * (KDefaultRootDirEntrySize) + 
					  (iFAT16BootSector.BytesPerSector() - 1)) / iFAT16BootSector.BytesPerSector();
}	

/**
Initialize the Bytes per Sector variable value.

@internalComponent
@released
*/
void CFat16FileSystem::ComputeBytesPerSector()
{
	iBytesPerSector = iFAT16BootSector.BytesPerSector();
}


/**
Compute the total number of clusters in Data segment of the FAT volume

@internalComponent
@released
*/
void CFat16FileSystem::ComputeTotalClusters(Long64 aPartitionSize)
{
	unsigned long int iTotalDataSectors = iFAT16BootSector.TotalSectors(aPartitionSize) - 
										  ((iFAT16BootSector.NumberOfFats() * iFAT16BootSector.FatSectors()) + 
										  iRootDirSectors + iFAT16BootSector.ReservedSectors());
	iTotalClusters = iTotalDataSectors / iFAT16BootSector.SectorsPerCluster();
	if(iTotalClusters < KMinimumFat16Clusters)
	{
		throw ErrorHandler(BOOTSECTORERROR,"Low Partition Size",__FILE__,__LINE__);
	}
	if(iTotalClusters > KMaximumFat16Clusters)
	{
		throw ErrorHandler(BOOTSECTORERROR,"High Partition Size",__FILE__,__LINE__);
	}
	
}

/**
This methods encapsulates the function call to write a complete FAT16 Image

@internalComponent
@released

@param aPartitionSize partition size in bytes
@param aNodeList Directory structure 
@param aOutPutStream output stream for writing file image
@param aImageFileName image file name 
@param aLogFileName log file name 
@param aConfigurableFatAttributes ConfigurableFatAttributes
*/

void CFat16FileSystem::Execute(Long64 aPartitionSize,EntryList aNodeList,ofstream& aOutPutStream,
							   ConfigurableFatAttributes* aConfigurableFatAttributes)
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
		CreateFatTable(aOutPutStream);
		dirRegionPtr ->WriteClustersIntoFile(aOutPutStream);
		delete dirRegionPtr ;
	}
	catch(ErrorHandler &aError)
	{
		delete dirRegionPtr;
		//Re throw the same error message
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
		throw ErrorHandler(UNKNOWNERROR, __FILE__, __LINE__);
	}
}
