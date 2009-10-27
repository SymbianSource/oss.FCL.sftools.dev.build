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
* This class provides the interface to external tools which can
* use FileSystem component library. Upon external request this class 
* classifies the request type either FAT16 or FAT32 and invokes 
* the specific functions to generate the FAT image.
* @internalComponent
* @released
*
*/

#include"errorhandler.h"
#include"filesysteminterface.h"
#include"fat16filesystem.h"
#include"fat32filesystem.h"
#include"dirregion.h"


//static member definition

Ofstream CFileSystemInterFace::iOutputStream;

/**
API exposed by the  FileSystem component to be used by an external component(s).
This is method to be used by the external component for passing information required 
by the FileSystem component

@internalComponent
@released

@param aNodeList Directory structure 
@param aFileSystem file system type
@param aImageFileName image file name 
@param aLogFileName log file name 
@param aPartitionSize partition size in bytes
*/
FILESYSTEM_API int CFileSystemInterFace::CreateFilesystem(EntryList* aNodeList , 
										   TFileSystem aFileSystem,
										   char* aImageFileName, 
										   char* aLogFileName,
										   ConfigurableFatAttributes* aConfigurableFatAttributes,
										   Long64 aPartitionSize)
{
	
	
	CFileSystem* iFileSystem = NULL;
	try
	{
		MessageHandler::StartLogging (aLogFileName);
		iOutputStream.open(aImageFileName,ios::out|ios::binary);
		if(iOutputStream.fail() == true )
		{
			throw ErrorHandler(FILEOPENERROR,aImageFileName,__FILE__, __LINE__);
		}
		switch(aFileSystem)
		{
			case EFAT16:
				iFileSystem = new CFat16FileSystem;
				break;
			
			case EFAT32:
				iFileSystem= new CFat32FileSystem;
				break;
			default:
				return EFSNotSupported;
				break;

		}
		iFileSystem->Execute(aPartitionSize,*aNodeList,iOutputStream,aConfigurableFatAttributes);
		delete iFileSystem;
		iFileSystem = NULL;
		iOutputStream.close();
		MessageHandler::CleanUp();
	}
	catch(ErrorHandler &error)
	{
		iOutputStream.close();
		delete iFileSystem;
		iFileSystem = NULL;
		MessageHandler::StartLogging (aLogFileName);
		error.Report();
		MessageHandler::CleanUp();
		return EFileSystemError;
	}
	/**
	Irrespective of successful or unsuccessful data drive image generation ROFSBUILD
	may try to generate images for successive oby file input.
	During this course unhandled exceptions may cause leaving some memory on heap 
	unused. so the unhandled exceptions handling is used to free the memory allocated 
	on heap. 
	*/
	catch(...)
	{
		iOutputStream.close();
		delete iFileSystem;
		iFileSystem = NULL;
		return EFileSystemError;
	}
	return 0;
}


/**
Constructor of Class ConfigurableFatAttributes

@internalComponent
@released
*/
ConfigurableFatAttributes::ConfigurableFatAttributes()
{
	iDriveSectorSize = 0;
	iDriveNoOfFATs = 0;
}
