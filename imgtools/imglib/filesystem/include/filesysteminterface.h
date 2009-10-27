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
* Interface class for FileSystem component
* @internalComponent
* @released
*
*/


#ifndef FILESYSTEMINTERFACE_H
#define FILESYSTEMINTERFACE_H

#include "directory.h"
#include <fstream>

typedef std::ofstream Ofstream;

//default image size in Bytes
const int KDefaultImageSize=50*1024*1024;

//enum representing the file system type
enum FILESYSTEM_API TFileSystem
{
	EFATINVALID=0,
	EFAT12=1,
	EFAT16,
	EFAT32,
	ELFFS
};

//error code return by the file system component
enum TErrorCodes
{
	//File system not supported
	EFSNotSupported = -1,
	//File System general errors
	EFileSystemError = EXIT_FAILURE
};

// Configurable FAT attributes
struct ConfigurableFatAttributes
{
	String iDriveVolumeLabel;
	unsigned int iDriveSectorSize;
	unsigned int iDriveNoOfFATs;
	
	ConfigurableFatAttributes();
};

/**
Interface class containing a static method exposed by the FileSystem 
component to be used by an external tools

@internalComponent
@released

@param aNodeList Directory structure 
@param aFileSystem file system type
@param aImageFileName image file name 
@param aLogFileName log file name 
@param aPartitionSize partition size in bytes
*/

class CFileSystemInterFace
{
private:
		static Ofstream iOutputStream;
public:
		/**This method is exported to the external component to receive the information 
		 * required by the FileSystem component
		 */
		static FILESYSTEM_API int CreateFilesystem(	EntryList* aNodeList ,TFileSystem aFileSystem, 
													char* aImageFileName, 
													char* aLogFileName,
													ConfigurableFatAttributes* aConfigurableFatAttributes,
													Long64 aPartitionSize=KDefaultImageSize); 
};

#endif //FILESYSTEMINTERFACE_H
