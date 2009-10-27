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
* SidChecker class is to 
* 1. extract all SID's from all executables present in ROM/ROFS sections.
* 2. Validate them.
* 3. Put the validated data into Reporter class Instance.
*
*/


/**
 @file
 @internalComponent
 @released
*/
#include "sidchecker.h"

/** 
Constructor.

@internalComponent
@released

@param aCmdPtr - pointer to an processed CmdLineHandler object
@param aImageReaderList - List of ImageReader insatance pointers
*/
SidChecker::SidChecker(CmdLineHandler* aCmdPtr, ImageReaderPtrList& aImageReaderList)
:Checker(aCmdPtr, aImageReaderList)
{
	iSidAll = (iCmdLine->ReportFlag() & KSidAll) ? true : false;
	iE32Mode = (iCmdLine->ReportFlag() & KE32Input) ? true : false;
}

/**
Destructor

@internalComponent
@released
*/
SidChecker::~SidChecker()
{
	iSidVsExeMap.clear();
}

/**
Function responsible to Prepare the ROM and ROFS image SID data

@internalComponent
@released

@param ImgVsExeStatus - Global integrated container which contains image, exes and attribute value status.
*/
void SidChecker::Check(ImgVsExeStatus& aImgVsExeStatus)
{
	ImageReaderPtrList::iterator begin = iImageReaderList.begin();
	ImageReaderPtrList::iterator end = iImageReaderList.end();

	ExeVsIdDataMap::iterator exeBegin;
	ExeVsIdDataMap::iterator exeEnd;
	ExeVsIdDataMap exeVsIdDataMap;
	ImageReader* imageReader = KNull;
	String imageName;
	while(begin != end)
	{
		imageReader = *begin;
		imageName = imageReader->ImageName();
		ExceptionReporter(GATHERINGIDDATA, (char*)KSid.c_str(),(char*)imageName.c_str()).Log();
		imageReader->PrepareExeVsIdMap();
		
		exeVsIdDataMap = imageReader->GetExeVsIdMap();
		exeBegin = exeVsIdDataMap.begin();
		exeEnd = exeVsIdDataMap.end();
		if((aImgVsExeStatus[imageName].size() == 0) 
			|| (aImgVsExeStatus[imageName][exeBegin->first].iIdData == KNull))
		{
			while(exeBegin != exeEnd)
			{
				if(!iSidAll)
				{
					if(ReaderUtil::IsExe(&exeBegin->second->iUid))
					{
						iSidVsExeMap.insert(std::make_pair(exeBegin->second->iSid, exeBegin->first));
					}
				}
				else
				{
					iSidVsExeMap.insert(std::make_pair(exeBegin->second->iSid, exeBegin->first));
				}
 				aImgVsExeStatus[imageName][exeBegin->first].iIdData = exeBegin->second;
				aImgVsExeStatus[imageName][exeBegin->first].iExeName = exeBegin->first;
				++exeBegin;
			}
		}
		++begin;
	}
}

/**
Function responsible to Validate and write the SID data into reporter.

@internalComponent
@released

@param aExeContainer - Global integrated container which contains all the attribute, values and the status.
*/
void SidChecker::PrepareAndWriteData(ExeContainer* aExeContainer)
{
	if(!iSidAll)
	{
		/**This map is used to find the uniqueness of the SID, instead of traversing through 
		the iImgVsExeStatus again and again to get all Executables SID*/
		if(ReaderUtil::IsExe(&aExeContainer->iIdData->iUid))
		{
			FillExeAttribute(aExeContainer);
		}
	}
	else
	{
		FillExeAttribute(aExeContainer);
	}
}

/**
Function responsible to Validate the executble SID.
1. If the SID occurence across all the ROM/ROFS sections is one then the status is Unique.
2. If more than one entry found and those executables Offset in ROM/ROFS section are same 
then its status is Unique(Alias).
3. If those Offsets are differnt, then the status is Duplicate.

@internalComponent
@released

@param aExeContainer - Global integrated container which contains all the attribute, values and the status.
*/
void SidChecker::FillExeSidStatus(ExeContainer* aExeContainer)
{
	SidVsExeMap::iterator sidIter;
	unsigned int cnt = iSidVsExeMap.count(aExeContainer->iIdData->iSid);
	if(cnt > 1) //Is More than one SID exists?
	{
		sidIter = iSidVsExeMap.find(aExeContainer->iIdData->iSid);
		while(cnt > 0)
		{
			if( aExeContainer->iExeName != sidIter->second)
			{
				aExeContainer->iIdData->iSidStatus = KDuplicate;
				
				if(!iE32Mode)
				{
					unsigned int offset = GetExecutableOffset(sidIter->second);
					if(aExeContainer->iIdData->iFileOffset == offset)
					{
						aExeContainer->iIdData->iSidStatus = KUniqueAlias;	
						break;
					}
				}
			}
			--cnt;
			++sidIter;
		}
	}
	else
	{
		aExeContainer->iIdData->iSidStatus = KUnique;
	}
}

/**
Function to get an executable's Offset location.
1. Traverse through all the image entries available in the iImgVsExeStatus container.
2. Get the executable Offset.

@internalComponent
@released

@param aExeName - Executable's name.

@return - returns 0 upon failure to find the Executable.
        - otherwise returns the Offset.
*/
const unsigned int SidChecker::GetExecutableOffset(const String& aExeName)
{
	Reporter* reporter = Reporter::Instance(iCmdLine->ReportFlag());
	ImgVsExeStatus& aImgVsExeStatus = reporter->GetContainerReference();

	ImgVsExeStatus::iterator imgBegin = aImgVsExeStatus.begin();
	ImgVsExeStatus::iterator imgEnd = aImgVsExeStatus.end();

	ExeVsMetaData::iterator exeBegin;
	ExeVsMetaData::iterator exeEnd;
	
	while(imgBegin != imgEnd)
	{
		ExeVsMetaData& exeVsMetaData = imgBegin->second;
		exeBegin = exeVsMetaData.begin();
		exeEnd = exeVsMetaData.end();
		
		while(exeBegin != exeEnd)
		{
			if(aExeName == (exeBegin->second).iExeName)
			{
				return (exeBegin->second).iIdData->iFileOffset;
			}
			++exeBegin;
		}
		++imgBegin;
	}
	return 0;
}

/**
Function responsible fill up the exe attribute list

@internalComponent
@released

@param aExeContainer - Global integrated container which contains all the attribute, values and the status.
*/
void SidChecker::FillExeAttribute(ExeContainer* aExeContainer)
{
	ExeAttribute* exeAtt = KNull;

	exeAtt = new ExeAttribute;
	if(!exeAtt)
	{
		throw ExceptionReporter(NOMEMORY, __FILE__, __LINE__);
	}

	exeAtt->iAttName = KSid;
	exeAtt->iAttValue = Common::IntToString(aExeContainer->iIdData->iSid);
	if(!iNoCheck)
	{
		FillExeSidStatus(aExeContainer);
		exeAtt->iAttStatus = aExeContainer->iIdData->iSidStatus;
	}
	else
	{
		exeAtt->iAttStatus = KNull;
	}
	if((iAllExecutables 
		|| (exeAtt->iAttStatus == KDuplicate)) && !exeAtt->iAttStatus.empty() 
		|| iNoCheck)
	{
		aExeContainer->iExeAttList.push_back(exeAtt);
	}
}
