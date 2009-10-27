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
* DriveImage class declaration.
*
*/


#ifndef __R_DRIVEIMAGE_H__
#define __R_DRIVEIMAGE_H__

#if defined(__MSVCDOTNET__) || defined(__TOOLS2__)
	#include <fstream>
#else //!__MSVCDOTNET__
	#include <fstream.h>
#endif 

#include "filesysteminterface.h" 
#include <vector>

typedef std::vector<void*> EntryReferenceVector;
typedef	std::list<CDirectory*> EntryList; 

const TInt KMaxGenBuffer=0x14;  

// Node Type.
enum KNodeType
	{
	KNodeTypeNone=0,		
	KNodeTypeRoot,
	KNodeTypeChild,
	KNodeTypeSibling
	};

// File Format Supported.
struct DriveFileFormatSupported
	{
	const char* iDriveFileFormat;
	enum TFileSystem iFileSystem;
	};

// Image creation class.
class CDriveImage
	{
public:
	CDriveImage(CObeyFile *aObey);
	~CDriveImage();
	TInt CreateImage(TText* alogfile);
	static TBool FormatTranslation(TText* aUserFileFormat,enum TFileSystem& aDriveFileFormat);

private:

	TInt CreateList();
	TInt GenTreeTraverse(TRomNode* anode,enum KNodeType anodeType);    
	TInt CreateDirOrFileEntry(TRomNode* atempnode,enum KNodeType aType);   
	TInt ConstructOptions();
	TInt PlaceFileTemporary(const TInt afileSize,TRomNode* acurrentNode); 
	TInt DeleteTempFolder(char* aTempDirName);

private:

	// Holds the address of CObeyFile object. used to get the object information.
	CObeyFile *iObey;
	// Container required for file sysem module.
	EntryList iNodeList;
	// Pointer for nested Container.
	EntryList *iParentInnerList;

	// For temp storge of Container address.
	EntryReferenceVector iNodeAddStore;

	// For file format support.
	static DriveFileFormatSupported iFormatType[];
	// Reference variable used for converting tree to list.
	TInt iListReference;
	// Holds temp folder name. 
	char *iTempDirName;
	// Pointer to buffer, which will be used for compression/un-compression purpose.
	char *iData;
	};

#endif
