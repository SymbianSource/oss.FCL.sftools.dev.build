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

#ifndef __SYMBOLSCREATER_H__
#define __SYMBOLSCREATER_H__
#include <queue>
#include <string>
#include <fstream>
#include <vector>
#include <map>

using namespace std;

#include <boost/thread/thread.hpp>
#include <boost/thread/condition.hpp>

struct SymGenContext {
	const char* iFileName ;
	TUint32	iTotalSize ;
	TUint32 iCodeAddress; 
	TUint32 iDataAddress; 
	TUint32 iDataBssLinearBase;	 
	TInt iTextSize; 
	TInt iDataSize; 
	TInt iBssSize;   	
	TInt iTotalDataSize;
	TBool iExecutable ;
};

class SymbolGenerator  {  
public :
		SymbolGenerator(const char* aSymbolFileName, int aMultiThreadsCount = 1);
		~SymbolGenerator();		
		void AddEntry(const SymGenContext& aEntry); 
		void WaitThreads();
private :
		SymbolGenerator();
		SymbolGenerator& operator = (const SymbolGenerator& aRight);
		static void ThreadFunc(SymbolGenerator* aInst); 
		bool ProcessEntry(const SymGenContext& aContext);
		bool ProcessARMV5Map(ifstream& aStream, const SymGenContext& aContext);
		bool ProcessGCCMap(ifstream& aStream, const SymGenContext& aContext);
		bool ProcessX86Map(ifstream& aStream, const SymGenContext& aContext);
		ofstream iOutput ; 
		boost::thread_group iThreads ;
		boost::condition_variable iCond;
		boost::mutex iQueueMutex;
		boost::mutex iFileMutex ;
		queue<SymGenContext> iEntries ;	
		vector<char*> iErrMsgs ;
	
};

#endif //__ROMSYMBOLGENERATOR_H__
