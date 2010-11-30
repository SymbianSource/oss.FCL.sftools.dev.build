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

#include <vector>
#include <boost/regex.hpp>
#define MAX_LINE 65535
#include "symbolgenerator.h"
#include "e32image.h"
#include "h_utl.h"

#if defined(__LINUX__)
#define PATH_SEPARATOR '/'
#else
#define PATH_SEPARATOR '\\'
#endif
extern TInt gThreadNum;
extern TBool gGenBsymbols;

boost::mutex SymbolGenerator::iMutexSingleton;
SymbolGenerator* SymbolGenerator::iInst = NULL;
SymbolGenerator* SymbolGenerator::GetInstance(){
    if(iInst == NULL)
    {
    	iMutexSingleton.lock();
    	if(iInst == NULL) {
        	iInst = new SymbolGenerator();
    	}
    	iMutexSingleton.unlock();
    }
    return iInst;
}
void SymbolGenerator::Release() {
    if(iInst != NULL) {
        iInst->join();
    }
    iMutexSingleton.lock();
    if(iInst != NULL) {
        delete iInst;
        iInst = NULL;
    }
    iMutexSingleton.unlock();
}
void SymbolGenerator::SetSymbolFileName( const string& fileName ){
    if(iSymFile.is_open())
        iSymFile.close();
    if(gGenBsymbols)
    {
    	string s = fileName.substr(0,fileName.rfind('.'))+".bsym";
    	if(iImageType == ERofsImage)
    	{
    		printf("* Writing %s - ROFS BSymbol file\n", s.c_str());
    	}
    	else
    	{
    		printf("* Writing %s - ROM BSymbol file\n", s.c_str());
    	}
    	iSymFile.open(s.c_str(), ios_base::binary);
    }
    else
    {
    	string s = fileName.substr(0,fileName.rfind('.'))+".symbol";
    	if(iImageType == ERofsImage)
    	{
    		printf("* Writing %s - ROFS Symbol file\n", s.c_str());
    	}
    	else
    	{
    		printf("* Writing %s - ROM Symbol file\n", s.c_str());
    	}
    iSymFile.open(s.c_str());
    }
	   
}
void SymbolGenerator::AddFile( const string& fileName, bool isExecutable ){
    iMutex.lock();
    iQueueFiles.push(TPlacedEntry(fileName, "" , isExecutable));
    iMutex.unlock();
    iCond.notify_all();
}

void SymbolGenerator::AddEntry(const TPlacedEntry& aEntry)
{
    iMutex.lock();
    iQueueFiles.push(aEntry);
    iMutex.unlock();
    iCond.notify_all();
}

void SymbolGenerator::SetFinished() 
{ 
	boost::mutex::scoped_lock lock(iMutex);
	iFinished = true; 
	iCond.notify_all();
}
TPlacedEntry SymbolGenerator::GetNextPlacedEntry()
{
	TPlacedEntry pe("", "", false);
	if(1)
	{
		boost::mutex::scoped_lock lock(iMutex);
		while(!iFinished && iQueueFiles.empty())
			iCond.wait(lock);
		if(!iQueueFiles.empty())
		{
			pe = iQueueFiles.front();
			iQueueFiles.pop();
        	}
    	}
	return pe;
}
void SymbolGenerator::thrd_func(){
    	boost::thread_group threads;
	SymbolWorker worker;
    	for(int i=0; i < gThreadNum; i++)
    	{
    		threads.create_thread(worker);
    	}
    	threads.join_all();
	SymbolGenerator::GetInstance()->FlushSymbolFileContent();
        }
SymbolGenerator::SymbolGenerator() : boost::thread(thrd_func),iFinished(false) {
	if(gGenBsymbols)
	{
		iSymbolType = ESymBsym;
	}
	else
	{
		iSymbolType = ESymCommon;
	}
    }
