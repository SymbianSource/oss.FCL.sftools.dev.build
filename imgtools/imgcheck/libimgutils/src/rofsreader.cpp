/*
* Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
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


/**
 @file
 @internalComponent
 @released
*/
#include "rofsreader.h"
#include "r_romnode.h"


/** 
Constructor intializes the class pointer members.

@internalComponent
@released

@param aFile - image file name
@param aImageType - image type
*/
RofsReader::RofsReader(const char* aFile, EImageType aImageType)
:ImageReader(aFile), iImageType(aImageType) {
	iImageReader = new RCoreImageReader(aFile);
	iImage = new RofsImage(iImageReader);
	iInputStream.open(aFile, ios_base::binary | ios_base::in);
}

/** 
Destructor deletes the class pointer members.

@internalComponent
@released
*/
RofsReader::~RofsReader() {
	 
	 for(ExeVsE32ImageMap::iterator it = iExeVsE32ImageMap.begin();
		it != iExeVsE32ImageMap.end(); it++) {
		if(it->second){
			delete it->second ;
			it->second = 0 ;
		}
		
	} 
	 
	iRootDirEntry = 0 ;
	 
	iExeVsOffsetMap.clear();
	if(iImageReader){
		delete iImageReader;
		iImageReader = 0 ;
	}
	if(iImage){
		delete iImage;
		iImage = 0 ;
	}
	iInputStream.close();
	iExeVsE32ImageMap.clear();
}

/** 
Dummy function for compatibility

@internalComponent
@released
*/
void RofsReader::ReadImage() {
}

/** 
Function responsible to 
1. Invoke E32Imagefile process method which will read the header part and identifies the 
   compression method.
2. Prepare executable vs E32Image map, which will be used later to read the E32Image contents.

@internalComponent
@released
*/
void RofsReader::ProcessImage() {
	int retVal = iImage->ProcessImage();
	if(retVal != KErrNone) {
		exit(retVal);
	}
	iRootDirEntry = iImage->RootDirectory();
	PrepareExeVsE32ImageMap(iRootDirEntry, iImage, iImageType, iInputStream, iExeVsE32ImageMap, iExeVsOffsetMap, iHiddenExeList);
}

/** 
Function to check whether the node is an executable or not.

@internalComponent
@released

@param aName - Executable name
*/
bool RofsReader::IsExecutable(const string& aName) {
	unsigned int extOffset = aName.find_last_of('.');
	if(extOffset != string::npos) {
		string ext = aName.substr(extOffset);
		if(ext.length() <= 4) {
			ReaderUtil::ToLower(ext);
			if (ext.find(".exe") != string::npos || ext.find(".dll") != string::npos || 
				ext.find(".prt") != string::npos || ext.find(".nif") != string::npos || 
				ext.find(".tsy") != string::npos || ext.find(".pdl") != string::npos || 
				ext.find(".csy") != string::npos || ext.find(".agt") != string::npos || 
				ext.find(".ani") != string::npos || //ext.find(".loc") != string::npos || 
				ext.find(".pdd") != string::npos || ext.find(".ldd") != string::npos ||
				ext.find(".drv") != string::npos)  {
				return true;
			}
		}
	}
	return false;
}

/** 
Function responsible to prepare iExeVsE32ImageMap by traversing the tree recursively.

@internalComponent
@released

@param aEntry - Root directory entry
@param aImage - core image
@param aImageType - Image type
@param aInputStream - Input stream to read image file
@param aExeVsE32ImageMap - Container to be filled
@param aExeVsOffsetMap - Container to be filled
@param aHiddenExeList - Hidden executables filled here.
*/
void RofsReader::PrepareExeVsE32ImageMap(TRomNode* aEntry, CCoreImage *aImage, EImageType aImageType, ifstream& aInputStream, ExeVsE32ImageMap& aExeVsE32ImageMap, ExeVsOffsetMap& aExeVsOffsetMap, StringList& aHiddenExes) {
    string name(aEntry->iName);
	bool insideRofs = false;
    E32Image* e32Image;
    if(IsExecutable(name)) {
		iExeAvailable = true;
		//V9.1 images has hidden file offset as 0x0
		//V9.2 to V9.6 has hidden file offset as 0xFFFFFFFFF
        if(aEntry->iEntry->iFileOffset != KFileHidden && aEntry->iEntry->iFileOffset != KFileHidden_9_1) {
            long fileOffset = 0;
            if(aImageType == ERofsExImage) {
				if(aEntry->iEntry->iFileOffset > (long)((RofsImage*)aImage)->iAdjustment) {
	            // File exists in Rofs extension 
		            fileOffset = aEntry->iEntry->iFileOffset - ((RofsImage*)aImage)->iAdjustment;
				}
				else {
					insideRofs = true;
				}
            }
            else {
	            // For rofs files
	            fileOffset = aEntry->iEntry->iFileOffset;
            }
	            
            aInputStream.seekg(fileOffset, ios_base::beg);
            /*
            Due to the complexities involved in sending the physical file size to E32Reader class, 
            here we avoided using it for gathering dependencies. Hence class E32ImageFile is used
            directly.
            */
            e32Image = new E32Image();
            e32Image->iFileSize = aEntry->iSize;
            e32Image->Adjust(aEntry->iSize); //Initialise the data pointer to the file size
            aInputStream >> *e32Image; //Input the E32 file to E32ImageFile class
            put_item_to_map(aExeVsOffsetMap,aEntry->iName,fileOffset);
			if(!insideRofs) {
				put_item_to_map_2(aExeVsE32ImageMap,aEntry->iName, e32Image);
				
			}
        }
        else { 
            aHiddenExes.push_back(aEntry->iName);
        }
    }

    if(aEntry->Currentchild()) {
        PrepareExeVsE32ImageMap(aEntry->Currentchild(), aImage, aImageType, aInputStream, aExeVsE32ImageMap, aExeVsOffsetMap, aHiddenExes);
    }
    if(aEntry->Currentsibling()) {
        PrepareExeVsE32ImageMap(aEntry->Currentsibling(), aImage, aImageType, aInputStream, aExeVsE32ImageMap, aExeVsOffsetMap, aHiddenExes);
    }
}

