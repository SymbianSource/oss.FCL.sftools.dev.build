/*
* Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* @internalComponent 
* @released
*
*/

#include <e32rom.h>
#include "rom_image_reader.h"
#include "r_rom.h"
#ifdef __LINUX__
#define _alloca alloca 
#endif
#include "utf16string.h"
void InflateUnCompress(unsigned char* source, int sourcesize, unsigned char* dest, int destsize);
RomImageFSEntry::RomImageFSEntry (const char* aName) : iName(aName), iSibling(0), iChildren(0) {
}
RomImageFSEntry::~RomImageFSEntry() {
	if(iChildren){
		delete iChildren;
		iChildren = NULL ;
	}
	if(iSibling){
		delete iSibling ;
		iSibling = NULL ;
	}	
}

//Rom Image header 
RomImageHeader::RomImageHeader(char* aHdr, EImageType aImgType) {
	switch( aImgType) {
	case EROM_IMAGE:
		iLoaderHdr = (TRomLoaderHeader*)aHdr;
		iRomHdr = (TRomHeader*)(aHdr + sizeof(TRomLoaderHeader));
		iExtRomHdr = 0;
		break;

	case EROMX_IMAGE:
		iExtRomHdr = (TExtensionRomHeader*)(aHdr);
		iRomHdr = 0;
		iLoaderHdr = 0;
		break;

	case EBAREROM_IMAGE:
		iLoaderHdr = 0;
		iRomHdr = (TRomHeader*)aHdr;
		iExtRomHdr = 0;
		break;
	default:
		iExtRomHdr = 0;
		iRomHdr = 0;
		iLoaderHdr = 0;
		break ;
	}
}


void RomImageHeader::DumpRomHdr() {
	if(iLoaderHdr)
		*out << "ROM Image " << endl << endl;
	else
		*out << "Bare ROM Image" << endl << endl;
	TUint aPos = 0;
	bool aContinue = true;

	*out << "Image Signature .................";

	if(iLoaderHdr){     
		char temp[KRomNameSize + 1];
		memcpy(temp,reinterpret_cast<char*>(iLoaderHdr),KRomNameSize);        
		temp[KRomNameSize] = 0;
		*out << temp;
	}

	*out << endl << endl;

	DumpInHex("Timestamp", (iRomHdr->iTime >> 32)) ;
	DumpInHex(" ", (iRomHdr->iTime &0xffffffff), aContinue) << endl;

	DumpInHex("RomBase", iRomHdr->iRomBase) << endl;

	DumpInHex("RomSize", iRomHdr->iRomSize) << endl;
	DumpInHex("KernelDataAddress", iRomHdr->iKernDataAddress) << endl;
	DumpInHex("KernelLimit", iRomHdr->iKernelLimit) << endl;
	DumpInHex("PrimaryFile", iRomHdr->iPrimaryFile) << endl;
	DumpInHex("SecondaryFile", iRomHdr->iSecondaryFile) << endl;
	DumpInHex("CheckSum", iRomHdr->iCheckSum) << endl;
	DumpInHex("Hardware", iRomHdr->iHardware) << endl;

	DumpInHex("Language", (TUint)(iRomHdr->iLanguage >> 32));
	DumpInHex(" ", ((TUint)(iRomHdr->iLanguage & 0xffffffff)), aContinue) <<endl;

	DumpInHex("KernelConfigFlags", iRomHdr->iKernelConfigFlags) << endl;
	DumpInHex("RomExceptionSearchTable", iRomHdr->iRomExceptionSearchTable) << endl;
	DumpInHex("RomHeaderSize", iRomHdr->iRomHeaderSize) << endl;
	DumpInHex("RomSectionHeader", iRomHdr->iRomSectionHeader) << endl;
	DumpInHex("TotalSvDataSize", iRomHdr->iTotalSvDataSize) << endl;
	DumpInHex("VariantFile", iRomHdr->iVariantFile) << endl;
	DumpInHex("ExtensionFile", iRomHdr->iExtensionFile) << endl;
	DumpInHex("RelocInfo", iRomHdr->iRelocInfo) << endl;
	DumpInHex("OldTraceMask", iRomHdr->iOldTraceMask) << endl;
	DumpInHex("UserDataAddress", iRomHdr->iUserDataAddress) << endl;
	DumpInHex("TotalUserDataSize", iRomHdr->iTotalUserDataSize) << endl;
	DumpInHex("DebugPort", iRomHdr->iDebugPort) << endl;

	DumpInHex("Version", iRomHdr->iVersion.iMajor, false, 2);
	DumpInHex(".", iRomHdr->iVersion.iMinor, aContinue, 2);
	DumpInHex("(" ,iRomHdr->iVersion.iBuild, aContinue, 2);
	*out << ")" << endl;

	DumpInHex("CompressionType", iRomHdr->iCompressionType) << endl;
	DumpInHex("CompressedSize", iRomHdr->iCompressedSize) << endl;
	DumpInHex("UncompressedSize", iRomHdr->iUncompressedSize) << endl;
	DumpInHex("HcrFileAddress", iRomHdr->iHcrFileAddress) << endl;

	DumpInHex("DisabledCapabilities", iRomHdr->iDisabledCapabilities[0]);
	DumpInHex(" ", iRomHdr->iDisabledCapabilities[1], aContinue) << endl;

	DumpInHex("TraceMask", iRomHdr->iTraceMask[0]);
	aPos = 1;
	while( aPos < (TUint)KNumTraceMaskWords) {
		if(iRomHdr->iTraceMask[aPos]) {
			DumpInHex(" ", iRomHdr->iTraceMask[aPos++], aContinue);
		}
		else {
			DumpInHex(" ", iRomHdr->iTraceMask[aPos++], aContinue, 1);
		}

	}

	*out << endl << endl;

}
void RomImageHeader::DumpRomXHdr() {
	*out << "Extension ROM Image" << endl << endl;
	bool aContinue = true;

	DumpInHex("Timestamp", (iExtRomHdr->iTime >> 32)) ;
	DumpInHex(" ", (iExtRomHdr->iTime &0xffffffff), aContinue) << endl;

	DumpInHex("RomBase", iExtRomHdr->iRomBase) << endl;

	DumpInHex("RomSize", iExtRomHdr->iRomSize) << endl;
	DumpInHex("CheckSum", iExtRomHdr->iCheckSum) << endl;

	DumpInHex("Version", iExtRomHdr->iVersion.iMajor, false, 2);
	DumpInHex(".", iExtRomHdr->iVersion.iMinor, aContinue, 2);
	DumpInHex("(" ,iExtRomHdr->iVersion.iBuild, aContinue, 2);
	*out << ")" << endl;

	DumpInHex("CompressionType", iExtRomHdr->iCompressionType) << endl;
	DumpInHex("CompressedSize", iExtRomHdr->iCompressedSize) << endl;
	DumpInHex("UncompressedSize", iExtRomHdr->iUncompressedSize) << endl;

	*out << endl << endl;

}
//Rom Image reader
RomImageReader::RomImageReader(const char* aFile, EImageType aImgType) :
ImageReader(aFile), iImageHeader(0),
iRomSize(0),iHeaderBuffer(0),
iRomLayoutData(0),iImgType(aImgType) {
	iRomImageRootDirEntry = new RomImageDirEntry("");
}

