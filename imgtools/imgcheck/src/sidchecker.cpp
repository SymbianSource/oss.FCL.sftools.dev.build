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
:Checker(aCmdPtr, aImageReaderList) {
	iSidAll = (iCmdLine->ReportFlag() & KSidAll) ? true : false;
	iE32Mode = (iCmdLine->ReportFlag() & KE32Input) ? true : false;
}

/**
Destructor

@internalComponent
@released
*/
SidChecker::~SidChecker() {
	iSidVsExeMap.clear();
}

/**
Function responsible to Prepare the ROM and ROFS image SID data

@internalComponent
@released

@param ImgVsExeStatus - Global integrated container which contains image, exes and attribute value status.
*/
void SidChecker::Check(ImgVsExeStatus& aImgVsExeStatus) {  
 
	int readerCount = iImageReaderList.size();
	for(int i = 0 ; i < readerCount ; i++) {
		ImageReader* imageReader = iImageReaderList.at(i);
		const char* imageName = imageReader->ImageName();
		ExceptionReporter(GATHERINGIDDATA, KSid,imageName).Log();
		imageReader->PrepareExeVsIdMap();

		ExeVsIdDataMap& exeVsIdDataMap = const_cast<ExeVsIdDataMap&>(imageReader->GetExeVsIdMap());
		ImgVsExeStatus::iterator pos = aImgVsExeStatus.find(imageName);
		ExeVsMetaData* p = 0;
		if(pos == aImgVsExeStatus.end()){
			p = new ExeVsMetaData();
			put_item_to_map(aImgVsExeStatus,imageName,p);
		}
		else
			p = pos->second ; 
		 
		for(ExeVsIdDataMap::iterator it = exeVsIdDataMap.begin()
			;it != exeVsIdDataMap.end(); it++) {
			ExeVsMetaData::iterator i = p->find(it->first);
			if(i == p->end()){
				ExeContainer container;
				container.iExeName = it->first;
				container.iIdData = KNull ;
				i = put_item_to_map(*p,it->first,container);
			}
			if(i->second.iIdData == KNull){
				if(!iSidAll) {
					if(ReaderUtil::IsExe(&it->second->iUid)) {
						iSidVsExeMap.insert(
							pair<unsigned long, string>(it->second->iSid, it->first)
							); 
					}
				}
				else {
					iSidVsExeMap.insert(
							pair<unsigned long, string>(it->second->iSid, it->first)
							); 
				}
				i->second.iIdData = it->second;
				i->second.iExeName = it->first; 
			}
		}		 
	}
}

/**
Function responsible to Validate and write the SID data into reporter.

@internalComponent
@released

@param aExeContainer - Global integrated container which contains all the attribute, values and the status.
*/
void SidChecker::PrepareAndWriteData(ExeContainer& aExeContainer) {
	if(!iSidAll) {
		/**This map is used to find the uniqueness of the SID, instead of traversing through 
		the iImgVsExeStatus again and again to get all Executables SID*/
		if(ReaderUtil::IsExe(&aExeContainer.iIdData->iUid)) {
			FillExeAttribute(aExeContainer);
		}
	}
	else {
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
void SidChecker::FillExeSidStatus(ExeContainer& aExeContainer) {
	SidVsExeMap::iterator sidIter;
	unsigned int cnt = iSidVsExeMap.count(aExeContainer.iIdData->iSid);
	if(cnt > 1) {//Is More than one SID exists? 
		sidIter = iSidVsExeMap.find(aExeContainer.iIdData->iSid);
		while(cnt > 0) {
			if( aExeContainer.iExeName != sidIter->second) {
				aExeContainer.iIdData->iSidStatus = KDuplicate;

				if(!iE32Mode) {
					unsigned int offset = GetExecutableOffset(sidIter->second.c_str());
					if(aExeContainer.iIdData->iFileOffset == offset) {
						aExeContainer.iIdData->iSidStatus = KUniqueAlias;	
						break;
					}
				}
			}
			--cnt;
			++sidIter;
		}
	}
	else {
		aExeContainer.iIdData->iSidStatus = KUnique;
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
const unsigned int SidChecker::GetExecutableOffset(const char* aExeName) {
	Reporter* reporter = Reporter::Instance(iCmdLine->ReportFlag());
	ImgVsExeStatus& aImgVsExeStatus = reporter->GetContainerReference();	 

	for(ImgVsExeStatus::iterator it = aImgVsExeStatus.begin();
		it != aImgVsExeStatus.end() ; it++) {
		ExeVsMetaData* exeVsMetaData = it->second; 
		for(ExeVsMetaData::iterator i = exeVsMetaData->begin();
			i != exeVsMetaData->end() ; i++) {
			if(i->second.iExeName == aExeName  ) {
				return (i->second).iIdData->iFileOffset;
			} 
		} 
	}
	return 0;
}

/**
Function responsible fill up the exe attribute list

@internalComponent
@released

@param aExeContainer - Global integrated container which contains all the attribute, values and the status.
*/
void SidChecker::FillExeAttribute(ExeContainer& aExeContainer) {
	ExeAttribute* exeAtt = KNull;

	exeAtt = new ExeAttribute;
	if(!exeAtt) {
		throw ExceptionReporter(NOMEMORY, __FILE__, __LINE__);
	}

	exeAtt->iAttName = KSid;
	exeAtt->iAttValue = Common::IntToString(aExeContainer.iIdData->iSid);
	if(!iNoCheck) {
		FillExeSidStatus(aExeContainer);
		exeAtt->iAttStatus = aExeContainer.iIdData->iSidStatus;
	}
	else {
		exeAtt->iAttStatus = KNull;
	}
	if((iAllExecutables 
		|| (exeAtt->iAttStatus == KDuplicate)) && !exeAtt->iAttStatus.empty() 
		|| iNoCheck) {
			aExeContainer.iExeAttList.push_back(exeAtt);
	}
}
