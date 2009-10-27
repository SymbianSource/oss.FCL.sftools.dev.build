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
* @internalComponent * @released
* Driveimage class implementation.
*
*/


#include <stdlib.h>
#include <string>

#ifndef __LINUX__
	#include <windows.h>
	#include <direct.h>
#else
	#include <dirent.h>
#endif

#ifdef __TOOLS2__
	#include <sys/stat.h>
	#include <sys/types.h>
	using namespace std;
#endif

#include <f32file.h>
#include "h_utl.h"
#include "r_obey.h"
#include "r_romnode.h"
#include "r_rofs.h"
#include "r_driveimage.h"

extern TBool gFastCompress;

// File format supported by Rofsbuild
DriveFileFormatSupported CDriveImage::iFormatType[] =
	{
		{"FAT16",EFAT16},
		{"FAT32",EFAT32},
		{0,EFATINVALID}
	};


/**
File format conversion from char* to coresponding enum value.

@param aUserFileFormat - pointer to user entered file format.
@param aDriveFileFormat - Reference to actual variable.
*/
TBool CDriveImage::FormatTranslation(TText* aUserFileFormat,enum TFileSystem& aDriveFileFormat)
	{
	struct DriveFileFormatSupported* strPointer = iFormatType;
	for( ; (strPointer->iDriveFileFormat) != '\0' ; ++strPointer )
		{
		if(!strcmp((char*)aUserFileFormat,strPointer->iDriveFileFormat))
			{
			aDriveFileFormat = strPointer->iFileSystem;
			return ETrue;
			}
		}	
	return EFalse;
	}


/**
Constructor: CDriveImage class 

@param aObey - pointer to Drive obey file.
*/
CDriveImage::CDriveImage(CObeyFile *aObey)
	: iObey( aObey ),iParentInnerList(0),iListReference(0),iTempDirName(NULL), iData(0)
	{
	}


/**
Destructor: CDriveImage class 

Release the resources allocated in heap.
*/
CDriveImage::~CDriveImage()
	{
	iNodeAddStore.clear();
	iNodeList.clear();
	if(iData)
		delete[] iData;
	if(iTempDirName)
		delete[] iTempDirName;
	}


/**
Creates the STL list to interface with file system module.
Creates the Temp folder for placing the executables
   (those changed,due to user option like compression,un-compression & fileattribute)
Updates the excutable options (file attributes, compression etc)

@return Status - 'KErrNone' - successfully done above operations.
                 'KErrNoMemory' - Not able to allocate the memory.
				 'KErrGeneral' - Unable to done the above operations.
*/
TInt CDriveImage::CreateList()
	{

	TRomNode* pRootDir = iObey->iRootDirectory;
	TInt16 dirCheck = 1;
	TInt retStatus = 0;

	// For Creating the temp folder.	
	iTempDirName = new char[KMaxGenBuffer];
	if(!iTempDirName)
		return KErrNoMemory;

	// Create the temp folder.
	// Check for folder exist, if exist it loops until dir created or loop exit.
	while(dirCheck)
		{
		sprintf(iTempDirName,"%s%05d","temp",dirCheck);
#ifdef __LINUX__
		retStatus = mkdir((char*)iTempDirName,0777);
#else
		retStatus = mkdir((char*)iTempDirName);
#endif
		if(!retStatus)
			break;	

		++dirCheck;
		}

	if(!dirCheck)
		{
		Print(EError,"Unable to Create the temp folder,Check directory settings.\n");
		if(iTempDirName)
			{
			delete[] iTempDirName;
			iTempDirName = 0;
			}
		return KErrCancel;
		}

	// Construct the file options.
	if(ConstructOptions() != KErrNone)
		{
		return KErrGeneral;
		}

	// Construct the List.
	if((GenTreeTraverse(pRootDir,KNodeTypeRoot)) != KErrNone )
		{
		return KErrGeneral;
		}

	return KErrNone;
	}


/**
Creates the Image/Call to file system module.

Updates the required operations to generate the data drive images.
Deletes the temp folder if created.
Calls the file system modules with required parameters.

@param alogfile - Logfile name required for file system module.
@return Status(r) - returns the status of file system module.
                   'KErrGeneral' - Unable to done the above operations properly.
*/
TInt CDriveImage::CreateImage(TText* alogfile)
	{

	TInt retStatus = 0;
	retStatus = CreateList();

	if((retStatus == KErrCancel) || (retStatus == KErrNoMemory))
		return KErrGeneral;

	if(retStatus != KErrNone)
		{
		Print(EError,"Insufficent Memory/Not able to generate the Structure\n");
		if(DeleteTempFolder((char*)iTempDirName) != KErrNone )
			{
			Print(EWarning,"Not able to delete the temp folder : %s",iTempDirName);
			}
		return KErrGeneral;
		}

	// Close log file.
	H.CloseLogFile();		
	
	// Convert fileformat to corresponding enum value.
	enum TFileSystem fileFormat = (TFileSystem)0;
	FormatTranslation(iObey->iDriveFileFormat,fileFormat);

	// Call to file system module. create the image.
	if(iObey->iDataSize)
		retStatus = CFileSystemInterFace::CreateFilesystem(&iNodeList,fileFormat,
														(char*)iObey->iDriveFileName,
														(char*)alogfile,
														iObey->iConfigurableFatAttributes,																											
														iObey->iDataSize); 
	else
		retStatus = CFileSystemInterFace::CreateFilesystem(&iNodeList,fileFormat,
														(char*)iObey->iDriveFileName,
														(char*)alogfile,
														iObey->iConfigurableFatAttributes);														; 

	//delete the temp folder.
	if(DeleteTempFolder((char*)iTempDirName) != KErrNone )
		{
		cout << "Warning: Not able to delete the temp folder : " << iTempDirName << "\n" ;
		}
	
	return 	retStatus;
	}