/** 
Function responsible to the executable lists using the container iExeVsE32ImageMap.

@internalComponent
@released
*/
void RofsReader::PrepareExecutableList() { 
	iExecutableList.clear();
    for(ExeVsE32ImageMap::iterator it = iExeVsE32ImageMap.begin();
		it != iExeVsE32ImageMap.end() ; it ++) { 
        iExecutableList.push_back(it->first); 
    }
	DeleteHiddenExecutableVsE32ImageEntry();
}

/** 
Function responsible to delete the hidden executable nodes, in order to
avoid the dependency data collection for the same.

@internalComponent
@released
*/
void RofsReader::DeleteHiddenExecutableVsE32ImageEntry() { 
	for(StringList::iterator it = iHiddenExeList.begin();
		it != iHiddenExeList.end(); it++){ 
		//Remove the hidden executable entry from executables vs RomNode Map
		ExeVsE32ImageMap::iterator pos = iExeVsE32ImageMap.find(*it);
		if(pos != iExeVsE32ImageMap.end()) { 
			if(pos->second)
				delete pos->second ;
			iExeVsE32ImageMap.erase(pos);
		} 
	}
}

/** 
Function responsible to gather dependencies for all the executables using the container iExeVsE32ImageMap.

@internalComponent
@released

@return iImageVsDepList - returns all executable's dependencies
*/
ExeNamesVsDepListMap& RofsReader::GatherDependencies() { 

	StringList executables;
	for(ExeVsE32ImageMap::iterator it = iExeVsE32ImageMap.begin() ; 
		it != iExeVsE32ImageMap.end() ; it++) {
		PrepareExeDependencyList(it->second, executables);
		put_item_to_map(iImageVsDepList,it->first, executables);
		executables.clear(); 
	}
	return iImageVsDepList;
}

/** 
Function responsible to prepare the dependency list.
This function can handle ROFS and ROFS extension images.

@internalComponent
@released

@param - aE32Image, Using this, can get all the information about the executable
@param - aExecutables, Excutables placed into this list
*/
void RofsReader::PrepareExeDependencyList(E32Image* aE32Image, StringList& aExecutables) {
	int count = 0;
	char** names = aE32Image->GetImportExecutableNames(count); 
	for(int i = 0 ; i < count; ++i) { 
		aExecutables.push_back(names[i]);
	}
	if(names){
		delete [](reinterpret_cast<long*>(names));
	}
}

/** 
Function responsible to say whether it is an ROFS image or not.

@internalComponent
@released

@param - aWord which has the identifier string
*/
bool RofsReader::IsRofsImage(const string& aWord) {
	return (aWord.find(KRofsImageIdentifier) == 0);//Identifier should start at the beginning
 
}

/** 
Function responsible to say whether it is an ROFS extension image or not.

@internalComponent
@released

@param - aWord which has the identifier string
*/
bool RofsReader::IsRofsExtImage(const string& aWord) {
	return (aWord.find(KRofsExtImageIdentifier) == 0) ;//Identifier should start at the beginning
}

/** 
Function responsible to traverse through the the map using the container iExeVsE32ImageMap to collect 
iExeVsIdData.

@internalComponent
@released
*/
void RofsReader::PrepareExeVsIdMap() { 
    if(iExeVsIdData.size() == 0) {//Is not already prepared 
        for(ExeVsE32ImageMap::iterator it = iExeVsE32ImageMap.begin();
			it != iExeVsE32ImageMap.end() ; it++) {
            string exeName(it->first);
            E32Image* e32Image = it->second;
			IdData* id = new IdData;
			id->iUid = e32Image->iOrigHdr->iUid1;
			id->iDbgFlag = (e32Image->iOrigHdr->iFlags & KImageDebuggable)? true : false;
            TUint aHeaderFmt = E32ImageHeader::HdrFmtFromFlags(e32Image->iOrigHdr->iFlags);
	        if (aHeaderFmt >= KImageHdrFmt_V) {
                E32ImageHeaderV* v = e32Image->iHdr;
                id->iSid = v->iS.iSecureId;
                id->iVid = v->iS.iVendorId;
	        }
			id->iFileOffset = iExeVsOffsetMap[exeName]; 
			put_item_to_map_2(iExeVsIdData,exeName,id); 
        }
    } 
}

/** 
Function responsible to return the Executable versus IdData container. 

@internalComponent
@released

@return - returns iExeVsIdData
*/
const ExeVsIdDataMap& RofsReader::GetExeVsIdMap() const {
    return iExeVsIdData;
}
