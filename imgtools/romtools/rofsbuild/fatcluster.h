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
#ifndef __FAT_CLUSTER_HEADER__
#define __FAT_CLUSTER_HEADER__
#include <e32std.h>
class TFatCluster {
public:
	TFatCluster(int aIndex,int aActClustCnt = 1);
	~TFatCluster();
	bool Init(TUint aSize);
	bool LazyInit(const char* aFileName,TUint aFileSize); 
	inline TUint8* GetData() const {return iData ;	}
	inline TUint GetSize() const { return iSize ;}
	inline const char* GetFileName() const { return iFileName ;}
	inline bool IsLazy() const { return iLazy;}
	inline int ActualClusterCount() const { return iActualClusterCount;}
	inline int GetIndex() const { return iIndex ;}
protected:
	int iIndex ; 
	int iActualClusterCount ;
	TUint iSize ; // length of file or size of data
	TUint8* iData ;
	char* iFileName ;	
	bool iLazy ;
};

#endif