RomImageReader::~RomImageReader() {
	if(iFile.is_open())
		iFile.close();
	if(iHeaderBuffer)
		delete []iHeaderBuffer;
	if(iRomLayoutData)
		delete []iRomLayoutData;  
	delete iRomImageRootDirEntry;


}

void RomImageReader::ReadImage() {
	if(iFile.is_open()) return ;
	iFile.open(iImgFileName.c_str(), ios_base::binary | ios_base::in);
	if( !iFile.is_open() ) {
		throw ImageReaderException(iImgFileName.c_str(), "Cannot open file ");
	}	

	TUint headerSize = GetHdrSize() ;	
	if(headerSize > 0){
		iHeaderBuffer = new char[headerSize];
		iFile.read(iHeaderBuffer,headerSize);
	}	
}

void RomImageReader::Validate() {
}

TUint32 RomImageReader::GetImageCompressionType() {
	if(iImageHeader->iRomHdr )// iImageType == EROM_IMAGE
		return iImageHeader->iRomHdr->iCompressionType;
	else
		return iImageHeader->iExtRomHdr->iCompressionType;
}


TLinAddr RomImageReader::GetRomBase() {
	if(iImageHeader->iRomHdr )// iImageType == EROM_IMAGE
		return iImageHeader->iRomHdr->iRomBase ;
	else
		return iImageHeader->iExtRomHdr->iRomBase;
}

TLinAddr RomImageReader::GetRootDirList() {
	if(iImageHeader->iRomHdr )// iImageType == EROM_IMAGE
		return iImageHeader->iRomHdr->iRomRootDirectoryList;
	else
		return iImageHeader->iExtRomHdr->iRomRootDirectoryList;
}

TUint RomImageReader::GetHdrSize() {
	TUint headerSize = 0;
	if(EROM_IMAGE == iImgType){
		headerSize = sizeof(TRomLoaderHeader) + sizeof(TRomHeader);
	}else if(EROMX_IMAGE == iImgType){
		headerSize = sizeof(TExtensionRomHeader);
	}else if(EBAREROM_IMAGE == iImgType){
		headerSize = sizeof(TRomHeader);
	}
	return headerSize;
}


