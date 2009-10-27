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

#ifdef __LINUX__
#include <dirent.h>
#include <sys/stat.h>
#else
#include <io.h>
#include <direct.h>
#endif

#define MAXPATHLEN 255

/** 
Constructor.

@internalComponent
@released
*/
DirReader::DirReader(char* aDirName)
:ImageReader(aDirName)
{
}

/** 
Destructor.

@internalComponent
@released
*/
DirReader::~DirReader(void)
{
	ExeVsE32ImageMap::iterator begin = iExeVsE32ImageMap.begin();
	ExeVsE32ImageMap::iterator end = iExeVsE32ImageMap.end();
	while(begin != end)
	{
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
bool DirReader::IsExecutable(String aName)
{
	unsigned int strPos = aName.find_last_of('.');
	if(strPos != String::npos)
	{
		aName = aName.substr(strPos);
		if(aName.length() <= 4)
		{
			ReaderUtil::ToLower(aName);
			if (aName.find(".exe") != String::npos || aName.find(".dll") != String::npos ||
				aName.find(".prt") != String::npos || aName.find(".nif") != String::npos ||
				aName.find(".pdl") != String::npos || aName.find(".csy") != String::npos || 
				aName.find(".agt") != String::npos || aName.find(".ani") != String::npos || 
				aName.find(".loc") != String::npos || aName.find(".drv") != String::npos || 
				aName.find(".pdd") != String::npos || aName.find(".ldd") != String::npos ||
				aName.find(".tsy") != String::npos || aName.find(".fsy") != String::npos ||
				aName.find(".fxt") != String::npos)
			{
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
void DirReader::ReadImage(void)
{
}

/** 
Function to 
1. Preserve the present working directory
2. Invoke the function which reads the directory entires recursively.
3. Go back to the original directory.

@internalComponent
@released
*/
void DirReader::ProcessImage()
{
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
void DirReader::ReadDir(String aPath)
{
	int handle;
	int retVal = 0; 
	E32Image* e32Image = KNull;

#ifdef __LINUX__
	DIR* dirEntry = opendir( aPath.c_str());
	static struct dirent* dirPtr;
	while ((dirPtr= readdir(dirEntry)) != NULL)
	{
		if ((strcmp(dirPtr->d_name, KChildDir.c_str()) == 0) || 
			(strcmp(dirPtr->d_name, KParentDir.c_str()) == 0)) 
			continue; // current dir || parent dir

		String fullName( aPath + "/" + dirPtr->d_name );
		
		struct stat fileEntrybuf;
		int retVal = stat((char*)fullName.c_str(), &fileEntrybuf);
		if(retVal >= 0)
		{
			if(S_ISDIR(fileEntrybuf.st_mode)) //Is Directory?
			{
				ReadDir(fullName);
			}
			else if(S_ISREG(fileEntrybuf.st_mode)) //Is regular file?
			{
				if ((fileEntrybuf.st_blksize > 0) && IsExecutable(String(dirPtr->d_name)) && E32Image::IsE32ImageFile((char*)fullName.c_str()))
				{
					iExeAvailable = true;
					e32Image = new E32Image();
					Ifstream inputStream((char*)fullName.c_str(), Ios::binary | Ios::in);
					inputStream.seekg(0, Ios::end);
					TUint32 aSz = inputStream.tellg();
					inputStream.seekg(0, Ios::beg);
					e32Image->iFileSize=aSz;
					e32Image->Adjust(aSz);
					inputStream >> *e32Image;
					String exeName(dirPtr->d_name);
					ReaderUtil::ToLower(exeName);
					if(iExeVsE32ImageMap.find(exeName) != iExeVsE32ImageMap.end())
					{
						cout << "Warning: "<< "Duplicate entry '" << dirPtr->d_name << " '"<< endl;
						continue;
					}
					iExeVsE32ImageMap.insert(std::make_pair(exeName, e32Image));
					iExecutableList.push_back(exeName);
				}
				else
				{
					cout << "Warning: "<< dirPtr->d_name << " is not a valid E32 executable" << endl;
				}
			}
		}
	}
	closedir(dirEntry);

#else
	retVal = chdir(aPath.c_str());
	struct _finddata_t  finder;
	handle = _findfirst("*.*", &finder);
	while (retVal == 0)
	{
		if ((strcmp(finder.name, KChildDir.c_str()) == 0) || 
			(strcmp(finder.name, KParentDir.c_str()) == 0) ) // current dir || parent dir  
		{
			retVal = _findnext(handle, &finder);
			continue;
		}

		if (finder.attrib & _A_SUBDIR)
		{
			ReadDir(finder.name);
			chdir(KParentDir.c_str());
		}
		else
		{
			if ((finder.size > 0) && IsExecutable(String(finder.name)) && E32Image::IsE32ImageFile(finder.name))
			{
				e32Image = new E32Image();
				Ifstream inputStream(finder.name, Ios::binary | Ios::in);
				iExeAvailable = true;
				e32Image->iFileSize=finder.size;
				e32Image->Adjust(finder.size);
				inputStream >> *e32Image;
				String exeName(finder.name);
				ReaderUtil::ToLower(exeName);
				if(iExeVsE32ImageMap.find(exeName) != iExeVsE32ImageMap.end())
				{
					cout << "Warning: "<< "Duplicate entry '" << finder.name << " '"<< endl;
					retVal = _findnext(handle, &finder);
					continue;
				}
				iExeVsE32ImageMap.insert(std::make_pair(exeName, e32Image));
				iExecutableList.push_back(exeName);
			}
			else
			{
				cout << "Warning: "<< finder.name << " is not a valid E32 executable" << endl;
			}
		}
		retVal = _findnext(handle,&finder);
	}
#endif
}

/** 
Function to traverse through ExeVsE32ImageMap and prepare ExeVsIdData map.

@internalComponent
@released
*/
void DirReader::PrepareExeVsIdMap(void)
{
	ExeVsE32ImageMap::iterator begin = iExeVsE32ImageMap.begin();
	ExeVsE32ImageMap::iterator end = iExeVsE32ImageMap.end();
	String exeName;
	E32Image* e32Image = KNull;
	IdData* id = KNull;
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
				id->iFileOffset = 0;//Entry read from directory input, has no offset.
			}
			iExeVsIdData[exeName] = id;
			++begin;
		}
	}
	id = KNull;
}

/** 
Function to return ExeVsIdData map.

@internalComponent
@released

@return returns iExeVsIdData.
*/
const ExeVsIdDataMap& DirReader::GetExeVsIdMap() const
{
	return iExeVsIdData;
}

/** 
Function responsible to gather dependencies for all the executables using the container iExeVsE32ImageMap.

@internalComponent
@released

@return iImageVsDepList - returns all executable's dependencies
*/
ExeNamesVsDepListMap& DirReader::GatherDependencies()
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

@internalComponent
@released

@param - aE32Image, Using this, can get all the information about the executable
@param - aExecutableList, Excutables placed into this list
*/
void DirReader::PrepareExeDependencyList(E32Image* aE32Image, StringList& aExecutableList)
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
Function to identify the given path as file or directory

@internalComponent
@released

@param - aStr, path name
@return - retuns the either Directory, file or Unknown.
*/
EImageType DirReader::EntryType(char* aStr)
{
	int strLength = strlen(aStr);
	if(aStr[strLength - 1] == '\\' || aStr[strLength - 1] == '/')
	{
		aStr[strLength - 1] = KNull;
	}
	int retVal = 0;
	#ifdef __LINUX__
		struct stat fileEntrybuf;
		retVal = stat(aStr, &fileEntrybuf);
		if(retVal >= 0)
		{
			if(S_ISDIR(fileEntrybuf.st_mode))
			{
	#else
		struct _finddata_t  finder;
		retVal = _findfirst(aStr, &finder);
		if(retVal > 0) //No error
		{
			if(finder.attrib & _A_SUBDIR)
			{
	#endif
				return EE32Directoy;
			}
			else
			{
				if(E32Reader::IsE32Image(aStr) == true)
				{
					return EE32File;
				}
			}
		}

	return EE32InputNotExist;
}
