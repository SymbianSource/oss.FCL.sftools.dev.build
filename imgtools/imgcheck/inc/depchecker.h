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
* DepChecker class declaration
* @internalComponent
* @released
*
*/


#ifndef DEPCHECKER_H
#define DEPCHECKER_H

#include "imgcheckmanager.h"
#include "hash.h"

/** 
Typedefs locally used

@internalComponent
@released
*/
typedef std::map<unsigned int, String> AddressVsExeName;

/**
If multiple images are specified as the input, then this value must be 
high to acheive effective searching

@internalComponent
@released
*/
const int KHashTableSize = 2000; 

/**
The possibilities for more number of hidden files are less, so this 
much size of Hash pointer is more than enough

@internalComponent
@released
*/
const int KHiddenExeHashSize = 100; //Hidden 
/**
class Dependency Checker

@internalComponent
@released
*/
class DepChecker : public Checker
{
public:
	DepChecker(CmdLineHandler* aCmdPtr, ImageReaderPtrList& aImageReaderList, bool aNoRomImage);
	~DepChecker(void);
	void Check(ImgVsExeStatus& aImgVsExeStatus);
	void PrepareAndWriteData(ExeContainer* aExeContainer);
	
private:
	void DeleteHiddenExeFromExecutableList(ImageReader* aImageReader, StringList& aHiddenExeList);
	void CollectDependencyStatus(String& aString, String& aStatus) const;
	void PrepareImageExeList(ImageReader* aImageReader);
	void RomImagePassed(void) const;
	
private:
	AddressVsExeName iAddressVsExeName; //ROM specific
	HashTable* iHashPtr; //Used to search the dependencies effectively
	HashTable* iHiddenExeHashPtr;
	bool iNoRomImage;
};

#endif //DEPCHECKER_H
