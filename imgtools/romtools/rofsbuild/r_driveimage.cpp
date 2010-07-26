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
#include "fsnode.h"
#include "fatimagegenerator.h"
#include <boost/filesystem.hpp>
#include <stack>
#include <utility>
#include <new>
using namespace boost ;
#ifdef __LINUX__
	
	#include <dirent.h>
	#ifndef MKDIR
		#define MKDIR(a)	mkdir(a,0777)
	#endif
#else
	#ifdef _STLP_INTERNAL_WINDOWS_H
	#define __INTERLOCKED_DECLARED
	#endif
	#include <windows.h>
	#include <direct.h>
	#ifndef MKDIR
		#define MKDIR		mkdir
	#endif
#endif
#include <sys/stat.h>
#include <sys/types.h>
using namespace std;


#include <f32file.h>
#include "h_utl.h"
#include "r_obey.h"
#include "r_romnode.h"
#include "r_rofs.h"
#include "r_driveimage.h"
 
/**
Constructor: CDriveImage class 

@param aObey - pointer to Drive obey file.
*/
CDriveImage::CDriveImage(CObeyFile *aObey)
	: iObey( aObey )
{
}


CDriveImage::~CDriveImage()
{
 
}
/**
	* 
  */
TFSNode* CDriveImage::PrepareFileSystem(TRomNode* aRomNode){ 
	TUint8 attrib ;
	TFSNode* root = 0;
	TRomNode* romNode = aRomNode;
	stack<pair<TRomNode*,TFSNode*> > nodesStack ;
	TFSNode* parentFS = 0 ;
	TFSNode* curFS = 0;
	bool err = false ;
    while(1) {
        attrib = 0 ;
        if(romNode->iAtt & KEntryAttReadOnly)
			attrib |= ATTR_READ_ONLY ;
		if(romNode->iAtt & KEntryAttHidden)
			attrib |= ATTR_HIDDEN ;
		if(romNode->iAtt & KEntryAttSystem)
			attrib |= ATTR_SYSTEM ;  
		if(romNode->IsDirectory()) {
			try {
				curFS = new TFSNode(parentFS,romNode->iName,attrib | ATTR_DIRECTORY);
			}
			catch(const char* errInfo){
				Print(EError,errInfo);
				err = true ;
				break ;
			}
			catch(...) {
				err = true ;
				break ;
			} 
			if(!root) root = curFS ;  
			time_t now = time(NULL); 
			curFS->Init(now,now,now,0); 
			TRomNode* child = romNode->Currentchild();
			if(child){
				TRomNode* sibling = romNode->Currentsibling(); 
				if(sibling)
					nodesStack.push(make_pair(sibling,parentFS));
				romNode = child ;
				parentFS = curFS ;
				continue ;
			}			
		}
		else { // file   
			try {         
				curFS = new TFSNode(parentFS,romNode->iEntry->iName,attrib,romNode->iEntry->iFileName);
			}
			catch(const char* errInfo){
				Print(EError,errInfo);
				err = true ;
				break ;
			}
			catch(...) { 
					err = true ;
					break ;
			} 
					
			if(!root) root = curFS ;  
			struct stat statbuf ;
			stat(romNode->iEntry->iFileName, &statbuf);             
			curFS->Init(statbuf.st_ctime,statbuf.st_atime,statbuf.st_mtime,statbuf.st_size);   
		 
		}
		
		TRomNode* sibling = romNode->Currentsibling(); 
		if(sibling) {
			romNode = sibling ; 
		}
		else { 
			if(nodesStack.empty()) {
				break ;
			}
			else {
				romNode = nodesStack.top().first;
				parentFS = nodesStack.top().second ;
				nodesStack.pop() ;
				
			}
		}		
    }
	if(err) {
		if(root) delete root ;
		return NULL ;
	}
    return root ;
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
TInt CDriveImage::CreateImage(const char* alogfile) {
	
	TSupportedFatType fst = EFatUnknown ;
	if(stricmp(iObey->iDriveFileFormat,"FAT16") == 0)
	    fst = EFat16 ;
	else if(stricmp(iObey->iDriveFileFormat,"FAT32") == 0)
	        fst = EFat32 ;
	if(EFatUnknown == fst){
        Print(EError,"Unsupported FAT type : %s",iObey->iDriveFileFormat);
        return KErrGeneral ;
	}
	 
	TFatImgGenerator generator(fst,iObey->iConfigurableFatAttributes);
	
	if(!generator.IsValid()){
	    return KErrGeneral; 
	}
	TFSNode* root = PrepareFileSystem(iObey->iRootDirectory);
	if(!root)
	    return KErrGeneral;
	
 
	TInt retVal = generator.Execute(root,iObey->iDriveFileName) ? KErrNone : KErrGeneral;
	
	delete root ;
		
	return 	retVal;
}
