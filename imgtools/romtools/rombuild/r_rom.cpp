/*
* Copyright (c) 1996-2009 Nokia Corporation and/or its subsidiary(-ies).
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


#include <e32std.h>
#include <e32std_private.h>
#include <e32uid.h>
#include "h_utl.h"
#include <string.h>
#include <stdlib.h>
#include <iomanip> 

#include "r_global.h"
#include "r_obey.h"
#include "r_rom.h"
#include "r_dir.h"
#include "patchdataprocessor.h"
#include "memmap.h"
#include "byte_pair.h"
#include "symbolgenerator.h"

const TInt KSpareExports=16;
extern TInt gThreadNum;
extern string gDepInfoFile;
extern TBool gGenDepGraph;

TUint32 DeflateCompressCheck(char *bytes,TInt size,ostream &os);
void DeflateCompress(char *bytes,TInt size,ostream &os);
void InflateUnCompress(unsigned char* source, int sourcesize,unsigned char* dest, int destsize);

EntryQueue* LoadImageWorker::m_queue = NULL;
TInt LoadImageWorker::m_errors = 0;
TMemModel LoadImageWorker::m_memmodel;
boost::mutex LoadImageWorker::m_mutex;
LoadImageWorker::LoadImageWorker(EntryQueue* aQueue, TMemModel aMemModel)
	{
	m_queue = aQueue;
	m_memmodel = aMemModel;
	}
void LoadImageWorker::operator()()
	{
	while(1)
		{
		m_mutex.lock();
		if(m_queue->size() > 0)
			{
			TRomBuilderEntry * current = m_queue->front();
			m_queue->pop();
			m_mutex.unlock();
			TInt err = current->OpenImageFile();
			m_mutex.lock();
			err = current->GetImageFileInfo(err);
			m_mutex.unlock();
			if(err)
				{
				m_mutex.lock();
				++m_errors;
				m_mutex.unlock();
				continue;
				}
			if(current->iOverrideFlags&KOverrideAddress || current->iHdr->iFlags & KImageFixedAddressExe)
				{
				if(m_memmodel != E_MM_Multiple && m_memmodel != E_MM_Flexible &&  !current->IsDll())
					current->iRomImageFlags |=KRomImageFlagFixedAddressExe;
				}
			if(gPagedRom)
				{
				if(current->iHdr->iFlags&KImageCodePaged)
					{
					current->iRomImageFlags&=~KRomImageFlagCodeUnpaged;
					current->iRomImageFlags|=KRomImageFlagCodePaged;
					}
				if(current->iHdr->iFlags&KImageCodeUnpaged)
					{
					current->iRomImageFlags|=KRomImageFlagCodeUnpaged;
					current->iRomImageFlags&=~KRomImageFlagCodePaged;
					}
				}
			if(current->iHdr->iFlags&KImageDataPaged)
				{
				current->iRomImageFlags&=~KRomImageFlagDataUnpaged;
				current->iRomImageFlags|=KRomImageFlagDataPaged;
				}
			if(current->iHdr->iFlags&KImageDataUnpaged)
				{
				current->iRomImageFlags|=KRomImageFlagDataUnpaged;
				current->iRomImageFlags&=~KRomImageFlagDataPaged;
				}
			if(current->iHdr->iFlags&KImageDebuggable)
				{
				current->iRomImageFlags|=KRomImageDebuggable;
				}
				else
				{
				current->iRomImageFlags&=~KRomImageDebuggable;
				}
			}
			else
			{
			m_mutex.unlock();
			break;
			}
		}
	}
E32Rom* CompressPageWorker::m_rom = NULL;
TInt CompressPageWorker::m_nextpage = 0;
TInt CompressPageWorker::m_totalpages = 0;
TInt CompressPageWorker::m_pagesize = 0;
boost::mutex CompressPageWorker::m_mutex;
TInt CompressPageWorker::m_error = 0;
CompressPageWorker::CompressPageWorker(E32Rom* aRom, TInt aPageSize, TInt aTotalPages, TInt aNextPage)
	{
	m_rom = aRom;
	m_pagesize = aPageSize;
	m_totalpages = aTotalPages;
	m_nextpage = aNextPage;
	}
void CompressPageWorker::operator()()
	{
	SRomPageInfo* pPageBase = (SRomPageInfo*)((TInt)m_rom->iHeader + m_rom->iHeader->iRomPageIndex);
	CBytePair bpe;
	while(1)
		{
		m_mutex.lock();
		TInt currentPageIndex = m_nextpage++;
		m_mutex.unlock();
		if(currentPageIndex < m_totalpages)
			{
			TInt inOffset = m_pagesize * currentPageIndex;
			TUint8 attrib = (TUint8)SRomPageInfo::EPageable;
			SRomPageInfo info ={ (TUint32)inOffset, (TUint16)m_pagesize, (TUint8)SRomPageInfo::EBytePair, attrib };
			TUint8* in = (TUint8*) m_rom->iHeader + inOffset;
			TUint8* out = in;
			TInt outSize = BytePairCompress(out, in, m_pagesize, &bpe);
			if(outSize == KErrTooBig)
				{
				info.iCompressionType = SRomPageInfo::ENoCompression;
				memcpy(out, in, m_pagesize);
				outSize = m_pagesize;
				}
				if(outSize < 0 )
					{
					m_mutex.lock();
					m_error = outSize;
					m_mutex.unlock();
					break;
					}
				info.iDataSize = (TUint16) outSize;
				*(pPageBase + currentPageIndex) = info;
				if((currentPageIndex & 255) == 255)
					{
					m_mutex.lock();
					Print(EAlways, ".\n");
					m_mutex.unlock();
					}
				}
			else
			{
			break;
			}
		}
	}
	
////////////////////////////////////////////////////////////////////////

TAddressRange::TAddressRange() 
	: iImagePtr(0), iImageAddr(0), iRunAddr(0), iSize(0) 
	{
	}

void TAddressRange::Append(TAddressRange& aRange)
	{ 
	if(aRange.iSize) 
		{ 
		aRange.iImagePtr = iImagePtr;
		aRange.iImageAddr = iImageAddr;
		aRange.iRunAddr = iRunAddr;
		Extend(aRange.iSize); 
		} 
	}

void TAddressRange::Move(TInt aOffset) 
	{ 
	iImagePtr = static_cast<char*>(iImagePtr) + aOffset; 
	iImageAddr += aOffset; 
	iRunAddr += aOffset;
	}

void TAddressRange::Extend(TInt aOffset) 
	{ 
	Move(aOffset);
	iSize += aOffset; 
	}

////////////////////////////////////////////////////////////////////////

inline TUint32 AlignData(TUint32 anAddr)
	{
	return ((anAddr+0x0f)&~0x0f);
	}

TUint32 E32Rom::AlignToPage(TUint32 anAddr)
	{
	TUint a=(TUint)iObey->iPageSize-1;
	return ((anAddr+a)&~a);
	}

/*
Allocate virtual memory for static data in rom.
@param aAddr Base address of last allocated memory.
@param aSize Size of memory to allocate.
@return Address allocated. This is below aAddr.
*/
TUint32 E32Rom::AllocVirtual(TUint32 aAddr,TUint aSize)
	{
	TInt align = iObey->iVirtualAllocSize;
	if(align<0)
		{
		align = -align; // get correct sign
		// -ve align means also align to next power-of-two >= aSize...
		while(aSize>(TUint)align)
			align <<=1;
		}

	TUint mask = (TUint)align-1;
	aSize = (aSize+mask)&~mask; // round up
	aAddr &= ~mask; // round down
	return aAddr-aSize;
	}

TUint32 E32Rom::AlignToChunk(TUint32 anAddr)
	{
	TUint a=(TUint)iObey->iChunkSize-1;
	return ((anAddr+a)&~a);
	}

COrderedFileList::COrderedFileList(TInt aMaxFiles)
	: iCount(0), iMaxFiles(aMaxFiles), iOrderedFiles(NULL)
	{}

COrderedFileList::~COrderedFileList()
	{
	iCount=0;
	if(iOrderedFiles)
		delete[] iOrderedFiles;
	}

COrderedFileList* COrderedFileList::New(TInt aMaxFiles)
	{
	COrderedFileList *pL=new COrderedFileList(aMaxFiles);
	pL->iOrderedFiles=new TRomBuilderEntry*[aMaxFiles];
	return pL;
	}

void COrderedFileList::Add(TRomBuilderEntry* anEntry)
	{
	// note: this routine assumes that the set of kernel-mode files
	// (primary/extension/device) required by a given variant is linearly ordered by <=
	// e.g. can't have three variants {A,B,V1} {A,B,C,V2} {A,C,V3} because B and C
	// are unordered with respect to <=, since neither of
	// {n | Vn requires B} and {n | Vn requires C} is a subset of the other.
	// In a case like this, ROMBUILD may fail to resolve the addresses of some global data
	THardwareVariant& v=anEntry->iHardwareVariant;
	TInt i=0;
	while(i<iCount && v<=iOrderedFiles[i]->iHardwareVariant) i++;
	TInt j=iCount;
	while(j>i)
		{
		iOrderedFiles[j]=iOrderedFiles[j-1];
		j--;
		}
	iOrderedFiles[i]=anEntry;
	iCount++;
	}

void GetFileNameAndUid(char *aDllName, TUid &aDllUid, char *aExportName)
	{	
	strcpy(aDllName, aExportName);
	aDllUid=KNullUid;
	TInt start;
	for (start=0; start<(TInt)strlen(aExportName) && aExportName[start]!='['; start++)
		;
	if (start==(TInt)strlen(aExportName))
		start=KErrNotFound;
	TInt end=strlen(aExportName)-1;
	while (end>=0)
		{
		if (aExportName[end]==']')
			break;
		--end;
		}
	if (end<0)
		end=KErrNotFound;

	if ((start!=KErrNotFound) && (end!=KErrNotFound) && (end>start))
		{
		// Importing from DLL with Uid
		char uidStr[0x100];
		strcpy(uidStr, "0x");
		strncat(uidStr, aExportName+start+1, end-start-1); 

				 
		if (IsValidNumber(uidStr)){
			TUint32 u = 0;
			Val(u,uidStr);
			aDllUid=TUid::Uid(u);
			char *dot=aExportName+strlen(aExportName)-1;
			while (dot>=aExportName)
				{
				if (*dot=='.')
					break;
				dot--;
				}
			if (dot<aExportName) // no dot
				aDllName[start]=0;
			else
				{
				aDllName[start]=0;
				strcat(aDllName, dot);
				}
			}
		}
	}

E32Rom::E32Rom(CObeyFile *aObey) {

	iSize=sizeof(TRomLoaderHeader)+aObey->iRomSize;
	iObey=aObey;
	iPeFiles=NULL;
	iSymGen = NULL ;
	if(gLowMem)
	{
		iImageMap = new Memmap();

		if(iImageMap == NULL)
		{
			iSize = 0;
			Print(EError, "Out of memory.\n");
		}
		else
		{
			iImageMap->SetMaxMapSize(iSize);
			if(iImageMap->CreateMemoryMap(0, 0xff) == EFalse)
			{
				iSize = 0;
				Print(EError, "Failed to create image map object");

				iImageMap->CloseMemoryMap(ETrue);
				delete iImageMap;
				iImageMap = NULL;
			}
			else
			{
				iData = iImageMap->GetMemoryMapPointer();
			}
		}
	}
	else
	{
		iData=new char [iSize];
		if (iData==NULL)
			{
			iSize=0;
			Print(EError, "Out of memory.\n");
			}
		HMem::Set(iData, 0xff, iSize);
	}
	iHeader=(TRomHeader *)(iData+sizeof(TRomLoaderHeader));
	iExtensionRomHeader=NULL;
	iLoaderHeader=(TRomLoaderHeader *)iData;
	iSectionPtr=(char *)iHeader+aObey->iSectionStart-aObey->iRomLinearBase+sizeof(TRomSectionHeader);
	TheRomHeader=(ImpTRomHeader *)iHeader;
	TheRomMem=(TUint32)iHeader;
	iNextDataChunkBase=aObey->iKernDataRunAddress;
	iTotalSvDataSize=0;
	iNextDllDataAddr=aObey->iDllDataTop;
	iPrevPrimaryAddress=NULL;
	iPrevVariantAddress=NULL;
	iVariantFileLists=NULL;
	iImportsFixedUp=0;
	iBranchesFixedUp=0;
	iVtableEntriesFixedUp=0;
	iOverhead=0;
	}

E32Rom::~E32Rom() {
	if(iSymGen){		
		delete iSymGen;
		iSymGen = NULL ;
	}
	if(gLowMem)
	{
		iImageMap->CloseMemoryMap(ETrue);
		delete iImageMap;
	}
	else
		delete iData;
	delete [] iPeFiles;
	if (iVariantFileLists)
		{
		TInt i;
		for (i=0; i<iObey->iNumberOfVariants; i++)
			delete iVariantFileLists[i];
		delete [] iVariantFileLists;
		}
	}

TInt E32Rom::Align(TInt aVal)
//
// Align to romalign
//
	{
 	
	return ((aVal+iObey->iRomAlign-1)/iObey->iRomAlign)*iObey->iRomAlign;
	}

