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
*
*/


/**
@file
@internalComponent
@released
*/

#include "romreader.h"
#include "romfsentry.h"
#include "romimageheader.h"
#include "utf16string.h"
#include  <e32rom.h>
#include  <e32ldr.h>
#include  <iostream>
#include  <algorithm>
#include  <functional>

void InflateUnCompress(unsigned char* source, int sourcesize, unsigned char* dest, int destsize);

/** 
Static variable to mark whether TRomLoaderHeader is present in the ROM image or not.

@internalComponent
@released
*/
bool RomReader::iNoRomLoaderHeader = false;

/** 
Constructor intializes the class pointer members and member variables.

@internalComponent
@released

@param aFile - image file name
@param aImageType - image type
*/
RomReader::RomReader(const char* aFile, EImageType aImgType) 
: ImageReader(aFile), iImageHeader(0), iData(0), iImgType(aImgType) {
	iRomImageRootDirEntry = new RomImageDirEntry("");
}

/** 
Destructor deletes the class pointer members.

@internalComponent
@released
*/
RomReader::~RomReader() {
	if(iData){
		delete [] iData;
		iData = 0 ;
	}
	iRomImageRootDirEntry->Destroy();
	iRomImageRootDirEntry = 0;
	if(iImageHeader){
		delete iImageHeader;
		iImageHeader = 0;
	}
	iRootDirList = 0;
	for(RomAddrVsExeName::iterator it = iAddVsExeMap.begin(); it != iAddVsExeMap.end() ; it++){
		delete (*it).second;
	}
	iAddVsExeMap.clear();
	iExeVsRomFsEntryMap.clear();
}

/** 
Function responsible to read the whole image and assign it to an member

@internalComponent
@released
*/
void RomReader::ReadImage() {
	iInputStream.open(iImgFileName.c_str(), ios_base::binary | ios_base::in);
	if(!iInputStream.is_open()) {
		cout << "Error: " << "Can not open file: " << ImageName() << endl;
		exit(EXIT_FAILURE);
	}
	iInputStream.seekg(0, ios_base::end);
	iImageSize = iInputStream.tellg();
	iData = new unsigned char[iImageSize];
	memset(iData, 0, iImageSize);
	iInputStream.seekg(0, ios_base::beg);
	iInputStream.read((char*)iData, iImageSize);
	iInputStream.close();
}


/** 
Function responsible to return the compression type
Can handle ROM and Extension ROM images.

@internalComponent
@released

@return - returns the compression type
*/
const unsigned long int RomReader::ImageCompressionType() const {
	if(iImageHeader->iRomHdr)
		return iImageHeader->iRomHdr->iCompressionType;
	else
		return iImageHeader->iExtRomHdr->iCompressionType;
}


/** 
Function responsible to return the Rom header pointer address
Can handle ROM and Extension ROM images.

@internalComponent
@released

@return - returns the Rom header pointer address
*/
const char* RomReader::RomHdrPtr() const {
	if(iImageHeader->iRomHdr)
		return (char*)(iImageHeader->iRomHdr);
	else
		return (char*)(iImageHeader->iExtRomHdr);
}


/** 
Function responsible to return the Rom base address in the image
Can handle ROM and Extension ROM images.

@internalComponent
@released

@return - returns the Rom base address
*/
const unsigned long int RomReader::RomBase() const {
	if(iImageHeader->iRomHdr)
		return iImageHeader->iRomHdr->iRomBase ;
	else
		return iImageHeader->iExtRomHdr->iRomBase;
}


/** 
Function responsible to return the Rom root directory list
Can handle ROM and Extension ROM images.

@internalComponent
@released

@return - returns the Rom root directory list
*/
const unsigned long int RomReader::RootDirList() const {
	if(iImageHeader->iRomHdr)
		return iImageHeader->iRomHdr->iRomRootDirectoryList;
	else
		return iImageHeader->iExtRomHdr->iRomRootDirectoryList;
}