static const TInt KIOBytes = 0x100000;
// reading a huge buffer at a time is very slow, reading 1MB bytes at a time is much faster
void RomImageReader::ReadData(char* aBuffer, TUint aLength) {
	TUint readBytes = 0 ;
	while(readBytes < aLength){
		TUint toRead = KIOBytes;
		if(readBytes + toRead > aLength)
			toRead = aLength - readBytes ;
		iFile.read(&aBuffer[readBytes],toRead);
		readBytes += toRead ;
	}	
}
void RomImageReader::ProcessImage() {
	if(iRomLayoutData) return ;
	iImageHeader = new RomImageHeader(iHeaderBuffer, iImgType);

	iFile.seekg(0, ios_base::end);
	// fileSize
	TUint fileSize = iFile.tellg(); 

	//let's skip the RomLoaderHeader
	TUint romDataBegin = (EROM_IMAGE == iImgType) ? sizeof(TRomLoaderHeader) : 0 ; 
	iFile.seekg(romDataBegin,ios_base::beg);	

	if(EROMX_IMAGE == iImgType){// EROMX_IMAGE, just set the iUnpagedRomBuffer		
		if(GetImageCompressionType() == KUidCompressionDeflate){
			TUint32 readLen = fileSize - sizeof(TExtensionRomHeader) ; 
			iRomSize = iImageHeader->iExtRomHdr->iUncompressedSize ;	 
			iRomLayoutData = new char[iRomSize];
			char* temp = new char[readLen];
			// header is not compressed.
			iFile.read(iRomLayoutData,sizeof(TExtensionRomHeader)); 
			ReadData(temp ,readLen);
			TUint8* uncompressDest = reinterpret_cast<TUint8*>(iRomLayoutData + sizeof(TExtensionRomHeader));
			InflateUnCompress(reinterpret_cast<TUint8*>(temp),readLen,uncompressDest,iRomSize - sizeof(TExtensionRomHeader));
			delete []temp ;	 

		}else{
			iRomSize = fileSize  ;
			iRomLayoutData = new char[iRomSize]; 
			ReadData(iRomLayoutData,iRomSize);
		}	 
	} // end EROMX_IMAGE
	else {
		//EROM_IMAGE or EBAREROM_IMAGE
		const TInt KPageSize = 0x1000; 
		TRomHeader *hdr = iImageHeader->iRomHdr; 
		iRomSize = hdr->iUncompressedSize ; 
		iRomLayoutData = new char[iRomSize]; 
		char* curDataPointer = iRomLayoutData ;
		TUint totalReadBytes = 0;
		bool hasPageableSec = (hdr->iPageableRomStart > 0 && hdr->iPageableRomSize > 0) ;

		// read data before unpaged 
		ReadData(curDataPointer,hdr->iCompressedUnpagedStart); 
		curDataPointer += hdr->iCompressedUnpagedStart ; 
		totalReadBytes += hdr->iCompressedUnpagedStart;		

		// read the unpaged part, if compressed , then decompress		 
		if(GetImageCompressionType() == KUidCompressionDeflate){
			char* temp = new char[hdr->iUnpagedCompressedSize];
			ReadData(temp,hdr->iUnpagedCompressedSize);
			totalReadBytes += hdr->iUnpagedCompressedSize;
			InflateUnCompress(reinterpret_cast<TUint8*>(temp),hdr->iUnpagedCompressedSize,reinterpret_cast<TUint8*>(curDataPointer) ,hdr->iUnpagedUncompressedSize);
			delete []temp ;			
		}else{
			TUint unpagedSeclen ;
			if(hasPageableSec) { // there is paged section 
				unpagedSeclen = hdr->iPageableRomStart - hdr->iCompressedUnpagedStart;
			}else{
				unpagedSeclen = iRomSize - hdr->iCompressedUnpagedStart;
			}
			ReadData(curDataPointer,unpagedSeclen);			 
			totalReadBytes += unpagedSeclen ;
		}
		curDataPointer = iRomLayoutData + totalReadBytes; 
		//if there is a paged section , read and extract it 

		// read the paged section,
		if(hasPageableSec){		
			if((TUint)(hdr->iPageableRomStart + hdr->iPageableRomSize) > iRomSize){
				throw ImageReaderException("Incorrect values of ROM header fields.", "");
			}
			if(0 == hdr->iRomPageIndex){ //
				// no compression for paged section ,just read it 			 
				iFile.read(curDataPointer,iRomSize - totalReadBytes);
			}
			else{
				//aligment calculation
				TUint pagedSecOffset = (totalReadBytes + KPageSize - 1) & (~(KPageSize - 1));
				if(pagedSecOffset > totalReadBytes){
					// there are gap bytes between unpaged and paged sections
					iFile.read(curDataPointer,pagedSecOffset - totalReadBytes);
					curDataPointer = iRomLayoutData + pagedSecOffset;
				}
				TUint pagedIndexCount = ( hdr->iUncompressedSize + KPageSize - 1) / KPageSize;
				// how many bytes ?
				// the page index table include the unpaged part ;
				TUint firstPagedIndexTblItem = hdr->iPageableRomStart / KPageSize;

				TUint tempBufLen = KPageSize << 8;
				char* readBuffer = new char[tempBufLen]; 

				TUint8* src,*srcNext = NULL;
				SRomPageInfo* pageInfo = reinterpret_cast<SRomPageInfo*>(&iRomLayoutData[hdr->iRomPageIndex]);
				CBytePair bpe;
				for(TUint i = firstPagedIndexTblItem ; i < pagedIndexCount ; i+= 256){
					TUint endIndex = i + 255 ;
					if(endIndex >= pagedIndexCount)
						endIndex = pagedIndexCount - 1;
					TUint readLen = pageInfo[endIndex].iDataStart + pageInfo[endIndex].iDataSize - pageInfo[i].iDataStart ; 
					iFile.read(readBuffer,readLen);
					src = reinterpret_cast<TUint8*>(readBuffer);
					for(TUint j = i ; j <= endIndex ; j++){
						switch(pageInfo[j].iCompressionType) {
						case SRomPageInfo::EBytePair: {
							TInt unpacked = bpe.Decompress(reinterpret_cast<TUint8*>(curDataPointer), KPageSize, src, pageInfo[j].iDataSize, srcNext);
							if (unpacked < 0) {
								delete []readBuffer;
								throw ImageReaderException("Corrupted BytePair compressed ROM image", "");
							}
							curDataPointer += unpacked;
							break ;
													  }
						case SRomPageInfo::ENoCompression:
							memcpy(curDataPointer,src,pageInfo[j].iDataSize);
							curDataPointer +=  pageInfo[j].iDataSize ;
							break ;
						default:
							delete []readBuffer;
							throw ImageReaderException("Undefined compression type", "");
							break ;

						}
						src += pageInfo[j].iDataSize; 
					} // end for(TUint j = i ; j <= endIndex ; j++) 
				} // end for(TUint i = firstPagedIndexTblItem ; i < pagedIndexCount ; i+= 256) 
				delete []readBuffer ;
			}// else

		} // if(hasPageableSec)  

	}
	TUint32 offset = GetRootDirList() - GetRomBase(); 
	TRomRootDirectoryList* rootDirList = reinterpret_cast<TRomRootDirectoryList*>(iRomLayoutData + offset );
	TInt dirCount = rootDirList->iNumRootDirs ; 
	string tempName ;
	for(TInt i = 0 ; i < dirCount ; i++) {
		offset = rootDirList->iRootDir[i].iAddressLin - GetRomBase(); 
		TRomDir* romDir = reinterpret_cast<TRomDir*>(iRomLayoutData + offset);	
		UTF16String unistr(reinterpret_cast<const TUint16*>(romDir->iEntry.iName),romDir->iEntry.iNameLength); 
		if(!unistr.ToUTF8(tempName)) //not utf16?
			tempName.assign(reinterpret_cast<const char*>(romDir->iEntry.iName),romDir->iEntry.iNameLength) ;
		BuildDir(romDir, iRomImageRootDirEntry);		 
	}

}


