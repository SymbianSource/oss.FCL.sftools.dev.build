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

#include "imagereader.h"
#include "romreader.h"
#include "rofsreader.h"

#include <time.h>
#include <boost/filesystem.hpp> 
using namespace boost::filesystem;
/** 
Constructor intializes the input stream.

@internalComponent
@released

@param aFile - image file name
*/
ImageReader::ImageReader(const char* aFile)
:iImgFileName(aFile), iImageSize(0), iExeAvailable(false) {
}

/** 
Destructor closes the input stream

@internalComponent
@released
*/
ImageReader::~ImageReader() {   
	 for(ExeVsIdDataMap::iterator it = iExeVsIdData.begin();
		it != iExeVsIdData.end(); it++) { 
		if(it->second){		 
			delete it->second ;
			it->second = 0 ;
		}
	}
	iHiddenExeList.clear();
	iExecutableList.clear();
	iImageVsDepList.clear(); 
}

/** 
Function responsible to identify the image type

@internalComponent
@released

@param aImageName - image filename
*/
EImageType ImageReader::ReadImageType(const string aImageName) {
	const char* imageName = aImageName.c_str();
	if(!exists(imageName)){
		cout << "Error: ROM\\ROFS image not found."<< endl;
		exit(EXIT_FAILURE);
	}
	ifstream aIfs(imageName, ios_base::in | ios_base::binary);
	if(!aIfs) {
		cout << "Error: " << "Cannot open file: " << imageName << endl;
		exit(EXIT_FAILURE);
	}
	EImageType imgType = EUnknownImage;
	char* aMagicW = new char[1024];
	aIfs.read(aMagicW, 1024);
	aIfs.close();
	string magicWord(aMagicW, 1024);
	if(aMagicW != NULL)
		delete [] aMagicW;
	aMagicW = 0;

	if(RofsReader::IsRofsImage(magicWord)) {
		imgType = ERofsImage;        
	}
	else if(RofsReader::IsRofsExtImage(magicWord)) {
		imgType = ERofsExImage;
	}
	else if (RomReader::IsRomImage(magicWord)) {
		imgType = ERomImage;
	}
	else if(RomReader::IsRomExtImage(magicWord)) {
		imgType = ERomExImage;
	}
	return imgType;
}

/** 
Dummy function.

@internalComponent
@released
*/
void ImageReader::PrepareExecutableList() {
}

/** 
Function responsible to return the executable list

@internalComponent
@released

@return iExecutableList - returns all executable names present in the image
*/
const StringList& ImageReader::GetExecutableList() const {
	return iExecutableList;
}

/** 
Function responsible to return the Hidden executables list

@internalComponent
@released

@return iHiddenExeList - returns all hidden executable names present in the image
*/
const StringList& ImageReader::GetHiddenExeList() const {
	return iHiddenExeList;
}

/** 
Function responsible to return the image name which is under process

@internalComponent
@released

@return iImgFileName - the image name which is under process
*/
const char* ImageReader::ImageName() const {
	return iImgFileName.c_str();
}

/** 
Function responsible to identify the executable presence.

@internalComponent
@released

@return true - Executable is present
false - Executable is not present
*/
bool ImageReader::ExecutableAvailable() {
	return iExeAvailable;
}