/**
Delete the temp directory.

@param aTempDirName - Temporory folder name to be deleted.
@return Status(r) - returns the status.
                   'KErrGeneral' - Unable to done the above operations properly.
				   'KErrNone' - successfully deleted the folder.
*/
TInt CDriveImage::DeleteTempFolder(char* aTempDirName)
	{

	TInt fileDeleted = 1;
	std::string dirPath(aTempDirName); 
	std::string fileName(aTempDirName); 

#ifdef __LINUX__

	// Open directory
	DIR *dirHandler = opendir(aTempDirName);
	struct dirent *dirEntry;

	if(!dirHandler)
		return KErrGeneral;

	dirPath.append("/");
	fileName.append("/");

	// Go through each entry
	while(dirEntry = readdir(dirHandler))
		{
		if(dirEntry->d_type != DT_DIR) 
			{
			fileName.append((char*)dirEntry->d_name);
			remove(fileName.c_str());
			fileName.assign(dirPath);
			}
		}
	//Close dir
	if(!closedir(dirHandler))
		{
		fileDeleted = rmdir(aTempDirName);
		}
#else

	WIN32_FIND_DATA FindFileData;
	HANDLE hFind = INVALID_HANDLE_VALUE;

	dirPath.append("\\*");
	fileName.append("\\");
	
	// find the first file
	hFind = FindFirstFile(dirPath.c_str(),&FindFileData);

	if(hFind == INVALID_HANDLE_VALUE) 
		return KErrGeneral;
	
	dirPath.assign(fileName);   

	do
	{
	// Check for directory or file.
	if(!(FindFileData.dwFileAttributes  & FILE_ATTRIBUTE_DIRECTORY))
		{
		// Delete the file.
		fileName.append((char*)FindFileData.cFileName);
		remove(fileName.c_str());
		fileName.assign(dirPath);
		}
	} while(FindNextFile(hFind,&FindFileData));

	FindClose(hFind);
					
	if(ERROR_NO_MORE_FILES != GetLastError())
		{
		cout << "Warning: FindNextFile error. Error is " << GetLastError() << "\n" ;
		}

	fileDeleted = _rmdir(aTempDirName);

#endif

	if(!fileDeleted)
		return KErrNone;
	else
		return KErrGeneral;
	}


/**
General Tree Traverse to create the List.
Recursive call to update the list.

@param anode - Current Node in the tree.
@param anodeType - Node type(root,child,sibling)

@return r - returns 'KErrNoMemory' if fails to generate the list or memory not allocated.
            or 'KErrNone'
*/
TInt CDriveImage::GenTreeTraverse(TRomNode* anode,enum KNodeType anodeType)    
	{
	 
	TInt r =0;			
	if((r = CreateDirOrFileEntry(anode,anodeType)) != KErrNone) 
		return KErrNoMemory;
	 
	if(anode->Currentchild())
		{
		if((r = GenTreeTraverse(anode->Currentchild(),KNodeTypeChild)) != KErrNone)
			return KErrNoMemory;
			
		if(iNodeAddStore.size())	
			iNodeAddStore.pop_back();

		--iListReference;
		}

	if(anode->Currentsibling())
		{
		if((r = GenTreeTraverse(anode->Currentsibling(),KNodeTypeSibling)) != KErrNone)
			return KErrNoMemory;
		}
	return r;
	}