void RomImageReader::BuildDir(TRomDir* aDir, RomImageFSEntry* aPaFSEntry)
{	 

	TInt processBytes = 0 ;
	TInt totalDirBytes = aDir->iSize - sizeof(aDir->iSize);
	TRomEntry* entry = &aDir->iEntry;
	RomImageFSEntry *fsEntry ;
	string pritableName ; 

	while(processBytes < totalDirBytes){ 
		UTF16String unistr(reinterpret_cast<const TUint16*>(entry->iName),entry->iNameLength);
		if(!unistr.ToUTF8(pritableName)) 
			pritableName.assign(reinterpret_cast<const char*>(entry->iName),entry->iNameLength);
		if(entry->iAtt & 0x10) { // is a directory
			fsEntry = new RomImageDirEntry(pritableName.c_str()); 
			AddChild(aPaFSEntry,fsEntry,NULL);
			TUint offset = entry->iAddressLin - GetRomBase();
			TRomDir* subFolder = reinterpret_cast<TRomDir*>(iRomLayoutData + offset);		 
			BuildDir(subFolder,fsEntry); 
		}
		else{
			fsEntry = new RomImageFileEntry(pritableName.c_str()); 
			AddChild(aPaFSEntry,fsEntry,entry);
		} 
		// increase the processedBytes
		processBytes += (entry->iNameLength << 1) +  reinterpret_cast<TInt>(entry->iName) - reinterpret_cast<TInt>(entry); 

		//align to next 4 bytes
		processBytes = (processBytes + 3) & ( ~3 ); 
		// get next entry
		entry =  reinterpret_cast<TRomEntry*>( reinterpret_cast<char*>(&aDir->iEntry) + processBytes);
	} 

}

