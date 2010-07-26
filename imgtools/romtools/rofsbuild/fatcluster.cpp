/*
* Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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
#include "fatcluster.h"
#include <string.h> 
#include <iostream>
#include <new>

TFatCluster::TFatCluster(int aIndex,int aActClustCnt/* = 1*/) :iIndex(aIndex), iActualClusterCount(aActClustCnt), 
iSize(0) ,iData(0),iFileName(0),iLazy(true){  
}

TFatCluster::~TFatCluster() {
	if(iData) 
		delete []iData ;
	if(iFileName)
		delete []iFileName;
}

 
bool TFatCluster::Init(TUint aSize) {
	if(iData == 0){
		iData = reinterpret_cast<TUint8*>(new(std::nothrow) char[aSize]);
		if(iData == 0)
			return false ;
		memset(iData,0,aSize);
		iSize = aSize ;
		iLazy = false ;
		return true ;
	}
	return false ;
}
bool TFatCluster::LazyInit(const char* aFileName,TUint aFileSize){
	if(iFileName == 0){		
		int len = strlen(aFileName) + 1;
		iFileName = new(std::nothrow) char[len] ;
		if(iFileName == 0)
			return false ;
		iLazy = true ; 
		memcpy(iFileName,aFileName,len);
		iSize = aFileSize ;
	}
	return false;
}
