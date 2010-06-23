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
* Class receives tree structured directory and file information. And 
* prepares the cluster versus content MAP by traversing through the same. 
* Later all the prepared clusters are written into image file.
* @internalComponent
* @released
*
*/


#include "dirregion.h"
#include "directory.h"
/**
Constructor:
1.Get the instance of class CCluster
2.Intializes the Cluster pointer
3.Intialize the flags and other variables

@internalComponent
@released

@param aNodeList - Root node placed in this list
@param aFileSystemPtr - CFileSystem class pointer
*/
CDirRegion::CDirRegion(EntryList aNodeList,
					   CFileSystem * aFileSystemPtr):
					   iCurrentDirEntry(false),
					   iParentDirEntry(false),
					   iFirstCluster(true),
   					   iNodeList(aNodeList)
{
	iClusterSize = aFileSystemPtr->GetClusterSize();
	iRootDirSizeInBytes = (aFileSystemPtr->GetRootDirSectors () * 
						   aFileSystemPtr->GetBytesPerSector());
	int totalClusters = aFileSystemPtr->GetTotalCluster();
	iClusterPtr = CCluster::Instance(iClusterSize,totalClusters);
	if(iClusterPtr == NULL)
	{
		throw ErrorHandler(CLUSTERERROR,"Instance creation error", __FILE__, __LINE__);
	}
	iClusterSize = iClusterPtr->GetClusterSize();
}

/**
Destructor: 
1. Clean the Node List 
2. Clean the instance of Cluster object 
3. Clean the Cluster MAP.
4. Invokes the DestroyShortEntryList to clear the contents of static GShortEntryList.

@internalComponent
@released
*/
CDirRegion::~CDirRegion()
{
	if(iNodeList.size() > 0)
	{
		//Delete the root node
		delete iNodeList.front();
	}
	if(iClusterPtr != NULL)
	{
		delete iClusterPtr;
		iClusterPtr = NULL;
	}
	iClusterMap.clear();
	ClongName::DestroyShortEntryList();
}

/**
Function to return Clusters per entry map(input for FAT table generator function) 
container

@internalComponent
@released

@return - returns clusters per entry map container
*/
TClustersPerEntryMap* CDirRegion::GetClustersPerEntryMap() const
{
	return iClusterPtr->GetClustersPerEntryMap();
}

/**
Function responsible to write all the clusters available in iClusterMap
into file. 

@internalComponent
@released

@param aOutPutStream - output file stream to write clusters in it
*/
void CDirRegion::WriteClustersIntoFile(OfStream& aOutPutStream)
{
	StringMap::iterator mapBeginIter = iClusterMap.begin();
	StringMap::iterator mapEndIter= iClusterMap.end();
	//MAPs are sorted associative containers, so no need to sort
	string tempString;
	while(mapBeginIter != mapEndIter)
	{
		tempString = (*mapBeginIter++).second;
		aOutPutStream.write(tempString.c_str(),tempString.length());
	}
	aOutPutStream.flush();
	if(aOutPutStream.bad())
	{
		throw ErrorHandler(FILEWRITEERROR, __FILE__, __LINE__);
	}
}

/**
Function responsible to 
1. Read the file content and write into string.
2. Invoke the function to push data clusters into cluster Map

@internalComponent
@released

@param aEntry - the directory entry node
*/
void CDirRegion::WriteFileDataInToCluster(CDirectory* aEntry)
{
	iInputStream.open(aEntry->GetFilePath().c_str(),ios_base::binary);
	if(iInputStream.fail() == true )
	{
		throw ErrorHandler(FILEOPENERROR,(char*)aEntry->GetFilePath().c_str(),__FILE__,__LINE__);
	}
	else
	{
		iInputStream.seekg (0,ios_base::end);
		Long64 fileSize = iInputStream.tellg(); 
		iInputStream.seekg(0,ios_base::beg);
		char* dataBuffer = (char*)malloc((unsigned int)fileSize);
		if(dataBuffer == 0)
		{
			throw ErrorHandler(MEMORYALLOCATIONERROR, __FILE__, __LINE__);
		}
		//Read the whole file in one short
		iInputStream.read (dataBuffer,fileSize);
		
		Long64 bytesRead = (unsigned int)iInputStream.tellg();
		if((iInputStream.bad()) || (bytesRead != fileSize))
		{
			throw ErrorHandler(FILEREADERROR,(char*)aEntry->GetFilePath().c_str(), __FILE__, __LINE__);
		}
		string clusterData(dataBuffer,(unsigned int)bytesRead);
		PushStringIntoClusterMap(iClusterPtr->GetCurrentClusterNumber(),clusterData,iClusterSize,aEntry->GetEntryAttribute());
	}
	iInputStream.close();
}