TInt E32Rom::LoadContents(char*& anAddr, TRomHeader* aHeader)
	{
	// Load all the PE/E32Image files
	TInt nfiles=iObey->iNumberOfPeFiles;
	iPeFiles=new TRomBuilderEntry* [nfiles];
	if (!iPeFiles)
		return Print(EError, "Out of memory.\n");

	TInt r=TranslateFiles();
	if (r!=KErrNone)
		return r;
	
	ProcessDllData();

	EnumerateVariants();

	r=BuildDependenceGraph();
	if (r!=KErrNone)
		return r;

	// Update the ROM image headers with SMP information.
	SetSmpFlags();

	r=ProcessDependencies();
	if (r!=KErrNone)
		return r;

	char* addr = anAddr;
	TRomExceptionSearchTable* exceptionSearchTable = 0;

	if(gPagedRom)
		{ 
		gDepInfoFile = iObey->iRomFileName; 
		iObey->SetArea().DefaultArea()->SortFilesForPagedRom();
		// exception search table needs to go at start of ROM to make it not demand paged...
		addr = ReserveRomExceptionSearchTable(addr,exceptionSearchTable);
		}
	else if(gGenDepGraph)
		{
			Print(EWarning, "Not dependence information in an unpaged ROM.");
		}

	addr=WriteDirectory(addr, aHeader);
	// Aligned

	TRACE(TSCRATCH,Print(EAlways,"Directory written\n"));

	// Stick all the files in ROM

	TReloc* relocationTable;
	addr = AllocateRelocationTable(addr, relocationTable);
	aHeader->iRelocInfo = relocationTable ? ActualToRomAddress(relocationTable) : 0;
	// Aligned

	TRACE(TSCRATCH,Print(EAlways,"Done AllocateRelocationTable\n"));

	CalculateDataAddresses();
	addr = LayoutRom(addr);

	TRACE(TSCRATCH,Print(EAlways,"Done LayoutRom\n"));

	FillInRelocationTable(relocationTable);

	TRACE(TSCRATCH,Print(EAlways,"Done FillInRelocationTable\n"));

	if(!exceptionSearchTable)
		addr = ReserveRomExceptionSearchTable(addr,exceptionSearchTable);
	ConstructRomExceptionSearchTable(exceptionSearchTable);

	TRACE(TSCRATCH,Print(EAlways,"Done ConstructRomExceptionSearchTable\n"));

	LinkKernelExtensions(iObey->iExtensions, iObey->iNumberOfExtensions);

	TRACE(TSCRATCH,Print(EAlways,"Done LinkKernelExtensions\n"));

	r=ResolveDllRefTables();
	if (r!=KErrNone)
		return r;
	r=ResolveImports();
	if (r!=KErrNone)
		return r;
	if (iObey->iCollapseMode>ECollapseNone)
		{
		r=CollapseImportThunks();
		if (r!=KErrNone)
			return r;
		if (iObey->iCollapseMode>ECollapseImportThunksOnly)
			{
			r=CollapseBranches();
			if (r!=KErrNone)
				return r;
			}
		Print(ELog,"%d imports, %d branches, %d vtable entries fixed up\n",
			  iImportsFixedUp,iBranchesFixedUp,iVtableEntriesFixedUp);
		}

	iSizeUsed=(TInt)addr-(TInt)iHeader;
	Print(ELog, "\n%08x of %08x bytes used.\n", iSizeUsed, iSize-sizeof(TRomLoaderHeader));

	// round the rom size in the header to a multiple of 1 Megabyte
	TInt rounded = ((iSizeUsed+0xfffff)&0xfff00000);
	if (rounded < iObey->iRomSize)
		iObey->iRomSize = rounded;
	iUncompressedSize = iSizeUsed;

	anAddr = addr;

	return KErrNone;
	}


void E32Rom::CreatePageIndex(char*& aAddr)
	{
	iHeader->iRomPageIndex = 0;
	if(gPagedRom==0 || gEnableCompress==0)
		return;

	// Insert space for Rom Page Info table...
	iHeader->iRomPageIndex = (TInt)aAddr-(TInt)iHeader;
	TInt pageSize = iObey->iPageSize;
	TInt numPages = iSize/pageSize+1;
	TInt pageInfoSize = numPages*sizeof(SRomPageInfo);
	
	gPageIndexTableSize = pageInfoSize;		// For accumulate uncompressed un-paged size added Page Index Table
		
	Print(ELog, "Inserting %d bytes for RomPageInfo at ROM offset 0x%08x\n", pageInfoSize, iHeader->iRomPageIndex);
	memset(aAddr,0,pageInfoSize);
	iOverhead += pageInfoSize;
	aAddr += pageInfoSize;
	}

TInt E32Rom::SetupPages()
	{
	iHeader->iPageableRomStart = 0;
	iHeader->iPageableRomSize = 0;
	iHeader->iDemandPagingConfig = gDemandPagingConfig;

	if(!gPagedRom)
		return KErrNone;

	// Initialise the Rom Page Info for each page which indicates it is uncompressed...
	TInt pageSize = iObey->iPageSize;

	TInt pagedStartOffset = 0x7fffffff;
	TRomBuilderEntry* e = iObey->SetArea().DefaultArea()->iFirstPagedCode;
	if(e)
		{
		// we have paged code...
		pagedStartOffset = e->RomEntry()->iAddressLin-iObey->iRomLinearBase;
		pagedStartOffset = (pagedStartOffset+pageSize-1)&~(pageSize-1); // round up to next page;
		iHeader->iPageableRomStart = pagedStartOffset;
		TInt pageableSize = iSizeUsed-pagedStartOffset;
		if(pageableSize>0)
			iHeader->iPageableRomSize = pageableSize;
		}
	
	return KErrNone;
	}

TInt E32Rom::CompressPages()
	{
	
	if(!gPagedRom || !gEnableCompress)
		return KErrNone;

	// Initialise the Rom Page Info for each page which indicates it is uncompressed...
	TInt pageSize = iObey->iPageSize;
	TInt numPages = (iSizeUsed+pageSize-1)/pageSize;

	TInt pagedStartOffset = iHeader->iPageableRomStart;

	Print(EAlways, "\nCompressing pages...\n");
	TInt inOffset = 0;
    SRomPageInfo* pi = (SRomPageInfo*)((TInt)iHeader+iHeader->iRomPageIndex);
	TInt currentIndex = 0;
	while(inOffset < pagedStartOffset)
		{
		
		TUint8 attrib = (TUint8)0;
		SRomPageInfo info = {(TUint32)inOffset,(TUint16)pageSize,(TUint8)SRomPageInfo::EBytePair,(TUint8)attrib};
		info.iDataSize = (TUint16) pageSize;
		*pi++ = info;
		inOffset += pageSize;
		if((currentIndex & 255) == 255)
			Print(EAlways, ".\n");
		currentIndex++;
		}
	CompressPageWorker compressworker(this, pageSize, numPages, currentIndex);

	boost::thread_group threads;
	for(int i = 0; i < gThreadNum; i++)
		{
		threads.create_thread(compressworker);
		}
	threads.join_all();
	if(compressworker.m_error < 0)
	       return compressworker.m_error;
	for(;currentIndex < numPages - 1; currentIndex++)
		{
		pi++;
		SRomPageInfo* prev = pi - 1;
		TUint8* dest = (TUint8*) iHeader + prev->iDataStart + prev->iDataSize;
		TUint8* src = (TUint8*) iHeader + pi->iDataStart;
		memcpy(dest, src, pi->iDataSize);
		pi->iDataStart = prev->iDataStart + prev->iDataSize;
		}
	TInt relSize = pi->iDataStart + pi->iDataSize;

	memset((TUint8*)iHeader + relSize, 0xff, iSizeUsed - relSize);
	TInt compression = (iSizeUsed >= 1000) ? (relSize*10)/(iSizeUsed/1000) : (relSize*10000)/iSizeUsed;
	Print(EAlways, "%d.%02d%%\n", compression/100, compression%100);
	iSizeUsed = relSize;
	return KErrNone;
	}

TInt E32Rom::CompressPage(SRomPageInfo& aPageInfo, TInt aOutOffset, CBytePair * aBPE)
	{
	TUint8* in = (TUint8*)iHeader+aPageInfo.iDataStart;
	TInt inSize = aPageInfo.iDataSize;
	TUint8* out = (TUint8*)iHeader+aOutOffset;
	switch(aPageInfo.iCompressionType)
		{
	case SRomPageInfo::ENoCompression:
		memcpy(out,in,inSize);
		return inSize;

	case SRomPageInfo::EBytePair:
		{
		TInt r = BytePairCompress(out, in, inSize, aBPE);
		if(r!=KErrTooBig)
			return r;
		// data can't be compressed...
		aPageInfo.iCompressionType = SRomPageInfo::ENoCompression;
		memcpy(out,in,inSize);
		return inSize;
		}

	default:
		Print(EError, "Unsupported page compression type (%d)\n", aPageInfo.iCompressionType);
		return KErrNotSupported;
		}
	}


// Avoid "warning" about constant expression
static void checksize(const char* aTypeName, int aSize, int aCorrectSize)
	{
	if (aSize != aCorrectSize)
		Print(EError, "sizeof(%s) = %d, should be %d\n", aTypeName, aSize, aCorrectSize);
	}

TInt E32Rom::CreateExtension(MRomImage* aKernelRom) 
	{

	// sanity check
	checksize("TExtensionRomHeader", sizeof(TExtensionRomHeader), 128);

	char *addr=(char *)iHeader;
	iExtensionRomHeader=(TExtensionRomHeader*)addr;
	addr += sizeof(TExtensionRomHeader);
	// Aligned

	TRomHeader dummy;
	TInt r=LoadContents(addr, &dummy);
	if (r!=KErrNone)
		{
		Print(EError, "LoadContents failed - return code %d\n", r);
		if(iSymGen)
			iSymGen->WaitThreads();
		return r;
		}
	iExtensionRomHeader->iRomRootDirectoryList = dummy.iRomRootDirectoryList;

	iLoaderHeader->SetUp(iObey);
	FinaliseExtensionHeader(aKernelRom);
	DisplayExtensionHeader();
	if(iSymGen)
		iSymGen->WaitThreads();
	return KErrNone;
	}
	
TInt E32Rom::Create()
	{

	TVariantList::Setup(iObey);
	char *addr=(char *)iHeader;
	// Aligned

	// Put the bootstrap in rom - it contains a hole at offset 0x80 where the 
	// TRomHeader information will be placed later

	gBootstrapSize = HFile::Read(iObey->iBootFileName, iHeader);
	if (gLogLevel & LOG_LEVEL_COMPRESSION_INFO)
		Print(ELog, "bootstrapSize: 0x%08x, (%d)\n", gBootstrapSize, gBootstrapSize);	
	
	if (gBootstrapSize==0)
		return Print(EError, "Cannot open the bootstrap file '%s'.\n", iObey->iBootFileName);
	gBootstrapSize=Align(gBootstrapSize);
	addr+=gBootstrapSize;
	iOverhead=gBootstrapSize;
	// Aligned

	CreatePageIndex(addr);

	TInt r=LoadContents(addr, iHeader);
	if (r!=KErrNone)
		{
		Print(EError, "LoadContents failed - return code %d\n", r);
		if(iSymGen)
			iSymGen->WaitThreads();
		return r;
		}

	r = SetupPages(); // initialize ROM paging info...
	if(r!=KErrNone)
		{
		Print(EError, "Setup pages information failed - return code %d\n", r);
		if(iSymGen)
			iSymGen->WaitThreads();
		return r;
		}
	
	r = CheckUnpagedMemSize(); // check for unpaged memory overflow
	if(r!=KErrNone)
	{
		if(iSymGen)
			iSymGen->WaitThreads();
		return r;
	}
	
	r = CompressPages(); // setup ROM paging info...
	if(r!=KErrNone)
		{
		Print(EError, "CompressPages failed - return code %d\n", r);
		if(iSymGen)
			iSymGen->WaitThreads();
		return r;
		}

	iLoaderHeader->SetUp(iObey);
	ImpTRomHeader* header = (ImpTRomHeader *)iHeader;
	header->SetUp(iObey);
	header->iTotalSvDataSize=iTotalSvDataSize;
	if (iObey->iMemModel==E_MM_Direct)
		{
		header->iUserDataAddress=iObey->iDataRunAddress;
		header->iTotalUserDataSize=iNextDataChunkBase-iObey->iDataRunAddress;
		}
	else
		{
		header->iUserDataAddress=iObey->iDllDataTop;
		header->iTotalUserDataSize=iObey->iDllDataTop-iNextDllDataAddr;
		}
	if (header->iRomSectionHeader)
		FinaliseSectionHeader();	// sorts out the second section checksum

	header->CheckSum(iObey->iCheckSum);	// finally, sort out the overall checksum

	header->Display();

	TUint testCheckSum = HMem::CheckSum((TUint *)iHeader, iHeader->iRomSize);
	Print(ELog, "Rom 32bit words sum to   %08x\n", testCheckSum);
	if (testCheckSum != iObey->iCheckSum){
		if(iSymGen)
			iSymGen->WaitThreads();
		return Print(EError, "Rom checksum is incorrect: %08x should be %08x\n",
					testCheckSum, iObey->iCheckSum);
	}

	// 8bit checksum = sum of bytes
	// odd/even checksum = checksum of the odd and even halfwords of the image

	Print(ELog, "Rom 8bit checksum        %08x\n", HMem::CheckSum8((TUint8 *)iHeader, iHeader->iRomSize));
	Print(ELog, "Rom 8bit odd checksum    %08x\n", HMem::CheckSumOdd8((TUint8 *)iHeader, iHeader->iRomSize));
	Print(ELog, "Rom 8bit even checksum   %08x\n", HMem::CheckSumEven8((TUint8 *)iHeader, iHeader->iRomSize));

	if (iHeader->iPrimaryFile)
		{
		if (iObey->iKernelModel==ESingleKernel)
			{
			Print(ELog,"\nPrimary details (Single Kernel):\n");
			TRomEntry *r = (TRomEntry *)(iHeader->iPrimaryFile-iObey->iRomLinearBase+(char *)iHeader);
			TRomImageHeader *hdr = (TRomImageHeader *)(r->iAddressLin-iObey->iRomLinearBase+(char *)iHeader);
			Display(hdr);
			Print(ELog,"\n");
			}
		else if (iObey->iKernelModel==EMultipleKernels)
			{
			Print(ELog,"\nPrimary details (Multiple Kernels):\n");
			TRomEntry *r = (TRomEntry *)(iHeader->iPrimaryFile-iObey->iRomLinearBase+(char *)iHeader);
			TInt n=1;
			FOREVER
					{
					Print(ELog,"\nKernel %d:\n",n);
					TRomImageHeader *hdr = (TRomImageHeader *)(r->iAddressLin-iObey->iRomLinearBase+(char *)iHeader);
					Display(hdr);
					Print(ELog,"\n");
					if (!hdr->iNextExtension)
						break;
					r=(TRomEntry*)(hdr->iNextExtension-iObey->iRomLinearBase+(char*)iHeader);
					n++;
					}
			}
		}
	if(iSymGen)
			iSymGen->WaitThreads();
	return KErrNone;
	}

