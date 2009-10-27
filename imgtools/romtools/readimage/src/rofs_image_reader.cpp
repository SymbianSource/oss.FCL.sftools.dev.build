/*
* Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* @internalComponent 
* @released
*
*/

#include "common.h"
#include "r_obey.h"
#include "rofs_image_reader.h"
#include "e32_image_reader.h"

RofsImage::RofsImage(RCoreImageReader *aReader) : CCoreImage(aReader) ,
iRofsHeader(0), iRofsExtnHeader(0),iAdjustment(0),  iImageType(RCoreImageReader::E_UNKNOWN)
{
}

RofsImageReader::RofsImageReader(char* aFile) : ImageReader(aFile), iInputFile(0)
{
	iImageReader = new RCoreImageReader(aFile);
	iImage = new RofsImage(iImageReader);
}

RofsImageReader::~RofsImageReader()
{
	if(iInputFile)
		iInputFile->close();
	delete iInputFile;
	delete iImage;
	delete iImageReader;
}

void RofsImageReader::SetSeek(streampos aOff, ios::seek_dir aStartPos)
{
	if(!iInputFile)
		return;

	iInputFile->seekg(aOff, aStartPos);
}

void RofsImageReader::ReadImage()
{
	if(!iImageReader->Open())
	{
		throw ImageReaderException((char*)(iImageReader->Filename()), "Failed to open Image File");
	}
}

void RofsImageReader::Validate()
{
}

TInt RofsImage::ProcessImage()
{
	int result = CreateRootDir();
	if (result == KErrNone)
	{
		if (iReader->Open())
		{
			iImageType = iReader->ReadImageType();
			if (iImageType == RCoreImageReader::E_ROFS)
			{
				iRofsHeader = new TRofsHeader;
				result = iReader->ReadCoreHeader(*iRofsHeader);
				if (result != KErrNone)
					return result;
				
				SaveDirInfo(*iRofsHeader);
				result = ProcessDirectory(0);
			}
#if defined(__TOOLS2__) || defined(__MSVCDOTNET__)
			else if (iImageType == RCoreImageReader::E_ROFX)
#else
			else if (iImageType == RCoreImageReader::TImageType::E_ROFX)
#endif
			{
				iRofsExtnHeader = new TExtensionRofsHeader ;
				result = iReader->ReadExtensionHeader(*iRofsExtnHeader);
				if(result != KErrNone)
					return result;

				long filePos = iReader->FilePosition();
				iAdjustment = iRofsExtnHeader->iDirTreeOffset - filePos;

				SaveDirInfo(*iRofsExtnHeader);
				result = ProcessDirectory(iAdjustment);
			}
			else
			{
				result = KErrNotSupported;
			}
		}
		else
		{
			result = KErrGeneral;
		}
	}

	return result;
}

void RofsImageReader::ProcessImage()
{
	iImage->ProcessImage();
	iRootDirEntry = iImage->RootDirectory();
}

void RofsImageReader::Dump()
{
	if( !((iDisplayOptions & EXTRACT_FILES_FLAG) || (iDisplayOptions & LOG_IMAGE_CONTENTS_FLAG) ||
		(iDisplayOptions & EXTRACT_FILE_SET_FLAG)) )
	{
		
		MarkNodes();
		if(iDisplayOptions & DUMP_HDR_FLAG)
		{
			DumpHeader();
		}
		if( (iDisplayOptions & DUMP_DIR_ENTRIES_FLAG) ||
			(iDisplayOptions & DUMP_VERBOSE_FLAG) )
		{
			DumpDirStructure();
			DumpFileAttributes();
		}
	}
}

