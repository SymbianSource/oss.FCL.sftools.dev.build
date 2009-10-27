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
*
*/


#include <e32def.h>
#include <e32def_private.h>
#include <e32rom.h>

#include "h_utl.h"
#include "r_rom.h"

#include "memmap.h"

#include "r_coreimage.h"
#include "r_global.h"


#define ROM_PTR(base_ptr) ((TInt8*)iRomHdr + (base_ptr - iRomHdr->iRomBase))

void InflateUnCompress(unsigned char* source, int sourcesize, unsigned char* dest, int destsize);

const TUint KEntryAttDir=0x0010;
const TUint KEntryAttXIP=0x0080;
const TUint KEntryAttHidden=0x0002;

// CoreRomImageReader
// 
CoreRomImageReader::CoreRomImageReader(String aFileName, TBool aUseMemMap) : iImgFileName(aFileName), 
iData(0), iLoaderHdr(0), iRomHdr(0), iRootDirList(0), iRootDirectory(0), iUseMemMap(aUseMemMap), iImageMap(0)
{
}

CoreRomImageReader::~CoreRomImageReader() 
{
	if(iData)
	{
		if(iUseMemMap)
		{
			iImageMap->CloseMemoryMap(ETrue);
			delete iImageMap;
		}
		else
			delete iData;
	}

	if(iRootDirectory)
	{
		DeleteAll(iRootDirectory);
	}
}

TBool CoreRomImageReader::IsCoreROM()
{
	if(iData)
	{
		if(iData[0] == 'E' && iData[1] == 'P' && iData[2] == 'O' && iData[3] == 'C' &&
			iData[8]  == 'R' && iData[9]  == 'O' && iData[10] == 'M')
		{
			return ETrue;
		}
	}

	return EFalse;
}

TUint CoreRomImageReader::GetHdrSize()
{ 
	return (sizeof(TRomLoaderHeader) + sizeof(TRomHeader)); 
}

TBool CoreRomImageReader::AllocateImageMap(Memmap*& aImageMap, TUint8*& aData, TUint aLen)
{
	aImageMap = new Memmap(EFalse);

	if(aImageMap == NULL)
	{
		return EFalse;
	}
	else
	{
		aImageMap->SetMaxMapSize(aLen);
		if(aImageMap->CreateMemoryMap() == EFalse)
		{
			aImageMap->CloseMemoryMap(ETrue);
			delete aImageMap;
			aImageMap = NULL;
			return EFalse;
		}
		else
		{
			aData = (TUint8*)aImageMap->GetMemoryMapPointer();
		}
	}

	return ETrue;
}

TBool CoreRomImageReader::OpenImage()
{
	TUint aLen = 0;

	Ifstream aIf(iImgFileName.data(), std::ios::binary | std::ios::in);
	if( !aIf.is_open() )
	{
		Print(EError, "Cannot open file %s", (char*)iImgFileName.data());
		return EFalse;
	}

	aIf.seekg(0, std::ios::end);
	aLen = aIf.tellg();

	if(iUseMemMap)
	{
		if(!AllocateImageMap(iImageMap, iData, aLen))
		{
			aLen = 0;
			Print(EError, "Failed to create image map object");
			return EFalse;
		}
	}
	else
	{
		iData = new unsigned char[aLen];
		if(iData == NULL)
		{
			aLen = 0;
			Print(EError, "Out of memory.\n");
			return EFalse;
		}
		memset(iData, 0, aLen);
	}
	aIf.seekg(0, std::ios::beg);
	aIf.read((char*)iData, aLen);

	if(!IsCoreROM() || !StoreImageHeader())
	{
		Print(EError, "Invalid Core ROM image %s", (char*)iImgFileName.data());
		aIf.close();
		return EFalse;
	}

	aIf.close();

	return ETrue;
}

TBool CoreRomImageReader::StoreImageHeader()
{
	iLoaderHdr = (TRomLoaderHeader*)iData;
	iRomHdr = (TRomHeader*)(iData + sizeof(TRomLoaderHeader));

	if(!iLoaderHdr || !iRomHdr)
		return EFalse;

	return ETrue;
}

TInt CoreRomImageReader::CreateRootDirectory()
{
	iRootDirectory = new TRomNode((TText*)"", (TRomBuilderEntry*)0);
	if (iRootDirectory == 0 )
		return KErrNoMemory;
	return KErrNone;
}