/**
Function invokes 
1. CheckEntry function, to identify whether the received entry list is proper or not.
2. Invokes CreateDirEntry, to create directory and data portion of FAT image.

@internalComponent
@released
  
*/
void CDirRegion::Execute()
{
	CheckEntry(iNodeList);
	CreateDirEntry(iNodeList.front(),KParentDirClusterNumber);
}

/**
Function is to initialize the Parent directory entry with parent cluster number
and appends all the attributes into the string (aString).

@internalComponent
@released

@param aParDirClusterNumber - parent directory cluster number
@param aString - parent directory entry attributes appended to this string
*/
void CDirRegion::CreateAndWriteParentDirEntry(unsigned int aParDirClusterNumber,string& aString)
{
	CDirectory* parentDirectory = new CDirectory("..",NULL);

	parentDirectory->SetEntryAttribute(EAttrDirectory);
	parentDirectory->SetClusterNumberLow((unsigned short) (aParDirClusterNumber & KHighWordMask));
	parentDirectory->SetClusterNumberHi((unsigned short) (aParDirClusterNumber >> KBitShift16));

	TShortDirEntry entry ;
	parentDirectory->GetShortEntry(entry);
	aString.append((const char*)(&entry),sizeof(entry));
	iParentDirEntry = true;
	delete parentDirectory;
	parentDirectory = NULL;
}

/**
Function responsible to 
1. Initialize the Current directory entry attribute
2. Write the entry attributes into received string

@internalComponent
@released

@param aCurDirClusterNumber - Current directory Cluster number
@param aString - the entry attributes should be appended to this string
*/
void CDirRegion::CreateAndWriteCurrentDirEntry(unsigned int aCurClusterNumber,string& aString)
{
	iCurEntryClusterNumber = aCurClusterNumber;
	CDirectory* currentDirectory = new CDirectory(".",NULL);

	currentDirectory->SetEntryAttribute(EAttrDirectory);
	currentDirectory->SetClusterNumberLow((unsigned short) (iCurEntryClusterNumber & KHighWordMask));
	currentDirectory->SetClusterNumberHi((unsigned short) (iCurEntryClusterNumber >> KBitShift16));

	TShortDirEntry entry ;
    currentDirectory->GetShortEntry(entry);
    aString.append((const char*)(&entry),sizeof(entry));
	iCurrentDirEntry = true;
	delete currentDirectory;
	currentDirectory = NULL;
}

/**
Function responsible to push the directory entry clusters into cluster MAP only if the
directory entry string size is greater than the cluster size.

@internalComponent
@released

@param aNumber - is the Cluster Key used to insert the cluster into cluster map
@param aString - is the directory entry string
@param aClustersRequired - No of clusters required to hold this string
*/

void CDirRegion::PushDirectoryEntryString(unsigned int aNumber,string& aString,int aClustersRequired)
{
	int clusterCount = 0;
	int clusterKey = aNumber;
	iClusterPtr->CreateMap(aNumber,clusterKey);
	iClusterMap[clusterKey] =	aString.substr(clusterCount*iClusterSize,iClusterSize);
	++clusterCount;
	string clusterSizeString;
	for(; clusterCount < aClustersRequired; ++clusterCount)
	{
		clusterKey = iClusterPtr->GetCurrentClusterNumber();
		clusterSizeString = aString.substr(clusterCount*iClusterSize,iClusterSize);
		clusterSizeString.append((iClusterSize - clusterSizeString.length()),0);
		iClusterMap[clusterKey] = clusterSizeString;
		iClusterPtr->CreateMap(aNumber,clusterKey);
		iClusterPtr->UpdateNextAvailableClusterNumber();
	}
}

