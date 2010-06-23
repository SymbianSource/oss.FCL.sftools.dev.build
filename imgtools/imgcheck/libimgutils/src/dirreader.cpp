/*
* Copyright (c) 2008-2009 Nokia Corporation and/or its subsidiary(-ies).
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
#include "dirreader.h"
#include "e32reader.h"

#ifdef WIN32
#include <io.h>
#include <direct.h>
#else//__LINUX__
#include <dirent.h>
#include <unistd.h>
#include <sys/stat.h>
#define stricmp strcasecmp
#define strinicmp strncasecmp
#endif

#define MAXPATHLEN 255

/** 
Constructor.

@internalComponent
@released
*/
DirReader::DirReader(const char* aDirName)
:ImageReader(aDirName) {
}

/** 
Destructor.

@internalComponent
@released
*/
DirReader::~DirReader(void) {
	ExeVsE32ImageMap::iterator begin = iExeVsE32ImageMap.begin();
	ExeVsE32ImageMap::iterator end = iExeVsE32ImageMap.end();
	while(begin != end) {
		DELETE(begin->second);
		++begin;
	}  
	iExeVsE32ImageMap.clear();
}

/** 
Function to check whether the node is an executable or not.

@internalComponent
@released

@param aName - Executable name
*/
bool DirReader::IsExecutable(const string& aName) {
	unsigned int strPos = aName.find_last_of('.');
	if(strPos != string::npos) {
		string ext = aName.substr(strPos);
		if(ext.length() <= 4) {
			ReaderUtil::ToLower(ext);
			if (ext.find(".exe") != string::npos || ext.find(".dll") != string::npos ||
				ext.find(".prt") != string::npos || ext.find(".nif") != string::npos ||
				ext.find(".pdl") != string::npos || ext.find(".csy") != string::npos || 
				ext.find(".agt") != string::npos || ext.find(".ani") != string::npos || 
				ext.find(".loc") != string::npos || ext.find(".drv") != string::npos || 
				ext.find(".pdd") != string::npos || ext.find(".ldd") != string::npos ||
				ext.find(".tsy") != string::npos || ext.find(".fsy") != string::npos ||
				ext.find(".fxt") != string::npos) {
				return true;
			}
		}
	}
	return false;
}

/** 
Dummy function to be compatible with other Readers.

@internalComponent
@released
*/
void DirReader::ReadImage(void) {
}

/** 
Function to 
1. Preserve the present working directory
2. Invoke the function which reads the directory entires recursively.
3. Go back to the original directory.

@internalComponent
@released
*/
void DirReader::ProcessImage() {
	char* cwd = new char[MAXPATHLEN]; 
	getcwd(cwd,MAXPATHLEN);
	ReadDir(iImgFileName); 
	chdir(cwd); 
	if(cwd != NULL)
		delete [] cwd;
	cwd = 0;
}

/** 
Function to 
1. Read the directory entires recursively.
2. Prepare the ExeVsE32ImageMap.

@internalComponent
@released

@param aPath - Directory name.
*/
void DirReader::ReadDir(const string& aPath) {


	E32Image* e32Image = KNull;

#ifdef WIN32
	int handle ; 
	int retVal = chdir(aPath.c_str());
	struct _finddata_t  finder;
	handle = _findfirst("*.*", &finder);
	while (retVal == 0) {
		if ((strcmp(finder.name, KChildDir.c_str()) == 0) || 
			(strcmp(finder.name, KParentDir.c_str()) == 0) ) {// current dir || parent dir   
			retVal = _findnext(handle, &finder);
			continue;
		}

		if (finder.attrib & _A_SUBDIR) {
			ReadDir(finder.name);  
			chdir(KParentDir.c_str()); 
		}
		else {
			if ((finder.size > 0) && IsExecutable(string(finder.name)) && E32Image::IsE32ImageFile(finder.name)) {
				e32Image = new E32Image();
				ifstream inputStream(finder.name, ios_base::binary | ios_base::in);
				iExeAvailable = true;
				e32Image->iFileSize=finder.size;
				e32Image->Adjust(finder.size);
				inputStream >> *e32Image;				
				ExeVsE32ImageMap::iterator it  ;
				for(it = iExeVsE32ImageMap.begin() ;it != iExeVsE32ImageMap.end(); it++){
					if(it->first == finder.name){ 
						break ;
					}
				}				
				if(it != iExeVsE32ImageMap.end()) {
					cout << "Warning: "<< "Duplicate entry '" << finder.name << " '"<< endl;					
					retVal = _findnext(handle, &finder);
					continue;
				}
				size_t len = strlen(finder.name) + 1;
				e32Image->iFileName = new char[len ];
				memcpy(e32Image->iFileName,finder.name,len); 
				put_item_to_map_2(iExeVsE32ImageMap,e32Image->iFileName, e32Image);
				
				iExecutableList.push_back(e32Image->iFileName); 
			}
			else {
				cout << "Warning: "<< finder.name << " is not a valid E32 executable" << endl;
			}
		}
		retVal = _findnext(handle,&finder);
	}
#else //__LINUX__
	DIR* dirEntry = opendir( aPath.c_str());
	static struct dirent* dirPtr;
	while ((dirPtr= readdir(dirEntry)) != NULL) {
		if ((strcmp(dirPtr->d_name, KChildDir.c_str()) == 0) || 
			(strcmp(dirPtr->d_name, KParentDir.c_str()) == 0)) 
			continue; // current dir || parent dir

		string fullName( aPath + "/" + dirPtr->d_name );

		struct stat fileEntrybuf; 
		int retVal = stat((char*)fullName.c_str(), &fileEntrybuf); 
		if(retVal >= 0) {
			if(S_ISDIR(fileEntrybuf.st_mode)) { //Is Directory?
				ReadDir(fullName);
			}
			else if(S_ISREG(fileEntrybuf.st_mode)){ //Is regular file? 
				if ((fileEntrybuf.st_blksize > 0) && IsExecutable(string(dirPtr->d_name)) && E32Image::IsE32ImageFile(fullName.c_str())) {
					iExeAvailable = true;
					e32Image = new E32Image();
					ifstream inputStream(fullName.c_str(), ios_base::binary | ios_base::in);
					inputStream.seekg(0, ios_base::end);
					TUint32 aSz = inputStream.tellg();
					inputStream.seekg(0, ios_base::beg);
					e32Image->iFileSize=aSz;
					e32Image->Adjust(aSz);
					inputStream >> *e32Image;
					//string exeName(dirPtr->d_name);
					//ReaderUtil::ToLower(exeName);
					ExeVsE32ImageMap::iterator it  ;
					for(it = iExeVsE32ImageMap.begin() ;it != iExeVsE32ImageMap.end(); it++){
						if(!stricmp(dirPtr->d_name,it->first.c_str())){ 
							break ;
						}
					}	
					if(it != iExeVsE32ImageMap.end()) {
						cout << "Warning: "<< "Duplicate entry '" << dirPtr->d_name << " '"<< endl;
						continue;
					}
					size_t len = strlen(dirPtr->d_name) + 1;
					if(e32Image->iFileName) delete []e32Image->iFileName;
					e32Image->iFileName = new char[len ];
					memcpy(e32Image->iFileName,dirPtr->d_name,len); 					
					put_item_to_map_2(iExeVsE32ImageMap,e32Image->iFileName, e32Image);					
					iExecutableList.push_back(e32Image->iFileName); 
				}
				else {
					cout << "Warning: "<< dirPtr->d_name << " is not a valid E32 executable" << endl;
				}
			}
		}
	}
	closedir(dirEntry);



#endif
}

