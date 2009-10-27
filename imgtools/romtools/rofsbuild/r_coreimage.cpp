/*
* Copyright (c) 2003-2009 Nokia Corporation and/or its subsidiary(-ies).
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
*
*/


#include <string.h>
#include "h_utl.h"

#include <e32std.h>
#include <e32std_private.h>
#include "rofs.h"

#include "r_obey.h"
#include "r_coreimage.h"

// -----------------------------------------------------------
//  RCoreImageReader
// -----------------------------------------------------------

/**
Constructs reader for the specified file.

@param aFilename Filename for core image file
*/
	RCoreImageReader::RCoreImageReader(char* aFilename) : 
			iImageType(E_UNKNOWN), iCoreImage(0), iFilename(aFilename)
	{
	}

/**
Closes the core image file if it was opened.
*/
RCoreImageReader::~RCoreImageReader() 
	{
	if (iCoreImage)
		fclose(iCoreImage);
	iCoreImage = 0;
	}

/**
Opens the image file that was specified at construction.

@return ETrue if file was opened successfully otherwise returns EFalse
*/
TBool RCoreImageReader::Open()
	{
	iCoreImage = fopen(iFilename, "rb");
	if (!iCoreImage)
		{
		Print(EError, "Cannot open image file %s\n", iFilename);
		return EFalse;
		}
	return ETrue;
	}

/**
Reads the image type from the core image file. It reads the value from the
file and then translates it into the internal enum used for processing 
the images. 

@return Image type
*/
RCoreImageReader::TImageType RCoreImageReader::ReadImageType() 
	{
	iImageType = E_UNKNOWN;
	if ( ReadIdentifier() == KErrNone)
		{
		if (iIdentifier[0] == 'R' &&
				iIdentifier[1] == 'O' &&
				iIdentifier[2] == 'F')
			{
			if (iIdentifier[3] == 'S')
				iImageType = E_ROFS;
			else if (iIdentifier[3] == 'x')
				iImageType = E_ROFX;
			}
		}
	return iImageType;
	}

/** 
Reads the 4 byte image type identifier from the core image file.

@return KErrNone for successful read or error number if failed 
*/
TInt RCoreImageReader::ReadIdentifier()
	{
	int itemsRead = fread(&iIdentifier, sizeof(TUint8), K_ID_SIZE, iCoreImage);
	TInt result = ImageError(itemsRead,  K_ID_SIZE, "Read Identifier");
	if (result != KErrNone)
		{
		iIdentifier[0] = 0;
		}
	return result;
	}

/**
Reads the core header from the image file.

@param aHeader space for the header read from the file. Only valid if KErrNone is returned.
@return KErrNone for successful read or error number if failed 
*/
TInt RCoreImageReader::ReadCoreHeader(TRofsHeader& aHeader) 
	{
	int itemsRead = fread (&aHeader.iHeaderSize, 
			(sizeof(TRofsHeader)) - K_ID_SIZE*sizeof(TUint8), 1, iCoreImage);
	TInt result = ImageError(itemsRead, 1, "Read Core Header");
	if (result == KErrNone)
		{
		// copy the previously read identifier into the header
		for (int i=0; i<K_ID_SIZE; i++)
			aHeader.iIdentifier[i] = iIdentifier[i];
		}
	return result;
	}

/**
Reads the extension header from the image file.

@param aHeader space for the header read from the file. Only valid if KErrNone is returned.
@return KErrNone for successful read or error number if failed 
*/
TInt RCoreImageReader::ReadExtensionHeader(TExtensionRofsHeader& aHeader)
	{
	int itemsRead = fread (&aHeader.iHeaderSize, 
			(sizeof(TExtensionRofsHeader)) - K_ID_SIZE*sizeof(TUint8), 1, iCoreImage);
	TInt result = ImageError(itemsRead, 1, "Read Extension Header");
	if (result == KErrNone)
		{
		// copy the previously read identifier into the header
		for (int i=0; i<K_ID_SIZE; i++)
			aHeader.iIdentifier[i] = iIdentifier[i];
		}
	return result;
	}