void RomImageReader::AddChild(RomImageFSEntry *aParent, RomImageFSEntry *aChild, TRomEntry* aRomEntry) {
	if(!aParent->iChildren)
		aParent->iChildren = aChild;
	else {
		RomImageFSEntry *aLast = aParent->iChildren;

		while(aLast->iSibling)
			aLast = aLast->iSibling;
		aLast->iSibling = aChild;
	}

	if(!aChild->IsDirectory()) { 
		RomImageFileEntry* file = static_cast<RomImageFileEntry*>(aChild);
		file->iTRomEntryPtr = aRomEntry;

		if(aRomEntry->iAddressLin > GetRomBase()) {
			TUint32 offset = aRomEntry->iAddressLin - GetRomBase();	 

			TRomImageHeader* imgHdr = reinterpret_cast<TRomImageHeader*>(iRomLayoutData + offset);

			file->ImagePtr.iRomFileEntry = imgHdr;

			TUint8 aUid1[4];
			memcpy(aUid1, &file->ImagePtr.iRomFileEntry->iUid1, 4);

			if( ReaderUtil::IsExecutable(aUid1) ) {
				file->iExecutable = true;
			}
			else {
				file->iExecutable = false;
				file->ImagePtr.iDataFileAddr = aRomEntry->iAddressLin;
			}
		}
		else {
			file->ImagePtr.iRomFileEntry = NULL; 
		}
	}

	if(aParent != iRomImageRootDirEntry) {
		aChild->iPath = aParent->iPath;
		aChild->iPath += SLASH_CHAR1;
		aChild->iPath += aParent->iName.c_str();
	}
}

void RomImageReader::DumpTree() {
	RomImageFSEntry* aFsEntry = iRomImageRootDirEntry;
	if( aFsEntry->iChildren ) 
		DumpSubTree(aFsEntry->iChildren); 
}

void RomImageReader::DumpDirStructure() {
	*out << "Directory Listing" << endl;
	*out << "=================" << endl;
	int aPadding = 0;
	if( iRomImageRootDirEntry ){
		DumpDirStructure(iRomImageRootDirEntry, aPadding);
	}	
	*out << endl << endl;
}

void RomImageReader::DumpDirStructure(RomImageFSEntry* aEntry, int &aPadding) {
	if(!aEntry)
		return;

	int aPadLen = 2 * aPadding;//scaling for legibility
	for (int i = 0; i < aPadLen; i++)
		*out << " ";

	*out << aEntry->Name() << endl;

	if( aEntry->iChildren){
		aPadding++;
		DumpDirStructure(aEntry->iChildren, aPadding);
		aPadding--;
	}
	DumpDirStructure(aEntry->iSibling, aPadding);
}

void RomImageReader::DumpSubTree(RomImageFSEntry* aFsEntry) {
	if(!aFsEntry)
		return;

	if( aFsEntry->iChildren ){
		DumpSubTree(aFsEntry->iChildren);
	}

	if( aFsEntry->iSibling )
		DumpSubTree(aFsEntry->iSibling);

	RomImageFSEntry *aEntry = aFsEntry;

	if(!aEntry->IsDirectory()) {
		*out << "********************************************************************" << endl;
		*out << "File........................" << aEntry->iPath.c_str() << SLASH_CHAR1 << aEntry->Name() << endl;

		if( ((RomImageFileEntry*)aEntry)->iExecutable )	{
			DumpImage((RomImageFileEntry*)aEntry);
		}
		else{
			*out << "Linear Addr................." << ((RomImageFileEntry*)aEntry)->ImagePtr.iDataFileAddr << endl;
		}
	}
}

