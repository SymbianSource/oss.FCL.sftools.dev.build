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
#ifndef __FAT_IMAGE_GENERATER_HEADER__
#define __FAT_IMAGE_GENERATER_HEADER__

#include "fatdefines.h"

#include <iostream>
#include <list>
#include <fstream>
using namespace std ;
const unsigned int KBufferedIOBytes = 0x800000 ; // 8M 
const unsigned int KMaxClusterBytes = 0x8000; // 32K
enum TSupportedFatType {
	EFatUnknown = 0,
	EFat16 = 1,
	EFat32 = 2
};
 
class TFSNode;
class TFatCluster;
typedef list<TFatCluster*> PFatClusterList ;
typedef list<TFatCluster*>::iterator Interator ;

class TFatImgGenerator
{
public :
	//The constructor ,
	//a TFatImgGenerator is created and initialized,
	//if the parameters breaks the FAT specification,
	// then iType is set to EFatUnknown and thus
	// IsValid return false
	TFatImgGenerator(TSupportedFatType aType , ConfigurableFatAttributes& aAttr  );
	~TFatImgGenerator();
	inline bool IsValid() const { return (EFatUnknown != iType);}
	
	//Create the FAT image, 
	//If FAT image is not valid, or error accurs, return false
	bool Execute(TFSNode* aRootDir , const char* aOutputFile);
protected :
	void InitAsFat16(TUint32 aTotalSectors, TUint16 aBytsPerSec);
	void InitAsFat32(TUint32 aTotalSectors, TUint16 aBytsPerSec);
	bool PrepareClusters(TUint& aNextClusIndex,TFSNode* aNode);
	TSupportedFatType iType ;
	char* iFatTable ; 
	TUint iFatTableBytes ;  
	TUint iTotalClusters ;	
	TUint iBytsPerClus ;
	TFATBootSector iBootSector ;
	TFAT32BSExt iFat32Ext ;
	TFATHeader iFatHeader ;	
	PFatClusterList iDataClusters ;
};


#endif