/**
Generate the List. required for drive image creation.
Hidden file node is not placed in list.

@param atempnode - Current Node in the tree.
@param aType - Node type(root,child,sibling)

@return r - returns 'KErrNoMemory' if memory is not allocated or 'KErrNone'
*/
TInt CDriveImage::CreateDirOrFileEntry(TRomNode* atempnode,enum KNodeType aType)    
	{

	CDirectory* iDirectory = new CDirectory((char*)atempnode->iName);
	if(!iDirectory)									
		return KErrNoMemory;
		
	char attrib = 0 ;
	if(atempnode->iAtt & KEntryAttReadOnly)
		attrib |= EAttrReadOnly ;
	if(atempnode->iAtt & KEntryAttHidden)
		attrib |= EAttrHidden ;
	if(atempnode->iAtt & KEntryAttSystem)
		attrib |= EAttrSystem ;
		

	// for files only.
	if(atempnode->iEntry)
		{
		iDirectory->SetEntryAttribute(attrib);

		// don't place the hidden files to list.
		if(!atempnode->iHidden)	
			{
			iDirectory->SetFilePath(atempnode->iEntry->iFileName);
			iDirectory->SetFileSize(atempnode->iSize);
			}
		else
			{
			iNodeAddStore.push_back((void*)iParentInnerList);
			++iListReference;
			return KErrNone;  
			}	
		}
	else
		iDirectory->SetEntryAttribute(attrib | EAttrDirectory);


	switch(aType)
		{
		case KNodeTypeRoot:
			iDirectory->SetEntryAttribute(EAttrVolumeId);
			iNodeList.push_back(iDirectory);	
			iParentInnerList = iDirectory->GetEntryList(); 
			break;
					
		case KNodeTypeChild:
			iNodeAddStore.push_back((void*)iParentInnerList);
			++iListReference;
			iParentInnerList->push_back(iDirectory);
			iParentInnerList = iDirectory->GetEntryList(); 
			break;

		case KNodeTypeSibling:									
			iParentInnerList =(std::list<CDirectory*> *)(iNodeAddStore[iListReference-1]);
			iParentInnerList->push_back(iDirectory);
			iParentInnerList = iDirectory->GetEntryList();
			break;

		default: 
			break;
		}
	return KErrNone;                                             
	}


/**
Traverses all entries and update compress/uncompress and file attribute options.

Place executables in temp folder.(if changed)
Hidden file node is not placed in temp folder.

@return r - returns 'KErrNoMemory/KErrGeneral' if fails to update the options or memory
            not allocated or else 'KErrNone' for Succesfully operation.
*/
TInt CDriveImage::ConstructOptions() 
	{

	TInt32 len = 0;
	TRomNode* node = TRomNode::FirstNode();
        CBytePair bpe(gFastCompress);
	
	while(node)
		{
		// Don't do anything for hidden files.
		if(node->IsFile() && (!node->iHidden))
			{
		
			TInt32 size=HFile::GetLength((TText*)node->iEntry->iFileName);    
			if(size <= 0)
				{
				Print(EWarning,"File %s does not exist or is 0 bytes in length.\n",node->iEntry->iFileName);
				}
			node->iSize = size;
			if(node->iEntry->iExecutable && (size > 0))
				{
				
				if((node->iFileUpdate) || (node->iOverride))
					{
					iData = new char[(size * 2)];
					if(!iData)
						return KErrNoMemory;
					
					HMem::Set(iData, 0xff, (size * 2));
                                        TUint8* aData = (TUint8*)iData;
					len = node->PlaceFile(aData,0,(size * 2),&bpe);
					if(len < KErrNone)
						{	
						delete[] iData;
						iData = 0;
						return KErrGeneral;
						}
						
					// Place the file in Newly created Folder. 
					TInt r = PlaceFileTemporary(len,node);
					delete[] iData;
					iData = 0;

					if(r != KErrNone)
						{
						return r;
						}
					} // file update end.
				}
			} // is file end
		node = node->NextNode();
		}
	return KErrNone;
	}


/**
Place the modified exe's(e32 format) in Temp Folder. 
Place executables in temp folder.(if changed)

@param afileSize    - No. of bytes to be palced in the file.
@param acurrentNode - file node, to modify its source path.

@return r - returns 'KErrNoMemory' if fails to allocate the memory.
            or 'KErrNone'
*/
TInt CDriveImage::PlaceFileTemporary(const TInt afileSize,TRomNode* acurrentNode) 
	{

	TInt randomValue = 0;
	char randomString[KMaxGenBuffer] = "\0";
	unsigned char* fileSourcePath = acurrentNode->iEntry->iName;
	std::string newFileName;

	do
		{
		newFileName.append(iTempDirName);
		newFileName.append("/");

		if(!randomValue)	
			{
			newFileName.append((char*)fileSourcePath);
			}
		else
			{  
			newFileName.append(randomString);
			newFileName.append((char*)fileSourcePath);
			}

#if defined(__MSVCDOTNET__) || defined(__TOOLS2__)
		ifstream test(newFileName.c_str());
#else //!__MSVCDOTNET__
		ifstream test(newFileName.c_str(), ios::nocreate);
#endif //__MSVCDOTNET__

		if (!test)
			{
			test.close();
			ofstream driveFile((char *)newFileName.c_str(),ios::binary);
			if (!driveFile)
				{
				Print(EError,"Cannot open file %s for output\n",newFileName.c_str());
				return KErrGeneral;
				}

			driveFile.write(iData,afileSize);
			driveFile.close();

			// Update the new source path.
			delete[] acurrentNode->iEntry->iFileName;
			acurrentNode->iEntry->iFileName = new char[ strlen(newFileName.c_str()) + 1 ];
			if(!acurrentNode->iEntry->iFileName)
				return KErrNoMemory;
				
			strcpy(acurrentNode->iEntry->iFileName,newFileName.c_str());
			break;
			}

		test.close();
		newFileName.erase();
		++randomValue;
		sprintf(randomString,"%d",randomValue);
	
		}
	while(randomValue);

	return KErrNone;
	}