void RomImageReader::DumpImage(RomImageFileEntry * aEntry) {
	bool aContinue = true;

	DumpInHex("Load Address", aEntry->iTRomEntryPtr->iAddressLin) << endl;
	DumpInHex("Size", aEntry->iTRomEntryPtr->iSize) << endl;

	TRomImageHeader		*aRomImgEntry = aEntry->ImagePtr.iRomFileEntry;

	if( !aRomImgEntry )
		return;
	//UIDs
	DumpInHex("Uids", aRomImgEntry->iUid1);
	DumpInHex(" ", aRomImgEntry->iUid2, aContinue);
	DumpInHex(" ", aRomImgEntry->iUid3, aContinue);
	DumpInHex(" ", aRomImgEntry->iUidChecksum, aContinue) << endl;

	DumpInHex("Entry point", aRomImgEntry->iEntryPoint) << endl;
	DumpInHex("Code start addr", aRomImgEntry->iCodeAddress) << endl;
	DumpInHex("Data start addr", aRomImgEntry->iDataAddress) << endl;
	DumpInHex("DataBssLinearBase", aRomImgEntry->iDataBssLinearBase) << endl;
	DumpInHex("Text size", aRomImgEntry->iTextSize) << endl;
	DumpInHex("Code size", aRomImgEntry->iCodeSize) << endl;
	DumpInHex("Data size", aRomImgEntry->iDataSize) << endl;
	DumpInHex("Bss size", (aRomImgEntry->iBssSize)) << endl;
	DumpInHex("Total data size", aRomImgEntry->iTotalDataSize) << endl;
	DumpInHex("Heap min", aRomImgEntry->iHeapSizeMin) << endl;
	DumpInHex("Heap max", aRomImgEntry->iHeapSizeMax) << endl;
	DumpInHex("Stack size", aRomImgEntry->iStackSize) << endl;

	TDllRefTable *aRefTbl = NULL;
 
	 if( aRomImgEntry->iDllRefTable ) {
		TUint32 aOff = (TUint32)aRomImgEntry->iDllRefTable  - iImageHeader->iRomHdr->iRomBase;
        if(static_cast<TInt32>(aOff) > 0) { 
			aRefTbl = (TDllRefTable*) (iRomLayoutData + aOff);		 
			TUint32 aVirtualAddr = reinterpret_cast<TUint32>(aRefTbl->iEntry[0]);
			DumpInHex("Dll ref table", aVirtualAddr) << endl;
			
        }
       else {
            DumpInHex("Error Dll ref table", 0) << endl;
        }
	}

	DumpInHex("Export directory", aRomImgEntry->iExportDir) << endl;
	DumpInHex("Export dir count", aRomImgEntry->iExportDirCount) << endl;
	DumpInHex("Hardware variant", aRomImgEntry->iHardwareVariant) << endl;
	DumpInHex("Flags", aRomImgEntry->iFlags) << endl;
	DumpInHex("Secure ID", aRomImgEntry->iS.iSecureId) << endl;
	DumpInHex("Vendor ID", aRomImgEntry->iS.iVendorId) << endl;

	DumpInHex("Capability", aRomImgEntry->iS.iCaps[1]);
	DumpInHex(" ", aRomImgEntry->iS.iCaps[0], aContinue) << endl;

	*out << "Tools Version..............." << dec << (TUint)aRomImgEntry->iToolsVersion.iMajor;
	*out << "." ; 
	out->width(2) ;
	out->fill('0');
	*out << dec << (TUint)aRomImgEntry->iToolsVersion.iMinor ;
	*out << "(" << dec << aRomImgEntry->iToolsVersion.iBuild << ")";
	*out << endl;

	*out << "Module Version.............." << dec << (aRomImgEntry->iModuleVersion >> 16) << endl;
	DumpInHex("Exception Descriptor", aRomImgEntry->iExceptionDescriptor) << endl;
	*out << "Priority...................." << dec << aRomImgEntry->iPriority << endl;

	if( aRefTbl )
		DumpInHex("Dll ref table size", aRefTbl->iNumberOfEntries*8) << endl;
	else
		DumpInHex("Dll ref table size", 0) << endl;

	if( iDisplayOptions & DUMP_E32_IMG_FLAG){
		if(stricmp(iE32ImgFileName.c_str(), aEntry->Name()) == 0){
			TUint aSectionOffset = aRomImgEntry->iCodeAddress - iImageHeader->iRomHdr->iRomBase;
			TUint* aCodeSection = (TUint*)((char*)iImageHeader->iRomHdr + aSectionOffset);
			//TUint* aCodeSection = (TUint*)(iRomLayoutData + aSectionOffset);
			*out << "\nCode (Size=0x" << hex << aRomImgEntry->iCodeSize << ")" << endl;
			DumpData(aCodeSection, aRomImgEntry->iCodeSize);

			aSectionOffset = aRomImgEntry->iDataAddress - iImageHeader->iRomHdr->iRomBase;
			TUint* aDataSection = (TUint*)((char*)iImageHeader->iRomHdr + aSectionOffset);
			//TUint* aDataSection = (TUint*)(iRomLayoutData + aSectionOffset);
			if( aRomImgEntry->iDataSize){
				*out << "\nData (Size=0x" << hex << aRomImgEntry->iDataSize << ")" << endl;
				DumpData(aDataSection, aRomImgEntry->iDataSize);
			}
		}
	}

	*out << endl << endl;
}

