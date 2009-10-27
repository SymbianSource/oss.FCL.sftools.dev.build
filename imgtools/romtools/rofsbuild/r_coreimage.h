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


#ifndef __R_COREIMAGE_H__
#define __R_COREIMAGE_H__

class TRomNode;
class E32Rofs;

/**
@internalComponent

MRofsImage is the interface used to access information held within an image.
This interface used to remove the dependency between processing of 
extensions and kernel commands in the obey file
*/
class MRofsImage
	{
public:
	/** Gets the root directory node from the image

	   @return TRomNode* the first node in the directory tree
	 */
	virtual TRomNode* RootDirectory() = 0;

	/** Copies the specified directory tree.

	   @param aSourceDirectory The directory that is to be copied
	   @return The copied directory tree.
	 */
	virtual TRomNode* CopyDirectory(TRomNode*& aSourceDirectory)=0;
	/** Sets the root directory to be the specified node.

	   @param aDir The node that is to be set as the root directory
	 */
	virtual void SetRootDirectory(TRomNode* aDir) = 0;
	/** Gets the filename of the core image 

	    @returns The filename of the core image file 
	 */
	virtual TText* RomFileName() = 0;
	/** Gets the size of the image file

	   @returns size of file
	 */
	virtual TInt Size() = 0;
	};

const int K_ID_SIZE=4; /** Size of the image header identifier */

/** 
@internalComponent

Provides the access the actual core image file. All file operations to the 
core image file are through this class.
*/
class RCoreImageReader
	{
public:
	/** Image Type read from header of image file */
	enum TImageType 
		{
		/** Format of file has not been recognised */
		E_UNKNOWN, 
		/** File is a core RofsImage file */
		E_ROFS, 
		/** File is an extension RofsImage file */
		E_ROFX
		};

	RCoreImageReader(char *aFilename);
	~RCoreImageReader();
	TBool Open();
	TImageType ReadImageType();
	TInt ReadCoreHeader(TRofsHeader& aHeader);
	TInt ReadExtensionHeader(TExtensionRofsHeader& aHeader);

	TInt ReadDirEntry(TRofsDir& aDir);
	TInt ReadDirEntry(TRofsDir& aDir, long aFilePos);

	long FilePosition();
	void SetFilePosition(long aFilePos);

	TInt ReadRofEntry(TRofsEntry& aEntry);
	TInt ReadRofEntry(TRofsEntry& aEntry, long aFilePos);
	TInt ReadRofEntryName(TUint16* aName, int aLength);
	TBool IsValidPosition(long filePos);
	TText* Filename();
private:
	TInt ReadIdentifier();
	TInt ImageError(int aBytesRead, int aExpected, char* aInfo);

	/** Image type of the file being read */
	TImageType iImageType;
	/** File handle of core image being read */
	FILE* iCoreImage;
	/** Filename of core image file */
	char* iFilename;
	/** Image type identifier read from image header */
	TUint8 iIdentifier[K_ID_SIZE];
	};

/** 

@internalComponent

Processes the core image file to create a directory tree.
It is used when the coreimage option has been specified either
on the command line or in the obey file. It implements the MRofsImage 
so it can be used by the extension image processing.
*/
class CCoreImage : public MRofsImage
	{
public:
	CCoreImage(RCoreImageReader* aReader);
	virtual TInt ProcessImage();
	void Display(ostream* aOut);
	virtual ~CCoreImage();

	// Implementation of MRofsImage
	TRomNode* RootDirectory();
	TRomNode* CopyDirectory(TRomNode*& aSourceDirectory);
	void SetRootDirectory(TRomNode* aDir);
	TText* RomFileName();
	TInt Size();

protected:
	void SaveDirInfo(TRofsHeader& header);
	void SaveDirInfo(TExtensionRofsHeader& header);
	TInt ProcessDirectory(long aAdjustment);
	TInt CreateRootDir();
	long DirTreeOffset();

	/** used to read the core image file*/
	RCoreImageReader *iReader;
private:
	/** The node for the root directory */
	TRomNode *iRootDirectory;
	/** The first node in list of file entries */
	TRomBuilderEntry *iFileEntries;
	/** Offset to the directory tree in the core image */
	long iDirTreeOffset;
	/** Size of the directory tree in the core image */
	long iDirTreeSize;
	/** Offset to the file entries of the directory in the core image */
	long iDirFileEntriesOffset;
	/** Size of the file entries block of the directory */
	long iDirFileEntriesSize;
	/** Filename of the rom image file */
	TText* iRomFileName;
	/** Size of image */
	TInt iImageSize;
	};

/**
@internalComponent

Used for handling a single directory entry in the core image. This class allows
the directory tree to be created recursively.
*/
class TDirectoryEntry
	{
public:
	TDirectoryEntry(long filePos, RCoreImageReader* aReader, TRomNode* aCurrentDir);
	~TDirectoryEntry();
	TInt Process(long adjustment);
private:
	TInt CreateFileEntry(TText* aName, TRofsEntry& aRofsEntry);
	TInt AddSubDirs(long endDirPos);
	TInt AddFiles(long startPos, int size);
	TText* GetName(TUint16 aFirstChar, TInt aLength);

	/** Handle to core image file */
	RCoreImageReader* iReader;
	/** Node for the current directory */
	TRomNode* iCurrentDir;
	/** Current position in the file */
	long iFilePos;
	/** 
	 The references in the extension directory tree are relative the core 
	 image and not the actual offset in the file. This variable holds the 
	 difference between the entries in the directory tree and the actual file
	 position. This allows the same methods to be used for both core and
	 extension images.
	 */
	long iAdjustment;
	};

#endif