/**
Moves the actual file position to the specified location.

@param aFilePos Desired location for the new position
*/
void RCoreImageReader::SetFilePosition(long aFilePos)
	{
	fseek(iCoreImage, aFilePos, 0);
	}

/**
Validates whether the supplied file position exists in the core image file. 
It is not sufficient to just move to the required position in the file, 
but a read needs to be performed as well to ensure that the position exists.
The method preserves the current file position.

@param aFilePos Desired File Position
@return ETrue if desired file position exists in file else EFalse
*/
TBool RCoreImageReader::IsValidPosition(long aFilePos)
	{
	TBool valid = EFalse;
	long currentPos = ftell(iCoreImage); // save current position
	
	int result = fseek(iCoreImage, aFilePos, 0);
	if (result == 0)
		{
		int dummy;
		int itemsRead = fread(&dummy, sizeof(dummy), 1, iCoreImage);

		if (!ferror(iCoreImage) && !feof(iCoreImage) && result==0 && itemsRead == 1)
			valid = ETrue;
		}
	fseek(iCoreImage, currentPos, 0); // return to previous position
	return valid;
	}

/**
Reads a directory entry from the current position in the core image file. This
method does not read the variable length TRofsEntry part of the directory entry.
TRofsEntry does not exist for all directory entries. This is read later by 
other methods

@param aDir memory where the directory entry is read from the file. This is only valid if KErrNone is returned.
@return KErrNone for successful read or error number if failed 
*/
TInt RCoreImageReader::ReadDirEntry(TRofsDir& aDir)
	{
	// read directory without the associated TRofsEntry. The TRofsEntry 
	// is read later when handling subdirectories
	int bytesRead = sizeof(TRofsDir) - sizeof(TRofsEntry);
	int itemsRead = fread (&aDir, bytesRead , 1, iCoreImage);
	if (ImageError(itemsRead, 1, "Read Dir") == KErrNone)
		return bytesRead;
	else
		return 0;
	}

/**
Reads a directory entry from the specified position in the core image file.
This method moves the position of the file to the specified value and then
uses the other ReadDirEntry method to read the directory entry

@param aDir memory where the directory entry is read from the file. This is only valid if KErrNone is returned.
@param aFilePos position in the core image file where the directory
entry is located
@return KErrNone for successful read or error number if failed 
@see RCoreImageReader::ReadDirEntry(TRofsDir* aDir)
*/
TInt RCoreImageReader::ReadDirEntry(TRofsDir& aDir, long aFilePos)
	{
	SetFilePosition(aFilePos);
	return ReadDirEntry(aDir);
	}

/**
Reads a TRofsEntry from the current file position within the core image.

@param aEntry memory to be used for reading the data from the file. This is only valid if the size returned is greater than zero
@return size of the entry read
*/
TInt RCoreImageReader::ReadRofEntry(TRofsEntry& aEntry)
	{
	// need to work out how big entry needs to be from the Struct Size
	// in TRofsEntry
	int itemsRead = fread(&aEntry.iStructSize, sizeof(TUint16), 1, iCoreImage);
	int result = ImageError(itemsRead, 1, "Read Entry Size");
	if (result == KErrNone)
		{
		// read rest of entry excluding the iStructSize
		itemsRead = fread(&aEntry.iUids[0], sizeof(TRofsEntry) -sizeof(TUint16), 
				          1, iCoreImage);
		result = ImageError(itemsRead, 1, "Rest of Entry");
		// return length read - this include includes iStructSize and first char of name
		if (result == KErrNone)
			return sizeof(TRofsEntry);	
		}
	return 0;
	}

/**
Reads a TRofsEntry from the specified position within the core image

@param aEntry memory to be used for reading the data from the file. This is only valid if the size returned is greater than zero
@param aFilePos position in the core image file where the entry is located
@return size of the entry read
*/
TInt RCoreImageReader::ReadRofEntry(TRofsEntry& aEntry, long aFilePos)
	{
	fseek(iCoreImage, aFilePos, 0);
	return ReadRofEntry(aEntry);
	}