void RomImageReader::DumpAttribs(RomImageFSEntry* aFsEntry) {

	// a larger rom image cause stack overflow under visual studio if we use recursion algorithm here.
	// can gcc compiler guarantee this overflow will never be happen ?
	if( aFsEntry->iChildren )
		DumpAttribs(aFsEntry->iChildren);

	if(aFsEntry->iSibling)
		DumpAttribs(aFsEntry->iSibling);
	if(aFsEntry->IsDirectory()) return ;
	RomImageFileEntry* file = static_cast<RomImageFileEntry*>(aFsEntry);
	if(!file->iExecutable) return ; 
	TRomImageHeader* aRomImgEntry = file->ImagePtr.iRomFileEntry;

	if( !aRomImgEntry)  return; 

	const char* prefix ;
	if(aRomImgEntry->iFlags & KRomImageFlagPrimary){
		prefix = "Primary";
	}
	else if(aRomImgEntry->iFlags & KRomImageFlagVariant){
		prefix = "Variant";
	}
	else if(aRomImgEntry->iFlags & KRomImageFlagExtension){
		prefix = "Extension";
	}
	else if(aRomImgEntry->iFlags & KRomImageFlagDevice){
		prefix = "Device";
	}
	else
		return;

	out->width(10);
	out->fill(' '); 
	*out << left << prefix;
	out->width(40);	
	*out << right << file->Name() << "[" ;
	DumpInHex( "", aRomImgEntry->iHardwareVariant, true) << "] ";
	DumpInHex( " DataSize=", (aRomImgEntry->iBssSize + aRomImgEntry->iDataSize), true) << endl;

}

void RomImageReader::Dump() {
	if( !((iDisplayOptions & EXTRACT_FILES_FLAG) || 
		(iDisplayOptions & LOG_IMAGE_CONTENTS_FLAG) ||
		(iDisplayOptions & EXTRACT_FILE_SET_FLAG)) ) {
			*out << "Image Name................." << iImgFileName.c_str() << endl;

			if( iImageHeader->iRomHdr )
				iImageHeader->DumpRomHdr();
			else
				iImageHeader->DumpRomXHdr();

			DumpAttribs(iRomImageRootDirEntry);
			*out << endl ;

			if(iDisplayOptions & DUMP_VERBOSE_FLAG) {
				DumpDirStructure();
				DumpTree();
			}

			if(iDisplayOptions & DUMP_DIR_ENTRIES_FLAG) {
				DumpDirStructure();
			}
	}
}


/** 
Function iterates through all the entries in the image 
by making a call to TraverseImage function.

@internalComponent
@released
*/
void RomImageReader::ExtractImageContents() {
	if( (iDisplayOptions & EXTRACT_FILE_SET_FLAG) ) { 
		ImageReader::ExtractFileSet(iRomLayoutData);
	}

	if( iDisplayOptions & EXTRACT_FILES_FLAG || iDisplayOptions & LOG_IMAGE_CONTENTS_FLAG ) {
		if(iRomImageRootDirEntry) {
			// name of the log file.
			string logFile;
			// output stream for the log file. 
			ofstream oFile;

			if( iDisplayOptions & LOG_IMAGE_CONTENTS_FLAG){
				if( ImageReader::iZdrivePath.compare("")){				 
					// create specified directory.
					CreateSpecifiedDir(ImageReader::iZdrivePath); 
					int len = ImageReader::iZdrivePath.length() ;
					const char* z = ImageReader::iZdrivePath.c_str();
					logFile = "";
					for(int i = 0 ; i < len ; i++){
						if(z[i] == SLASH_CHAR2)
							logFile += SLASH_CHAR1;
						else
							logFile += z[i];
					}
					len -- ;
					if(z[len] != SLASH_CHAR1)
						logFile += SLASH_CHAR1;
					logFile += ImageReader::iLogFileName ;
				}
				else {				
					logFile = ImageReader::iLogFileName;
				}
				// open the specified file in append mode.
				oFile.open(logFile.c_str() ,ios_base::out|ios_base::app);

				if(!oFile.is_open()){
					throw ImageReaderException(ImageReader::iLogFileName.c_str(), "Failed to open the log file");
				}
			}
			TraverseImage(iRomImageRootDirEntry,oFile);
			if(oFile.is_open())  oFile.close();  
		}
	}
}


/** 
Function to traverse entire image and check for an entity.If the entity found in the image is a file 
then it makes a call to CheckFileExtension to check for extension.

@internalComponent
@released

@param aEntity		- pointer to the entry in rom image.
@param aFile		- output stream.
*/
void RomImageReader::TraverseImage(RomImageFSEntry*  aEntity,ofstream& aFile) {
	if(!aEntity->IsDirectory())	{
		CheckFileExtension(aEntity,aFile);
	}

	if (aEntity->iChildren)	{
		TraverseImage(aEntity->iChildren,aFile);
	}

	if (aEntity->iSibling)	{
		TraverseImage(aEntity->iSibling,aFile);
	}
}