void RofsImageReader::DumpHeader()
{
	*out << "Image Name................." << iImgFileName.c_str() << endl;

	int aPos = 0;

	if( ((RofsImage*)iImage)->iImageType == RCoreImageReader::E_ROFS)
	{
		*out << "ROFS Image" << endl;

		*out << "Image Signature..........." ;
		while(aPos < K_ID_SIZE)
		{
			*out << ((RofsImage*)iImage)->iRofsHeader->iIdentifier[aPos++];
		}
		*out << endl << endl;

		TUint aTotalDirSz = ((RofsImage*)iImage)->iRofsHeader->iDirTreeSize +
							((RofsImage*)iImage)->iRofsHeader->iDirFileEntriesSize;
		(*out).width(8);

		*out << "Directory block size: 0x" << hex << ((RofsImage*)iImage)->iRofsHeader->iDirTreeSize << endl;
		*out <<	"File block size:      0x" << hex << ((RofsImage*)iImage)->iRofsHeader->iDirFileEntriesSize << endl;
		*out << "Total directory size: 0x" << hex << ( aTotalDirSz ) << endl;
		*out << "Total image size:     0x" << hex << ((RofsImage*)iImage)->iRofsHeader->iImageSize << endl;
	}
	else if(((RofsImage*)iImage)->iImageType == RCoreImageReader::E_ROFX)
	{
		*out << "Extension ROFS Image" << endl;
		*out << "Image Signature..........." ;
		while(aPos < K_ID_SIZE)
		{
			*out << ((RofsImage*)iImage)->iRofsExtnHeader->iIdentifier[aPos++];
		}
		*out << endl << endl;

		TUint aTotalDirSz = ((RofsImage*)iImage)->iRofsExtnHeader->iDirTreeSize +
						((RofsImage*)iImage)->iRofsExtnHeader->iDirFileEntriesSize;
		out->width(8);

		*out << "Directory block size: 0x" << hex << ((RofsImage*)iImage)->iRofsExtnHeader->iDirTreeSize << endl;
		*out <<	"File block size:      0x" << hex << ((RofsImage*)iImage)->iRofsExtnHeader->iDirFileEntriesSize << endl;
		*out << "Total directory size: 0x" << hex << ( aTotalDirSz ) << endl;
		*out << "Total image size:     0x" << hex << ((RofsImage*)iImage)->iRofsExtnHeader->iImageSize << endl;
	}
}

void RofsImageReader::DumpDirStructure()
{
	 
	*out << "Directory Listing" << endl;
	*out << "=================" << endl; 
	iImage->Display(out);

}

void RofsImageReader::MarkNodes()
{
	TRomNode *aNode = iRootDirEntry->NextNode();

	while( aNode )
	{
		if(aNode->iEntry)
		{
			if( ReaderUtil::IsExecutable(aNode->iEntry->iUids) )
			{
				aNode->iEntry->iExecutable = true;
			}
			else
			{
				aNode->iEntry->iExecutable = false;
			}
		}
		aNode = aNode->NextNode();
	}
}

void RofsImageReader::DumpFileAttributes()
{
	TRomNode *aNode = iRootDirEntry->NextNode();
	E32ImageFile	aE32Img;
	streampos		aFileOffset;
	string			iPath;
	
	while( aNode )
	{
		if( aNode->IsFile() )
		{
			if( !iInputFile )
			{
				// Open the image file once and to access the E32 images within,#
				// seek to the file offsets...
				iInputFile = new ifstream( (char*)(iImageReader->Filename()), ios::binary|ios::in);
				
				if(!iInputFile->is_open())
				{
					throw ImageReaderException((char*)iImageReader->Filename(), "Failed to open file");
				}
			}

			try 
			{
				if( aNode->iEntry->iExecutable)
				{
					aFileOffset = 0;
					if( ((RofsImage*)iImage)->iImageType == RCoreImageReader::E_ROFX)
					{
						if((TUint)aNode->iEntry->iFileOffset > ((RofsImage*)iImage)->iRofsExtnHeader->iDirTreeOffset)
						{
							//This is set only for files within this extended ROFS
							aFileOffset = aNode->iEntry->iFileOffset - ((RofsImage*)iImage)->iAdjustment;
						}
					}
					else
					{
						//This is set only for files within ROFS
						aFileOffset = aNode->iEntry->iFileOffset;
					}

					if( aFileOffset )
					{
						SetSeek(aFileOffset , ios::beg);
						memset(&aE32Img, 0, sizeof(aE32Img));
						aE32Img.Adjust(aNode->iSize);
						aE32Img.iFileSize = aNode->iSize;
						if( iInputFile->fail())
						{
							// Check why is the fail bit set causing all subsequent
							// istream operations to fail.
							// For now, clear the fail bit...
							iInputFile->clear();
						}
						*iInputFile >> aE32Img;
						if(aE32Img.iError != KErrNone)
						{
							throw int (0);
						}
					}
				}
			}
			catch(...)
			{
				// Just in case this was't a valid E32 image and the E32 reader didn't 
				// catch it...
				
				string aStr("Failed to read contents of ");
				aStr.append((char*)aNode->iName);

				throw ImageReaderException((char*)iImageReader->Filename(), (char*)aStr.c_str());
			}

			*out << "********************************************************************" << endl;
			iPath.assign((char*)aNode->iName);	
			GetCompleteNodePath(aNode,iPath,"/");
			*out << "File........................" << iPath.c_str() << endl;
			if( aNode->iEntry->iExecutable )
			{
				if(aFileOffset)
				{
					// When its an E32 Image...
					E32ImageReader::DumpE32Attributes(aE32Img);
					if( iDisplayOptions & DUMP_E32_IMG_FLAG){
						if(stricmp(iE32ImgFileName.c_str(), (const char*)aNode->iName) == 0){
							TUint aSectionOffset = aE32Img.iOrigHdr->iCodeOffset;
							TUint* aCodeSection = (TUint*)(aE32Img.iData + aSectionOffset);
							*out << "\nCode (Size=0x" << hex << aE32Img.iOrigHdr->iCodeSize << ")" << endl;
							DumpData(aCodeSection, aE32Img.iOrigHdr->iCodeSize);

							aSectionOffset = aE32Img.iOrigHdr->iDataOffset;
							TUint* aDataSection = (TUint*)(aE32Img.iData + aSectionOffset);
							if( aE32Img.iOrigHdr->iDataSize){
								*out << "\nData (Size=0x" << hex << aE32Img.iOrigHdr->iDataSize << ")" << endl;
								DumpData(aDataSection, aE32Img.iOrigHdr->iDataSize);
							}
						}
					}
				}
				else
				{
					*out << "Image "<< aNode->iName << " not in the extended ROFS " << iImgFileName.c_str() << endl;
				}
			}
		}

		aNode = aNode->NextNode();
	}
}


