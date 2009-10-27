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
RofsReader::RofsReader(char* aFile, EImageType aImageType)
:ImageReader(aFile), iImageType(aImageType)
{
	iImageReader = new RCoreImageReader(aFile);
	iImage = new RofsImage(iImageReader);
	iInputStream.open(aFile, Ios::binary | Ios::in);
}

/** 
Destructor deletes the class pointer members.

@internalComponent
@released
*/
RofsReader::~RofsReader()
{
	ExeVsE32ImageMap::iterator e32ImageBegin = iExeVsE32ImageMap.begin();
    ExeVsE32ImageMap::iterator e32ImageEnd  = iExeVsE32ImageMap.end();
	while(e32ImageBegin != e32ImageEnd)
	{
		DELETE(e32ImageBegin->second);
		++e32ImageBegin;
	}
	iRootDirEntry->Destroy();
	iExeVsOffsetMap.clear();
	DELETE(iImageReader);
	iInputStream.close();
	iExeVsE32ImageMap.clear();
}

/** 
Dummy function for compatibility

@internalComponent
@released
*/
void RofsReader::ReadImage()
{
}

/** 
Function responsible to 
1. Invoke E32Imagefile process method which will read the header part and identifies the 
   compression method.
2. Prepare executable vs E32Image map, which will be used later to read the E32Image contents.

@internalComponent
@released
*/
void RofsReader::ProcessImage()
{
	int retVal = iImage->ProcessImage();
	if(retVal != KErrNone)
	{
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
bool RofsReader::IsExecutable(String aName)
{
	unsigned int extOffset = aName.find_last_of('.');
	if(extOffset != String::npos)
	{
		aName = aName.substr(extOffset);
		if(aName.length() <= 4)
		{
			ReaderUtil::ToLower(aName);
			if (aName.find(".exe") != String::npos || aName.find(".dll") != String::npos || 
				aName.find(".prt") != String::npos || aName.find(".nif") != String::npos || 
				aName.find(".tsy") != String::npos || aName.find(".pdl") != String::npos || 
				aName.find(".csy") != String::npos || aName.find(".agt") != String::npos || 
				aName.find(".ani") != String::npos || aName.find(".loc") != String::npos || 
				aName.find(".pdd") != String::npos || aName.find(".ldd") != String::npos ||
				aName.find(".drv") != String::npos) 
			{
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
void RofsReader::PrepareExeVsE32ImageMap(TRomNode* aEntry, CCoreImage *aImage, EImageType aImageType, Ifstream& aInputStream, ExeVsE32ImageMap& aExeVsE32ImageMap, ExeVsOffsetMap& aExeVsOffsetMap, StringList& aHiddenExeList)
{
    String name((char*)aEntry->iName);
	bool insideRofs = false;
    E32Image* e32Image;
    if(IsExecutable(name))
    {
		iExeAvailable = true;
		//V9.1 images has hidden file offset as 0x0
		//V9.2 to V9.6 has hidden file offset as 0xFFFFFFFFF
        if(aEntry->iEntry->iFileOffset != KFileHidden && aEntry->iEntry->iFileOffset != KFileHidden_9_1)
        {
            long fileOffset = 0;
            if(aImageType == ERofsExImage)
            {
				if(aEntry->iEntry->iFileOffset > (long)((RofsImage*)aImage)->iAdjustment)
				{
	            // File exists in Rofs extension 
		            fileOffset = aEntry->iEntry->iFileOffset - ((RofsImage*)aImage)->iAdjustment;
				}
				else
				{
					insideRofs = true;
				}
            }
            else
            {
	            // For rofs files
	            fileOffset = aEntry->iEntry->iFileOffset;
            }
	            
            aInputStream.seekg(fileOffset, Ios::beg);
            /*
            Due to the complexities involved in sending the physical file size to E32Reader class, 
            here we avoided using it for gathering dependencies. Hence class E32ImageFile is used
            directly.
            */
            e32Image = new E32Image();
            e32Image->iFileSize = aEntry->iSize;
            e32Image->Adjust(aEntry->iSize); //Initialise the data pointer to the file size
            aInputStream >> *e32Image; //Input the E32 file to E32ImageFile class
            aExeVsOffsetMap[ReaderUtil::ToLower(name)] = fileOffset;
			if(!insideRofs)
			{
				aExeVsE32ImageMap.insert(std::make_pair(ReaderUtil::ToLower(name), e32Image));
			}
        }
        else
        {
            aHiddenExeList.push_back(ReaderUtil::ToLower(name));
        }
    }

    if(aEntry->Currentchild())
    {
        PrepareExeVsE32ImageMap(aEntry->Currentchild(), aImage, aImageType, aInputStream, aExeVsE32ImageMap, aExeVsOffsetMap, aHiddenExeList);
    }
    if(aEntry->Currentsibling())
    {
        PrepareExeVsE32ImageMap(aEntry->Currentsibling(), aImage, aImageType, aInputStream, aExeVsE32ImageMap, aExeVsOffsetMap, aHiddenExeList);
    }
}

/** 
Function responsible to the executable lists using the container iExeVsE32ImageMap.

@internalComponent
@released
*/
void RofsReader::PrepareExecutableList()
{
    ExeVsE32ImageMap::iterator e32ImageBegin = iExeVsE32ImageMap.begin();
    ExeVsE32ImageMap::iterator e32ImageEnd  = iExeVsE32ImageMap.end();
    E32Image* entry;
    String name;
    while(e32ImageBegin != e32ImageEnd)
    {
        entry = e32ImageBegin->second;
        name = e32ImageBegin->first;
        iExecutableList.push_back(name);
        ++e32ImageBegin;
    }
	DeleteHiddenExecutableVsE32ImageEntry();
}

/** 
Function responsible to delete the hidden executable nodes, in order to
avoid the dependency data collection for the same.

@internalComponent
@released
*/
void RofsReader::DeleteHiddenExecutableVsE32ImageEntry()
{
	StringList::iterator hExeBegin = iHiddenExeList.begin();
	StringList::iterator hExeEnd = iHiddenExeList.end();
	ExeVsE32ImageMap::iterator loc;

	while(hExeBegin != hExeEnd)
	{
		//Remove the hidden executable entry from executables vs RomNode Map
		loc = iExeVsE32ImageMap.find(*hExeBegin);
		if(loc != iExeVsE32ImageMap.end())
		{
			iExeVsE32ImageMap.erase(loc);
		}
		++hExeBegin;
	}
}

/** 
Function responsible to gather dependencies for all the executables using the container iExeVsE32ImageMap.

@internalComponent
@released

@return iImageVsDepList - returns all executable's dependencies
*/
ExeNamesVsDepListMap& RofsReader::GatherDependencies()
{
	ExeVsE32ImageMap::iterator begin = iExeVsE32ImageMap.begin();
	ExeVsE32ImageMap::iterator end = iExeVsE32ImageMap.end();

	StringList executableList;
	while(begin != end)
	{
		PrepareExeDependencyList((*begin).second, executableList);
		iImageVsDepList.insert(std::make_pair((*begin).first, executableList));
		executableList.clear();
		++begin;
	}
	return iImageVsDepList;
}

/** 
Function responsible to prepare the dependency list.
This function can handle ROFS and ROFS extension images.

@internalComponent
@released

@param - aE32Image, Using this, can get all the information about the executable
@param - aExecutableList, Excutables placed into this list
*/
void RofsReader::PrepareExeDependencyList(E32Image* aE32Image, StringList& aExecutableList)
{
	int count = 0;
	char** nameList = aE32Image->GetImportExecutableNames(count);
	int i = 0;
	String dependency;
	for(; i < count; ++i)
	{
		dependency.assign(nameList[i]);
		aExecutableList.push_back(ReaderUtil::ToLower(dependency));
	}
	DELETE(nameList);
}

/** 
Function responsible to say whether it is an ROFS image or not.

@internalComponent
@released

@param - aWord which has the identifier string
*/
bool RofsReader::IsRofsImage(String& aWord)
{
	if(aWord.find(KRofsImageIdentifier) == 0) //Identifier should start at the beginning
	{
		return true;
	}
	return false;
}

/** 
Function responsible to say whether it is an ROFS extension image or not.

@internalComponent
@released

@param - aWord which has the identifier string
*/
bool RofsReader::IsRofsExtImage(String& aWord)
{
	if(aWord.find(KRofsExtImageIdentifier) == 0) //Identifier should start at the beginning
	{
		return true;
	}
	return false;
}

/** 
Function responsible to traverse through the the map using the container iExeVsE32ImageMap to collect 
iExeVsIdData.

@internalComponent
@released
*/
void RofsReader::PrepareExeVsIdMap()
{
    ExeVsE32ImageMap::iterator begin = iExeVsE32ImageMap.begin();
    ExeVsE32ImageMap::iterator end = iExeVsE32ImageMap.end();
    String exeName;
    E32Image* e32Image;
    IdData* id;
    if(iExeVsIdData.size() == 0) //Is not already prepared
    {
        while(begin != end)
        {
            exeName = begin->first;
            e32Image = begin->second;
			id = new IdData;
			id->iUid = e32Image->iOrigHdr->iUid1;
			id->iDbgFlag = (e32Image->iOrigHdr->iFlags & KImageDebuggable)? true : false;
            TUint aHeaderFmt = E32ImageHeader::HdrFmtFromFlags(e32Image->iOrigHdr->iFlags);
	        if (aHeaderFmt >= KImageHdrFmt_V)
	        {
                E32ImageHeaderV* v = e32Image->iHdr;
                id->iSid = v->iS.iSecureId;
                id->iVid = v->iS.iVendorId;
	        }
			id->iFileOffset = iExeVsOffsetMap[exeName];
			iExeVsIdData[exeName] = id;
            ++begin;
        }
    }
	id = KNull;
}

/** 
Function responsible to return the Executable versus IdData container. 

@internalComponent
@released

@return - returns iExeVsIdData
*/
const ExeVsIdDataMap& RofsReader::GetExeVsIdMap() const
{
    return iExeVsIdData;
}