char *E32Rom::WriteDirectory(char *aAddr, TRomHeader* aHeader)
//
// Write the directory structure where appropriate
//
	{

	TLinAddr dirptr=ActualToRomAddress(aAddr);
	if (iObey->iSectionPosition==-1)
		{
		// Just the one rom.  Put the directory structure at aAddr
		iDirectorySize=WriteHeadersToRom(aAddr);
		aAddr+=Align(iDirectorySize);
		}
	else
		{
		// Put the directory structure in the second ROM, after the SectionHeader
		// and the second section information for first section files
		TInt size=0;
		TInt i;
		for (i=0; i<iObey->iNumberOfPeFiles; i++)
			{
			TRomBuilderEntry *file=iPeFiles[i];
			if (file->iRomSectionNumber!=0)
				break;
			TInt size1, size2;
			file->SizeInSections(size1,size2);
			size+=size2;
			}
		dirptr=ActualToRomAddress(iSectionPtr)+size;
		iDirectorySize=WriteHeadersToRom(RomToActualAddress(dirptr));
		}
	aHeader->iRomRootDirectoryList=dirptr;
	return aAddr;
	}

void E32Rom::Display(TRomImageHeader *aHdr)
//
// Print info on a file
//
	{
	TRACE(TAREA, Print(ELog, "+Display header %08x\n", aHdr));
	Print(ELog, "Uids:                    %08x %08x %08x %08x\n", aHdr->iUid1, aHdr->iUid2, aHdr->iUid3, aHdr->iUidChecksum);
	Print(ELog, "Entry point:             %08x\n", aHdr->iEntryPoint);
	Print(ELog, "Code start addr:         %08x\n", aHdr->iCodeAddress);
	Print(ELog, "Data start addr:         %08x\n", aHdr->iDataAddress);
	Print(ELog, "DataBssLinearBase:       %08x\n", aHdr->iDataBssLinearBase);
	Print(ELog, "Text size:               %08x\n", aHdr->iTextSize);
	Print(ELog, "Code size:               %08x\n", aHdr->iCodeSize);
	Print(ELog, "Data size:               %08x\n", aHdr->iDataSize);
	Print(ELog, "BssSize:                 %08x\n", aHdr->iBssSize);
	Print(ELog, "Total data size:         %08x\n", aHdr->iTotalDataSize);
	Print(ELog, "Heap min:                %08x\n", aHdr->iHeapSizeMin);
	Print(ELog, "Heap max:                %08x\n", aHdr->iHeapSizeMax);
	Print(ELog, "Stack size:              %08x\n", aHdr->iStackSize);
	Print(ELog, "Dll ref table:           %08x\n", aHdr->iDllRefTable);
	Print(ELog, "Export directory:        %08x\n", aHdr->iExportDir);
	Print(ELog, "Export dir count:        %08x\n", aHdr->iExportDirCount);
	Print(ELog, "Hardware variant:        %08x\n", aHdr->iHardwareVariant);
	Print(ELog, "Flags:                   %08x\n", aHdr->iFlags);
	Print(ELog, "Secure ID:               %08x\n", aHdr->iS.iSecureId);
	Print(ELog, "Vendor ID:               %08x\n", aHdr->iS.iVendorId);
	Print(ELog, "Capability:              %08x %08x\n", aHdr->iS.iCaps[1], aHdr->iS.iCaps[0]);
	Print(ELog, "Tools Version:           %d.%02d(%d)\n", aHdr->iToolsVersion.iMajor, aHdr->iToolsVersion.iMinor, aHdr->iToolsVersion.iBuild);
	Print(ELog, "Module Version:          %d.%d\n", aHdr->iModuleVersion>>16, aHdr->iModuleVersion&0x0000ffffu);
	Print(ELog, "Exception Descriptor:    %08x\n", aHdr->iExceptionDescriptor);
	Print(ELog, "Priority:                %d\n", aHdr->iPriority);
	}

void E32Rom::DisplaySizes(TPrintType aWhere)
	{

	Print(aWhere, "Summary of file sizes in rom:\n");
	Print(aWhere, "Overhead (bootstrap+gaps+sectioning)\t%d\n", iOverhead);
	Print(aWhere, "Overhead (directory size)\t%d\n", iDirectorySize);
	TRomBuilderEntry *file=iObey->FirstFile();
	while (file)
		{
		file->DisplaySize(aWhere);
		file=iObey->NextFile();
		}
	Print(aWhere, "\nTotal used\t%d\n", iSizeUsed);
	Print(aWhere, "Free\t%d\n", iObey->iRomSize-iSizeUsed);

	if (iObey->SetArea().Count() > 1)
		{
		Print(aWhere, "\nArea summary:\n");
		for (NonDefaultAreasIterator it(iObey->SetArea());
			 ! it.IsDone();
			 it.GoToNext())
			{
			const Area& a = it.Current();
			Print(aWhere, "%s\t used: %d bytes / free: %d bytes\n",
				  a.Name(), a.UsedSize(), a.MaxSize()-a.UsedSize());
			}
		}
	}

TInt E32Rom::RequiredSize()
//
// Get the (approximate) required size of the Rom
//
	{

	TInt sum=0;
	TRomBuilderEntry *current=iObey->FirstFile();
	while (current)
		{
		if (current->iResource || current->HCRDataFile())
			sum+=Align(HFile::GetLength(current->iFileName));
		else
 			sum+=Align(current->SizeInRom());
		current=iObey->NextFile();
		}
	return sum+iOverhead+Align(iDirectorySize);
	}

TInt E32Rom::TranslateFiles()
//
// Load and translate all PE/E32 image files
//
	{

	TInt i=0;
	TInt total_errors = 0;
	TRomBuilderEntry* current = 0;
	EntryQueue imagesQueue;
	for (current = iObey->FirstFile(); current; current = iObey->NextFile() )
		{	
		if ((!current->iResource) && (!current->HCRDataFile()))
			{
			iPeFiles[i++]=current;
			imagesQueue.push(current);
			}
		}
	LoadImageWorker loadworker(&imagesQueue, iObey->iMemModel);
	boost::thread_group threads;
	for(int i = 0; i < gThreadNum; i++)
		{
		threads.create_thread(loadworker);
		}
	threads.join_all();

	total_errors = loadworker.m_errors;
	if (total_errors)
		return KErrGeneral;
	for (current = iObey->FirstFile(); current; current = iObey->NextFile() )
		{
		if ((!current->iResource) && (!current->HCRDataFile()))
			{
			TInt err = CheckForVersionConflicts(current);
			total_errors += err;
			}
		}
	return total_errors ? KErrGeneral : KErrNone;
	}

const char FileTypeFile[]=		"File     ";
const char FileTypePrimary[]=	"Primary  ";
const char FileTypeVariant[]=	"Variant  ";
const char FileTypeExtension[]="Extension";
const char FileTypeDevice[]=	"Device   ";

void E32Rom::EnumerateVariants()
	{
	TInt vIndex;
	TInt nFiles=iObey->iNumberOfExtensions+iObey->iNumberOfDevices+3;
	iVariantFileLists=new COrderedFileList*[iObey->iNumberOfVariants];
	for (vIndex=0; vIndex<iObey->iNumberOfVariants; vIndex++)
		iVariantFileLists[vIndex]=COrderedFileList::New(nFiles);
	for (vIndex=0; vIndex<iObey->iNumberOfVariants; vIndex++)
		{
		TRomBuilderEntry *variant=iObey->iVariants[vIndex];
		THardwareVariant& v=variant->iHardwareVariant;
		TInt i;
		for (i=0; i<iObey->iNumberOfPrimaries; i++)
			{
			TRomBuilderEntry *primary=iObey->iPrimaries[i];
			if (v<=primary->iHardwareVariant)
				{
				iVariantFileLists[vIndex]->Add(primary);
				break;
				}
			}
		iVariantFileLists[vIndex]->Add(variant);
		for (i=0; i<iObey->iNumberOfExtensions; i++)
			{
			TRomBuilderEntry *ext=iObey->iExtensions[i];
			if (v<=ext->iHardwareVariant)
				{
				iVariantFileLists[vIndex]->Add(ext);
				}
			}
		for (i=0; i<iObey->iNumberOfDevices; i++)
			{
			TRomBuilderEntry *dev=iObey->iDevices[i];
			if (v<=dev->iHardwareVariant)
				{
				iVariantFileLists[vIndex]->Add(dev);
				}
			}
		}
	TUint totalDataBss=0;
	for (vIndex=0; vIndex<iObey->iNumberOfVariants; vIndex++)
		{
		TRomBuilderEntry *variant=iObey->iVariants[vIndex];
		THardwareVariant& v=variant->iHardwareVariant;
		COrderedFileList& files=*iVariantFileLists[vIndex];
		TInt count=files.Count();
		Print(ELog,"\nVariant %08x, %d Files:\n",v.ReturnVariant(),count); 
		TInt i;
		TUint dataOffset=0;
		for (i=0; i<count; i++)
			{
			TRomBuilderEntry *pF=files[i];
			TUint gap=0;
			if (pF->iDataAlignment>0)
				{
				gap=(pF->iDataAlignment-dataOffset)%(pF->iDataAlignment);
				dataOffset+=gap;
				}
			E32ImageHeader *pH=pF->iHdr;
			if (pF->iDataBssOffset!=0xffffffff && pF->iDataBssOffset!=dataOffset)
				Print(EError,"Conflicting DataBss addresses\n");
			pF->iDataBssOffset=dataOffset;
			TInt dataSize=AlignData(pH->iDataSize+pH->iBssSize);
			const char* pT=FileTypeFile;
			if (pF->Primary())
				pT=FileTypePrimary;
			if (pF->Variant())
				pT=FileTypeVariant;
			if (pF->Extension())
				pT=FileTypeExtension;
			if (pF->Device())
				pT=FileTypeDevice;
			Print(ELog,"%s %12s[%08x] DataSize=%6x DataOffset=%6x",pT,pF->iName,pF->iHardwareVariant.ReturnVariant(),dataSize,dataOffset);
			if (gap)
				Print(ELog, " (gap %x for %x alignment)\n", gap, pF->iDataAlignment);
			Print(ELog, "\n");
			dataOffset+=dataSize;
			}
		if (dataOffset>totalDataBss)
			totalDataBss=dataOffset;
		}
	Print(ELog,"\nTotal SvData size=%6x\n",totalDataBss);
	iTotalSvDataSize=totalDataBss;
	}