TBool CoreRomImageReader::ProcessImage()
{
	Memmap *aImageMap = 0;

	if(iRomHdr->iCompressionType == KUidCompressionDeflate)
	{
		TUint aDataStart = GetHdrSize();
		TUint8* aData = 0;
		if(iUseMemMap)
		{
			if(!AllocateImageMap(aImageMap, aData, (iRomHdr->iUncompressedSize + aDataStart)))
			{
				Print(EError, "Failed to create image map object");
				return EFalse;
			}
		}
		else
		{
			aData = new unsigned char[iRomHdr->iUncompressedSize + aDataStart];
		}

		InflateUnCompress((unsigned char*)(iData + aDataStart), iRomHdr->iCompressedSize, (unsigned char*)(aData + aDataStart), iRomHdr->iUncompressedSize);
		memcpy(aData, iData, aDataStart);

		if(iUseMemMap)
		{
			iImageMap->CloseMemoryMap(ETrue);
			delete iImageMap;
			iImageMap = aImageMap;
		}
		else
		{
			delete [] iData;
		}
		
		iData = aData;
		
		//update the header fields...
		if(!StoreImageHeader())
		{
			return EFalse;
		}
	}
	else if (iRomHdr && iRomHdr->iRomPageIndex) // paged ROM
	{
		const TInt KPageSize = 0x1000;
		TUint8* aData = 0;
		
		TRomHeader *pRomHdr = iRomHdr;
		
		TUint headerSize = GetHdrSize();
		
		TInt numPages = (pRomHdr->iPageableRomStart + pRomHdr->iPageableRomSize+KPageSize-1)/KPageSize;
		if(iUseMemMap)
		{
			if(!AllocateImageMap(aImageMap, aData, (pRomHdr->iUncompressedSize + headerSize)))
			{
				Print(EError, "Failed to create image map object");
				return EFalse;
			}
		}
		else
		{
			aData = new TUint8[pRomHdr->iUncompressedSize + headerSize];
		}
		TUint8* dest = (aData + sizeof(TRomLoaderHeader) + pRomHdr->iPageableRomStart);
		SRomPageInfo* pi = (SRomPageInfo*)((TUint8*)pRomHdr + pRomHdr->iRomPageIndex);
		
                CBytePair bpe(gFastCompress);
		for(TInt i=0; i<numPages; i++,pi++)
		{
			if (pi->iPagingAttributes != SRomPageInfo::EPageable) // skip uncompressed part at the beginning of ROM image
				continue;
			
			switch(pi->iCompressionType)
			{
			case SRomPageInfo::ENoCompression:
				{
					memcpy(dest, (TUint8*)pRomHdr + pi->iDataStart, pi->iDataSize);
					dest += pi->iDataSize;
				}
				break;
				
			case SRomPageInfo::EBytePair:
				{
					TUint8* srcNext=0;
					TInt unpacked = bpe.Decompress((unsigned char*)dest, KPageSize, (TUint8*)pRomHdr + pi->iDataStart, pi->iDataSize, srcNext);
					if (unpacked < 0)
					{
						if(iUseMemMap)
						{
							aImageMap->CloseMemoryMap(ETrue);
							delete aImageMap;
						}
						else
						{
							delete [] aData;
						}
						Print(EError, "Corrupted BytePair compressed ROM image %s", (char*)iImgFileName.data());
						return EFalse;
					}
					
					dest += unpacked;
				}
				break;

			default:
				{
					if(iUseMemMap)
					{
						aImageMap->CloseMemoryMap(ETrue);
						delete aImageMap;
					}
					else
					{
						delete [] aData;
					}
					Print(EError, "Undefined compression type in %s", (char*)iImgFileName.data());
					return EFalse;
				}
			}
		}
		
		memcpy(aData, iData, sizeof(TRomLoaderHeader) + pRomHdr->iPageableRomStart);
		if(iUseMemMap)
		{
			iImageMap->CloseMemoryMap(ETrue);
			delete iImageMap;
			iImageMap = aImageMap;
		}
		else
		{
			delete [] iData;
		}
		
		iData = aData;
		
		//update the header fields...
		if(!StoreImageHeader())
		{
			return EFalse;
		}
	}

	if(CreateRootDirectory() != KErrNone)
	{
		return EFalse;
	}

	if(GetDirectoryStructures() != KErrNone)
	{
		return EFalse;
	}

	return ETrue;
}

