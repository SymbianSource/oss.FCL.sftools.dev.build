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

/** 
Constructor intializes the input stream.

@internalComponent
@released

@param aFile - image file name
*/
ImageReader::ImageReader(const char* aFile)
:iImgFileName(String(aFile)), iImageSize(0), iExeAvailable(false)
{
}

/** 
Destructor closes the input stream

@internalComponent
@released
*/
ImageReader::~ImageReader()
{
    ExeVsIdDataMap::iterator exeBegin = iExeVsIdData.begin();
    ExeVsIdDataMap::iterator exeEnd = iExeVsIdData.end();
    while(exeBegin != exeEnd)
    {
        DELETE(exeBegin->second);
        ++exeBegin;
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
EImageType ImageReader::ReadImageType(const String aImageName)
{
	char* imageName = (char*)aImageName.c_str();
	Ifstream aIfs(imageName, Ios::in | Ios::binary);
	if(!aIfs)
	{
		cout << "Error: " << "Cannot open file: " << imageName << endl;
		exit(EXIT_FAILURE);
	}
	EImageType imgType = EUnknownImage;
	char* aMagicW = new char[1024];
	aIfs.read(aMagicW, 1024);
	aIfs.close();
	String magicWord(aMagicW, 1024);
	if(aMagicW != NULL)
		delete [] aMagicW;
	aMagicW = 0;

	if(RofsReader::IsRofsImage(magicWord))
	{
		imgType = ERofsImage;        
	}
	else if(RofsReader::IsRofsExtImage(magicWord))
	{
		imgType = ERofsExImage;
	}
	else if (RomReader::IsRomImage(magicWord))
	{
		imgType = ERomImage;
	}
	else if(RomReader::IsRomExtImage(magicWord))
	{
		imgType = ERomExImage;
	}
	return imgType;
}

/** 
Dummy function.

@internalComponent
@released
*/
void ImageReader::PrepareExecutableList()
{
}

/** 
Function responsible to return the executable list

@internalComponent
@released

@return iExecutableList - returns all executable names present in the image
*/
const StringList& ImageReader::GetExecutableList() const
{
	return iExecutableList;
}

/** 
Function responsible to return the Hidden executables list

@internalComponent
@released

@return iHiddenExeList - returns all hidden executable names present in the image
*/
const StringList& ImageReader::GetHiddenExeList() const
{
	return iHiddenExeList;
}

/** 
Function responsible to return the image name which is under process

@internalComponent
@released

@return iImgFileName - the image name which is under process
*/
String& ImageReader::ImageName()
{
	return iImgFileName;
}

/** 
Function responsible to identify the executable presence.

@internalComponent
@released

@return true - Executable is present
        false - Executable is not present
*/
bool ImageReader::ExecutableAvailable()
{
	return iExeAvailable;
}
