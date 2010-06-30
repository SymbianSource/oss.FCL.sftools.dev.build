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

#include <fstream> 
#include <vector>

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

class TFSNode ;
// Image creation class.
class CDriveImage
	{
public:
	CDriveImage(CObeyFile *aObey);
	~CDriveImage();
	TInt CreateImage(const char* alogfile);
	
private:
 
	TFSNode* PrepareFileSystem(TRomNode* aRomNode); 	
	// Holds the address of CObeyFile object. used to get the object information.
	CObeyFile *iObey;	  
	 
	 
	};

#endif