/**Function responsible to 
1. Convert the string into equal size clusters of cluster size
2. Insert the clusters into Cluster MAP

@internalComponent
@released

@param aNumber - cluster number, used to map the cluster
@param aString - reference of input string
@param aClusterSize - used to split the string
@param aAttribute - current entry attribute
*/
void CDirRegion::PushStringIntoClusterMap(unsigned int aNumber, string& aString, unsigned long int aClusterSize,char aAttribute)
{
	int receivedStringLength = aString.length();
	/* Precaution, once the map is initialized with specific cluster number don't over write
	 * it once again. Look for the cluster number within the existing MAP and then proceed with 
	 * filling in the cluster.
	 */
	StringMap::iterator iter= iClusterMap.find(aNumber);
	if(iter == iClusterMap.end())
	{
		/* The length of the cluster content (aString) can be more or less than the cluster size, 
		 * hence, calculate the total number of clusters required.
		 */
		int clustersRequired = receivedStringLength / aClusterSize;
		if((receivedStringLength % aClusterSize) > 0)
		{
			++clustersRequired;
		}
		if((clustersRequired > 1) && (aAttribute == EAttrDirectory))
		{
			PushDirectoryEntryString(aNumber,aString,clustersRequired);
			return;
		}
		int updatedClusterNumber = aNumber;
		string clusterSizeString;
		for(short int clusterCount = 0; clusterCount < clustersRequired; ++clusterCount)
		{
			/* In case of the contents occupying more than one cluster, break the contents into
			 * multiple parts, each one measuring as that of the cluster size.
			 */
			clusterSizeString = aString.substr(clusterCount * aClusterSize,aClusterSize);
			iClusterPtr->CreateMap(aNumber,updatedClusterNumber);
			if(clusterSizeString.length() < aClusterSize)
			{
				/* Copied string size is less than cluster size, fill the remaining space
				 * with zero
				 */
				clusterSizeString.append((aClusterSize - clusterSizeString.length()),0);
			}
			// Insert the string into ClusterMap	
			iClusterMap[updatedClusterNumber] = clusterSizeString;
		
			iClusterPtr->UpdateNextAvailableClusterNumber();
			updatedClusterNumber = iClusterPtr->GetCurrentClusterNumber ();
		}
		/* In the above loop, cluster number is incremented to point to the next entry.
		 * However, before writing a directory or a volume id entry, it is always ensured 
		 * to get the next cluster number. Hence in this case, it is required to decrement
		 * the cluster number, so that the pointer points to the end of the cluster occupied.
		 */
		if(aAttribute == EAttrDirectory || aAttribute == EAttrVolumeId)
		{
			iClusterPtr->DecrementCurrentClusterNumber ();
		}
	}
}

/**
Function is responsible to take in the tree structured directory 
information and to initialize the starting cluster in the Cluster Map.

@internalComponent
@released

@param aNodeList - the list which holds root entry
*/
void CDirRegion::CheckEntry(EntryList aNodeList)
{
	if(aNodeList.size() > 0)
	{
		if(iRootDirSizeInBytes > 0)
		{
			//FAT16 Root entries are written into Cluster 1
			iClusterKey = KFat16RootEntryNumber;
		}
		else
		{
			//FAT32 Root entries are written into Cluster 2			
			iClusterPtr->UpdateNextAvailableClusterNumber();
			iClusterKey = KFat32RootEntryNumber; 
		}
		if(aNodeList.front()->GetEntryList()->size() <= 0)
		{
			throw ErrorHandler(NOENTRIESFOUND, __FILE__, __LINE__);
		}
	}
	else
	{
		throw ErrorHandler(ROOTNOTFOUND, __FILE__, __LINE__);
	}
}

