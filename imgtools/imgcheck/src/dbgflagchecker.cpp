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
* DbgFlagChecker class is to 
* 1. extract all Debuggable flag from all executables present in ROM/ROFS sections.
* 2. Validate them.
* 3. Put the validated data into Reporter class Instance.
*
*/


/**
 @file
 @internalComponent
 @released
*/
#include "dbgflagchecker.h"

/** 
Constructor intializes the iDbgFlag member.

@internalComponent
@released

@param aCmdPtr - pointer to an processed CmdLineHandler object
@param aImageReaderList - List of ImageReader insatance pointers
*/
DbgFlagChecker::DbgFlagChecker(CmdLineHandler* aCmdPtr, ImageReaderPtrList& aImageReaderList)
:Checker(aCmdPtr, aImageReaderList) {
	iUserDefinedDbgFlag = iCmdLine->DebuggableFlagVal();
}

/**
Destructor

@internalComponent
@released
*/
DbgFlagChecker::~DbgFlagChecker() {
}

/**
Fucntion responsible to Prepare the E32 executables Debuggable flag data

@internalComponent
@released

@param ImgVsExeStatus - Global integrated container which contains image, exes and attribute value status.
*/
void DbgFlagChecker::Check(ImgVsExeStatus& aImgVsExeStatus) { 
	 
	int readerCount = iImageReaderList.size();
	for(int i = 0 ; i < readerCount ; i++) {
		ImageReader* reader = iImageReaderList.at(i);
		const char* imageName = reader->ImageName();
		ExceptionReporter(GATHERINGIDDATA, KDbgFlag,imageName).Log();
		reader->PrepareExeVsIdMap();
		
		ExeVsIdDataMap& exeVsIdDataMap = const_cast<ExeVsIdDataMap&>(reader->GetExeVsIdMap()); 
		ImgVsExeStatus::iterator pos = aImgVsExeStatus.find(imageName);
		ExeVsMetaData* p = 0;
		if(pos == aImgVsExeStatus.end()){
			p = new ExeVsMetaData();
			put_item_to_map(aImgVsExeStatus,imageName,p);
		}
		else
			p = pos->second ;
		for(ExeVsIdDataMap::iterator it = exeVsIdDataMap.begin();
		it != exeVsIdDataMap.end(); it++ ) {			 
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
Function responsible to Validate and write the debuggable flag data into Reporter.

@internalComponent
@released

@param aExeContainer - Global integrated container which contains all the attribute, values and the status.
*/
void DbgFlagChecker::PrepareAndWriteData(ExeContainer& aExeContainer) {
	ExeAttribute* exeAtt = KNull;
	IdData* idData = KNull;
	
	idData = aExeContainer.iIdData;
	exeAtt = new ExeAttribute;
	if(!exeAtt) {
		throw ExceptionReporter(NOMEMORY, __FILE__, __LINE__);
	}
	exeAtt->iAttName = KDbgFlag;
	exeAtt->iAttValue = (idData->iDbgFlag)? string("true") : string("false");
	if(!iNoCheck) {
		idData->iDbgFlagStatus = (iUserDefinedDbgFlag == idData->iDbgFlag) ? KDbgMatching : KDbgNotMatching;
		exeAtt->iAttStatus = idData->iDbgFlagStatus;		
	}
	else {
		exeAtt->iAttStatus = KNull;
	}
	if(iAllExecutables || (exeAtt->iAttStatus == KDbgNotMatching) || iNoCheck) {
		aExeContainer.iExeAttList.push_back(exeAtt);
	}
}
