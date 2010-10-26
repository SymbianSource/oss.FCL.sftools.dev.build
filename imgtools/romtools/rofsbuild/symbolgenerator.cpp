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

#if defined(__LINUX__)
#define PATH_SEPARATOR '/'
#else
#define PATH_SEPARATOR '\\'
#endif
extern TInt gThreadNum;

boost::mutex SymbolGenerator::iMutexSingleton;
SymbolGenerator* SymbolGenerator::iInst = NULL;
SymbolGenerator* SymbolGenerator::GetInstance(){
    iMutexSingleton.lock();
    if(iInst == NULL) {
        iInst = new SymbolGenerator();
    }
    iMutexSingleton.unlock();
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
    string s = fileName.substr(0,fileName.rfind('.'))+".symbol";
    printf("* Writing %s - ROFS symbol file\n", s.c_str());
    iSymFile.open(s.c_str());
}
void SymbolGenerator::AddFile( const string& fileName, bool isExecutable ){
    iMutex.lock();
    iQueueFiles.push(TPlacedEntry(fileName,isExecutable));
    iMutex.unlock();
    iCond.notify_all();
}
void SymbolGenerator::SetFinished() 
{ 

	iFinished = true; 
	iCond.notify_all();
    }
TPlacedEntry SymbolGenerator::GetNextPlacedEntry()
{
	TPlacedEntry pe("", false);
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
        }
SymbolGenerator::SymbolGenerator() : boost::thread(thrd_func),iFinished(false) {
    }
SymbolGenerator::~SymbolGenerator(){
    if(joinable())
        join();
    iSymFile.flush();
    iSymFile.close();
            }
SymbolWorker::SymbolWorker()
{
        // end of regex_search
    }
SymbolWorker::~SymbolWorker()
{
    }
void SymbolWorker::operator()()
{
	SymbolProcessUnit* aSymbolProcessUnit = new CommenSymbolProcessUnit();
	SymbolGenerator* symbolgenerator = SymbolGenerator::GetInstance();

	while(1)
	{
		if(symbolgenerator->HasFinished() && symbolgenerator->IsEmpty())
		{

                break;
                    }




		TPlacedEntry pe = symbolgenerator->GetNextPlacedEntry();

            //scope the code block with if(1) for lock
            /*
            if(me->iQueueFiles.empty()) {
                boost::this_thread::sleep(boost::posix_time::milliseconds(10));
                continue;
            }
            */


        if(pe.iFileName == "")
			continue;
        else if(pe.iExecutable) 
			aSymbolProcessUnit->ProcessExecutableFile(pe.iFileName);
        else
			aSymbolProcessUnit->ProcessDataFile(pe.iFileName);
		symbolgenerator->LockOutput();
		aSymbolProcessUnit->FlushStdOut(cout);
		aSymbolProcessUnit->FlushSymbolContent(symbolgenerator->GetOutputFileStream());
		symbolgenerator->UnlockOutput();
}
	delete aSymbolProcessUnit;
}