TInt CoreRomImageReader::GetDirectoryStructures()
{
	int aDirs = 0;
	TRomDir	*aRomDir = 0;

	iRootDirList = (TRomRootDirectoryList*)ROM_PTR(iRomHdr->iRomRootDirectoryList);

	while( aDirs < iRootDirList->iNumRootDirs )
	{
		aRomDir = (TRomDir*)ROM_PTR(iRootDirList->iRootDir[aDirs].iAddressLin);

		if(BuildDir(aRomDir, iRootDirectory) != KErrNone)
		{
			return KErrNoMemory;
		}
		aDirs++;
	}

	return KErrNone;
}


TInt OffsetCompare(const void *a, const void *b)
{
	return ( *(TInt16*)a - *(TInt16*)b );
}

TInt CoreRomImageReader::BuildDir(TRomDir* aDir, TRomNode* aPaFSEntry)
{
	TInt16			*aFileCnt = 0;
	TInt16			*aBase, aCount;
	TInt16			*aSubDirCnt = 0;

	//Sub directories in this directories
	aSubDirCnt = (TInt16*)((char*)aDir + aDir->iSize + sizeof(aDir->iSize));

	//Files within this directory
	aFileCnt = aSubDirCnt+1;

	aCount = (*aFileCnt + *aSubDirCnt);

	aBase = aFileCnt+1;

	qsort((void*)aBase, aCount, sizeof(TInt16), &OffsetCompare);

	return BuildDir(aBase, aCount, aDir, aPaFSEntry);
}

TInt CoreRomImageReader::BuildDir(TInt16 *aOffsetTbl, TInt16 aOffsetTblCount, 
								  TRomDir *aPaRomDir, TRomNode* aPaFSEntry)
{
	TRomNode		*aNewFSEntry;
	TRomDir			*aNewDir;
	TRomEntry		*aRomEntry;
	TUint32			aOffsetFromBase;

	String	aName;
	char	*aPtr;

	while( aOffsetTblCount )
	{
		aOffsetFromBase = *aOffsetTbl;

		aOffsetFromBase <<= 2;

		aRomEntry = (TRomEntry*)((char*)aPaRomDir + sizeof(int) + aOffsetFromBase);

		aPtr = (char*)aRomEntry->iName;
		Name(aName, aPtr, aRomEntry->iNameLength);

		if( aRomEntry->iAtt & KEntryAttDir )
		{
			// add directory
			aNewFSEntry = aPaFSEntry->NewSubDir((unsigned char*)aName.data());
			if(aRomEntry->iAtt & KEntryAttHidden)
				aNewFSEntry->iHidden = ETrue;
			else
				aNewFSEntry->iHidden = EFalse;

			aNewDir = (TRomDir*)ROM_PTR(aRomEntry->iAddressLin);
			if(BuildDir(aNewDir, aNewFSEntry) != KErrNone)
			{
				return KErrNoMemory;
			}
		}
		else
		{
			// add file
			if(AddFile(aPaFSEntry, (char*)aName.data(), aRomEntry) != KErrNone)
			{
				return KErrNoMemory;
			}
		}

		aOffsetTblCount--;
		aOffsetTbl++;
	}

	return KErrNone;
}

