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


struct TPlacedEntry{
    string iFileName;
    bool iExecutable;
    TPlacedEntry(const string& aName, bool aExecutable) {
        iFileName = aName;
        iExecutable = aExecutable;
    }
};
class SymbolGenerator : public boost::thread {
    public:
        static SymbolGenerator* GetInstance();
        static void Release();
        void SetSymbolFileName( const string& fileName );
        void AddFile( const string& fileName, bool isExecutable );
    private:
        SymbolGenerator();
        ~SymbolGenerator();
        void ProcessExecutable( const string& fileName );
        void ProcessDatafile( const string& fileName );
        void ProcessArmv5File( const string& fileName, ifstream& aMap );
        void ProcessGcceOrArm4File( const string& fileName, ifstream& aMap );
        int GetSizeFromBinFile( const string& fileName );
        static void thrd_func();

        queue<TPlacedEntry> iQueueFiles;
        boost::mutex iMutex;
        static boost::mutex iMutexSingleton;
        static SymbolGenerator* iInst;
        boost::condition_variable iCond;

        ofstream iSymFile;
};
#endif