/**
Reads a name of the specified length from the core image file.

@param aName memory for the name read from the file. Only valid if KErrNone is returned
@param aLength length of name to be read
@return KErrNone for successful read or error number if failed 
*/
TInt RCoreImageReader::ReadRofEntryName(TUint16* aName, int aLength)
	{
	int itemsRead = fread(aName, sizeof(TUint16), aLength, iCoreImage);
	return ImageError(itemsRead, aLength, "Rof Entry Name");
	}

/**
Provides the current file position in the core image file.

@return Current file position
*/
long  RCoreImageReader::FilePosition()
	{
	return ftell(iCoreImage);
	}

/** 
Provides the name of the core image file being read.

@return Core image Filename
*/
TText* RCoreImageReader::Filename()
	{
	return (TText *)iFilename;
	}

/**
Determines whether the last read from the file was valid or not.
It checks that the number of items read where the same number as expected,
that there are no file errors and that the end of file was not reached. If an
error is found than a message is printed and the appropriate error number is 
returned.

@param aItemsRead Number of items read
@param aExpected Number of items expected to have been read
@param aInfo Used by the caller to identify where the error occurred.
@return Error number. KErrNone is returned if there are no errors.
*/
TInt RCoreImageReader::ImageError(int aItemsRead, int aExpected, char *aInfo)
	{
	if (aItemsRead != aExpected)
		{
		Print(EError, "Read From Core Image Failed (%s) \n", aInfo);
		return KErrCorrupt;
		}
	if (int errnum = ferror(iCoreImage))
		{
		Print(EError, "Core Image File Error (%s) : %d\n", aInfo, errnum);
		return KErrCorrupt;
		}
	if (feof(iCoreImage))
		{
		Print(EError, "Premature End of File Detected (%s)\n", aInfo);
		return KErrEof;
		}
	return KErrNone;
	}

// -----------------------------------------------------------
//  CCoreImage 
// -----------------------------------------------------------

/**
Initialises the reader to be used for accessing the core image file

@param aReader Reader to be used for accessing the core image file
*/
CCoreImage::CCoreImage(RCoreImageReader* aReader) : iReader(aReader),
	iRootDirectory(0), iFileEntries(0), iDirTreeOffset(0),
	iDirTreeSize(0), iDirFileEntriesOffset(0),
iDirFileEntriesSize(0), iRomFileName(0), iImageSize(0)
	{
	}

/**
Deletes the directory tree that was created from the core image.
*/
CCoreImage::~CCoreImage()
	{
	delete iRootDirectory;
	iRootDirectory=0;
	}


/**
Creates the node to be used as the root directory of the directory tree.

@return KErrNone for successful read or error number if failed 
*/
TInt CCoreImage::CreateRootDir()
	{
	iRootDirectory = new TRomNode((TText*)"");
	if (iRootDirectory == 0 )
		return KErrNoMemory;
	return KErrNone;
	}

/**
Processes the core image file to produce a directory tree.

@return KErrNone for successful read or error number if failed 
*/
TInt CCoreImage::ProcessImage()
	{
	iRomFileName = iReader->Filename();
	int result = CreateRootDir();
	if (result == KErrNone)
		{
		if (iReader->Open())
			{
			RCoreImageReader::TImageType imageType = iReader->ReadImageType();
			if (imageType == RCoreImageReader::E_ROFS)
				{
				TRofsHeader header;
				result = iReader->ReadCoreHeader(header);
				if (result == KErrNone)
					{
					SaveDirInfo(header);
					result = ProcessDirectory(0);
					}
				}
			else
				result = KErrNotSupported;
			}
		else
			result = KErrGeneral;
		}
	return result;
	}

/**
Processes the directory in the core image file.

@param aAdjustment The difference between offsets in the core image directory and
@return KErrNone for successful read or error number if failed 
*/
TInt CCoreImage::ProcessDirectory(long aAdjustment)
	{
	long filePos = iDirTreeOffset - aAdjustment;
	TDirectoryEntry *firstDir = new TDirectoryEntry(filePos, iReader, iRootDirectory);
	if (firstDir == 0)
		return KErrNoMemory;
	TInt result = firstDir->Process(aAdjustment);
	delete firstDir;
	return result;
	}