TInt CoreRomImageReader::AddFile(TRomNode *aPa, char *entryName, TRomEntry* aRomEntry)
{
	TRomImageHeader*	aImgHdr = 0;
	TRomBuilderEntry*	aFile = 0;
	TRomNode*			aNewFSEntry = 0;
	static TRomNode*	aLastExecutable = GetRootDirectory();
	TUint8				aUid1[4];

	aImgHdr = (TRomImageHeader*)ROM_PTR(aRomEntry->iAddressLin);

	aFile = new TRomBuilderEntry(0, (TUint8*)entryName);

	if(!aFile)
	{
		return KErrNoMemory;
	}

	aFile->iBareName = strdup((char*)aFile->iName);
	aFile->iUid1 = aImgHdr->iUid1;
	aFile->iUid2 = aImgHdr->iUid2;
	aFile->iUid3 = aImgHdr->iUid3;
	aFile->iRomImageFlags = aImgHdr->iFlags;
	aFile->iHardwareVariant = aImgHdr->iHardwareVariant;

	memcpy(aUid1, &(aImgHdr->iUid1), 4);

	aFile->iResource = !IsExecutable(aUid1);

	aNewFSEntry = new TRomNode((TUint8*)entryName, aFile);
	if(!aNewFSEntry)
	{
		return KErrNoMemory;
	}

	if(aRomEntry->iAtt & KEntryAttHidden)
		aNewFSEntry->iHidden = ETrue;
	else
		aNewFSEntry->iHidden = EFalse;

	// RomEntry Update
	aNewFSEntry->iRomFile->SetRomEntry(aRomEntry);
	aNewFSEntry->iRomFile->iFinal = ETrue;
	
	// E32 Image Pointer Update
	aNewFSEntry->iRomFile->iAddresses.iImageAddr = aRomEntry->iAddressLin;
	aNewFSEntry->iRomFile->iAddresses.iRunAddr = aRomEntry->iAddressLin;
	aNewFSEntry->iRomFile->iAddresses.iSize = aRomEntry->iSize;
	aNewFSEntry->iRomFile->iAddresses.iImagePtr = 0;
	aNewFSEntry->iRomFile->iExportDir.iImagePtr = 0;

	if(!aFile->iResource  && !aFile->HCRDataFile())
	{
		// Hardware Variant Update
		aNewFSEntry->iRomFile->iHwvd = aImgHdr->iHardwareVariant;
		// Security Info Update
		aNewFSEntry->iRomFile->iRbEntry->iS = aImgHdr->iS;

		// Export Table Update
		aNewFSEntry->iRomFile->iExportDir.iSize = aImgHdr->iExportDirCount*4;
		aNewFSEntry->iRomFile->iExportDir.iImageAddr = aImgHdr->iExportDir;
		aNewFSEntry->iRomFile->iExportDir.iRunAddr = aImgHdr->iExportDir;

		if(aImgHdr->iExportDirCount)
		{
			aNewFSEntry->iRomFile->iExportDir.iImagePtr = new char[aNewFSEntry->iRomFile->iExportDir.iSize];
			memcpy(aNewFSEntry->iRomFile->iExportDir.iImagePtr,
				   (TInt8*)ROM_PTR(aImgHdr->iExportDir), 
				   aNewFSEntry->iRomFile->iExportDir.iSize);
		}

		// E32 Image pointer Update
		aNewFSEntry->iRomFile->iAddresses.iImagePtr = new char[sizeof(TRomImageHeader)];
		memcpy(aNewFSEntry->iRomFile->iAddresses.iImagePtr, aImgHdr, sizeof(TRomImageHeader));
	}
	else
	{
		aNewFSEntry->iRomFile->iHwvd = KVariantIndependent;
	}

	aPa->AddFile(aNewFSEntry);

	if(aRomEntry->iAtt & KEntryAttXIP)
	{
		TRomNode::AddExecutableFile(aLastExecutable, aNewFSEntry);
	}

	return KErrNone;
}

void CoreRomImageReader::Name(String& aName, char * aUnicodeName, int aLen)
{
	int aPos = 0;
	int uncodeLen = aLen << 1;
	aName=("");
	while( aPos < uncodeLen)
	{
		if( aUnicodeName[aPos] )
			aName += aUnicodeName[aPos];
		aPos++;
	}
}

TBool CoreRomImageReader::IsExecutable(TUint8* Uids1)
{
	//In the little-endian world
	if( Uids1[3] == 0x10 &&
		Uids1[2] == 0x0 &&
		Uids1[1] == 0x0 )
	{
		if(Uids1[0] == 0x79 || Uids1[0] == 0x7a)
			return ETrue;
	}
	return EFalse;
}

void CoreRomImageReader::DeleteAll(TRomNode *node)
{
	if(!node)
		return;

	if(node->iChild)
	{
		DeleteAll(node->iChild);
	}

	if(node->iSibling)
	{
		DeleteAll(node->iSibling);
	}

	if(node->iRomFile)
	{
		if(!node->iRomFile->iDir)
		{
			if(node->iRomFile->iExportDir.iImagePtr)
			{
				delete[] (char*)node->iRomFile->iExportDir.iImagePtr;
				node->iRomFile->iExportDir.iImagePtr = 0;
			}
			if(node->iRomFile->iAddresses.iImagePtr)
			{
				delete[] (char*)node->iRomFile->iAddresses.iImagePtr;
				node->iRomFile->iAddresses.iImagePtr = 0;
			}

			if(node->iRomFile->iRbEntry)
			{
				delete node->iRomFile->iRbEntry;
				node->iRomFile->iRbEntry = 0;
			}
		}
		delete node->iRomFile;
		node->iRomFile = 0;
	}
	delete node;
	node = 0;
}


void CoreRomImageReader::Display(TRomNode *node, TInt pad)
{
	if(!node)
		return;

	Print(ELog, "\n%*s%s", pad, " ", node->iBareName);

	if(node->iChild)
	{
		pad += 2;
		Display(node->iChild, pad);
		pad -= 2;
	}

	if(node->iSibling)
	{
		Display(node->iSibling, pad);
	}
}