TInt E32Rom::LoadDataToRom(TRomBuilderEntry *aFile, TAddressRange& aAddress, CBytePair* aBPE)
//
// Load a data file to rom
//
	{
	const char* tn = "resource";
	if (aFile->iNonXIP)
		tn = (aFile->iCompression) ? "compressed executable" : "uncompressed executable";
	Print(ELog,"Reading %s %s to rom linear address %08x\n", tn, aFile->iFileName, aAddress.iImageAddr);

	TUint32 size=HFile::GetLength(aFile->iFileName);
	if (size==0)
		{
		Print(EWarning, "File %s does not exist or is 0 bytes in length.\n",aFile->iFileName);
		return size;
		}

	aFile->iHeaderRange=aAddress;
	char* addr = (char*)aFile->iHeaderRange.iImagePtr;
	const char* src = NULL; 
	ostringstream os; 
	if (aFile->iNonXIP)
		{
		E32ImageFile f(aBPE);
		TInt r = f.Open(aFile->iFileName);
		// is it really a valid E32ImageFile?
		if (r != KErrNone)
			{
			Print(EWarning, "File '%s' is not a valid executable.  Loading file as data.\n", aFile->iFileName);
			aFile->iNonXIP = EFalse;
			}
		else
			{
			TUint compression = f.iHdr->CompressionType();
			if (compression != aFile->iCompression || aFile->iPreferred)
				{
				if (compression == 0)
					Print(ELog, "Compressing file %s\n", aFile->iFileName);
				else if (aFile->iCompression == 0)
					Print(ELog, "Decompressing file %s\n", aFile->iFileName);
				f.iHdr->iCompressionType = aFile->iCompression;
				if (aFile->iPreferred)
					{
					f.iHdr->iModuleVersion &= ~0xffffu;
					f.iHdr->iModuleVersion |= 0x8000u;
					}
				f.UpdateHeaderCrc();
				}
			Print(ELog, "Compression Method:0x%08x/0x%08x \n", f.iHdr->CompressionType(), aFile->iCompression);
			os << f; 
			size = (os.str()).length(); 
			src = (os.str()).c_str(); 
			}
		}
	if (addr+size>iData+iSize)
		{
		Print(EError, "Can't fit '%s' in Rom.\n", aFile->iFileName);
		Print(EError, "Rom overflowed by approximately 0x%x bytes.\n", RequiredSize()-iObey->iRomSize);
		exit(667);
		}
	if (src)
		memcpy(addr, src, size);
	else
		size = HFile::Read(aFile->iFileName, (TAny *)addr);
	Print(ELog,"Size:                    %08x\n", size);

	aFile->iHeaderRange.iSize=size;
	aAddress.Extend(aFile->iHeaderRange.iSize);
	return size;
	}


void E32Rom::CalculateDataAddresses()
//
//
//
	{

	TInt i;
	TUint32 maxkern = 0;
	Print(ELog, "\nCalculating kernel limit.\n");
	for (i=0; i<iObey->iNumberOfPeFiles; i++)
		{
		TRomBuilderEntry* e = iPeFiles[i];
		if (e->Primary())
			{
			// this is a kernel
			TUint32 stack = AlignToPage(e->iHdr->iStackSize);
			TUint32 heap = AlignToPage(e->iHdr->iHeapSizeMax);
			if (stack + heap > maxkern)
				maxkern = stack + heap;
			}
		}
	iObey->iKernelLimit = AlignToChunk(maxkern + iTotalSvDataSize) + iObey->iKernDataRunAddress;
	if (iObey->iMemModel==E_MM_Direct)
		iNextDataChunkBase=iObey->iDataRunAddress;
	else
		iNextDataChunkBase = iObey->iKernelLimit;
	Print(ELog, "\nCalculating data addresses.\n");
	for (i=0; i<iObey->iNumberOfPeFiles; i++)
		{
		TRACE(TAREA,Print(ELog,"CalculateDataAddresses %d %s\n",i,iPeFiles[i]->iFileName));
		CalculateDataAddress(iPeFiles[i]);
		}
	TRACE(TIMPORT,Print(ELog,"CalculateDataAddresses complete\n"));

	// On moving model, advance kernel limit past fixed process data areas
	if (iObey->iMemModel==E_MM_Moving)
		iObey->iKernelLimit = iNextDataChunkBase;
	}

void E32Rom::CalculateDataAddress(TRomBuilderEntry *aFile)
//
// Work out where the .data/.bss will be
//
	{
	TUint32 dataBssSize=aFile->iRomNode->iRomFile->iTotalDataBss;
	TUint32 dataRunAddr;
	if (aFile->Primary())
		{
		dataRunAddr = iObey->iKernDataRunAddress;
		CPU = aFile->iHdr->CpuIdentifier();
		}
	else
		{
		dataRunAddr = iObey->iDataRunAddress;
		if (iObey->iMemModel!=E_MM_Multiple && iObey->iMemModel!=E_MM_Flexible && (aFile->iHdr->iFlags & KImageFixedAddressExe))	// propagate 'fixed' from PETRAN
			{
			dataRunAddr=0xffffffff;
			}
		}
	if (aFile->iOverrideFlags&KOverrideAddress)
		{
		if ((iObey->iMemModel!=E_MM_Multiple && iObey->iMemModel!=E_MM_Flexible) || aFile->iRelocationAddress!=0xffffffff)
			dataRunAddr=aFile->iRelocationAddress;
		if (aFile->Extension() || aFile->Variant() || aFile->Device())
			Print(EError, "reloc not permitted with extension/variant/device\n");
		}
	if (!aFile->IsDll() && !aFile->Primary() && (dataRunAddr==0xffffffff || iObey->iMemModel==E_MM_Direct))
		{
		dataRunAddr=iNextDataChunkBase;
		TInt stackreserve=iObey->iDefaultStackReserve;
		if (aFile->iOverrideFlags & KOverrideStackReserve)
			stackreserve=aFile->iStackReserve;
		TInt datsize=AlignToChunk(dataBssSize+stackreserve);
		// Move target data address to next free chunk
		iNextDataChunkBase+=datsize;
		}
	if (aFile->Extension() || aFile->Device() || aFile->Variant())
		{
		dataRunAddr=iObey->iKernDataRunAddress+aFile->iDataBssOffset;
		}
	else if (aFile->IsDll() && dataBssSize!=0 && aFile->iRomNode->iRomFile->iDataBssOffsetInExe<0)
		{
		iNextDllDataAddr = AllocVirtual(iNextDllDataAddr,dataBssSize);
		dataRunAddr=iNextDllDataAddr;
		}
	if (iObey->iMemModel==E_MM_Moving && dataRunAddr==iObey->iDataRunAddress && aFile->Secondary())
		{
		Print(EWarning,"Secondary not fixed\n");
		}

	TRACE(TAREA, Print(ELog, "Data run address %08x\n", dataRunAddr));
	aFile->iDataBssLinearBase=dataRunAddr;
	}

void E32Rom::LoadFileToRom(TRomBuilderEntry *aFile)
//
// Load an E32Image/PE file to rom
//
	{

	char* addr = (char*)aFile->iHeaderRange.iImagePtr;
	TRACE(TAREA, Print(ELog,"+LoadFileToRom addr %08x %08x %08x\n", addr,
					   aFile->iHeaderRange.iImageAddr, aFile->iHeaderRange.iRunAddr));

	if (addr+aFile->SizeInRom()>iData+iSize) // check this
		{
		Print(EError, "Can't fit '%s' in Rom.\n", aFile->iFileName);
		Print(EError, "Rom overflowed by approximately 0x%x bytes.\n", RequiredSize()-iObey->iRomSize);
		exit(666);
		}

	// check file will not overflow into next ROM
	if (aFile->Primary())
		{
		if (!iPrevPrimaryAddress)
			iHeader->iPrimaryFile=ActualToRomAddress(aFile->RomEntry());
		else if (iObey->iKernelModel==EMultipleKernels)
			{
			((TRomImageHeader*)iPrevPrimaryAddress)->iNextExtension=ActualToRomAddress(aFile->RomEntry());
			}
		iPrevPrimaryAddress=addr;
		TRACE(TAREA, Print(ELog, "iHeader->iPrimaryFile = %08x\n", iHeader->iPrimaryFile));
		}

	// Place the file in rom
	if (aFile->Variant())
		{
		if (iPrevVariantAddress)
			((TRomImageHeader*)iPrevVariantAddress)->iNextExtension=ActualToRomAddress(aFile->RomEntry());
		else
			iHeader->iVariantFile=ActualToRomAddress(aFile->RomEntry());
		iPrevVariantAddress=addr;
		}
	if (aFile->IsDll() && aFile->iRomNode->iRomFile->iTotalDataBss!=0 && aFile->iRomNode->iRomFile->iDataBssOffsetInExe>=0)
		{
		TRomFile* f=aFile->iRomNode->iRomFile->iPDeps[0];	// attach process
		aFile->iDataBssLinearBase = f->DataBssLinearBase() + aFile->iRomNode->iRomFile->iDataBssOffsetInExe;
		}

	aFile->LoadToRom();
	}

char *E32Rom::LayoutRom(char *romaddr)
//
// Layout the files from the obey file starting at romaddr in the image
// dealing correctly with areas
// Also deals with two section ROMs
//
	{

	TAddressRange main;
	TAddressRange* mainptr=&main;
	SetImageAddr(main, romaddr);

	TAddressRange second;
	TAddressRange* secondptr=0;
	if (iObey->iSectionStart != 0)
		{
		SetImageAddr(second,iSectionPtr);
		secondptr = &second;
		}

	TInt fileCount=0;
	if(gGenSymbols && !iSymGen) {
		string filename(iObey->GetFileName());
		filename.erase(filename.length() - 3,3);
		filename.append("symbol");
		iSymGen = new SymbolGenerator(filename.c_str(),gThreadNum - 1);		
	}
		
	//
	// Process files in non default areas
	//

        CBytePair bpe;
	for (NonDefaultAreasIterator areaIt(iObey->SetArea());
		 ! areaIt.IsDone();
		 areaIt.GoToNext())
		{
		Area& currentArea = areaIt.Current();
		currentArea.SetSrcBaseAddr(mainptr->iImageAddr);

		mainptr->iRunAddr = currentArea.DestBaseAddr();

		for (FilesInAreaIterator fileIt(currentArea);
			 ! fileIt.IsDone();
			 fileIt.GoToNext())
			{
			TRomBuilderEntry* currentFile = fileIt.Current();

			LayoutFile(currentFile, *mainptr, secondptr, &bpe);
		
			TUint overflow;
			if (! currentArea.ExtendSrcLimitAddr(mainptr->iImageAddr, overflow))
				{
				Print(EError, "Can't fit '%s' in area '%s'\n", currentFile->iFileName, currentArea.Name());
				Print(EError, "Area overflowed by 0x%x bytes.\n", overflow);
				exit(666);
				}

			++fileCount;
			assert(iObey->iSectionPosition == -1 || fileCount < iObey->iSectionPosition);
			}

		TInt offset=(char*)mainptr->iImagePtr-romaddr;
		mainptr->Extend(Align(offset)-offset);
		} // for every non default area


	//
	// Process files in default area
	//

	mainptr->iRunAddr = mainptr->iImageAddr;

	for (FilesInAreaIterator fileIt(*(iObey->SetArea().DefaultArea()));
		 ! fileIt.IsDone();
		 fileIt.GoToNext())
		{
		if (fileCount==iObey->iSectionPosition)
			{
			// skip rest of first section and pick up after the
			// information already accumulated in the second section
			NextRom(mainptr, secondptr);
			mainptr = secondptr;
			secondptr = 0;
			}

		LayoutFile(fileIt.Current(), *mainptr, secondptr, &bpe);

		++fileCount;
		}

	// align to likely position of next file
	TInt offset=(char*)mainptr->iImagePtr-romaddr;
	offset = Align(offset)-offset;
	mainptr->Extend(offset);
	iOverhead +=offset;
	if(iSymGen){
		SymGenContext context ;
		memset(&context,0,sizeof(SymGenContext));
		iSymGen->AddEntry(context);
	}
	return (char*)mainptr->iImagePtr;
 	}