/** 
Function to traverse through ExeVsE32ImageMap and prepare ExeVsIdData map.

@internalComponent
@released
*/
void DirReader::PrepareExeVsIdMap(void) {  
	if(iExeVsIdData.size() == 0)  {//Is not already prepared
		for(ExeVsE32ImageMap::iterator it = iExeVsE32ImageMap.begin();
		it != iExeVsE32ImageMap.end(); it++) { 
			E32Image* e32Image = it->second;
			IdData* id = new IdData;
			id->iUid = e32Image->iOrigHdr->iUid1;
			id->iDbgFlag = (e32Image->iOrigHdr->iFlags & KImageDebuggable)? true : false;
			TUint aHeaderFmt = E32ImageHeader::HdrFmtFromFlags(e32Image->iOrigHdr->iFlags);
			if (aHeaderFmt >= KImageHdrFmt_V) {
				E32ImageHeaderV* v = e32Image->iHdr;
				id->iSid = v->iS.iSecureId;
				id->iVid = v->iS.iVendorId;
				id->iFileOffset = 0;//Entry read from directory input, has no offset.
			}
			put_item_to_map_2(iExeVsIdData,it->first,id); 
		}
	} 
}

/** 
Function to return ExeVsIdData map.

@internalComponent
@released

@return returns iExeVsIdData.
*/
const ExeVsIdDataMap& DirReader::GetExeVsIdMap() const {
	return iExeVsIdData;
}

/** 
Function responsible to gather dependencies for all the executables using the container iExeVsE32ImageMap.

@internalComponent
@released

@return iImageVsDepList - returns all executable's dependencies
*/
ExeNamesVsDepListMap& DirReader::GatherDependencies() {  
	StringList executables;
	for(ExeVsE32ImageMap::iterator it =  iExeVsE32ImageMap.begin();
	it != iExeVsE32ImageMap.end(); it++) {
		PrepareExeDependencyList(it->second, executables);
		put_item_to_map(iImageVsDepList,it->first, executables);
		executables.clear(); 
	}
	return iImageVsDepList;
}

/** 
Function responsible to prepare the dependency list.

@internalComponent
@released

@param - aE32Image, Using this, can get all the information about the executable
@param - aExecutables, Excutables placed into this list
*/
void DirReader::PrepareExeDependencyList(E32Image* aE32Image, StringList& aExecutables) {
	int count = 0;
	char** names = aE32Image->GetImportExecutableNames(count); 
	for(int i = 0; i < count; ++i) { 
		aExecutables.push_back(names[i]);
	}
	if(names){
		delete [](reinterpret_cast<long*>(names));
	}
}

/** 
Function to identify the given path as file or directory

@internalComponent
@released

@param - aStr, path name
@return - retuns the either Directory, file or Unknown.
*/
EImageType DirReader::EntryType(string& aStr) {	
	int pos = aStr.length() - 1;
	if(pos < 0)
		return EUnknownImage;
	char ch = aStr.at(pos);
	if(ch == SLASH_CHAR1 || ch == SLASH_CHAR2) {
		aStr.erase(pos,1);
	} 
#ifdef WIN32 
	struct _finddata_t  finder;
	int retVal = _findfirst(aStr.c_str(), &finder);
	if(retVal > 0) {//No error 
		if(finder.attrib & _A_SUBDIR) {
#else//__LINUX__
	struct stat fileEntrybuf;
	int retVal = stat(aStr.c_str(), &fileEntrybuf);
	if(retVal >= 0) {
		if(S_ISDIR(fileEntrybuf.st_mode)) {


#endif
			return EE32Directoy;
		}
		else {
			if(E32Reader::IsE32Image(aStr.c_str()) == true) {
				return EE32File;
			}
		}
	}

	return EE32InputNotExist;
}
