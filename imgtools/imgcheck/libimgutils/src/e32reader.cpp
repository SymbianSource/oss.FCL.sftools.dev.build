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

#include "e32reader.h"
#include <f32image.h>

/** 
Constructor.

@internalComponent
@released
*/
E32Image::E32Image()
:E32ImageFile()
{
}

/** 
Destructor.

@internalComponent
@released
*/
E32Image::~E32Image()
{
}

/** 
Function responsible to read the import section of an e32 image and return the dependency names.

@internalComponent
@released

@param aCount - Number of imports found

@return - returns the two dimensional 
*/
char** E32Image::GetImportExecutableNames(int& aCount)
{
	const E32ImportSection* isection = (const E32ImportSection*)(iData + iOrigHdr->iImportOffset);
	const E32ImportBlock* impBlock = (const E32ImportBlock*)(isection + 1);

	char** nameList = (char**)malloc(iOrigHdr->iDllRefTableCount * sizeof(char*));

	aCount = iOrigHdr->iDllRefTableCount;

	for (int d = 0; d < iOrigHdr->iDllRefTableCount; ++d)
		{
			char* dllname = iData + iOrigHdr->iImportOffset + impBlock->iOffsetOfDllName;
			char* curlyStart = strchr(dllname, '{');
			char* dotStart = strrchr(dllname, '.');
			
			dllname[curlyStart - dllname] = '\0';
			strcat(dllname,dotStart);
			
			nameList[d] = dllname;
			TUint impfmt = iOrigHdr->ImportFormat();
			impBlock = impBlock->NextBlock(impfmt); //Get next import block
		}
	return nameList;	
}

/** 
Constructor intializes the class pointer members.

@internalComponent
@released

@param aImageName - image file name
*/
E32Reader::E32Reader(char* aImageName)
:ImageReader(aImageName)
{
	iInputStream.open(iImgFileName.c_str(), Ios::binary | Ios::in);
	int fwdSlashOff = iImgFileName.find_last_of('/');
	int bwdSlashOff = iImgFileName.find_last_of('\\');
	int exeNameOff = (fwdSlashOff > bwdSlashOff) ? fwdSlashOff : bwdSlashOff;
	iExeName = iImgFileName.substr(exeNameOff + 1);
}

/** 
Destructor deletes the class pointer members.

@internalComponent
@released
*/
E32Reader::~E32Reader()
{
	iInputStream.close();
	DELETE(iE32Image);
}

/** 
Function responsible to say whether it is an e32 image or not.

@internalComponent
@released

@param aImage - e32 image
*/
bool E32Reader::IsE32Image(char* aFile)
{
	if(E32Image::IsE32ImageFile(aFile))
		return true;
	return false;
}

/** 
Funtion to read the whole e32 image file and write the contents into iData memeber

@internalComponent
@released
*/
void E32Reader::ReadImage()
{
	if( !iInputStream.is_open() )
	{
		cerr << "Error: " << "Can not open file" << iImgFileName.c_str() << endl;
		exit(EXIT_FAILURE);
	}
	iE32Image = new E32Image();
	iInputStream.seekg(0, Ios::end);
	TUint32 aSz = iInputStream.tellg();
	iInputStream.seekg(0, Ios::beg);
	iE32Image->Adjust(aSz);
	iE32Image->iFileSize = aSz;
}

/** 
Function responsible to read the E32 image and put the data into E32ImageFile object.
It is achieved using the operator >> overloaded function.

@internalComponent
@released
*/
void E32Reader::ProcessImage()
{
	iInputStream >> *iE32Image;
	iExeAvailable = true;
}

/** 
Function responsible to gather dependencies for one e32 image.

@internalComponent
@released

@return iExeNamesVsDepListMap - returns all executable's dependencies
*/
ExeNamesVsDepListMap& E32Reader::GatherDependencies()
{
	int count=0;
	char** nameList = iE32Image->GetImportExecutableNames(count);
	int i = 0;
	for(; i < count; ++i)
	{
		iDependencyList.push_back(String(nameList[i]));
	}
	iImageVsDepList.insert(std::make_pair(iExeName, iDependencyList));
	return iImageVsDepList;
}

/** 
Function responsible to return the dependency list of an e32 image.

@internalComponent
@released

@return iDependencyList - returns all executable's dependencies
*/
const StringList& E32Reader::GetDependencyList()
{
	return iDependencyList;
}

/** 
Function responsible prepare the ExeVsId map.

@internalComponent
@released
*/
void E32Reader::PrepareExeVsIdMap()
{
	IdData* id;
	if(iExeVsIdData.size() == 0) //Is not already prepared
	{
		id = new IdData;
		id->iUid = iE32Image->iOrigHdr->iUid1;
		id->iDbgFlag = (iE32Image->iOrigHdr->iFlags & KImageDebuggable)? true : false;
		TUint aHeaderFmt = E32ImageHeader::HdrFmtFromFlags(iE32Image->iOrigHdr->iFlags);
		if (aHeaderFmt >= KImageHdrFmt_V)
		{
			E32ImageHeaderV* v = iE32Image->iHdr;
			id->iSid = v->iS.iSecureId;
			id->iVid = v->iS.iVendorId;
		}
		id->iFileOffset = 0;
		iExeVsIdData[iExeName] = id;
	}
	id = KNull;
}

/** 
Function responsible to return the Executable versus IdData container. 

@internalComponent
@released

@return - returns iExeVsIdData
*/
const ExeVsIdDataMap& E32Reader::GetExeVsIdMap() const
{
	return iExeVsIdData;
}