/** 
Function to get check extension of the given file.If the extension of the file is "sis"
then call ExtractFile function to extract the file from the image.  

@internalComponent
@released

@param aEntity		- pointer to the entry in rom image.
@param aFile		- output stream.
*/
void RomImageReader::CheckFileExtension(RomImageFSEntry*  aEntity,ofstream& aFile) {
	RomImageFileEntry*	romEntry = (RomImageFileEntry*)aEntity;
	// get the size of the entity.
	TUint32 size = romEntry->iTRomEntryPtr->iSize;
	// get the offset of the entity.
	TUint32 offset =  romEntry->iTRomEntryPtr->iAddressLin - GetRomBase() ;

	const char* fileName = aEntity->iName.c_str();

	// create a string to hold the path information.
	string romfilePath(romEntry->iPath);
	int len = romfilePath.length();
	char* str = const_cast<char*>(romfilePath.c_str());
	for(int i = 0 ; i < len ; i++){
		if(str[i] == SLASH_CHAR2)
			str[i] = SLASH_CHAR1;
	}
	if(str[len - 1] != SLASH_CHAR1)
		romfilePath += SLASH_CHAR1;

	if( iDisplayOptions & LOG_IMAGE_CONTENTS_FLAG && iDisplayOptions & EXTRACT_FILES_FLAG ) {
		// get the position.
		size_t pos = aEntity->iName.find_last_of(".");

		const char* extName = fileName + ( pos + 1 );
		if ( !stricmp(extName ,"SIS")	||  !stricmp(extName ,"DAT") ) {
			// if the two strings are same then extract the corresponding file.
			ImageReader::ExtractFile(offset,size,fileName,romfilePath.c_str(),ImageReader::iZdrivePath.c_str(),iRomLayoutData);
		}
		else {
			LogRomEnrtyToFile(romfilePath.c_str(),fileName,aFile);
		}
	}
	else if( iDisplayOptions & LOG_IMAGE_CONTENTS_FLAG ) {
		LogRomEnrtyToFile(romfilePath.c_str(),fileName,aFile);
	}
	else {
		if(romEntry->iExecutable) {
			size += sizeof(TRomImageHeader);
		}
		// extract the corresponding file. 
		ImageReader::ExtractFile(offset,size,fileName,romfilePath.c_str(),ImageReader::iZdrivePath.c_str(),iRomLayoutData);
	}
}


/** 
Function to log the rom entry to a specified file. 

@internalComponent
@released

@param aPath		- Complete path of an entity.
@param aEntityName	- Entity name. 
@param aFile		- output stream.
*/
void RomImageReader::LogRomEnrtyToFile(const char* aPath,const char* aEntityName,ofstream& aFile) {
	if(aFile.is_open()) {
		aFile.seekp(0,ios_base::end);
		aFile<<aPath <<aEntityName << endl;
	}
}


/** 
Function to read the directory structure details of te ROM image.  

@internalComponent
@released

@param aEntity		- pointer to the entry in rom image.
@param aFileMap		- map of filename with its size and offset values.
@param aImgSize		- Image size
*/
void RomImageReader::ProcessDirectory(RomImageFSEntry *aEntity, FILEINFOMAP &aFileMap) {
	if(!aEntity->IsDirectory()) { 

		RomImageFileEntry*	romEntry = (RomImageFileEntry*)aEntity;

		PFILEINFO fileInfo = new FILEINFO;

		// get the size of the entity.
		fileInfo->iSize = romEntry->iTRomEntryPtr->iSize;
		// get the offset of the entity.
		fileInfo->iOffset = (romEntry->iTRomEntryPtr->iAddressLin - GetRomBase()); 

		if(romEntry->iExecutable) {
			fileInfo->iSize += sizeof(TRomImageHeader);
		}

		if((fileInfo->iOffset + fileInfo->iSize) > iRomSize) {
			fileInfo->iOffset = 0;
			fileInfo->iSize = 0;
		}

		string fileName(romEntry->iPath);
		fileName += SLASH_CHAR1;
		fileName.append(aEntity->iName);
		aFileMap[fileName] = fileInfo;
	}

	if (aEntity->iChildren) {
		ProcessDirectory(aEntity->iChildren, aFileMap);
	}

	if (aEntity->iSibling) {
		ProcessDirectory(aEntity->iSibling, aFileMap);
	}
}

/** 
Function to read the directory structure details of te ROM image.  

@internalComponent
@released

@param aFileMap		- map of filename with its size and offset values.
*/
void RomImageReader::GetFileInfo(FILEINFOMAP &aFileMap) {
	ProcessDirectory(iRomImageRootDirEntry, aFileMap);
}

/** 
Function to get the ROM image size.

@internalComponent
@released
*/
TUint32 RomImageReader::GetImageSize() {
	return iRomSize;
}