/** 
Function iterates through all the entries in the image.If the entry is a file,
then it makes a call to GetFileExtension to check for the extension.

@internalComponent
@released
*/
void RofsImageReader::ExtractImageContents()
{
	if( (iDisplayOptions & EXTRACT_FILE_SET_FLAG) )
	{
		ImageReader::ExtractFileSet(NULL);
	}

	if( iDisplayOptions & EXTRACT_FILES_FLAG || iDisplayOptions & LOG_IMAGE_CONTENTS_FLAG  )
	{
		// get the next Node 
		TRomNode *nextNode = iRootDirEntry->NextNode();
		// current Node.
		TRomNode *currNode = iRootDirEntry;
		// name of the log file.
		string  logFile;
		// output stream for the log file.
		ofstream oFile;

		if( iDisplayOptions & LOG_IMAGE_CONTENTS_FLAG ){		 
			if( ImageReader::iZdrivePath.compare("")){
				// create a string to hold path information.
				string filePath;
				string delimiter;
				delimiter.assign("\\");
				filePath.assign( ImageReader::iZdrivePath );
				// replace backslash with double backslash. 
				FindAndInsertString(filePath,delimiter,delimiter);
				logFile.assign(filePath);
				// create specified directory.
				CreateSpecifiedDir(&filePath[0],"\\\\");
				logFile.append("\\\\");
				logFile.append(ImageReader::iLogFileName);
			}
			else {				
				logFile.assign(ImageReader::iLogFileName);
			}

			// open the specified file in append mode.
			oFile.open(logFile.c_str(),ios::out|ios::app);

			if(!oFile.is_open()) {
				throw ImageReaderException((char*)ImageReader::iLogFileName.c_str(), "Failed to open the log file");
			}
		}

		while( nextNode ){
			if(nextNode->IsDirectory())	{
				// if next node is a directory set current node as next node.
				currNode = nextNode;
			}
			else {
				// get file extension
				CheckFileExtension((char*) nextNode->iName,nextNode->iEntry,currNode,oFile);
			}
			nextNode = nextNode->NextNode();
		}

		if(oFile.is_open()) oFile.close(); 

	}
}


/** 
Function to get check extension of the given file.If the extension of the file is "sis"
then call ExtractFile function to extract the file from the image.  

@internalComponent
@released

@param aFile	- file name. 
@param aEntry	- entry of the file in image.
@param aNode	- current node.
@param aLogFile	- output stream.
*/
void RofsImageReader::CheckFileExtension(char* aFileName,TRomBuilderEntry* aEntry,TRomNode* aNode,ofstream& aLogFile)
{
	//create a string to hold path information.
	string path;
	// check whether the node has parent 
	if(aNode->GetParent())
	{
		// get the complete path 
		path.assign( (char*)aNode->iName );
		GetCompleteNodePath( aNode, path, "\\\\" );
	}
	else
	{
		// else path is the current path
		path.assign("");
	}
	if( iDisplayOptions & LOG_IMAGE_CONTENTS_FLAG && iDisplayOptions & EXTRACT_FILES_FLAG )
	{
	 
		size_t pos = string(aFileName).find_last_of(".");

		const char* extName = "";
		if(pos != string::npos)
			extName = aFileName + pos + 1;	 
		if ( 0 == stricmp(extName,"SIS") || 0 == stricmp(extName,"DAT")) {
			// if the two strings are same then extract the corresponding file.
			ImageReader::ExtractFile(aEntry->iFileOffset,aEntry->RealFileSize(),aFileName,path.c_str(),&ImageReader::iZdrivePath[0]);
		}
		else {
			// log the entry path information on to the specified file.
			WriteEntryToFile(aFileName,aNode,aLogFile);
		}	 
	}
	else if( iDisplayOptions & LOG_IMAGE_CONTENTS_FLAG ) {
		// log the entry path information on to the specified file.
		WriteEntryToFile(aFileName,aNode,aLogFile);
	}
	else {
		// if the two strings are same then extract the corresponding file.
		ImageReader::ExtractFile(aEntry->iFileOffset,aEntry->RealFileSize(),aFileName,path.c_str(),&ImageReader::iZdrivePath[0]);
	}
}