/** 
Function responsible to return the Rom header size
Can handle ROM and Extension ROM images.

@internalComponent
@released

@return - returns the Rom header size
*/
const unsigned int RomReader::HdrSize() const {
	if(iImageHeader->iRomHdr) 
		return (sizeof(TRomLoaderHeader) + sizeof(TRomHeader));
	else
		return sizeof(TExtensionRomHeader);
}

/** 
Function responsible to return the Rom image size
Can handle ROM and Extension ROM images.

@internalComponent
@released

@return - returns the Rom Image size
*/
const unsigned int RomReader::ImgSize() const {
	if(ImageCompressionType() == KUidCompressionDeflate) 
		return iImageHeader->iRomHdr->iUncompressedSize;
	else
		return iImageSize;
}

/** 
Function responsible to process the ROM image
1. Read the header.
2. Identify the compression type.
3. If the image is compressed then uncompress and update the image content buffer iData.
4. Build the directory tree by reading all the Rood and subdirectory elements.

@internalComponent
@released
*/
void RomReader::ProcessImage() {
	if(iImageSize > sizeof(TRomLoaderHeader) || iImageSize > sizeof(TExtensionRomHeader)) {
		iImageHeader = new RomImageHeader(reinterpret_cast<char*>(iData), iImgType, iNoRomLoaderHeader);

		if(ImageCompressionType() == KUidCompressionDeflate) {
			unsigned int aDataStart = HdrSize();
			unsigned char* aData = new unsigned char[iImageHeader->iRomHdr->iUncompressedSize + aDataStart];
			InflateUnCompress((iData + aDataStart), iImageHeader->iRomHdr->iCompressedSize, (aData + aDataStart), iImageHeader->iRomHdr->iUncompressedSize);
			memcpy(aData, iData, aDataStart);
			delete [] iData;

			iData = aData;
			//update the header fields...
			if(iImgType == ERomImage) {
				iImageHeader->iLoaderHdr = (TRomLoaderHeader*)iData;
				iImageHeader->iRomHdr = (TRomHeader*)(iData + sizeof(TRomLoaderHeader));
			}
		}
		else if(ImageCompressionType() != 0) {
			cout << "Error: Invalid image: " << ImageName() << endl;
			exit(EXIT_FAILURE);
		}
		else if (iImageHeader->iRomHdr && iImageHeader->iRomHdr->iRomPageIndex)  { // paged ROM
			const int KPageSize = 0x1000;
			TRomHeader *pRomHdr = iImageHeader->iRomHdr;
			unsigned int headerSize = HdrSize();

			TInt numPages = (pRomHdr->iPageableRomStart + pRomHdr->iPageableRomSize+KPageSize-1)/KPageSize;
			unsigned char* aData = new unsigned char[pRomHdr->iUncompressedSize + headerSize];
			unsigned char* dest = aData + sizeof(TRomLoaderHeader) + pRomHdr->iPageableRomStart;
			SRomPageInfo* pi = (SRomPageInfo*)((unsigned char*)pRomHdr + pRomHdr->iRomPageIndex);
			CBytePair bpe;

			for(int i = 0; i < numPages; i++, pi++) {
				if (pi->iPagingAttributes != SRomPageInfo::EPageable) // skip uncompressed part at the beginning of ROM image
					continue;

				switch(pi->iCompressionType) {
				case SRomPageInfo::ENoCompression:
					memcpy(dest, (unsigned char*)pRomHdr + pi->iDataStart, pi->iDataSize);
					dest += pi->iDataSize;
					break;

				case SRomPageInfo::EBytePair: {
					unsigned char* srcNext = 0;
					int unpacked = bpe.Decompress(dest, KPageSize, (unsigned char*)pRomHdr + pi->iDataStart, pi->iDataSize, srcNext);
					if (unpacked  <  0) {
						delete [] aData;
						cout  << "Error:" <<  "Corrupted BytePair compressed ROM image"  <<  endl;
						exit(EXIT_FAILURE);
					}

					dest += unpacked;
					break;
											  }

				default:
					delete [] aData;
					cout  << "Error:" << "Undefined compression type"  <<  endl;
					exit(EXIT_FAILURE);
				}
			}

			memcpy(aData, iData, sizeof(TRomLoaderHeader) + pRomHdr->iPageableRomStart);
			delete [] iData;

			iData = aData;

			//update the header fields...
			if(iImgType == ERomImage) {
				iImageHeader->iLoaderHdr = (TRomLoaderHeader*)iData;
				iImageHeader->iRomHdr = (TRomHeader*)(iData + sizeof(TRomLoaderHeader));
			}
		}

		unsigned long int aOff = RootDirList() - RomBase();
		iRootDirList = (TRomRootDirectoryList*)(RomHdrPtr() + aOff);
		int aDirs = 0;
		TRomDir	*aRomDir;
		while(aDirs  <  iRootDirList->iNumRootDirs) {
			aOff = iRootDirList->iRootDir[aDirs].iAddressLin - RomBase();
			aRomDir = (TRomDir*)(RomHdrPtr() + aOff);

			BuildDir(aRomDir, iRomImageRootDirEntry);
			aDirs++;
		}
	}
	else {
		cout << "Error: " << "Invalid image: " << iImgFileName.c_str() << endl;
		exit(EXIT_FAILURE);
	}
}