void E32Rom::LayoutFile(TRomBuilderEntry* current, TAddressRange& aMain, TAddressRange* aSecond, CBytePair * aBPE)
//
// Work out where to place a file in ROM and set up the 
// appropriate TAddressRange information
//
	{
	TInt alignment = iObey->iRomAlign;
	if (current->iAlignment > alignment)
		alignment = current->iAlignment;

	if (alignment)
		{
		// Align this file on a boundary
		TUint32 romaddr=aMain.iRunAddr;
		TInt i=romaddr & (alignment-1);
		TInt gap=0;
		if (i!=0)
			gap=alignment-i;
		if (current->iAlignment)
			Print(ELog, "\nAlign to %08x.  Skipped %d bytes\n", romaddr+gap, gap);
		aMain.Extend(gap);
		iOverhead += gap;
		}

	if (current->iCodeAlignment != 0)
		{
		TUint32 runaddr=aMain.iRunAddr + sizeof(TRomImageHeader);
		TInt i=runaddr & (current->iCodeAlignment-1);
		TInt gap=0;
		if (i!=0)
			gap=current->iCodeAlignment-i;
		Print(ELog, "\nCode Align to %08x.  Skipped %d bytes\n", runaddr+gap, gap);
		aMain.Extend(gap);
		iOverhead += gap;
		}

	Print(ELog,"\n********************************************************************\n");

	if (current->iPatched)
		Print(ELog, "[Patched file]\n");
	TLinAddr savedAddr = aMain.iImageAddr;
	if (current->iResource)
		{		
		TInt size=LoadDataToRom(current, aMain, aBPE);
		if (aSecond != 0 && aMain.iImageAddr > iObey->iSectionStart)
			return;		// first section has overflowed
		current->FixupRomEntries(size);
		if(iSymGen) {
			SymGenContext context ;
			memset(&context,0,sizeof(SymGenContext));
			context.iFileName = current->iFileName ;
			context.iDataAddress = savedAddr ;
			iSymGen->AddEntry(context); 
		}
		return;
		}
	if(current->HCRDataFile()){	
		TInt size=LoadDataToRom(current, aMain, aBPE);		
		if (aSecond != 0 && aMain.iImageAddr > iObey->iSectionStart)
			return;		// first section has overflowed
		current->FixupRomEntries(size);
		iHeader->iHcrFileAddress =  current->iHeaderRange.iImageAddr ;
		TRACE(TAREA, Print(ELog, "iHeader->iHcrFileAddress = %08x\n", iHeader->iHcrFileAddress));	
		if(iSymGen) {
			SymGenContext context ;
			memset(&context,0,sizeof(SymGenContext));
			context.iFileName = current->iFileName ;
			context.iDataAddress = savedAddr ;
			iSymGen->AddEntry(context); 
		}		
		return ;
	}
	Print(ELog,"Processing file %s\n",current->iFileName);

	if (current->Primary())
		{
		Print(ELog, "[Primary]\n");
		}

	if (current->Secondary())
		{
		iHeader->iSecondaryFile=ActualToRomAddress(current->RomEntry());
		Print(ELog, "[Secondary]\n");
		}

	// Section 1 things
	//
	// TRomImageHeader, text, export directory, data

	aMain.Append(current->iHeaderRange);
	aMain.Append(current->iCodeSection);
	aMain.Append(current->iDataSection);

	// section 2 things
	//
	// dll ref table

	if (aSecond != 0)
		{
		// two section ROM - split image between both sections
		aSecond->Append(current->iExportDirSection);
		aSecond->Append(current->iDllRefTableRange);
		}
	else
		{
		// default placement in first section
		aMain.Append(current->iExportDirSection);
		aMain.Append(current->iDllRefTableRange);
		}

	TInt section1size = aMain.iRunAddr-current->iCodeSection.iRunAddr;

	if (aMain.iRunAddr == aMain.iImageAddr)
		{
		Print(ELog, "Load Address:            %08x\n", current->iHeaderRange.iImageAddr);
		}
	else
		{
		Print(ELog, "Rom Address:             %08x\n", current->iHeaderRange.iImageAddr);
		Print(ELog, "Area Address:            %08x\n", current->iHeaderRange.iRunAddr);
		}
	Print(ELog,     "Size:                    %08x\n", section1size);

	if (aSecond != 0 && aMain.iImageAddr > iObey->iSectionStart)
		return;		// first section has overflowed

	LoadFileToRom(current);
	TRomImageHeader *header = current->iRomImageHeader;
	if(iSymGen){
		SymGenContext context  ;
		context.iFileName = current->iFileName ;		
		context.iTotalSize = section1size;
		context.iCodeAddress = header->iCodeAddress; 
		context.iDataAddress = header->iDataAddress; 
		context.iDataBssLinearBase = header->iDataBssLinearBase;	 
		context.iTextSize = header->iTextSize; 
		context.iDataSize = header->iDataSize; 
		context.iBssSize = header->iBssSize;   	
		context.iTotalDataSize = header->iTotalDataSize;
		context.iExecutable = ETrue ;
		iSymGen->AddEntry(context);		
	}
	Display(header);
	Print(ELog,     "Dll ref table size:      %08x\n", current->iDllRefTableRange.iSize);
	Print(ELog,     "Compression:             %08x\n", current->iCompression);
	Print(ELog,     "\n");

	current->FixupRomEntries(section1size);	
	}

static int CompareAddresses(const void * arg1, const void * arg2) 
	{ 
	return (* (TUint32 *)arg1) < (* (TUint32 *)arg2) ? -1: 1; 
	}

char *E32Rom::ReserveRomExceptionSearchTable(char *anAddr, TRomExceptionSearchTable*& exceptionSearchTable)
	{
	TRomExceptionSearchTable *pT = (TRomExceptionSearchTable *)anAddr;
	exceptionSearchTable = pT;
	if (iExtensionRomHeader)
		{
		iExtensionRomHeader->iRomExceptionSearchTable = ActualToRomAddress(anAddr);
		}
	else
		{
		iHeader->iRomExceptionSearchTable = ActualToRomAddress(anAddr);
		}
	TLinAddr * addr = &pT->iEntries[0];
	int numEntries = 0;
	int errors = 0;
	// Count number of entries needed
	for (int i = 0; i < iObey->iNumberOfPeFiles; i++)
		{
		TUint32 xd = iPeFiles[i]->iHdr->iExceptionDescriptor;
		if ((xd & 1) && (xd != 0xffffffffu))
			{
			numEntries++;
			}
		else if (!iPeFiles[i]->iHdr->iExceptionDescriptor)
			{
#ifdef __REJECT_NON_EXCEPTION_AWARE_BINARIES__
			Print(EError, "Executable not exception aware: %s\n", iPeFiles[i]->iName);
			errors++;
#else
			Print(ELog, "Executable not exception aware: %s\n", iPeFiles[i]->iName);
#endif
			}
		}
	if (errors > 0) exit(666);
	// NB we add one to numEntries to allow space for a fencepost value (see below for more)
	int spaceNeeded = sizeof(pT->iNumEntries) + sizeof(pT->iEntries[0])*(numEntries+1);
	int delta = (int)(addr+spaceNeeded) - (int)(iData+iSize);
	// Check we've got enough room
	if (delta > 0)
		{
		Print(EError, "Can't fit Rom Exception Search Table in Rom.\n");
		Print(EError, "Rom overflowed by approximately 0x%x bytes.\n", delta);
		exit(666);
		}
	pT->iNumEntries = numEntries;
	return anAddr+spaceNeeded;
	}
	
void E32Rom::ConstructRomExceptionSearchTable(TRomExceptionSearchTable* exceptionSearchTable)
	{
	TRomExceptionSearchTable *pT = exceptionSearchTable;
	TLinAddr * addr = &pT->iEntries[0];
	// Initialize the table
	int numEntries = pT->iNumEntries;
	TLinAddr fencepost = 0xffffffff;
	if (numEntries)
		{
		TLinAddr fp = 0;
		for (int j = 0; j < iObey->iNumberOfPeFiles; j++)
			{
			TUint32 xd = iPeFiles[j]->iHdr->iExceptionDescriptor;
			if ((xd & 1) && (xd != 0xffffffff))
				{
				// mask out bottom bit set by ELFTRAN.
				xd &= ~1;
				*addr++ = iPeFiles[j]->iHdr->iCodeBase;
				TLinAddr aEDAddr = iPeFiles[j]->iHdr->iCodeBase + xd; 
				// Keep track of greatest code limit so we can use it as the fencepost value
				TExceptionDescriptor * aEDp = (TExceptionDescriptor *)RomToActualAddress(aEDAddr);
				TLinAddr codeLimit = aEDp->iROSegmentLimit;
				if (codeLimit>fp) fp=codeLimit;
				}
			}
		if (fp) fencepost=fp;
		// now check they're in order (they should be).
		int inOrder = 1;
		for (int k=numEntries-1;inOrder && k; k--) 
			{
			inOrder = pT->iEntries[k]>pT->iEntries[k-1]?1:0;
			}

		if (!inOrder)
			{
			Print(ELog, "Sorting Rom Exception Table.\n");
			qsort(&pT->iEntries[0],numEntries,sizeof(pT->iEntries[0]), CompareAddresses);
			}
		}
	/*
	  Add the fencepost value at the end of the table. This is used to optimize the comparison
	  function passed to bsearch when retrieving values from the search table. It also allows a certain
	  amount of error checking on lookup keys.
	*/
	*addr++ = fencepost;
	}

void TRomBuilderEntry::SizeInSections(TInt& aSize1, TInt& aSize2)
//
// Exact size of the upper & lower section information
// lower = text + data
// upper = export directory + dllref table
//
	{
	aSize1  = iHeaderRange.iSize;
	aSize1 += iCodeSection.iSize;			// text (including rdata)
	aSize1 += iDataSection.iSize;			// static data

	aSize2  = iExportDirSection.iSize;		// export directory
	aSize2 += iDllRefTableRange.iSize;	// DLL ref table
	}

							
void E32Rom::NextRom(TAddressRange* aFirst, TAddressRange* aSecond)
//
// Move on to the next Rom bank, taking the IATs with us
//
	{

	Print(ELog,"\n####################################################################\n");
	TInt gap=iObey->iSectionStart-aFirst->iImageAddr;
	if (gap<0)
		{
		Print(EError, "First section overflowed by %08x bytes\n", -gap);
		exit(669);
		}
	iOverhead+=gap+sizeof(TRomSectionHeader);
	Print(ELog, "[Next rom section]\n");
	Print(ELog, "Skipping %08x bytes\n", gap);
	Print(ELog, "LinAddr:                 %08x\n", iObey->iSectionStart);
	Print(ELog, "First section tables:    %08x\n", iObey->iSectionStart+sizeof(TRomSectionHeader));
	TInt size=aSecond->iImageAddr-iObey->iSectionStart;
	Print(ELog, "Tables size:             %08x\n", size-sizeof(TRomSectionHeader));
	Print(ELog, "Rom Directory            %08x\n", iHeader->iRomRootDirectoryList);
	Print(ELog, "Rom Directory size       %08x\n", iDirectorySize);

	if (aSecond->iImageAddr != iHeader->iRomRootDirectoryList)
		{
		Print(EError, "Second section has overwritten the Rom directory\n");
		exit(669);
		}
	aSecond->Extend(iDirectorySize);

	Print(ELog, "\n");
	}

TInt E32Rom::ResolveDllRefTables()
//
//
//
	{

	Print(ELog, "\nResolving Dll reference tables.\n");
	TInt i;
	TInt err = KErrNone;
	for (i=0; i<iObey->iNumberOfPeFiles; i++)
		{
		TRACE(TIMPORT,Print(ELog,"ResolveDllRefTables %d\n",i));
		TInt r=iPeFiles[i]->ResolveDllRefTable(*this);
		if (r!=KErrNone)
			err=r;
		}
	TRACE(TIMPORT,Print(ELog,"ResolveDllRefTables complete\n"));
	return err;
	}


TInt E32Rom::BuildDependenceGraph()
	{
	Print(ELog, "\nBuilding dependence graph.\n");
	TInt i;
	TInt err = KErrNone;
	for (i=0; i<iObey->iNumberOfPeFiles; i++)
		{
		TRACE(TIMPORT,Print(ELog,"BuildDep %d\n",i));
		TRomBuilderEntry* e=iPeFiles[i];
		TInt r=e->BuildDependenceGraph(*this);
		if (r!=KErrNone)
			err=r;
		if (!e->IsDll())
			{
			if (e->iHdr->iDataSize!=0 || e->iHdr->iBssSize!=0)
				e->iRomImageFlags|=(KRomImageFlagData|KRomImageFlagDataPresent);	// EXE with static data
			}
		else if ((e->iHdr->iDataSize!=0 || e->iHdr->iBssSize!=0) && !e->Variant() && !e->Extension())
			{
			// requires normal case DLL data initialisation
			e->iRomImageFlags|=(KRomImageFlagData|KRomImageFlagDataInit|KRomImageFlagDataPresent);
			}
		}
	TRACE(TIMPORT,Print(ELog,"BuildDep complete\n"));

	if(!gPagedRom)
		return err;

	Print(ELog,"\n");

	return err;
	}

#define MARK_BEEN_HERE	1
#define MARK_KEEP		2
#define	MARK_EXE		4
#define MARK_CHECKED	8
void E32Rom::UnmarkGraph(TInt aMark)
	{
	TRomNode* x = 0;
	for (x=iObey->iRootDirectory->iNextExecutable; x; x=x->iNextExecutable)
		x->iRomFile->iMark &= ~aMark;
	}

void E32Rom::FindMarked(TInt aMarkMask, TInt aMark, TRomFile**& aList)
	{
	UnmarkGraph(MARK_CHECKED);
	TRomNode* x = 0;
	aMarkMask |= MARK_CHECKED;
	aMark &= ~MARK_CHECKED;
	for (x=iObey->iRootDirectory->iNextExecutable; x; x=x->iNextExecutable)
		{
		TRomFile* e = x->iRomFile;
		if ((e->iMark&aMarkMask)==aMark)
			{
			*aList++=e;
			e->iMark |= MARK_CHECKED;
			}
		}
	}

TInt TRomFile::MarkDeps()
	{
	TInt n=0;
	TInt i;
	for (i=0; i<iNumDeps; ++i)
		{
		TRomFile* e=iDeps[i];
		if (!(e->iMark & MARK_BEEN_HERE))
			{
			e->iMark|=MARK_BEEN_HERE;
			++n;
			n+=e->MarkDeps();
			TUint32 flg = RomImageFlags();
			TUint32 eflg = e->RomImageFlags();
			if (eflg & KRomImageFlagDataPresent)
				iRbEntry->iRomImageFlags |= KRomImageFlagDataPresent;
			TBool e_is_dll = eflg & KImageDll;
			if ((flg & KImageDll) && e_is_dll && (eflg & KRomImageFlagDataInit))
				iRbEntry->iRomImageFlags |= KRomImageFlagDataInit;
			if (!e_is_dll)
				e->iMark|=MARK_EXE;
			if (eflg&KRomImageFlagData)
				e->iMark|=MARK_KEEP;
			}
		}
	return n;
	}

