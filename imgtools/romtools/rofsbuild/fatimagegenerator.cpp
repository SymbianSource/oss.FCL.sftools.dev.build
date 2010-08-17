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
#include "fatimagegenerator.h"
#include "fatcluster.h"
#include "fsnode.h"
#include "h_utl.h"

#include <memory.h>
#include <time.h>
#include <iostream>
#include <fstream>
#include <iomanip>
using namespace std;

const TInt KCharsOfCmdWndLine = 80 ;
const TInt KRootEntryCount = 0x200;
const TInt KRootClusterIndex = 0;

TFatImgGenerator::TFatImgGenerator(TSupportedFatType aType ,ConfigurableFatAttributes& aAttr ) :
iType(aType),
iFatTable(0),
iFatTableBytes(0), 
iTotalClusters(0),	
iBytsPerClus(aAttr.iDriveClusterSize)
{
	memset(&iBootSector,0,sizeof(iBootSector));
	memset(&iFat32Ext,0,sizeof(iFat32Ext));
	memset(&iFatHeader,0,sizeof(iFatHeader));
	
	if(iBytsPerClus != 0){
		if(iBytsPerClus > KMaxClusterBytes){
			Print(EError,"Cluster size is too large!\n");
			iType = EFatUnknown;
			return ;
		}else if(iBytsPerClus < aAttr.iDriveSectorSize){
			Print(EError,"Cluster size cannot be smaller than sector size (%d)!\n", aAttr.iDriveSectorSize);
			iType = EFatUnknown;
			return ;
		}else{
			TUint32 tempSectorSize = aAttr.iDriveSectorSize;
			while (tempSectorSize < iBytsPerClus){
				tempSectorSize <<=1;
			}
			if (tempSectorSize > iBytsPerClus){
				Print(EError,"Cluster size should be (power of 2)*(sector size) i.e. 512, 1024, 2048, 4096, etc!\n");
				iType = EFatUnknown;
				return;
			}
		}
	}
	if(aAttr.iDriveSectorSize != 512 && aAttr.iDriveSectorSize != 1024 && aAttr.iDriveSectorSize != 2048 && aAttr.iDriveSectorSize != 4096) {
		Print(EError,"Sector size must be one of (512, 1024, 2048, 4096)!\n");
		iType = EFatUnknown ;
		return ;
	}
	*((TUint32*)iBootSector.BS_jmpBoot) = 0x00905AEB ; 
	memcpy(iBootSector.BS_OEMName,"SYMBIAN ",8);
	*((TUint16 *)iBootSector.BPB_BytsPerSec) = aAttr.iDriveSectorSize;
	
	iBootSector.BPB_NumFATs = aAttr.iDriveNoOfFATs;
	iBootSector.BPB_Media = 0xF8 ;
	iFatHeader.BS_DrvNum = 0x80 ;
	iFatHeader.BS_BootSig = 0x29 ;

	time_t rawtime;
	time(&rawtime);
	*((TUint32*)iFatHeader.BS_VolID) = (TUint32)rawtime;
	memcpy(iFatHeader.BS_VolLab,aAttr.iDriveVolumeLabel,sizeof(iFatHeader.BS_VolLab));
	if(aAttr.iImageSize == 0){
		if(aType == EFat32)
			aAttr.iImageSize = 0x100000000LL ;// 4G
		else
			aAttr.iImageSize = 0x40000000LL ; // 1G 
	}

	TUint32 totalSectors = (TUint32)((aAttr.iImageSize + aAttr.iDriveSectorSize - 1) / aAttr.iDriveSectorSize);
	if(aType == EFat32) {
		InitAsFat32(totalSectors,aAttr.iDriveSectorSize);
	}
	else if(aType == EFat16) {
		InitAsFat16(totalSectors,aAttr.iDriveSectorSize); 
	}
	if(iType == EFatUnknown) return ;
	iBytsPerClus = iBootSector.BPB_SecPerClus * aAttr.iDriveSectorSize;

}
TFatImgGenerator::~TFatImgGenerator() {
	if(iFatTable)
		delete []iFatTable;  
	Interator it = iDataClusters.begin();
	while(it != iDataClusters.end()){
		TFatCluster* cluster = *it ;
		delete cluster;
		it++;
	}
}