/**
Function receives Tree structured folder information and does the following:
1. Generates Directory Entry portion of FAT image recursively.
2. If it finds the entry as file then writes its contents.
3. If the entry is long name then longfilename class invoked to create long entries.

@internalComponent
@released

@param aEntry  - Subdirectory pointer of root directory
@param aParentDirClusterNumber - parent directory cluster number
*/
void CDirRegion::CreateDirEntry(CDirectory* aEntry,unsigned int aParentDirClusterNumber)
{
	unsigned int currentDirClusterNumber = 0;
	int rootClusterSize = 0;
	if(iFirstCluster == true)
	{
			iCurrentDirEntry = true;
			iParentDirEntry = true;
			/**Root directory and Normal directory has one difference.
			FAT16 : Root cluster occupies 32 sectors
			FAT32 : Root cluster occupies only one cluster
			*/
			rootClusterSize = (iRootDirSizeInBytes > 0)?iRootDirSizeInBytes:iClusterSize; 
	}
	else
	{
		currentDirClusterNumber = Get32BitClusterNumber(aEntry->GetClusterNumberHi(),
														aEntry->GetClusterNumberLow());
	}
	
	//printIterator used while printing the entries
	EntryList::iterator printIterator = aEntry->GetEntryList()->begin(); 
	//traverseIterator used during recursive call
	EntryList::iterator traverseIterator = printIterator;
	
	unsigned int dirEntryCount = aEntry->GetEntryList()->size();

	string dirString;
	string nameString;
	CDirectory* tempDirEntry = (*printIterator);
	list<TLongDirEntry> longNames ; 
	//Writes all the Directory entries available in one Directory entry
	while(dirEntryCount > 0)
	{
		tempDirEntry = (*printIterator);
		
		tempDirEntry->SetClusterNumberHi(iClusterPtr->GetHighWordClusterNumber());
		tempDirEntry->SetClusterNumberLow(iClusterPtr->GetLowWordClusterNumber());

		/* Every directory should have current and parent directory entries in its
		 * respective cluster. Hence Create the current and parent directory entries 
		 * only if it is not created already.
		 */
		if(!iCurrentDirEntry && !iParentDirEntry)
		{
			CreateAndWriteCurrentDirEntry(currentDirClusterNumber,dirString);
			iClusterKey = currentDirClusterNumber;
			CreateAndWriteParentDirEntry(aParentDirClusterNumber,dirString);
		}
		MessageHandler::ReportMessage(INFORMATION,
									  ENTRYCREATEMSG,
									  (char*)tempDirEntry->GetEntryName().c_str()); 
									  
		if(tempDirEntry->GetLongEntries(longNames)){ 
			list<TLongDirEntry>::const_iterator i = longNames.begin();
			while(i != longNames.end()) {
				dirString.append((char*)(&(*i)),sizeof(TLongDirEntry)); 
				i++ ;
			} 
		}
		TShortDirEntry shortEntry ;
		tempDirEntry->GetShortEntry(shortEntry);	 
		dirString.append((char*)(&shortEntry),sizeof(TShortDirEntry));		 
		if(tempDirEntry->IsFile())
		{
			WriteFileDataInToCluster(tempDirEntry);
		}
		else
		{
			iClusterPtr->UpdateNextAvailableClusterNumber ();
			//tempDirEntry->SetEntryAttribute(tempDirEntry->GetEntryAttribute() | EAttrDirectory);
		}
		++printIterator;
		--dirEntryCount;
	}

	iCurrentDirEntry = false;
	iParentDirEntry = false;
	aParentDirClusterNumber = currentDirClusterNumber;
	if(iFirstCluster == true)
	{
		PushStringIntoClusterMap(iClusterKey,dirString,rootClusterSize,aEntry->GetEntryAttribute());
		iFirstCluster = false;
	}
	else
	{
		PushStringIntoClusterMap(iClusterKey,dirString,iClusterSize,aEntry->GetEntryAttribute());
	}

	dirEntryCount = aEntry->GetEntryList()->size();

	//Recursive algorithm to print all entries
	while(dirEntryCount > 0)
	{
		if(aEntry->GetEntryList()->size() > 0)
		{		
			CreateDirEntry((*traverseIterator),aParentDirClusterNumber);
		}
		--dirEntryCount;
		//if no entries found don't go deep
		if(dirEntryCount > 0)
		{
			aEntry = (*++traverseIterator);
		}
	}
}

/**
Function responsible to convert two 16 bit words into single 32 bit integer

@internalComponent
@released

@param aHighWord - 16 bit high word
@param aLowWord - 16 bit low word
@return returns the 32 bit integer
*/
unsigned int CDirRegion::Get32BitClusterNumber(unsigned int aHighWord, unsigned int aLowWord)
{
	unsigned int clusterNumber = aHighWord;
	clusterNumber <<= KBitShift16;
	clusterNumber |= aLowWord;
	return clusterNumber;
}
