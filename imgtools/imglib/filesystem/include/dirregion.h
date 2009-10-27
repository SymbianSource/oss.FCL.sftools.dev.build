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
* CDIRREGION.H
* Directory Region Operations for FileSystem component
* @internalComponent
* @released
*
*/


#ifndef DIRREGION_H
#define DIRREGION_H

#include "filesystemclass.h"
#include "longname.h"

#include <fstream>
#include <map>
#include <string>

class CFileSystem;

typedef std::ofstream OfStream;
typedef std::ifstream IfStream;
typedef std::ios Ios;
typedef std::map<unsigned int,std::string> StringMap;

/**
This class describes the member functions and data members required to create directory/data
region of FAT image.

@internalComponent
@released
*/

class CDirRegion
	{
	private:
		void FormatName(String& aString,char aAttrValue);
		unsigned int Get32BitClusterNumber(unsigned int aHighWord, unsigned int aLowWord);
		void CheckEntry(EntryList aNodeList);
		void CreateDirEntry(CDirectory* aEntry,unsigned int aParentDirClusterNumber);
		void CreateAndWriteCurrentDirEntry(unsigned int aCurClusterNumber,String& aString);
		void CreateAndWriteParentDirEntry(unsigned int aParDirClusterNumber,String& aString);
		void WriteEntryToString(CDirectory* aEntry,String& aString);
		bool IsLongEntry(CDirectory* aEntry) const;
		void CreateLongEntries(CDirectory* aEntry,String& aDirString);
		void WriteFileDataInToCluster(CDirectory* aEntry); 
		void PushStringIntoClusterMap(unsigned int aNumber, 
									  String& aDirString,
									  unsigned long int aClusterSize,
									  char aAttribute);
		void PushDirectoryEntryString(unsigned int aNumber,String& aString,int aClustersRequired);

	public:
		CDirRegion(	EntryList iNodeList,
					CFileSystem *aFileSystemPtr);
		~CDirRegion();
		void Execute();
		void WriteClustersIntoFile(OfStream& aOutPutStream);
		TClustersPerEntryMap* GetClustersPerEntryMap() const;

	private:
		IfStream iInputStream; //Input stream, used to read file contents
		CCluster* iClusterPtr; //pointer to class CCluster
		bool iCurrentDirEntry; //Is current entry(.) is created?
		bool iParentDirEntry;//Is parent entry (..) is created?
		bool iFirstCluster; //Is this the first cluster for the current FAT image?

		unsigned int iCurEntryClusterNumber; //Holds current entries cluster number
		unsigned int iClusterKey; //Number used to map cluster with cluster contents
		/* To avoid calling CCluster::GetClusterSize() function multiple times, this 
		 *variable introduced.
		 */
		unsigned long int iClusterSize;
		
		StringMap iClusterMap; //The map between cluster number and cluster
		unsigned int iRootDirSizeInBytes;//Reserved sectors for root directory entry
		EntryList iNodeList;//To hold root directory entry
	};

#endif //DIRREGION_H
