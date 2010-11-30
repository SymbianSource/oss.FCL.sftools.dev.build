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

#ifndef __SYMBOLGENERATOR_H__
#define __SYMBOLGENERATOR_H__
#include <queue>
#include <string>
#include <fstream>
using namespace std;
#include <boost/thread/thread.hpp>
#include <boost/thread/condition.hpp>
#include "symbolprocessunit.h"


enum TSymbolType {
	ESymCommon = 0,
	ESymBsym ,
};
enum TImageType {
	ERomImage = 0,
	ERofsImage,
	EUnknownType,
};


class SymbolGenerator : public boost::thread {
    public:
        static SymbolGenerator* GetInstance();
        static void Release();
        void SetSymbolFileName( const string& fileName );
        void AddFile( const string& fileName, bool isExecutable );
	void AddEntry(const TPlacedEntry& aEntry);
        bool HasFinished()	{ return iFinished; }
        void SetFinished();
        bool IsEmpty() { return iQueueFiles.empty(); }
        void LockOutput() { iOutputMutex.lock(); }
        void UnlockOutput() { iOutputMutex.unlock(); }
        TPlacedEntry GetNextPlacedEntry();
        ofstream& GetOutputFileStream() { return iSymFile; };
        void AppendMapFileInfo(MapFileInfo& aMapFileInfo) { iMapFileInfoSet.push_back(aMapFileInfo); }
        void FlushSymbolFileContent();
	void SetImageType(TImageType aImageType) {	iImageType = aImageType; };
	TImageType GetImageType() {	return iImageType; };
	stringlist iLogMessages;
    private:
        SymbolGenerator();
        ~SymbolGenerator();
        static void thrd_func();

        queue<TPlacedEntry> iQueueFiles;
        boost::mutex iMutex;
        boost::mutex iOutputMutex;
        static boost::mutex iMutexSingleton;
        static SymbolGenerator* iInst;
        boost::condition_variable iCond;
        bool iFinished;
        TSymbolType iSymbolType;
	TImageType iImageType;

        ofstream iSymFile;
        MapFileInfoSet iMapFileInfoSet;
};
class SymbolWorker{
public:
	SymbolWorker();
	~SymbolWorker();
	void operator()();
private:
};
class PageCompressWorker {
public:
	PageCompressWorker(TCompressedHeaderInfo* aHeaderInfo, char* aChar);
	~PageCompressWorker();
	void operator()();
	static TCompressedHeaderInfo * pHeaderInfo;
	static int currentPage;
	static boost::mutex m_mutex;
	static int m_error;
	static char* iChar;
};
#endif