TInt TRomFile::FindRouteTo(TRomFile* aDest, TRomFile** aStack, TInt aIndex)
	{
	TInt i;
	for (i=0; i<iNumDeps; ++i)
		{
		TRomFile* e=iDeps[i];
		if (e == aDest)
			return aIndex;
		if (!(e->iMark & MARK_BEEN_HERE))
			{
			e->iMark|=MARK_BEEN_HERE;
			aStack[aIndex] = e;
			TInt r = e->FindRouteTo(aDest, aStack, aIndex+1);
			if (r >= 0)
				return r;
			}
		}
	return KErrNotFound;
	}

void E32Rom::ListRouteTo(TRomFile* aStart, TRomFile* aDest, TInt aNDeps)
	{
	TRomNode* rootdir = iObey->iRootDirectory;
	TRomFile** stack = new TRomFile*[aNDeps];
	UnmarkGraph();
	TInt depth = aStart->FindRouteTo(aDest, stack, 0);
	assert(depth >= 0);
	Print(EAlways, "\t--->%s\n", (const char*)TModuleName(*aDest, rootdir));
	while(--depth >= 0)
		Print(EAlways, "\tvia %s\n", (const char*)TModuleName(*stack[depth], rootdir));
	delete[] stack;
	}

TInt E32Rom::ProcessDependencies()
	{
	TInt i;
	TInt errors = 0;
	for (i=0; i<iObey->iNumberOfPeFiles; i++)
		{
		TRomBuilderEntry* e=iPeFiles[i];
		TRomNode* rn = e->iRomNode;
		TRomFile* rf = rn->iRomFile;
		UnmarkGraph();
		TInt n=rf->MarkDeps();
		rf->iNumPDeps=n;
		if (n)
			{
			rf->iPDeps=new TRomFile* [n];
			if (!rf->iPDeps)
				return KErrNoMemory;
			TRomFile** l=rf->iPDeps;
			FindMarked(MARK_EXE, MARK_EXE, l);
			TInt nx=l-rf->iPDeps;
			if (!e->IsDll() && (nx>1 || nx==1 && l[-1]!=rf))
				{
				Print(EError,"EXE %s links to the following other EXEs:\n", e->iFileName);
				TInt j;
				for (j=0; j<nx; ++j)
					{
					if (rf->iPDeps[j] != rf)
						ListRouteTo(rf, rf->iPDeps[j], n);
					}
				++errors;
				continue;
				}
			else if (nx>1)
				{
				Print(EError,"DLL %s links to more than one EXE:\n",e->iFileName);
				TInt j;
				for (j=0; j<nx; ++j)
					ListRouteTo(rf, rf->iPDeps[j], n);
				++errors;
				continue;
				}
			if (nx)
				e->iRomImageFlags|=KRomImageFlagExeInTree;
			FindMarked(MARK_KEEP|MARK_EXE, MARK_KEEP, l);
			rf->iNumPDeps=l-rf->iPDeps;
			if (rf->iNumPDeps)
				{
				e->iDllRefTableRange.iSize=(rf->iNumPDeps-1)*sizeof(TRomImageHeader*)+sizeof(TDllRefTable);
				if (e->IsDll() && rf->iTotalDataBss)
					{
					TRomFile* f=rf->iPDeps[0];	// first dependency, EXE if there is one
					TUint fflg = f->RomImageFlags();
					TBool f_is_dll = fflg & KImageDll;
					if (!f_is_dll)
						{
						// DLL with data/bss depends on EXE
						if ((fflg & KRomImageFlagFixedAddressExe) || iObey->iMemModel==E_MM_Direct)
							{
							// assign the DLL data address in the EXE bss section
							rf->iDataBssOffsetInExe=f->iTotalDataBss;
							f->iTotalDataBss+=rf->iTotalDataBss;
							}
						}
					else if (iObey->iMemModel==E_MM_Direct)
						{
						Print(EError, "DLL with data/bss must have attach process specified\n");
						return KErrGeneral;
						}
					}
				}
			else
				{
				delete[] rf->iPDeps;
				rf->iPDeps=NULL;
				}
			}
		if (!rf->iNumPDeps)
			e->iDllRefTableRange.iSize=0;
		}
	if (iObey->iMemModel == E_MM_Moving)
		{
		// On moving model only, we must verify that no fixed process links to a
		// DLL with data/bss which is attached to a fixed process.
		// On multiple model there is no restriction.
		// On direct model all DLLs with data/bss must specify an attach process
		// and the error will show up as one EXE depending on another.
		for (i=0; i<iObey->iNumberOfPeFiles; i++)
			{
			TRomBuilderEntry* e=iPeFiles[i];
			TRomNode* rn = e->iRomNode;
			TRomFile* rf = rn->iRomFile;
			TUint rif = rf->RomImageFlags();
			if (e->IsDll() || e->Primary() || !(rif & KRomImageFlagFixedAddressExe))
				continue;	// only need to check fixed address user mode EXEs
			TInt n = rf->iNumPDeps;
			TInt j;
			for (j=0; j<n; ++j)
				{
				TRomFile* f = rf->iPDeps[j];
				TUint fflg = f->RomImageFlags();
				if ((fflg & KImageDll) && (f->iDataBssOffsetInExe < 0))
					{
					// fixed user EXE links to DLL with data/bss and no attach process
					Print(EError,"Fixed EXE %s links to DLL with data/bss and no attach process:\n", e->iFileName);
					ListRouteTo(rf, rf->iPDeps[j], n);
					++errors;
					}
				}
			}
		}
	if (errors)
		return KErrGeneral;

	STRACE(TIMPORT, 
		{
		for (i=0; i<iObey->iNumberOfPeFiles; i++)
			{
			TRomBuilderEntry* e=iPeFiles[i];
			TRomNode* rn = e->iRomNode;
			TRomFile* rf = rn->iRomFile;
			Print(ELog,"File %s: PN=%d\n",e->iFileName,rf->iNumPDeps);
			TInt j;
			for (j=0; j<rf->iNumPDeps; ++j)
				{
				TRomFile* f=rf->iPDeps[j];
				Print(ELog,"\t%s\n", (const char*)TModuleName(*f, iObey->iRootDirectory));
				}
			}
		})
	return KErrNone;
	}

void E32Rom::SetSmpFlags()
    {
	if (gLogLevel & LOG_LEVEL_SMP_INFO)
		{
		Print(ELog,"\nComputing SMP properties. The following components are SMP-unsafe:\n");
		}

	bool is_all_safe = 1;

	for (int i = 0; i < iObey->iNumberOfPeFiles; i++)
		{
		TRomBuilderEntry* e = iPeFiles[i];

        if ( e->iRomNode->iRomFile->ComputeSmpSafe(e) )
			{
			e->iRomImageFlags |= KRomImageSMPSafe;
			}
		else
			{
			is_all_safe = 0;
			e->iRomImageFlags &= ~KRomImageSMPSafe;
			}
		}

	if ( (gLogLevel & LOG_LEVEL_SMP_INFO) && is_all_safe)
		{
		Print(ELog,"There are no unsafe components.");
		}
    }

TInt E32Rom::ResolveImports()
//
// Fix the import address table for each of the files in rom
//	
	{

	Print(ELog, "Resolving Imports.\n");
	TInt i;
	for (i=0; i<iObey->iNumberOfPeFiles; i++)
		{
		TInt r=iPeFiles[i]->FixupImports(*this);
		if (r!=KErrNone)
			return r;
		}
	return KErrNone;
	}

char *E32Rom::RomToActualAddress(TUint aPtr)
	{
	return (char *)(aPtr-iObey->iRomLinearBase+(TUint)iHeader);
	}

TUint E32Rom::ActualToRomAddress(TAny *aPtr)
	{
	return ((TUint)aPtr)-(TUint32)iHeader+iObey->iRomLinearBase;
	}

void E32Rom::SetImageAddr(TAddressRange& aRange, TAny* aPtr, TUint32 aRunOffset)
	{
	aRange.iImagePtr=aPtr;
	aRange.iImageAddr=ActualToRomAddress(aPtr);
	aRange.iRunAddr=aRange.iImageAddr+aRunOffset;
	}

void E32Rom::SetImageAddr(TAddressRange& aRange, TUint aAddr, TUint32 aRunOffset)
	{
	aRange.iImagePtr=RomToActualAddress(aAddr);
	aRange.iImageAddr=aAddr;
	aRange.iRunAddr=aAddr+aRunOffset;
	}

TRomNode* E32Rom::FindImageFileByName(const TDllFindInfo& aInfo, TBool aPrintDiag, TBool& aFallBack)
//
// return the file with the name aName
//
	{
	return iObey->iRootDirectory->FindImageFileByName(aInfo, aPrintDiag, aFallBack);
	}

TInt E32Rom::CheckForVersionConflicts(const TRomBuilderEntry* a)
	{
	return iObey->iRootDirectory->CheckForVersionConflicts(a);
	}

TRomNode* E32Rom::CopyDirectory(TRomNode*& aLastExecutable)
	{
	return iObey->iRootDirectory->CopyDirectory(aLastExecutable, 0);
	}

TInt E32Rom::CollapseImportThunks()
//
// Collapse 3-word import thunks into a single branch
//	
	{

	Print(ELog, "\nCollapsing Import Thunks.\n");
	TInt i;
	for (i=0; i<iObey->iNumberOfPeFiles; i++)
		{
		if (iPeFiles[i]->iHdr->iImportOffset)
			{
			TInt r=CollapseImportThunks(iPeFiles[i]);
			if (r!=KErrNone)
				return r;
			}
		}
	return KErrNone;
	}

TInt E32Rom::WriteImages(TInt aHeaderType)
	{
	if (aHeaderType < 0)
		aHeaderType = 1;
	ofstream romFile((const char *)iObey->iRomFileName,ios_base::binary);
	if (!romFile)
		return Print(EError,"Cannot open ROM file %s for output\n",iObey->iRomFileName);
	Write(romFile, aHeaderType);
	romFile.close();

	// Write out the odd/even 16-bits of the images

	char sname[256];
	if (iObey->iRomOddFileName)
		{
		strcpy(sname, (const char*)iObey->iRomOddFileName);
		if (strcmp(sname, "*")==0)
			{
			// use romname with ".odd" appended.
			sprintf(sname,"%s.odd",(const char *)iObey->iRomFileName);
			}
		ofstream oFile(sname,ios_base::binary);
		if (!oFile)
			return Print(EError,"Cannot open file %s for output\n",sname);
		Print(EAlways, "Writing odd half words to file %s\n",sname);
		WriteOdd(oFile);
		oFile.close();
		}
	if (iObey->iRomEvenFileName)
		{
		strcpy(sname, (const char*)iObey->iRomEvenFileName);
		if (strcmp(sname, "*")==0)
			{
			// use romname with ".even" appended.
			sprintf(sname,"%s.even",(const char *)iObey->iRomFileName);
			}
		ofstream oFile(sname,ios_base::binary);
		if (!oFile)
			return Print(EError,"Cannot open file %s for output\n",sname);
		Print(EAlways, "Writing even half words to file %s\n",sname);
		WriteEven(oFile);
		oFile.close();
		}

	// Write out the ROM in the SREC or S19 format

	if (iObey->iSRecordFileName)
		{
		strcpy(sname, (const char*)iObey->iSRecordFileName);
		if (strcmp(sname, "*")==0)
			{
			// use romname with ".srec" appended.
			sprintf(sname,"%s.srec",(const char *)iObey->iRomFileName);
			}
		ofstream sFile(sname,ios_base::binary);
		if (!romFile)
			return Print(EError,"Cannot open file %s for output\n",sname);
		Print(EAlways, "Writing S record format to file %s\n",sname);
		WriteSRecord(sFile);
		sFile.close();
		}
	return KErrNone;
	}

void E32Rom::WriteOdd(ofstream &os)
	{
	char *ptr=(char *)iHeader+2;
	TInt i;
	for (i=2; i<iObey->iRomSize; i+=4, ptr+=4)
		os.write(ptr, 2);
	}

void E32Rom::WriteEven(ofstream &os)
	{
	char *ptr=(char *)iHeader;
	TInt i;
	for (i=0; i<iObey->iRomSize; i+=4, ptr+=4)
		os.write(ptr, 2);
	}

void E32Rom::SetCompressionInfo(TUint aCompressionType, TUint aCompressedSize, TUint aUncompressedSize)
	{

	if (iExtensionRomHeader)
		{
		iExtensionRomHeader->iCompressionType=aCompressionType;
		iExtensionRomHeader->iCompressedSize=aCompressedSize;
		iExtensionRomHeader->iUncompressedSize=aUncompressedSize;
		}
	else
		{
		iHeader->iCompressionType=aCompressionType;
		iHeader->iCompressedSize=aCompressedSize;
		iHeader->iUncompressedSize=aUncompressedSize;
		}
	}