SymbolGenerator::~SymbolGenerator(){
    if(joinable())
        join();
    for(int i=0; i < (int)iLogMessages.size(); i++)
    {
	    cout << iLogMessages[i];
    }
    iSymFile.flush();
    iSymFile.close();
}
void SymbolGenerator::FlushSymbolFileContent()
{
    if(iSymbolType == ESymCommon)
    {
	return;
    }
    TBsymHeader tmpBsymHeader;
    memset(&tmpBsymHeader, 0, sizeof(tmpBsymHeader));
    tmpBsymHeader.iMagic[0] = 'B';
    tmpBsymHeader.iMagic[1] = 'S';
    tmpBsymHeader.iMagic[2] = 'Y';
    tmpBsymHeader.iMagic[3] = 'M';
    tmpBsymHeader.iMajorVer[0] = BsymMajorVer >> 8;
    tmpBsymHeader.iMajorVer[1] = BsymMajorVer & 0xff;
    tmpBsymHeader.iMinorVer[0] = BsymMinorVer >> 8;
    tmpBsymHeader.iMinorVer[1] = BsymMinorVer & 0xff;
    if(ByteOrderUtil::IsLittleEndian())
    {
	    tmpBsymHeader.iEndiannessFlag = 0;
    }
    else
    {
	    tmpBsymHeader.iEndiannessFlag = 1;
    }
    tmpBsymHeader.iCompressionFlag = 1;
    //count the space for TDbgUnitEntries and TSymbolEntries
    int fileCount = iMapFileInfoSet.size();
    TUint32 sizeNeeded = fileCount * sizeof(TDbgUnitEntry);
    for(int i = 0; i < fileCount; i++)
    {
    	sizeNeeded += iMapFileInfoSet[i].iSymbolPCEntrySet.size() * sizeof(TSymbolEntry);
    }
    //write string to the temporary memory area
    MemoryWriter mWriter;
    mWriter.SetOffset(sizeNeeded);
    mWriter.SetStringTableStart(sizeNeeded);
    mWriter.AddEmptyString();

    //first to prepare the file info entries TDbgUnitEntry
    TUint32 startSymbolIndex = 0;
    for(int i = 0; i < fileCount; i++)
    {
    	iMapFileInfoSet[i].iDbgUnitPCEntry.iDbgUnitEntry.iStartSymbolIndex = startSymbolIndex;
    	iMapFileInfoSet[i].iDbgUnitPCEntry.iDbgUnitEntry.iPCNameOffset = mWriter.AddString(iMapFileInfoSet[i].iDbgUnitPCEntry.iPCName);
    	iMapFileInfoSet[i].iDbgUnitPCEntry.iDbgUnitEntry.iDevNameOffset = mWriter.AddString(iMapFileInfoSet[i].iDbgUnitPCEntry.iDevName);
    	startSymbolIndex += iMapFileInfoSet[i].iSymbolPCEntrySet.size();
    }
    //second to layout the symbols unit for the mapfile
    for(int i = 0; i < fileCount; i++)
    {
        int symbolcount = iMapFileInfoSet[i].iSymbolPCEntrySet.size();
        for(int j =0; j< symbolcount; j++)
        {
        	iMapFileInfoSet[i].iSymbolPCEntrySet[j].iSymbolEntry.iScopeNameOffset = mWriter.AddScopeName(iMapFileInfoSet[i].iSymbolPCEntrySet[j].iScopeName);
        	iMapFileInfoSet[i].iSymbolPCEntrySet[j].iSymbolEntry.iNameOffset = mWriter.AddString(iMapFileInfoSet[i].iSymbolPCEntrySet[j].iName);
        	iMapFileInfoSet[i].iSymbolPCEntrySet[j].iSymbolEntry.iSecNameOffset = mWriter.AddString(iMapFileInfoSet[i].iSymbolPCEntrySet[j].iSecName);
        }
    }

    //write out the BSym file content
    char* pstart = mWriter.GetDataPointer();
    //write out the map file info
    int unitlen = sizeof(TDbgUnitEntry);
    for(int i = 0; i < fileCount; i++)
    {
    	memcpy(pstart, &iMapFileInfoSet[i].iDbgUnitPCEntry.iDbgUnitEntry, unitlen);
    	pstart += unitlen;
    }
    //wirte out the symbol unit info
    unitlen = sizeof(TSymbolEntry);
    for(int i = 0; i < fileCount; i++)
    {
    	int symbolcount = iMapFileInfoSet[i].iSymbolPCEntrySet.size();
    	for(int j =0; j < symbolcount; j++)
    	{
    		memcpy(pstart, &iMapFileInfoSet[i].iSymbolPCEntrySet[j].iSymbolEntry, unitlen);
    		pstart += unitlen;
    	}
    }
    //write out the memory out to the symbol file

    int totalPages = (mWriter.GetOffset() + ( BSYM_PAGE_SIZE -1)) / 4096;
    TUint32 compressInfoLength = sizeof(TCompressedHeaderInfo) + sizeof(TPageInfo)*(totalPages -1);
    char* tmpBuffer = new char[compressInfoLength];
    TCompressedHeaderInfo * pCompressedHeaderInfo = (TCompressedHeaderInfo *) tmpBuffer;
    pCompressedHeaderInfo->iPageSize = BSYM_PAGE_SIZE;
    pCompressedHeaderInfo->iTotalPageNumber = totalPages;
    TPageInfo* tmpPage = &pCompressedHeaderInfo->iPages[0];
    for(int i = 0; i < totalPages; i++)
    {
	    tmpPage->iPageStartOffset = i * BSYM_PAGE_SIZE;
	    if(tmpPage->iPageStartOffset + BSYM_PAGE_SIZE < mWriter.GetOffset())
	    {
	    	tmpPage->iPageDataSize = BSYM_PAGE_SIZE;
	    }
	    else
	    {
		tmpPage->iPageDataSize = mWriter.GetOffset() - tmpPage->iPageStartOffset;
	    }
	    tmpPage++;
    }

    //prepare the TBsymHeader, TDbgUnitEntry and TSymbolEntry to the memory
    tmpBsymHeader.iDbgUnitOffset = sizeof(TBsymHeader) + compressInfoLength;
    tmpBsymHeader.iDbgUnitCount = fileCount;
    tmpBsymHeader.iSymbolOffset = fileCount*sizeof(TDbgUnitEntry);
    tmpBsymHeader.iSymbolCount = startSymbolIndex;
    tmpBsymHeader.iStringTableOffset = mWriter.GetStringTableStart();
    tmpBsymHeader.iStringTableBytes = mWriter.GetOffset() - tmpBsymHeader.iStringTableOffset;
    tmpBsymHeader.iUncompressSize = mWriter.GetOffset();
    //start the compress threads
    Print(EAlways, "Start compress for Bsymbol file\n");
    PageCompressWorker compressWorker(pCompressedHeaderInfo, mWriter.GetDataPointer());
    boost::thread_group threads;
    for(int i=0; i < gThreadNum; i++)
    {
	    threads.create_thread(compressWorker);
    }
    threads.join_all();
    Print(EAlways, "Complete compress for Bsymbol file\n");
    //pack all the pages together
    tmpPage = &pCompressedHeaderInfo->iPages[0];
    TPageInfo* prePage = NULL;
    char* pchar = mWriter.GetDataPointer();
    for(int i=0; i < totalPages -1; i++)
    {
	    prePage = tmpPage;
	    tmpPage++;
	    memcpy(pchar + prePage->iPageStartOffset + prePage->iPageDataSize, pchar + tmpPage->iPageStartOffset, tmpPage->iPageDataSize);
	    tmpPage->iPageStartOffset = prePage->iPageStartOffset + prePage->iPageDataSize;

    }
    tmpBsymHeader.iCompressedSize = tmpPage->iPageStartOffset + tmpPage->iPageDataSize;
    mWriter.SetOffset(tmpBsymHeader.iCompressedSize);
    tmpBsymHeader.iCompressInfoOffset = sizeof(TBsymHeader);

    iSymFile.write((char*)&tmpBsymHeader, sizeof(TBsymHeader));
    iSymFile.write((char*)pCompressedHeaderInfo, compressInfoLength);
    iSymFile.write(mWriter.GetDataPointer(), mWriter.GetOffset());
    delete[] tmpBuffer;
    for(int i = 0; i < fileCount; i++)
    {
    	iMapFileInfoSet[i].iSymbolPCEntrySet.clear();
    }
    iMapFileInfoSet.clear();
}

