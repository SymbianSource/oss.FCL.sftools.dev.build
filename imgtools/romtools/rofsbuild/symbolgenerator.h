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