/** 
Function responsible to Get Rom directory table

@internalComponent
@released

@param aBase - base poniter
@param aCount - No of entries in the table
@param aRomDir - Current Rom directory.
*/
void RomReader::GetRomDirTbl(short int** aBase, short int& aCount, TRomDir *aRomDir) {
	short int *aSubDirCnt = 0;
	short int *aFileCnt = 0;

	//Sub directories in this directories
	aSubDirCnt = (short int*)((char*)aRomDir + aRomDir->iSize + sizeof(aRomDir->iSize));
	//Files within this directory
	aFileCnt = aSubDirCnt+1;
	aCount = (*aFileCnt + *aSubDirCnt);
	*aBase = aFileCnt+1;
}


/** 
Function responsible to Build directory tree.

@internalComponent
@released

@param aDir - directory
@param aPaFSEntry - Parent RomImageFSEntry
*/
void RomReader::BuildDir(TRomDir* aDir, RomImageFSEntry* aPaFSEntry) {

	short int			*aBase, aCount;

	GetRomDirTbl(&aBase, aCount, aDir);
	/**Images built using option -no-sorted-romfs are compatible with Symbian OS v6.1.
	But imgcheck tool supports only Symbian OS v9.1 to Future versions.
	*/
	if(aCount <= 0) {
		cerr << "Error: Invalid Image " << iImgFileName.c_str() << endl;
		exit(EXIT_FAILURE);
	}
	BuildDir(aBase, aCount, aDir, aPaFSEntry);
}


/** 
Function responsible to add the read directory or file into tree.

@internalComponent
@released

@param aOffsetTbl - Table offset
@param aOffsetTblCount - No of entries in the table
@param aPaRomDir - Parent TRomDir
@param aPaFSEntry - Parent RomImageFSEntry
*/
void RomReader::BuildDir(short int *aOffsetTbl, short int aOffsetTblCount, 
						 TRomDir *aPaRomDir, RomImageFSEntry* aPaFSEntry) {
							 RomImageFSEntry *aNewFSEntry;
							 TRomDir	*aNewDir;
							 TRomEntry *aRomEntry;
							 unsigned long int aOffsetFromBase;
							 unsigned int aOffset;
							 string	aName; 

							 while(aOffsetTblCount--) {
								 aOffsetFromBase = *aOffsetTbl;
								 aOffsetFromBase  <<= 2;
								 aRomEntry = (TRomEntry*)((char*)aPaRomDir + sizeof(int) + aOffsetFromBase);
								 UTF16String unistr(reinterpret_cast<const TUint16*>(aRomEntry->iName),aRomEntry->iNameLength);
								 if(!unistr.ToUTF8(aName))
									 aName.assign(reinterpret_cast<const char*>(aRomEntry->iName),aRomEntry->iNameLength);

								 if(aRomEntry->iAtt & 0x10) {//KEntryAttDir

									 aNewFSEntry = new RomImageDirEntry(const_cast<char*>(aName.c_str()));
									 AddChild(aPaFSEntry, aNewFSEntry, KNull);

									 aOffset = aRomEntry->iAddressLin - RomBase();
									 aNewDir = (TRomDir*)(RomHdrPtr() + aOffset);
									 BuildDir(aNewDir, aNewFSEntry);
								 }
								 else {
									 aNewFSEntry = new RomImageFileEntry((char*)aName.data());
									 AddChild(aPaFSEntry, aNewFSEntry, aRomEntry);
								 }
								 aOffsetTbl++;
							 }
}