void TFatImgGenerator::InitAsFat16(TUint32 aTotalSectors,TUint16 aBytsPerSec){
	
	TUint32 numOfClusters ;
	TUint8 aSecPerClus = iBytsPerClus / aBytsPerSec;
	if(aSecPerClus == 0) {
		//Auto-calc the SecPerClus
		// FAT32 ,Count of clusters must >= 4085 and < 65525 , however , to avoid the "off by xx" warning, 
		// proprositional value >= (4085 + 16) && < (65525 - 16)
		if(aTotalSectors < (4085 + 16)) { //when SecPerClus is 1, numOfClusters eq to aTotalSectors
			iType = EFatUnknown ;
			Print(EError,"Size is too small for FAT16, please set a bigger size !\n");
			return ;
		}
		TUint8 secPerClusMax = KMaxClusterBytes / aBytsPerSec; 
		numOfClusters = (aTotalSectors + secPerClusMax - 1) / secPerClusMax ; 
		if(numOfClusters >= (65525 - 16)) { // too big 
			iType = EFatUnknown ;
			Print(EError,"Size is too big for FAT16, please use the FAT32 format!\n");
			return ;
		}
		
		aSecPerClus = 1;
		while(aSecPerClus < secPerClusMax){
			numOfClusters = (aTotalSectors + aSecPerClus - 1) / aSecPerClus ;
			if (numOfClusters >= (4085 + 16) && numOfClusters < (65525 - 16)) {
				break;
			}
			aSecPerClus <<= 1 ; 
		}	
	}
	else {
		numOfClusters = (aTotalSectors + aSecPerClus - 1) / aSecPerClus;
		if(numOfClusters >= (65525 - 16)){
      Print(EError,"Cluster count is too big for FAT16, please use the FAT32 format or set a new bigger cluster size!\n");
			iType = EFatUnknown ;
			return ;
		}
		else if(numOfClusters < (4085 + 16)){
      Print(EError,"Cluster count is too small for FAT16, please set a new smaller cluster size or set the image size bigger!\n");
			iType = EFatUnknown ;
			return ;
		}

	}
	iTotalClusters = (aTotalSectors + aSecPerClus - 1) / aSecPerClus ;
	iFatTableBytes = ((iTotalClusters << 1) +  aBytsPerSec - 1) & (~(aBytsPerSec - 1)); 
	iFatTable = new(std::nothrow) char[iFatTableBytes];
	if(!iFatTable) {
        Print(EError,"Memory allocation failed for FAT16 Table!\n");
		iType = EFatUnknown ;
		return ;
	}
	memset(iFatTable,0,iFatTableBytes);
	*((TUint32*)iFatTable) = 0xFFFFFFF8 ; 
	iBootSector.BPB_SecPerClus = aSecPerClus;
	*((TUint16*)iBootSector.BPB_RsvdSecCnt) = 0x0001 ;
	*((TUint16*)iBootSector.BPB_RootEntCnt) = KRootEntryCount ;
	if(aTotalSectors > 0xFFFF)
		*((TUint32*)iBootSector.BPB_TotSec32) = aTotalSectors; 
	else
		*((TUint16*)iBootSector.BPB_TotSec16) = (TUint16)aTotalSectors; 
	TUint16 sectorsForFAT = (TUint16)((iFatTableBytes + aBytsPerSec - 1) / aBytsPerSec);
	*((TUint16*)iBootSector.BPB_FATSz16) =  sectorsForFAT ; 
	memcpy(iFatHeader.BS_FilSysType,"FAT16   ",sizeof(iFatHeader.BS_FilSysType));
}
void TFatImgGenerator::InitAsFat32(TUint32 aTotalSectors,TUint16 aBytsPerSec) { 
	
	TUint32 numOfClusters;
	TUint8 aSecPerClus = iBytsPerClus / aBytsPerSec;
	if(aSecPerClus == 0) {
		//Auto-calc the SecPerClus
		// FAT32 ,Count of clusters must >= 65525, however , to avoid the "off by xx" warning, 
		// proprositional value >= (65525 + 16)			
		if(aTotalSectors < (65525 + 16)) { //when SecPerClus is 1, numOfClusters eq to aTotalSectors
			iType = EFatUnknown ;
			Print(EError,"Size is too small for FAT32, please use the FAT16 format, or set the data size bigger!\n");
			return ;
		}

		TUint8 secPerClusMax = KMaxClusterBytes / aBytsPerSec; 
		aSecPerClus = secPerClusMax;
		while(aSecPerClus > 1){
			numOfClusters = (aTotalSectors + aSecPerClus - 1) / aSecPerClus ;
			if (numOfClusters >= (65525 + 16)) {
				break;
			}
			aSecPerClus >>= 1 ; 
		}	
	}
	else {
		numOfClusters = (aTotalSectors + aSecPerClus - 1) / aSecPerClus;
		if(numOfClusters < (65525 + 16)) {
            Print(EError,"Cluster count is too small for FAT32, please set a new smaller cluster size or set the image size bigger or use the FAT16 format!\n");
			iType = EFatUnknown ;
			return ;
		}

	}
	iTotalClusters = (aTotalSectors + aSecPerClus - 1) / aSecPerClus ;
	iFatTableBytes = ((iTotalClusters << 2) +  aBytsPerSec - 1) & (~(aBytsPerSec - 1));
	iFatTable = new(std::nothrow) char[iFatTableBytes];
	if(!iFatTable) {
        Print(EError,"Memory allocation failed for FAT32 Table!\n");
		iType = EFatUnknown ;
		return ;
	}
	memset(iFatTable,0,iFatTableBytes);
	TUint32* fat32table = reinterpret_cast<TUint32*>(iFatTable);
	fat32table[0] = 0x0FFFFFF8 ;
	fat32table[1] = 0x0FFFFFFF ;  
	iBootSector.BPB_SecPerClus = aSecPerClus;
	iBootSector.BPB_RsvdSecCnt[0] = 0x20 ;
	*((TUint32*)iBootSector.BPB_TotSec32) = aTotalSectors; 
	*((TUint32*)iFat32Ext.BPB_FATSz32) =  (iFatTableBytes + aBytsPerSec - 1) / aBytsPerSec; 
	*((TUint32*)iFat32Ext.BPB_RootClus) = 2 ; 
	*((TUint16*)iFat32Ext.BPB_FSInfo) = 1 ;
	*((TUint16*)iFat32Ext.BPB_BkBootSec) = 6 ;
	memcpy(iFatHeader.BS_FilSysType,"FAT32   ",sizeof(iFatHeader.BS_FilSysType));
}