/**
Saves directory information from core image header for later usage.

@param aHeader Header containing information to be saved
*/
void CCoreImage::SaveDirInfo(TRofsHeader& aHeader)
	{
	iDirTreeOffset = aHeader.iDirTreeOffset;
	iDirTreeSize = aHeader.iDirTreeSize;
	iDirFileEntriesOffset = aHeader.iDirFileEntriesOffset;
	iDirFileEntriesSize = aHeader.iDirFileEntriesSize;
	iImageSize = aHeader.iMaxImageSize;
	}

/**
Saves directory information from extension image header for later usage.

@param aHeader Header containing information to be saved
*/
void CCoreImage::SaveDirInfo(TExtensionRofsHeader& aHeader)
	{
	iDirTreeOffset = aHeader.iDirTreeOffset;
	iDirTreeSize = aHeader.iDirTreeSize;
	iDirFileEntriesOffset = aHeader.iDirFileEntriesOffset;
	iDirFileEntriesSize = aHeader.iDirFileEntriesSize;
	iImageSize = aHeader.iMaxImageSize;
	}

/**
Displays the directory tree. This is used for debug purposes only.
*/
void CCoreImage::Display(ostream* aOut)
	{
	iRootDirectory->DisplayStructure(aOut);
	}

/**
Reads offset where directory tree starts in core image.

@return offset of directory tree in image
*/
long CCoreImage::DirTreeOffset()
	{
	return iDirTreeOffset;
	}

TRomNode* CCoreImage::CopyDirectory(TRomNode*& aSourceDirectory)
	{
	return iRootDirectory->CopyDirectory(aSourceDirectory);
	}

TRomNode* CCoreImage::RootDirectory()
	{
	return iRootDirectory;
	}

void CCoreImage::SetRootDirectory(TRomNode* aDir)
	{
	iRootDirectory = aDir;
	}

TText* CCoreImage::RomFileName()
	{
	return iRomFileName;
	}

TInt CCoreImage::Size()
	{
	return iImageSize;
	}

// -----------------------------------------------------------
//  TDirectoryEntry 
// -----------------------------------------------------------

/**
Initialises the directory entry

@param aFilePos Position within file where the directory entry is located
@param aReader Handle used to access the file;
@param aDir The TRomNode associated with this directory
*/
TDirectoryEntry::TDirectoryEntry(long aFilePos, RCoreImageReader* aReader, 
		TRomNode* aDir) :
			iReader(aReader),  iCurrentDir(aDir),iFilePos(aFilePos),
			iAdjustment(0) 
	{
	}

/**
Empty destructor.
*/
TDirectoryEntry::~TDirectoryEntry()
	{
	}

/**
Processes the current directory entry. If the directory has any files it will 
create the appropriate file entries in the directory tree. If the directory 
has any subdirectories it will create nodes in the directory tree and will 
create an TDirectoryEntry and then use that to process the subdirectory

@param aAdjustment The difference between offsets in the core image directory and
the actual position in the file
*/
TInt TDirectoryEntry::Process(long aAdjustment)
	{
	TRofsDir dir;
	iAdjustment = aAdjustment;
	long dirStartPos = iFilePos;
	int result = KErrNone;
	int dirSize = iReader->ReadDirEntry(dir, iFilePos);
	if (dirSize != 0)
		{
		if (dir.iFileBlockAddress != 0)
			{
			// directory has files in it
			result = AddFiles(dir.iFileBlockAddress-iAdjustment, dir.iFileBlockSize);
			}
		if (result == KErrNone && dir.iStructSize > dirSize)
			{
			// directory has subdirectories
			result = AddSubDirs(dirStartPos + dir.iStructSize);
			}
		}
	else 
		result = KErrGeneral;

	return result;
	}