/** 
Function responsible to add current entry as child to aPa.

@internalComponent
@released

@param aPa - Parent RomImageFSEntry.
@param aChild - child RomImageFSEntry.
@param aRomEntry - Current entry.
*/

void RomReader::AddChild(RomImageFSEntry *aPa, RomImageFSEntry *aChild, TRomEntry* aRomEntry) {
	if(!aPa->iChildren) {
		aPa->iChildren = aChild;
	}
	else {
		RomImageFSEntry *aLast = aPa->iChildren;
		while(aLast->iSibling)
			aLast = aLast->iSibling;

		aLast->iSibling = aChild;
	}

	if(!aChild->IsDirectory()) {
		TRomImageHeader* aImgHdr;
		unsigned long int aOff;
		RomImageFileEntry* entry = dynamic_cast<RomImageFileEntry*>(aChild);
		entry->iTRomEntryPtr = aRomEntry;
		if(aRomEntry->iAddressLin > RomBase()) {
			aOff = aRomEntry->iAddressLin - RomBase();
			aImgHdr = (TRomImageHeader*)(RomHdrPtr() + aOff);
			entry->ImagePtr.iRomFileEntry = aImgHdr;
			unsigned char aUid1[4];
			memcpy(aUid1, &entry->ImagePtr.iRomFileEntry->iUid1, 4);

			//Skip the E32 executables included as a DATA files in ROM image.
			if(ReaderUtil::IsExecutable(aUid1) && aImgHdr->iCodeAddress > RomBase() && 
				aImgHdr->iCodeAddress < (RomBase() + ImgSize())) {
					iExeAvailable = true;
					entry->iExecutable = true; 
					pair<ExeVsRomFsEntryMap::iterator,bool> ret =
						iExeVsRomFsEntryMap.insert(
							pair<const char*,RomImageFSEntry*>(entry->Name(), aChild));
					if(ret.second == false)
						ret.first->second = aChild ;
						
			}
			else {
				entry->iExecutable = false;
				entry->ImagePtr.iDataFileAddr = aRomEntry->iAddressLin;
			}
		}
		else {
			entry->ImagePtr.iRomFileEntry = KNull;
		}
	}
	if(aPa != iRomImageRootDirEntry) {
		aChild->iPath = aPa->iPath;
		aChild->iPath += KDirSeperaor;
		aChild->iPath += aPa->iName.data();
	}

}


/** 
Function responsible to prepare Executable List by traversing through iExeVsRomFsEntryMap

@internalComponent
@released
*/
void RomReader::PrepareExecutableList() { 
	for (ExeVsRomFsEntryMap::iterator it = iExeVsRomFsEntryMap.begin() ;
		it != iExeVsRomFsEntryMap.end(); it++) { 
		iExecutableList.push_back(it->first); 
	}
}

/** 
Function responsible to create address vs executable map.
Later this address is used as a key to get executable name

@internalComponent
@released
*/
void RomReader::PrepareAddVsExeMap() {
	for (ExeVsRomFsEntryMap::iterator it = iExeVsRomFsEntryMap.begin() ;
		it != iExeVsRomFsEntryMap.end(); it++) { 
		UintVsString* sizeVsExeName = new UintVsString();
		unsigned int address;
		RomImageFileEntry* fileEntry = (RomImageFileEntry*)it->second;
		TRomImageHeader	*aRomImgEntry = fileEntry->ImagePtr.iRomFileEntry;
		const char* name = it->second->Name();
		if(aRomImgEntry != KNull) {
			address = aRomImgEntry->iCodeAddress;
			put_item_to_map(*sizeVsExeName,aRomImgEntry->iCodeSize,name);
		}
		else {
			address = fileEntry->iTRomEntryPtr->iAddressLin;
			put_item_to_map(*sizeVsExeName,fileEntry->iTRomEntryPtr->iSize,name);
		}
		put_item_to_map(iAddVsExeMap,address, sizeVsExeName);
		iImageAddress.push_back(address); 
	}
	sort(iImageAddress.begin(), iImageAddress.end(), greater < unsigned int>());
}