/** 
Function to get the complete path information of a file from an image.

@internalComponent
@released

@param aNode	- starting offset of the file in the image.
@param aName	- name of the current entry in the image.
@param aAppStr	- string to append.
@return - returns full path of the given file.
*/
void RofsImageReader::GetCompleteNodePath(TRomNode* aNode,string& aName,char* aAppStr)
{
	// check if the entry has a parent.
	TRomNode* NodeParent = aNode->GetParent();
	if(NodeParent)
	{
		string str( (char*)NodeParent->iName );
		str.append( aAppStr );
		str.append( aName );
		aName = str;
		GetCompleteNodePath(NodeParent,aName,aAppStr);
	}
}


/** 
Function to write the rom entry to an output stream.

@internalComponent
@released

@param aNode		- starting offset of the file in the image.
@param aFileName	- name of the current entry in the image.
@param aLogFile		- output stream.
*/
void RofsImageReader::WriteEntryToFile(char* aFileName,TRomNode* aNode,ofstream& aLogFile)
{
	//create a string to hold path information.
	string path;
	
	if(aNode->GetParent())
	{
		// get the complete path 
		path.assign( (char*)aNode->iName );
		GetCompleteNodePath( aNode, path, "\\" );
	}
	else
	{
		// else path is the current path
		path.assign("");
	}
	
	if(aLogFile.is_open())
	{
		aLogFile.seekp(0,ios::end);
		aLogFile<<path.c_str()<<"\\"<<aFileName<<"\n";
	}
}

/** 
Function to get the directory structure information.

@internalComponent
@released

@param aFileMap		- map of filename with its size and offset values.
*/
void RofsImageReader::GetFileInfo(FILEINFOMAP &aFileMap)
{
	// get the next Node 
	TRomNode *nextNode = iRootDirEntry->NextNode();
	// current Node.
	TRomNode *currNode = iRootDirEntry;
	// image size
	TUint32 imgSize = GetImageSize();

	while(nextNode)
	{
		if(nextNode->IsDirectory())
		{
			// if next node is a directory set current node as next node.
			currNode = nextNode;
		}
		else
		{
			PFILEINFO fileInfo = new FILEINFO;
			//create a string to hold path information.
			string fileName;
			TUint32 aFileOffset = 0;

			// check whether the node has parent 
			if(currNode->GetParent())
			{
				if( !((currNode->GetParent() == currNode->FirstNode()) && !(currNode->IsDirectory())) )
				{
					// get the complete path 
					fileName.assign( (char*)currNode->iName );
					GetCompleteNodePath( currNode, fileName, (char*)DIR_SEPARATOR );
				}
			}
			else
			{
				// else path is the current path
				fileName.assign("");
			}
			fileName.append(DIR_SEPARATOR);
			fileName.append((char*)nextNode->iName);

			// get the size of the entity.
			fileInfo->iSize = nextNode->iEntry->RealFileSize();

			// get the offset of the entity.
			if( ((RofsImage*)iImage)->iImageType == RCoreImageReader::E_ROFX)
			{
				if((TUint)nextNode->iEntry->iFileOffset > ((RofsImage*)iImage)->iRofsExtnHeader->iDirTreeOffset)
				{
					//This is set only for files within this extended ROFS
					aFileOffset = nextNode->iEntry->iFileOffset - ((RofsImage*)iImage)->iAdjustment;
				}
			}
			else
			{
				//This is set only for files within ROFS
				aFileOffset = nextNode->iEntry->iFileOffset;
			}

			fileInfo->iOffset = aFileOffset;

			if((!fileInfo->iOffset) || ((fileInfo->iOffset + fileInfo->iSize) > imgSize))
			{
				fileInfo->iOffset = 0;
				fileInfo->iSize = 0;
			}

			aFileMap[fileName] = fileInfo;
		}

		nextNode = nextNode->NextNode();
	}
}

/** 
Function to get the ROFS image size.

@internalComponent
@released
*/
TUint32 RofsImageReader::GetImageSize()
{
	TUint32 result = 0;

	if( ((RofsImage*)iImage)->iImageType == RCoreImageReader::E_ROFS)
	{
		result = ((RofsImage*)iImage)->iRofsHeader->iImageSize;
	}
	else if(((RofsImage*)iImage)->iImageType == RCoreImageReader::E_ROFX)
	{
		result = ((RofsImage*)iImage)->iRofsExtnHeader->iImageSize;
	}

	return result;
}