void E32Rom::Write(ofstream &os, TInt aHeaderType)
//
// Output a rom image
//
	{

	const char *compressed=gEnableCompress ? " compressed" : " uncompressed"; 

	switch (aHeaderType)
		{
	case 0:
		Print(EAlways, "\nWriting%s Rom image without",compressed);
		break;
	case 1:
	default:
		Print(EAlways, "\nWriting%sRom image with repro",compressed);
		os.write(iData, sizeof(TRomLoaderHeader));
		break;
	case 2:
		Print(EAlways, "\nWriting%s Rom image with PE-COFF",compressed);
			{
			unsigned char coffhead[0x58] = {0};  // zero all the elements

			// fill in the constant bits
			// this is supposed to be simple, remember
			coffhead[1] = 0x0a;
			coffhead[2] = 0x01;
			coffhead[0x10] = 0x1c;
			coffhead[0x12] = 0x0f;
			coffhead[0x13] = 0xa1;
			coffhead[0x14] = 0x0b;
			coffhead[0x15] = 0x01;
			coffhead[0x26] = 0x40;
			coffhead[0x2a] = 0x40;
			coffhead[0x30] = 0x2e;
			coffhead[0x31] = 0x74;
			coffhead[0x32] = 0x65;
			coffhead[0x33] = 0x78;
			coffhead[0x34] = 0x74;
			coffhead[0x3a] = 0x40;
			coffhead[0x3e] = 0x40;
			coffhead[0x44] = 0x58;
			coffhead[0x54] = 0x20;

			// now fill in the text segment size
			*(TUint32 *) (&coffhead[0x18]) = ALIGN4K(iSizeUsed);
			*(TUint32 *) (&coffhead[0x40]) = ALIGN4K(iSizeUsed);

			os.write(reinterpret_cast<char *>(coffhead), sizeof(coffhead));
			}
		break;
		}
	Print(EAlways, " header to file %s\n", iObey->iRomFileName);
	
	iHeader->iUnpagedCompressedSize   = 0;
	iHeader->iUnpagedUncompressedSize = iHeader->iPageableRomStart;
	iHeader->iCompressedUnpagedStart =  gBootstrapSize + gPageIndexTableSize;	// AttilaV calculate uncompressed un-paged size 
	
	if (gLogLevel & LOG_LEVEL_COMPRESSION_INFO)
		{
		Print(ELog, "iUnpagedCompressedSize  :0x%08x (%d)\n",     iHeader->iUnpagedCompressedSize);
		Print(ELog, "iUnpagedUncompressedSize:0x%08x (%d)\n\n",   iHeader->iUnpagedUncompressedSize);
		
		Print(ELog, "iExtensionRomHeader     :%d\n",     iExtensionRomHeader);
		Print(ELog, "iCompressionType        :0x%08x\n", (iExtensionRomHeader ? iExtensionRomHeader->iCompressionType : iHeader->iCompressionType ));	
		Print(ELog, "iCompressedSize         :0x%08x (%d)\n",     (iExtensionRomHeader ? iExtensionRomHeader->iCompressedSize  : iHeader->iCompressedSize ), (iExtensionRomHeader ? iExtensionRomHeader->iCompressedSize  : iHeader->iCompressedSize ));
		Print(ELog, "iUncompressedSize       :0x%08x (%d)\n\n",   (iExtensionRomHeader ? iExtensionRomHeader->iUncompressedSize: iHeader->iUncompressedSize ), (iExtensionRomHeader ? iExtensionRomHeader->iUncompressedSize: iHeader->iUncompressedSize ));
	
		Print(ELog, "iPageableRomStart       :0x%08x (%d)\n",   iHeader->iPageableRomStart, iHeader->iPageableRomStart );
		Print(ELog, "iPageableRomSize        :0x%08x (%d)\n",   iHeader->iPageableRomSize, iHeader->iPageableRomSize  );
		Print(ELog, "iRomPageIndex           :0x%08x (%d)\n",   iHeader->iRomPageIndex, iHeader->iRomPageIndex );
	
		Print(ELog, "iSizeUsed               :0x%08x (%d)\n",   iSizeUsed, iSizeUsed );
		Print(ELog, "Linear base address     :0x%08x\n",iHeader->iRomBase); 
		Print(ELog, "Size:                    0x%08x\n",iHeader->iRomSize);
		}

	if ( gPagedRom && gCompressUnpaged)
		{
		if (gLogLevel & LOG_LEVEL_COMPRESSION_INFO)
			Print(ELog, "Write out compressed un-paged and paged sections\n\n");
		ImpTRomHeader* header = (ImpTRomHeader *)iHeader;
		
		if (gLogLevel & LOG_LEVEL_COMPRESSION_INFO)
			{
			Print(ELog, "Header:\n");
			header->Display();
			}
		
		streampos headerpos=os.tellp();
		
		// Write out uncompressed un-paged part (bootstrap + Page Index Table)
		os.write((char *)(iHeader), iHeader->iCompressedUnpagedStart);
		
		// write out the compressed unpaged part
		int srcsize=iHeader->iPageableRomStart - iHeader->iCompressedUnpagedStart;		
		
		int rawimagelen=DeflateCompressCheck(((char *)iHeader)+iHeader->iCompressedUnpagedStart,srcsize,os);
		iHeader->iUnpagedCompressedSize = rawimagelen;
		iHeader->iUnpagedUncompressedSize = srcsize ;
		
		// align to 4kbyte boundary if neccessary
		TUint32 distanceFrom4kBoundary = ((~(iHeader->iCompressedUnpagedStart + rawimagelen /*+ sizeof(TRomLoaderHeader)*/ )) & 0xfff) + 1;
		if (gLogLevel & LOG_LEVEL_COMPRESSION_INFO)
			Print(ELog, "distanceFrom4kBoundary  :0x%08x (%d)\n", distanceFrom4kBoundary, distanceFrom4kBoundary);
		char filer[0x1000];
		memset( filer, 0, 0x1000);
		os.write((char *)filer, distanceFrom4kBoundary);
		
		
		// write out the paged part
		os.write((char *)iHeader + iHeader->iPageableRomStart, ALIGN4K(iSizeUsed - iHeader->iPageableRomStart));
		
		// update size and compression information of paged-part
		SetCompressionInfo(KUidCompressionDeflate, ALIGN4K(iSizeUsed), ALIGN4K(iUncompressedSize));
		
		// Calculate starting index of the Pageable Rom Start
		if (gLogLevel & LOG_LEVEL_COMPRESSION_INFO)
			{
			Print(ELog, "iPageableRomStart				: %d (0x%08x)\n", iHeader->iPageableRomStart, iHeader->iPageableRomStart);
			Print(ELog, "iCompressedUnpagedStart			: %d (0x%08x)\n", iHeader->iCompressedUnpagedStart, iHeader->iCompressedUnpagedStart);
			Print(ELog, "rawimagelen						: %d (0x%08x)\n", rawimagelen, rawimagelen);
			}
		
		TInt displacement = iHeader->iCompressedUnpagedStart + rawimagelen + distanceFrom4kBoundary; 
		if (gLogLevel & LOG_LEVEL_COMPRESSION_INFO)
			Print(ELog, "new iPageableRomStart			: %d (0x%08x)\n", (iHeader->iCompressedUnpagedStart + rawimagelen + distanceFrom4kBoundary), (iHeader->iCompressedUnpagedStart + rawimagelen + distanceFrom4kBoundary));
		displacement = iHeader->iPageableRomStart-displacement;
		if (gLogLevel & LOG_LEVEL_COMPRESSION_INFO)
			Print(ELog, "displacement					: %d (0x%08x)\n", displacement, displacement);
		
		SRomPageInfo* pi = (SRomPageInfo*)((TInt)iHeader+iHeader->iRomPageIndex);
		if (gLogLevel & LOG_LEVEL_COMPRESSION_INFO)
			Print(ELog, "First Pageable page info[0x%08x]:(iDataStart:0x%08x, iDataSize:0x%08x (%d))\n\n", pi, pi->iDataStart, pi->iDataSize, pi->iDataSize);
		
		TInt startPageableIndex = (iHeader->iPageableRomStart) / (iObey->iPageSize);
		if (gLogLevel & LOG_LEVEL_COMPRESSION_INFO)
			{
			Print(ELog, "iObey->iPageSize				: %d (0x%08x)\n", iObey->iPageSize, iObey->iPageSize);
			Print(ELog, "startPageableIndex				: %d (0x%08x)\n", startPageableIndex, startPageableIndex);
			}
		pi += startPageableIndex;
		
		
		while ( 0 != pi->iDataStart)
			{
				if (H.iVerbose) Print(ELog, "\t\tinfo[0x%08x]:(iDataStart:0x%08x, iDataSize:0x%08x (%d))\n\n", pi, pi->iDataStart, pi->iDataSize, pi->iDataSize);		
				
				pi->iDataStart -= displacement;
				
				if (H.iVerbose) Print(ELog, "\t\tinfo[0x%08x]:(iDataStart:0x%08x, iDataSize:0x%08x (%d))\n\n", pi, pi->iDataStart, pi->iDataSize, pi->iDataSize);		
				
				++pi;
			}
		
		
		
		// Rewrite the header with updated info
		#ifdef __TOOLS2__
		os.seekp(headerpos); 
		#else
		os.seekp(headerpos,ios_base::beg);
		#endif
		
		// Rewrite uncompressed un-paged part (bootstrap + Page Index Table)
		os.write((char *)(iHeader), iHeader->iCompressedUnpagedStart);
		
		
		if (gLogLevel & LOG_LEVEL_COMPRESSION_INFO)
			{
			Print(ELog, "iUnpagedCompressedSize  :0x%08x (%d)\n",     iHeader->iUnpagedCompressedSize, iHeader->iUnpagedCompressedSize);
			Print(ELog, "iUnpagedUncompressedSize:0x%08x (%d)\n\n",   iHeader->iUnpagedUncompressedSize, iHeader->iUnpagedUncompressedSize);
		
			Print(ELog, "iCompressionType        :0x%08x\n", (iExtensionRomHeader ? iExtensionRomHeader->iCompressionType : iHeader->iCompressionType ));	
			Print(ELog, "iCompressedSize         :0x%08x (%d)\n",     (iExtensionRomHeader ? iExtensionRomHeader->iCompressedSize  : iHeader->iCompressedSize ), (iExtensionRomHeader ? iExtensionRomHeader->iCompressedSize  : iHeader->iCompressedSize ));
			Print(ELog, "iUncompressedSize       :0x%08x (%d)\n\n",   (iExtensionRomHeader ? iExtensionRomHeader->iUncompressedSize: iHeader->iUncompressedSize ), (iExtensionRomHeader ? iExtensionRomHeader->iUncompressedSize: iHeader->iUncompressedSize ));
		
			Print(ELog, "iPageableRomStart       :0x%08x (%d)\n",   iHeader->iPageableRomStart, iHeader->iPageableRomStart );
			Print(ELog, "iPageableRomSize        :0x%08x (%d)\n",   iHeader->iPageableRomSize, iHeader->iPageableRomSize  );
			Print(ELog, "iRomPageIndex           :0x%08x (%d)\n",   iHeader->iRomPageIndex, iHeader->iRomPageIndex );
			Print(ELog, "\t\tinfo(iDataStart:0x%08x, iDataSize:0x%08x (%d))\n\n", pi->iDataStart, pi->iDataSize, pi->iDataSize);
		
			Print(ELog, "Linear base address:     %08x\n",iHeader->iRomBase); 
			Print(ELog, "Size:                    %08x\n",iHeader->iRomSize);
			}
		
		return;
		}

	if (!gEnableCompress || gPagedRom || !gCompressUnpaged)
		{
		if (gLogLevel & LOG_LEVEL_COMPRESSION_INFO)
			Print(ELog, "Writeout uncompressed un-paged and paged sections2\n");
		SetCompressionInfo(KFormatNotCompressed, ALIGN4K(iSizeUsed), ALIGN4K(iUncompressedSize));
		iHeader->iUnpagedCompressedSize = ALIGN4K(iSizeUsed);
		iHeader->iUnpagedUncompressedSize = ALIGN4K(iUncompressedSize);
		
		os.write((char *)iHeader, ALIGN4K(iSizeUsed));
		
		if (gLogLevel & LOG_LEVEL_COMPRESSION_INFO)
			{
			Print(ELog, "iUnpagedCompressedSize  :0x%08x (%d)\n",     iHeader->iUnpagedCompressedSize);
			Print(ELog, "iUnpagedUncompressedSize:0x%08x (%d)\n\n",   iHeader->iUnpagedUncompressedSize);
		
			Print(ELog, "iCompressionType        :0x%08x\n", (iExtensionRomHeader ? iExtensionRomHeader->iCompressionType : iHeader->iCompressionType ));	
			Print(ELog, "iCompressedSize         :0x%08x (%d)\n",     (iExtensionRomHeader ? iExtensionRomHeader->iCompressedSize  : iHeader->iCompressedSize ), (iExtensionRomHeader ? iExtensionRomHeader->iCompressedSize  : iHeader->iCompressedSize ));
			Print(ELog, "iUncompressedSize       :0x%08x (%d)\n\n",   (iExtensionRomHeader ? iExtensionRomHeader->iUncompressedSize: iHeader->iUncompressedSize ), (iExtensionRomHeader ? iExtensionRomHeader->iUncompressedSize: iHeader->iUncompressedSize ));
		
			Print(ELog, "iPageableRomStart       :0x%08x (%d)\n",   iHeader->iPageableRomStart, iHeader->iPageableRomStart );
			Print(ELog, "iPageableRomSize        :0x%08x (%d)\n",   iHeader->iPageableRomSize, iHeader->iPageableRomSize  );
			Print(ELog, "iRomPageIndex           :0x%08x (%d)\n",   iHeader->iRomPageIndex, iHeader->iRomPageIndex );
			}
		
		return;
		}

	// compressed image without paging section
	streampos headerpos=os.tellp();
	int headersize=iExtensionRomHeader ? sizeof(TExtensionRomHeader) : sizeof(TRomHeader);

	os.write(reinterpret_cast<char*>(iHeader), headersize); // write a dummy header
	// compress the rest of the image
	int srcsize=iSizeUsed - headersize;
	int rawimagelen=DeflateCompressCheck(((char *)iHeader)+headersize,srcsize,os);
	// write the compression info into the header
	SetCompressionInfo(KUidCompressionDeflate, rawimagelen, iUncompressedSize); // doesn't need to be 4K aligned
	iHeader->iCompressedUnpagedStart = headersize; 
	iHeader->iUnpagedCompressedSize = rawimagelen;
	iHeader->iUnpagedUncompressedSize = srcsize;
		
	#ifdef __TOOLS2__
	os.seekp(headerpos); 
	#else
	os.seekp(headerpos,ios_base::beg);
	#endif
	os.write(reinterpret_cast<char*>(iHeader), headersize);	// write header again with (compressed) size info
	
	if (gLogLevel & LOG_LEVEL_COMPRESSION_INFO)
		Print(ELog, "\tiSizeUsed:%d, iUncompressedSize:%d, headersize:%d, srcsize:%d, rawimagelen:%d \n",iSizeUsed, iUncompressedSize, headersize, srcsize, rawimagelen);
	}

