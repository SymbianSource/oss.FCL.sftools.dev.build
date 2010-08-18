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
* DepChecker class is responsible to Validate the dependencies existence and put the  
* prepared data into Reporter.
*
*/


/**
@file
@internalComponent
@released
*/

#include "depchecker.h"

/** 
Constructor intializes the iHashPtr and iHiddenExeHashPtr members.

@internalComponent
@released

@param aCmdInput - pointer to a processed CmdLineHandler object
@param aImageReaderList - List of ImageReader insatance pointers
*/
DepChecker::DepChecker(CmdLineHandler* aCmdPtr, ImageReaderPtrList& aImageReaderList, bool aNoRomImage) 
:Checker(aCmdPtr, aImageReaderList), iNoRomImage(aNoRomImage) {
	iHashPtr = new HashTable(KHashTableSize); 
	iHiddenExeHashPtr = new HashTable(KHiddenExeHashSize);
}

/** 
Destructor deletes the imagereader objects and hash tables.

@internalComponent
@released
*/
DepChecker::~DepChecker() {
	if(iHiddenExeHashPtr){
		delete iHiddenExeHashPtr;
		iHiddenExeHashPtr = 0 ;
	}
	if(iHashPtr){
		delete iHashPtr ;
		iHashPtr = 0 ;
	}
	iAddressVsExeName.clear();
}

/**
Fucntion responsible to
1. Prepare the ROM and ROFS image executable List
2. Gather Dependencies of all executables present in the ROFS image
3. Prepare the input data for Reporter

@internalComponent
@released

@param ImgVsExeStatus - Global integrated container which contains image, exes and attribute value status.
*/
void DepChecker::Check(ImgVsExeStatus& aImgVsExeStatus) { 
	RomImagePassed();  
	int readerCount = iImageReaderList.size();  
	
	for(int i = 0 ; i < readerCount ; i++){ 
		ImageReader* reader = iImageReaderList.at(i);
		const char* name = reader->ImageName();
		PrepareImageExeList(reader); 
		//Gather dependencies of all the images.
		ExceptionReporter(GATHERINGDEPENDENCIES, name).Log();
		ExeNamesVsDepListMap& depMap = iImageReaderList[i]->GatherDependencies();  
		for(ExeNamesVsDepListMap::iterator it = depMap.begin() ; 
				it != depMap.end() ; it++) { 
			StringList& list = it->second;
			ImgVsExeStatus::iterator pos = aImgVsExeStatus.find(name);
			ExeVsMetaData* p = 0;
			if(pos == aImgVsExeStatus.end()){
				p = new ExeVsMetaData();
				put_item_to_map(aImgVsExeStatus,name,p);
			}
			else
				p = pos->second ;
			ExeContainer container ;
			container.iExeName = it->first ;
			container.iIdData = KNull;
			container.iDepList = list ;
			put_item_to_map(*p,it->first,container);  
		} 
	} 
}

/**
Function responsible to
1. Prepare the ExecutableList
2. Put the received Excutable list into HASH table, this data will be used later 
to identify the dependencies existense.

@internalComponent
@released

@param aImageReader - ImageReader instance pointer.
*/
void DepChecker::PrepareImageExeList(ImageReader* aImageReader) {
	 
	aImageReader->PrepareExecutableList(); 
	const StringList& aExeList = aImageReader->GetExecutableList(); 
	iHashPtr->InsertStringList(aExeList); //Put executable names into Hash 
	/**
	In ROM if any file is hidden then its entry is not placed in the directory 
	section of the image during image building time. But still the entry data is 
	already resolved and ready for xip. So this entry is marked here as Unknown
	Dependency and its status is Hidden.
	*/
	const StringList& hiddenExeList = aImageReader->GetHiddenExeList(); 	 
	iHiddenExeHashPtr->Insert(KUnknownDependency); //ROm Specific and only once 
	iHiddenExeHashPtr->InsertStringList(hiddenExeList); 
	DeleteHiddenExeFromExecutableList(aImageReader, hiddenExeList); 
	const char* imgName = aImageReader->ImageName();
	ExceptionReporter(NOOFEXECUTABLES, imgName, aExeList.size()).Log();
	ExceptionReporter(NOOFHEXECUTABLES, imgName, hiddenExeList.size()).Log();
}

/**
Function responsible to delete the hidden executables from iExecutableList.
In ROFS image, if a file is hidden then its duplicate entry is created to say it is
hidden. But the other entry is already placed in the executable list and it is 
available in iHashPtr Hash table. So this needs to be deleted form iHashPtr, then only
it is possible to get the status "Hidden" for such executables.

@internalComponent
@released

@param aImageReader - ImageReader instance pointer.
@param aHiddenExeList - List containing the hidden exe's.
*/
void DepChecker::DeleteHiddenExeFromExecutableList(ImageReader* /*aImageReader*/, const StringList& aHiddenExeList) {
	for(StringList::const_iterator it = aHiddenExeList.begin(); it != aHiddenExeList.end(); it++){
		iHashPtr->Delete(*it);  
	}
}

/**
Function responsible to prepare the data input for Report Generator.
Traverses through all the images to identify the executables dependency status.

@internalComponent
@released

@param aExeContainer - Global integrated container which contains all the attribute, values and the status.
*/
void DepChecker::PrepareAndWriteData(ExeContainer& aExeContainer) { 
	StringList& depList = aExeContainer.iDepList;  
	for(StringList::iterator it = depList.begin(); it != depList.end(); it++) {
		string status;
		const char* str = it->c_str() ;
		if(!iNoCheck) {			
			CollectDependencyStatus(str, status);
			if(status == KStatusNo) { 
				if(iHiddenExeHashPtr->IsAvailable(str)) { 
					status.assign(KStatusHidden);
				}
			}			 
			//Include only missing dependencies by default
			if(!iAllExecutables && (status != KStatusNo)) {
				continue;
			}
		}
		ExeAttribute* exeAtt = new ExeAttribute();
		if(exeAtt == KNull) {
			throw ExceptionReporter(NOMEMORY, __FILE__, __LINE__);
		}
		exeAtt->iAttName.assign(KDependency);
		exeAtt->iAttValue.assign(str);
		if(!iNoCheck) {
			exeAtt->iAttStatus = status;
		}
		else {
			exeAtt->iAttStatus = KNull;
		}
		aExeContainer.iExeAttList.push_back(exeAtt); 
	}
}

/**
Function responsible to Get the dependency status for one executable at instant.
Check for the existence of executable in the Hash table which is created while
preparing executable list.

@internalComponent
@released

@param aString - Individual dependency name. (input)
@param aStatus - Dependency status.(for output)
*/
void DepChecker::CollectDependencyStatus(const char* aString, string& aStatus) const {
	if(iHashPtr->IsAvailable(aString)) 
		aStatus.assign(KStatusYes);
	else
		aStatus.assign(KStatusNo);
}

/**
Function responsible to display the no rom image warning.
While checking for dependency if ROM image is not passed and only ROFS is passed then 
there is a chance that most of the executables dependencies will not be available.
Hence this warning is raised.

@internalComponent
@released
*/
void DepChecker::RomImagePassed(void) const {
	if(iNoRomImage) {
		ExceptionReporter(NOROMIMAGE).Report();
	}
}