bool TFatImgGenerator::Execute(TFSNode* aRootDir , const char* aOutputFile){
	if(EFatUnknown == iType)
		return false ;	
	ofstream o(aOutputFile,ios_base::binary + ios_base::out + ios_base::trunc);
	TUint32 writtenBytes = 0 ;
	if(!o.is_open()) {
  	Print(EError,"Can not open \"%s\" for writing !\n",aOutputFile) ;
		return false;
	}
	TUint16 bytsPerSector = *((TUint16*)iBootSector.BPB_BytsPerSec);
	Interator it = iDataClusters.begin();
	while(it != iDataClusters.end()){
		TFatCluster* cluster = *it ;
		delete cluster;
		it++;
	}
	iDataClusters.clear();
	Print(EAlways,"Filesystem ready.\nWriting Header...");
	
	if(EFat16 == iType){		 
		char* header = new(std::nothrow) char[bytsPerSector];
		if(!header){
      Print(EError,"Can not allocate memory for FAT16 header!\n");
			o.close();
			return false ;
		}
		int offset = 0;
		memcpy(header,&iBootSector,sizeof(iBootSector));
		offset = sizeof(iBootSector);
		memcpy(&header[offset],&iFatHeader,sizeof(iFatHeader));
		offset += sizeof(iFatHeader);
		memset(&header[offset],0,bytsPerSector - offset);
		*((TUint16*)(&header[510])) = 0xAA55 ;

		o.write(header,bytsPerSector); 
		writtenBytes +=  bytsPerSector;
		delete []header ;		 
		TUint16 rootDirSectors = (KRootEntryCount * 32) / bytsPerSector ;
		TUint16 rootDirClusters = (rootDirSectors + iBootSector.BPB_SecPerClus - 1) /iBootSector.BPB_SecPerClus;		 
		TUint32 rootDirBytes = KRootEntryCount * 32;
		TFatCluster* rootDir = new(std::nothrow) TFatCluster(0,rootDirClusters);
		rootDir->Init(rootDirBytes);
		iDataClusters.push_back(rootDir);
		aRootDir->WriteDirEntries(KRootClusterIndex,rootDir->GetData());
		 
		TUint index = 2 ;
		Print(EAlways,"    OK.\nPreparing cluster list..."); 
		TFSNode* child = aRootDir->GetFirstChild() ; 
		while(child){
			if(!PrepareClusters(index,child)){
                Print(EAlways,"    Failed.\nError:Image size is expected to be big enough for all the files.\n");
				return false ;
			}
			child = child->GetSibling() ;
		}
	}
	else if(EFat32 == iType){

		TUint headerSize = ( bytsPerSector << 5 ); // 32 reserved sectors for fat32
		char* header = new(std::nothrow) char[headerSize];
		if(!header){
            Print(EError,"Can not allocate memory for FAT32 header!\n");
			o.close();
			return false ;
		}
		memset(header,0,headerSize);

		int offset = 0;
		memcpy(header,&iBootSector,sizeof(iBootSector));
		offset = sizeof(iBootSector);
		memcpy(&header[offset],&iFat32Ext,sizeof(iFat32Ext));
		offset += sizeof(iFat32Ext);
		memcpy(&header[offset],&iFatHeader,sizeof(iFatHeader));
		offset += sizeof(iFatHeader);

		TFAT32FSInfoSector* fsinfo = reinterpret_cast<TFAT32FSInfoSector*>(&header[bytsPerSector]);
		*((TUint32*)fsinfo->FSI_LeadSig) = 0x41615252 ;
		*((TUint32*)fsinfo->FSI_StrucSig) = 0x61417272 ;
		memset(fsinfo->FSI_Free_Count,0xFF,8);
		char* tailed = header + 510 ;
		for(int i = 0 ; i < 32 ; i++ , tailed += bytsPerSector )
			*((TUint16*)tailed) = 0xAA55 ;		
		 
		TUint index = 2 ;		
		Print(EAlways,"    OK.\nPreparing cluster list...");
		if(!PrepareClusters(index,aRootDir)) {
            Print(EAlways,"    Failed.\nERROR: Image size is expected to be big enough for all the files.\n");
			delete []header ;
			return false;
		}
	 
 
		*(TUint32*)(fsinfo->FSI_Free_Count) = iTotalClusters - index + 3;
		*(TUint32*)(fsinfo->FSI_Nxt_Free) =  index ;

		// write bakup boot sectors
		memcpy(&header[bytsPerSector * 6],header,(bytsPerSector << 1));
		o.write(header,headerSize); 
		writtenBytes += headerSize;
		delete []header ;
	}
	//iDataClusters.sort();
	it = iDataClusters.end() ;
	it -- ;
	int clusters = (*it)->GetIndex() + (*it)->ActualClusterCount() - 1;

	Print(EAlways,"    OK.\n%d clusters of data need to be written.\nWriting Fat table...",clusters);
	for(TUint8 w = 0 ; w < iBootSector.BPB_NumFATs ; w++){
		o.write(iFatTable,iFatTableBytes);	 
		if(o.bad() || o.fail()){
			Print(EAlways,"\nERROR:Writting failed. Please check the filesystem\n");
			delete []iFatTable,
			o.close();
			return false ;
		}
		writtenBytes += iFatTableBytes;
	}
	char* buffer = new(std::nothrow) char[KBufferedIOBytes];
	if(!buffer){
    Print(EError,"Can not allocate memory for I/O buffer !\n");
		o.close();
		return false ;
	}
	o.flush();
	Print(EAlways,"    OK.\nWriting clusters data...");
 
	int bytesInBuffer = 0;
	int writeTimes = 24; 
 
	TFatCluster* lastClust = 0 ;	
	for(it = iDataClusters.begin(); it != iDataClusters.end() ; it++ ){
		TFatCluster* cluster = *it ;
		TUint fileSize = cluster->GetSize(); 		 
		TUint toProcess = cluster->ActualClusterCount() * iBytsPerClus ; 
		if(toProcess > KBufferedIOBytes){ // big file 
			if(bytesInBuffer > 0){
				o.write(buffer,bytesInBuffer); 
				if(o.bad() || o.fail()){
					Print(EError,"Writting failed.\n");
					delete []buffer,
					o.close();
					return false ;
				}
				writtenBytes += bytesInBuffer;
				bytesInBuffer = 0;
				Print(EAlways,".");
				writeTimes ++ ;
				if((writeTimes % KCharsOfCmdWndLine) == 0){
					o.flush();
					cout << endl ;
				} 
			}
			if(cluster->IsLazy()){
				ifstream ifs(cluster->GetFileName(), ios_base::binary + ios_base::in);
				if(!ifs.is_open()){
					Print(EError,"Can not open file \"%s\"\n",cluster->GetFileName()) ;
					o.close();
					delete []buffer;
					return false ;
				}
				if(!ifs.good()) ifs.clear(); 
				TUint processedBytes = 0 ; 

				while(processedBytes < 	fileSize){
					TUint ioBytes = fileSize - processedBytes ;
					if(ioBytes > KBufferedIOBytes)
						ioBytes = KBufferedIOBytes;
					ifs.read(buffer,ioBytes);
					processedBytes += ioBytes;					 
					o.write(buffer,ioBytes); 
					if(o.bad() || o.fail()){
						Print(EError,"Writting failed.\n");
						delete []iFatTable,
						o.close();
						return false ;
					}
					writtenBytes += ioBytes;
					Print(EAlways,".");
					writeTimes ++ ;
					if((writeTimes % KCharsOfCmdWndLine) == 0){
						o.flush();
						Print(EAlways,"\n") ;
					}

				}
				TUint paddingBytes = toProcess - processedBytes;
				if( paddingBytes > 0 ){
					memset(buffer,0,paddingBytes);
					o.write(buffer,paddingBytes);
					if(o.bad() || o.fail()){
						Print(EError,"Writting failed.\n");
						delete []buffer,
						o.close();
						return false ;
					}
					writtenBytes += paddingBytes;
				}
				ifs.close();

			}
			else {
				// impossible 
        Print(EError,"Unexpected result!\n");
				o.close();
				delete []buffer;
				return false ;
			}
		}
		else {
			if(toProcess > (KBufferedIOBytes - bytesInBuffer)){
				o.write(buffer,bytesInBuffer); 
				if(o.bad() || o.fail()){
					Print(EError,"Writting failed.\n");
					delete []buffer,
					o.close();
					return false ;
				}
				writtenBytes += bytesInBuffer;
				Print(EAlways,".");
				writeTimes ++ ;
				if((writeTimes % KCharsOfCmdWndLine) == 0){
					o.flush();
					cout  << endl ;
				}
				bytesInBuffer = 0;
			}
			if(cluster->IsLazy()){
				ifstream ifs(cluster->GetFileName(), ios_base::binary + ios_base::in);
				if(!ifs.is_open()){
				    Print(EError,"Can not open file \"%s\"\n",cluster->GetFileName()) ;
					o.close();
					delete []buffer;
					return false ;
				}
				if(!ifs.good()) ifs.clear(); 
				ifs.read(&buffer[bytesInBuffer],fileSize);
				bytesInBuffer += fileSize;
				if(toProcess > fileSize) { // fill padding bytes 
					memset(&buffer[bytesInBuffer],0,toProcess - fileSize);
					bytesInBuffer += (toProcess - fileSize);
				}
				ifs.close();

			}
			else{
				if(toProcess != cluster->GetSize() && cluster->GetIndex() != KRootClusterIndex){
        	Print(EError,"Unexpected size!\n");
					o.close();
					delete []buffer;
					return false ;
				}
				memcpy(&buffer[bytesInBuffer],cluster->GetData(),cluster->GetSize());
				bytesInBuffer += cluster->GetSize();
			}

		} 
		lastClust = cluster ;	 

	}
	if(bytesInBuffer > 0){
		o.write(buffer,bytesInBuffer);
		if(o.bad() || o.fail()){
			Print(EError,"Writting failed.\n");
			delete []buffer,
			o.close();
			return false ;
		}
		writtenBytes += bytesInBuffer;
		o.flush();
	}
	Print(EAlways,"\nDone.\n\n");
	o.close();

	return true ;
}
bool TFatImgGenerator::PrepareClusters(TUint& aNextClusIndex,TFSNode* aNode) { 
	TUint sizeOfItem = aNode->GetSize();
	TUint clusters = (sizeOfItem + iBytsPerClus - 1) / iBytsPerClus;
	
	if(iTotalClusters < aNextClusIndex + clusters)
		return false ;
		
	TUint16* fat16Table = reinterpret_cast<TUint16*>(iFatTable);
	TUint32* fat32Table = reinterpret_cast<TUint32*>(iFatTable);	 
	 
	for(TUint i = aNextClusIndex + clusters - 1 ; i > aNextClusIndex  ; i--){
		if(iType == EFat16)
			fat16Table[i - 1] = i ;
		else
			fat32Table[i - 1] = i ;
	}
	if(iType == EFat16)
		fat16Table[aNextClusIndex + clusters - 1] = 0xffff ;
	else
		fat32Table[aNextClusIndex + clusters - 1] = 0x0fffffff ;
		
	TFatCluster* cluster = new TFatCluster(aNextClusIndex,clusters);
	if(aNode->IsDirectory()) {
    TUint bytes = clusters * iBytsPerClus ;
		cluster->Init(bytes);
		aNode->WriteDirEntries(aNextClusIndex,cluster->GetData());
	}
	else {
		cluster->LazyInit(aNode->GetPCSideName(),sizeOfItem);
		aNode->WriteDirEntries(aNextClusIndex,NULL);
	}
	iDataClusters.push_back(cluster);
 
	aNextClusIndex += clusters;
	if(aNode->GetFirstChild()){
		if(!PrepareClusters(aNextClusIndex,aNode->GetFirstChild()))
			return false ;
	}
	if(aNode->GetSibling()){
		if(!PrepareClusters(aNextClusIndex,aNode->GetSibling()))
			return false;
	}
	return true ;
}