/** 
Function responsible to say whether it is an ROM image or not.

@internalComponent
@released

@param aWord - which has the identifier string
@return - returns true or false.
*/
bool RomReader::IsRomImage(const string& aWord) {
	//Epoc Identifier should start at 0th location, Rom Identifier should start at 8th location
	if((aWord.find(KEpocIdentifier) == 0) && (aWord.find(KRomImageIdentifier) == 8)) {
		return true;
	}
	else {
		iNoRomLoaderHeader = true;
		//TRomLoaderHeader is not present
		TRomHeader *romHdr = (TRomHeader*)aWord.c_str();
		/**If the ROM image is built without TRomLoaderHeaderi, ROM specific identifier will not be available
		hence these two header variables used.*/
		if((romHdr->iRomBase >= KRomBase) && (romHdr->iRomRootDirectoryList > KRomBase) 
			&& (romHdr->iRomBase < KRomBaseMaxLimit) && (romHdr->iRomRootDirectoryList < KRomBaseMaxLimit)) {
				return true;
		}
	}
	return false;
}

/** 
Function responsible to say whether it is an ROM extension image or not.

@internalComponent
@released

@param aWord - which has the identifier string
@return - retruns true or false.
*/
bool RomReader::IsRomExtImage(const string& aWord) {
	if(aWord.at(0) == KNull && aWord.at(1) == KNull &&
		aWord.at(2) == KNull && aWord.at(3) == KNull &&
		aWord.at(4) == KNull && aWord.at(5) == KNull) {
			//Since no specific identifier is present in the ROM Extension image these two header variables used.
			TExtensionRomHeader* romHdr = (TExtensionRomHeader*)aWord.c_str();
			if((romHdr->iRomBase > KRomBase) && (romHdr->iRomRootDirectoryList > KRomBase)
				&& (romHdr->iRomBase < KRomBaseMaxLimit) && (romHdr->iRomRootDirectoryList < KRomBaseMaxLimit)) {
					return true;
			}
	}
	return false;
}

/** 
Function responsible to gather dependencies for all the executables.

@internalComponent
@released

@return iImageVsDepList - returns all executable's dependencies
*/
 
ExeNamesVsDepListMap& RomReader::GatherDependencies() {  
	PrepareAddVsExeMap();   
	for(ExeVsRomFsEntryMap::iterator it =  iExeVsRomFsEntryMap.begin();
		it != iExeVsRomFsEntryMap.end(); it++) {
		RomImageFileEntry* entry = dynamic_cast<RomImageFileEntry*>(it->second);
		if(!entry){ 
			continue ;
		}
		if(entry->iTRomEntryPtr->iAddressLin > RomBase()) {
			StringList executables; 
			CollectImportExecutableNames(entry, executables); 
			put_item_to_map(iImageVsDepList,entry->Name(), executables); 
		} 
	}
	return iImageVsDepList;
}