TInt E32Rom::Compare(const char *aImage, TInt aHeaderType)
	{
	if (aHeaderType < 0)
		aHeaderType = 1;
	ifstream file(aImage, ios_base::binary);
	if (!file)
		return Print(EError, "Cannot open Rom image '%s' for verification\n", aImage);
	Print(ELog, "\nVerifying ROM against image in %s\n", aImage);
	switch (aHeaderType)
		{
	case 0:
		break;
	case 1:
	default:
		Print(ELog, "Skipping repro header\n");
		file.seekg(sizeof(TRomLoaderHeader));
		break;
	case 2:
		Print(ELog, "Skipping coff header\n");
		file.seekg(0x58);
		break;
		}
	TInt length=ALIGN4K(iSizeUsed);
	if (iObey->iSectionStart != 0)
		{
		length = iObey->iSectionStart-iObey->iRomLinearBase;
		Print(ELog, "Verifying first section (%08x bytes)... ", length);
		}

	TRomHeader compareHeader;
	file.read((char *)&compareHeader, sizeof(TRomHeader));
	// Arrange different settings for TRomHeader and
	// TRomSectionHeader in the obey file
	// For now just copy across the things that'll change
	compareHeader.iVersion=iHeader->iVersion;
	compareHeader.iTime=iHeader->iTime;
	compareHeader.iTimeHi=(TUint32)(iHeader->iTime >> 32);
	compareHeader.iCheckSum=iHeader->iCheckSum;
	compareHeader.iLanguage=iHeader->iLanguage;

	if (memcmp(&compareHeader, iHeader, sizeof(TRomHeader))!=0)
		return Print(EError, "Verify failed.\nRom headers are different\n");

	// Now compare the rest of the image (or first section)

	TUint *ptr=(TUint *)(iHeader+1);
	TInt i;
	for (i=sizeof(TRomHeader); i<length; i+=4)
		{
		TUint a;
		file.read((char *)&a, sizeof(TUint));
		if (file.eof())
			return Print(EError, "Verify failed.\nDifferent Rom sizes\n");
		if (a!=*ptr)
			return Print(EError, "Verify failed.\nContents differ at Rom address %08x\n", i+iObey->iRomLinearBase);
		ptr++;
		}
	file.close();
	Print(EAlways, "Verify OK\n");
	return KErrNone;
	}


char* E32Rom::AllocateRelocationTable(char* aAddr, TReloc*& aRelocTable)
	{
	if(iObey->SetArea().Count() > 1)
		{
		aRelocTable = reinterpret_cast<TReloc*>(aAddr);

		// Allocate one entry per non default area + 1 sentinel
		// (Count() returns number of non default areas + 1 (the
		// default area))
		TInt size = iObey->SetArea().Count() * sizeof(TReloc);	
		aAddr += Align(size);
		}
	else
		{
		aRelocTable = 0;
		}

	return aAddr;
	}


void E32Rom::FillInRelocationTable(TReloc* aRelocTable)
	{
	TReloc* p = aRelocTable;
	TInt wastedBytes = 0;

	for (NonDefaultAreasIterator areaIt(iObey->SetArea());
		 ! areaIt.IsDone();
		 areaIt.GoToNext())
		{
		Area& currentArea = areaIt.Current();

		if (currentArea.UsedSize() > 0)
			{
			p->iLength = currentArea.UsedSize();
			p->iSrc = currentArea.SrcBaseAddr();
			p->iDest = currentArea.DestBaseAddr();
			++p;
			}
		else
			{
			wastedBytes += sizeof(TReloc);
			}
		}

	if (aRelocTable != 0)
		{
		// Last entry acts as a sentinel
		memset(p, 0, sizeof(*p));
		}

	if (wastedBytes > 0)
		{
 		Print(EWarning, "Some areas are declared but not used\n");
 		Print(EWarning, "%d bytes wasted in relocation table\n", wastedBytes);
		}
	}


/**
 Link together the kernel extensions.

 Must be called only after space has been allocated in the ROM image
 for the kernel extension.
 */

void E32Rom::LinkKernelExtensions(TRomBuilderEntry* aExtArray[], TInt aExtCount)
	{
	/**
	 * The kernel extensions should never be linked together as part of extension ROMs.
	 */
	if (!iExtensionRomHeader)
		{
		TLinAddr* pLastNextExtAddr = &(iHeader->iExtensionFile);

		for (TInt i=0; i<aExtCount; ++i)
			{
			TRomBuilderEntry* curExt = aExtArray[i];
			*pLastNextExtAddr = ActualToRomAddress(curExt->RomEntry());
			pLastNextExtAddr = &(curExt->iRomImageHeader->iNextExtension);
			}
	
		*pLastNextExtAddr = 0;
		}
	}

void E32Rom::ProcessDllData()
	{
		DllDataEntry *entry = iObey->GetFirstDllDataEntry();
		TRomBuilderEntry	*romEntry;
		TLinAddr* aExportTbl;
		void	*aLocation;
		TUint	aDataAddr;
		while(entry){
			// A Dll data may be patched either via the ordinal number (as in ABIv2), or via
			// the address of the data field (as in ABIv1).
			romEntry = entry->iRomNode->iRomFile->iRbEntry;
			if((TInt)entry->iOrdinal != -1) { 
				
				// const data symbol may belong in the Code section. Get the address of the data field via the 
				// export table. If the address lies within the Code or data section limits, 
				// get the corresponding location and update it.While considering the Data section limits don't 
				// include the Bss section, as it doesn't exist as yet in the image.
				if(entry->iOrdinal < 1 || entry->iOrdinal > (TUint32)romEntry->iOrigHdr->iExportDirCount)
				{
					Print(EWarning, "Invalid ordinal %d specified for DLL %s\n", entry->iOrdinal, romEntry->iName);
					entry = entry->NextDllDataEntry();
					continue;
				}
				aExportTbl = (TLinAddr*)((char*)romEntry->iOrigHdr + romEntry->iOrigHdr->iExportDirOffset);
				aDataAddr = (TInt32)(aExportTbl[entry->iOrdinal - 1] + entry->iOffset);
				
				if( (aDataAddr >= romEntry->iOrigHdr->iCodeBase) && 
					(aDataAddr <= (TUint)(romEntry->iOrigHdr->iCodeBase + \
										romEntry->iOrigHdr->iCodeSize)) )
				{
					char *aCodeSeg = (char*)((char*)romEntry->iOrigHdr + romEntry->iOrigHdr->iCodeOffset);
					aLocation = (void*)(aCodeSeg + (aDataAddr - romEntry->iOrigHdr->iCodeBase));
					memcpy(aLocation, &(entry->iNewValue), entry->iSize);
				}
				else if( (aDataAddr >= romEntry->iOrigHdr->iDataBase) && 
					(aDataAddr <= (TUint)(romEntry->iOrigHdr->iDataBase + \
										romEntry->iOrigHdr->iDataSize )) )
				{
					char *aDataSeg = (char*)((char*)romEntry->iOrigHdr + romEntry->iOrigHdr->iDataOffset);
					aLocation = (void*)(aDataSeg + (aDataAddr - romEntry->iOrigHdr->iDataBase));
					memcpy(aLocation, &(entry->iNewValue), entry->iSize);
				}
				else
				{
					Print(EWarning, "Patchdata failed as address pointed by ordinal %d of DLL %s doesn't lie within Code or Data section limits\n", entry->iOrdinal, romEntry->iName);
				}
				
			}
			else if((TInt)entry->iDataAddress != -1) { 
				// const data symbol may belong in the Code section. If the address lies within the Code
				// or data section limits, get the corresponding location and update it.While considering 
				// the Data section limits don't include the Bss section, as it doesn't exist as yet in the image.
				aDataAddr = (TUint)(entry->iDataAddress + entry->iOffset);
				if( (aDataAddr >= romEntry->iOrigHdr->iCodeBase) && 
					(aDataAddr <= (TUint)(romEntry->iOrigHdr->iCodeBase + \
											romEntry->iOrigHdr->iCodeSize )) )
				{
					char *aCodeSeg = (char*)((char*)romEntry->iOrigHdr + romEntry->iOrigHdr->iCodeOffset);
					aLocation = (void*)(aCodeSeg + (aDataAddr - romEntry->iOrigHdr->iCodeBase));
					memcpy(aLocation, &(entry->iNewValue), entry->iSize);
				}
				else if( (aDataAddr   >= romEntry->iOrigHdr->iDataBase) && 
					(aDataAddr <= (TUint)(romEntry->iOrigHdr->iDataBase + \
											romEntry->iOrigHdr->iDataSize )) )
				{
					char *aDataSeg = (char*)((char*)romEntry->iOrigHdr + romEntry->iOrigHdr->iDataOffset);
					aLocation = (void*)(aDataSeg + (aDataAddr - romEntry->iOrigHdr->iDataBase));
					memcpy(aLocation, &(entry->iNewValue), entry->iSize);
				}
				else
				{
					Print(EWarning, "Patchdata failed as address 0x%x specified for DLL %s doesn't lie within Code or Data section limits\n", entry->iOrdinal, romEntry->iName);
				}
			}
			else {
			}
			entry = entry->NextDllDataEntry();
		}
	}

TInt E32Rom::CheckUnpagedMemSize()
	{

	if (H.iVerbose && gPagedRom)
		{
		Print(EDiagnostic, "iMaxUnpagedMemSize 0x%08x (%d)\n", iObey->iMaxUnpagedMemSize, iObey->iMaxUnpagedMemSize);
		}
		
	// Only check if the iMaxUnpagedMemSize is set
	if (iObey->iMaxUnpagedMemSize <= 0) return KErrNone;
	
	// Only for paged rom
	if (!gPagedRom) 
		{
		Print(EWarning, "The unpaged size overflow check is skipped.\n");
		return KErrNone;
		}
	
	if (iHeader->iPageableRomStart > 0)
		{
		if (iHeader->iPageableRomStart > iObey->iMaxUnpagedMemSize) 
			{
			Print(EError, "Unpaged memory size overflow: require 0x%08x (%d) bytes while the maximum size is 0x%08x (%d) bytes\n",
				iHeader->iPageableRomStart, 
				iHeader->iPageableRomStart, 
				iObey->iMaxUnpagedMemSize, 
				iObey->iMaxUnpagedMemSize);
			
			return KErrNoMemory;
			}
		}
	else
		{
		Print(EWarning, "The size of unpaged memory is not available. The unpaged memory overflow checking is skipped.\n");
		}
		
	return KErrNone;
}
TRomNode* E32Rom::RootDirectory() const {
	return iObey->iRootDirectory; 
}
const char* E32Rom::RomFileName() const {
	return iObey->iRomFileName; 
}
TUint32 E32Rom::RomBase() const {
	return iHeader->iRomBase; 
}
TUint32 E32Rom::RomSize() const {
	return iHeader->iRomSize;
}
TVersion E32Rom::Version() const {
	return iHeader->iVersion;
}
TInt64 E32Rom::Time() const {
	return iHeader->iTime;
}
TUint32 E32Rom::CheckSum() const {
	return iHeader->iCheckSum;
}
TUint32 E32Rom::DataRunAddress() const {
	return iObey->iDataRunAddress;
}
TUint32 E32Rom::RomAlign() const {
	return iObey->iRomAlign;
}
