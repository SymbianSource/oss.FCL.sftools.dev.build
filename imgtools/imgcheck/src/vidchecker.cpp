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
* VidChecker class is to 
* 1. extract all VIDs from all executables present in ROM/ROFS sections.
* 2. Validate them.
* 3. Put the validated data into Reporter class Instance.
*
*/


/**
 @file
 @internalComponent
 @released
*/
#include "vidchecker.h"

/** 
Constructor intializes the iVidValList member.

@internalComponent
@released

@param aCmdPtr - pointer to an processed CmdLineHandler object
@param aImageReaderList - List of ImageReader insatance pointers
*/
VidChecker::VidChecker(CmdLineHandler* aCmdPtr, ImageReaderPtrList& aImageReaderList)
:Checker(aCmdPtr, aImageReaderList) {
	iVidValList = iCmdLine->VidValueList();
	iVidValList.push_back(KDefaultVid);
}

/**
Destructor

@internalComponent
@released
*/
VidChecker::~VidChecker() {
	iVidValList.clear();
}

/**
Fucntion responsible to Prepare the ROM and ROFS image VID data

@internalComponent
@released

@param ImgVsExeStatus - Global integrated container which contains image, exes and attribute value status.
*/
void VidChecker::Check(ImgVsExeStatus& aImgVsExeStatus) {  	
	int readerCount = iImageReaderList.size();
	for(int i = 0 ; i < readerCount ; i++ ) {
		ImageReader* imageReader = iImageReaderList.at(i);
		const char* imageName = imageReader->ImageName();
		ExceptionReporter(GATHERINGIDDATA, KVid ,imageName).Log();
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
		for(ExeVsIdDataMap::iterator it = exeVsIdDataMap.begin(); 
		it != exeVsIdDataMap.end(); it++) {
			ExeVsMetaData::iterator i = p->find(it->first);
			if(i == p->end()){
				ExeContainer container;
				container.iExeName = it->first;
				container.iIdData = it->second ;
				put_item_to_map(*p,it->first,container);
			}
			else if(i->second.iIdData == KNull){				
				i->second.iExeName = it->first;
				i->second.iIdData = it->second ;
			}  
		}
		 
	}
}

/**
Function responsible to Validate and write the VID data into Reporter.

@internalComponent
@released

@param aExeContainer - Global integrated container which contains all the attribute, values and the status.
*/
void VidChecker::PrepareAndWriteData(ExeContainer& aExeContainer) {
	ExeAttribute* exeAtt = KNull;
	
	IdData* idData = KNull;

	idData = aExeContainer.iIdData;
	exeAtt = new ExeAttribute;
	if(!exeAtt) {
		throw ExceptionReporter(NOMEMORY, __FILE__, __LINE__);
	}
	exeAtt->iAttName = KVid;
	exeAtt->iAttValue = Common::IntToString(idData->iVid);
	if(!iNoCheck) {
		FillExeVidStatus(idData);
		exeAtt->iAttStatus = idData->iVidStatus;
	}
	else {
		exeAtt->iAttStatus = KNull;
	}
	if(iAllExecutables || (exeAtt->iAttStatus == KInValid) || iNoCheck) {
		aExeContainer.iExeAttList.push_back(exeAtt);
	}
}

/**
Function responsible to Validate the executble VID.
1. Compare the executable VID with all the iVidValList entries, if any one of the
comparison is success then the VID status is Valid.
2. Otherwise Invalid.

@internalComponent
@released

@param aIdData - Executable's IdData data instance.
*/
void VidChecker::FillExeVidStatus(IdData* aIdData) {
	aIdData->iVidStatus.assign(KInValid); 
	for(UnIntList::iterator it = iVidValList.begin(); 
		it != iVidValList.end(); it++) {
		if(*it == aIdData->iVid) {
			aIdData->iVidStatus.assign(KValid);
			break;
		} 
	}
}