/** 
Function responsible to read the dependency names.

@internalComponent
@released

@param aRomReader - ROM reader pointer
@param aEntry - Current RomImageFSEntry
@param aImportExecutableNameList - Executable list.(output)
*/
void RomReader::CollectImportExecutableNames(const RomImageFSEntry* aEntry, StringList&  aImportExecutables) { 
	RomImageFileEntry* fileEntry = (RomImageFileEntry*)aEntry;
	TRomImageHeader	*romImgEntry = fileEntry->ImagePtr.iRomFileEntry;
	TUint sectionOffset = romImgEntry->iCodeAddress - RomBase();
	TUint* codeSection = reinterpret_cast<TUint*>(const_cast<char*>(RomHdrPtr()) + sectionOffset);
	TUint codeSize = romImgEntry->iCodeSize;
	// Checking for LDR Instruction in PLT section(Inside Code section)
	// to get the import address.	
	bool patternFound = false;	
	while(codeSize > 0) {
		if(*codeSection++ == KLdrOpcode) {
			patternFound = true;
			TUint dependencyAddress = *codeSection++;
			
			unsigned int addr = CodeSectionAddress(dependencyAddress);			 
			RomAddrVsExeName::iterator it = iAddVsExeMap.find(addr);
			
			if(it == iAddVsExeMap.end()) break ; 
			
			UintVsString::iterator i = it->second->begin();
			 
			if(!(dependencyAddress < (it->first + i->first))) {
				aImportExecutables.push_back(KUnknownDependency);
			}
			else {
				aImportExecutables.push_back(i->second);
			}			 
		}
		else if(patternFound) {
			break;
			
		}
		--codeSize;
	} 
	aImportExecutables.sort();
	aImportExecutables.unique();
}
typedef iterator_traits<VectorList::iterator>::difference_type Distance;
static VectorList::iterator get_lower_bound(VectorList aVec, const unsigned int& aVal){
	VectorList::iterator first = aVec.begin();
	VectorList::iterator last = aVec.end();
	Distance len = distance(first, last);
	Distance half;
	VectorList::iterator middle;

	while (len > 0) {
		half = len >> 1;
		middle = first;
		advance(middle, half);    
		if (*middle > aVal) {      
			first = middle;
			++first;
			len = len - half - 1;
		}
		else
			len = half;
	}
	return first;
}


/** 
Function responsible to read the dependency address from the Exe Map container.

@internalComponent
@released

@param aImageAddress - Dependency address (function address)
@returns - e32image start address(code section).
*/
unsigned int RomReader::CodeSectionAddress(unsigned int& aImageAddress) {
	/*
	This invocation leads to a warning, due to the stlport implememtation
	VectorList::iterator lowerAddress = lower_bound(iImageAddress.begin(), 
	iImageAddress.end(), aImageAddress, greater <unsigned int>());
	*/

	VectorList::iterator lowerAddress = get_lower_bound(iImageAddress,aImageAddress);
	return *lowerAddress;
}

/** 
Function responsible to fill iExeVsIdData and iSidVsExeName containers.

@internalComponent
@released

@param iRomImageRootDirEntry - Root directory entry
@param iExeVsIdData - Container
@param iSidVsExeName - Container
*/
void RomReader::PrepareExeVsIdMap() {
	  
	//IdData* id = KNull;
	//RomImageFileEntry* entry = KNull;
	if(iExeVsIdData.size() == 0) { //Is not already prepared 
		for(ExeVsRomFsEntryMap::iterator it =  iExeVsRomFsEntryMap.begin();
		it != iExeVsRomFsEntryMap.end() ; it++) {
			RomImageFileEntry* entry = dynamic_cast<RomImageFileEntry*>(it->second);
			if(!entry) continue ;			
			IdData* id = new IdData;
			id->iUid = entry->ImagePtr.iRomFileEntry->iUid1;
			id->iDbgFlag = (entry->ImagePtr.iRomFileEntry->iFlags & KImageDebuggable) ? true : false;
			if(entry->iTRomEntryPtr->iAddressLin > RomBase()) {
				const char* exeName = it->second->Name();
				//This header contains the SID and VID, so create the instance of IdData.
				TRomImageHeader	*aRomImgEntry = entry->ImagePtr.iRomFileEntry;

				id->iSid = aRomImgEntry->iS.iSecureId;
				id->iVid = aRomImgEntry->iS.iVendorId;
				id->iFileOffset = aRomImgEntry->iEntryPoint; 
				put_item_to_map_2(iExeVsIdData,exeName,id);  
			} 
		}
	} 
}

/** 
Function responsible to return the Executable versus IdData container. 

@internalComponent
@released

@return - returns iExeVsIdData
*/
const ExeVsIdDataMap& RomReader::GetExeVsIdMap() const {
	return iExeVsIdData;
}