/**
Processes the subdirectories in the current directory. For each subdirectory
a TDirectoryEntry is created and is then used to process the directory

@param aEndDirPos Position where the directory block finishes. This is to determine when all subdirectories have been processed
*/
TInt TDirectoryEntry::AddSubDirs(long aEndDirPos)
	{
	TRofsEntry entry;
	iFilePos = iReader->FilePosition();
	TInt result = KErrNone;
	while (iFilePos < aEndDirPos && result == KErrNone)
		{
		TInt size = iReader->ReadRofEntry(entry, iFilePos);
		if (size >0)
			{
			TText* nameStr = GetName(entry.iName[0], entry.iNameLength);
			if (nameStr !=0)
				{
				TRomNode *dir = iCurrentDir->NewSubDir(nameStr);
				TDirectoryEntry *subDir = new TDirectoryEntry(
						entry.iFileAddress-iAdjustment, iReader, dir);
				if (subDir != 0)
					{
					// now process the subdirectory
					subDir->Process(iAdjustment);
					iFilePos += entry.iStructSize;
					// round to nearest word boundary
					iFilePos += (4-entry.iStructSize) & 3;
					}
				else
					result = KErrNoMemory;

                if (subDir)
                {
                    delete subDir;
                }
				}
			else
				result = KErrNoMemory;
			if(nameStr != 0)
				delete [] nameStr;
			}
		else
			{
			result = KErrGeneral;
			}
		}
	return result;
	}

/**
Processes a file entries block in the directory and creates the appropriate 
nodes for each file in the block

@param aStartPosition start for file block in the core image file
@param aSize size of the file entries block
*/
TInt TDirectoryEntry::AddFiles(long aStartPosition, int aSize )
	{
	long savedPosition = iReader->FilePosition();
	long currentPos = aStartPosition;
	iReader->SetFilePosition(aStartPosition);
	long endPos = aStartPosition+aSize;
	TRofsEntry entry;
	TInt result = KErrNone;
	while (currentPos < endPos && result == KErrNone)	
		{
		TInt size = iReader->ReadRofEntry(entry, currentPos);
		if (size > 0)
			{
			TText *nameStr = GetName(entry.iName[0], entry.iNameLength);
			if (nameStr != 0)
				{
				result = CreateFileEntry(nameStr, entry);
				currentPos += entry.iStructSize;
				}
			else
				result = KErrNoMemory;
			if(nameStr != 0)
			    delete [] nameStr;
			}
		else
			{
			result = KErrGeneral;
			}
		}
	iReader->SetFilePosition(savedPosition);
	return result;
	}

/** 
Creates a new node for a file entry and the associated TRomBuilderEntry.

@param aNameStr Name of the file entry to be created
@param aFileAddress Address of file in the core image
@param aFileSize Size of the file
*/
TInt TDirectoryEntry::CreateFileEntry(TText* aNameStr, TRofsEntry& aRofsEntry)
	{
	TRomBuilderEntry *fileEntry = new TRomBuilderEntry(0,aNameStr);
	if (fileEntry == 0)
		return KErrNoMemory;

	memcpy(&fileEntry->iUids[0], &aRofsEntry.iUids[0], sizeof(fileEntry->iUids));
	fileEntry->iFileOffset = aRofsEntry.iFileAddress;
	fileEntry->SetRealFileSize(aRofsEntry.iFileSize);
	TRomNode *file = new TRomNode(aNameStr, fileEntry);
	file->iSize = aRofsEntry.iFileSize;
	if (file == 0)
		{
		delete fileEntry;
		return KErrNoMemory;
		}
	file->iAtt = aRofsEntry.iAtt;
	file->iAttExtra = aRofsEntry.iAttExtra;
	iCurrentDir->AddFile(file);
	return KErrNone;
	}

/**
Gets the name of a file or directory from the core image. The first character
of the name has already been read.

@param aFirstChar first character of name (already read by TRofsEntry)
@param aLength Length of name to be read (including the first character)
*/
TText* TDirectoryEntry::GetName(TUint16 aFirstChar, TInt aLength)
	{
	TText *nameStr = 0;
	TUint16* name = new TUint16[aLength];
	if (name !=0)
		{
		name[0] = aFirstChar;
		TInt result = iReader->ReadRofEntryName(&name[1], aLength-1);
		if (result == KErrNone)
			{
			nameStr = new TText[aLength+1];
			if (nameStr != 0)
				{
				for (int i=0; i< aLength; i++)
					{
					nameStr[i] = (TText) name[i];
					}
				nameStr[aLength]=0;
				}
			}
		delete [] name;
		}
	return nameStr;
	}