SymbolWorker::SymbolWorker()
{
}
SymbolWorker::~SymbolWorker()
{
    }
void SymbolWorker::operator()()
{
	SymbolProcessUnit* aSymbolProcessUnit;
	SymbolGenerator* symbolgenerator = SymbolGenerator::GetInstance();
	if(symbolgenerator->GetImageType() == ERomImage)
	{
		if(gGenBsymbols)
		{
			aSymbolProcessUnit = new BsymRomSymbolProcessUnit(symbolgenerator);
		}
		else
		{
			aSymbolProcessUnit = new CommenRomSymbolProcessUnit();
		}
	}
	else
	{
		if(gGenBsymbols)
		{
			aSymbolProcessUnit = new BsymRofsSymbolProcessUnit(symbolgenerator);
		}
		else
		{
			aSymbolProcessUnit = new CommenRofsSymbolProcessUnit();
		}
	}

	while(1)
	{
		if(symbolgenerator->HasFinished() && symbolgenerator->IsEmpty())
		{
			break;
                }
		TPlacedEntry pe = symbolgenerator->GetNextPlacedEntry();
		if(pe.iFileName.empty())
			continue;

		aSymbolProcessUnit->ProcessEntry(pe);

		symbolgenerator->LockOutput();
		aSymbolProcessUnit->FlushStdOut(symbolgenerator->iLogMessages);
		aSymbolProcessUnit->FlushSymbolContent(symbolgenerator->GetOutputFileStream());
		symbolgenerator->UnlockOutput();
	}
	delete aSymbolProcessUnit;
}
TCompressedHeaderInfo* PageCompressWorker::pHeaderInfo = NULL;
int PageCompressWorker::currentPage = 0;
boost::mutex PageCompressWorker::m_mutex;
int PageCompressWorker::m_error = 0;
char* PageCompressWorker::iChar = NULL;

PageCompressWorker::PageCompressWorker(TCompressedHeaderInfo* aHeaderInfo, char* aChar) 
{
	pHeaderInfo = aHeaderInfo;
	iChar = aChar;
}

PageCompressWorker::~PageCompressWorker() {}
void PageCompressWorker::operator()()
{
	int tobecompress = 0;
	CBytePair bpe;
	while(1)
	{
		m_mutex.lock();
		tobecompress =currentPage;
		currentPage++;
		m_mutex.unlock();
		if(tobecompress >= (int) pHeaderInfo->iTotalPageNumber)
			break;
		TPageInfo* current = &pHeaderInfo->iPages[0] + tobecompress;
		TUint8* in = (TUint8*)(iChar + current->iPageStartOffset);
		TUint8* out = in;
		TInt outSize = BytePairCompress(out, in, current->iPageDataSize, &bpe);
		if(outSize == KErrTooBig)
		{
			outSize = BSYM_PAGE_SIZE;
		}
		if(outSize < 0)
		{
			m_mutex.lock();
			m_error = -1;
			m_mutex.unlock();
			break;
		}
		current->iPageDataSize = outSize;
	}
	
}

