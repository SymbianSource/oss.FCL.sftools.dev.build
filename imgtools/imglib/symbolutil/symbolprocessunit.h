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
#ifndef __SYMBOLPROCESSUNIT_H__
#define __SYMBOLPROCESSUNIT_H__
#include <vector>
#include <string>
#include <iostream>
#include <fstream>

#include "bsymutil.h"

using namespace std;

struct TPlacedEntry{
    string iFileName;
    string iDevFileName;
    TUint32 iTotalSize;
    TUint32 iCodeAddress;
    TUint32 iDataAddress;
    TUint32 iDataBssLinearBase;
    TUint32 iTextSize;
    TUint32 iDataSize;
    TUint32 iBssSize;
    TUint32 iTotalDataSize;
    bool iExecutable;
    TPlacedEntry(const string& aName, const string& aDevFileName, bool aExecutable) {
        iFileName = aName;
	iDevFileName = aDevFileName; 
        iExecutable = aExecutable;
    }
    TPlacedEntry() {
    }
};

typedef vector<string> stringlist;

class SymbolProcessUnit
{
public:
	virtual void ProcessExecutableFile(const string& aFile) = 0;
	virtual void ProcessDataFile(const string& afile) = 0;
	virtual void FlushStdOut(ostream& aOut) = 0;
	virtual void FlushSymbolContent(ostream &aOut) = 0;
	virtual void ResetContentLog() = 0;
	virtual ~SymbolProcessUnit() {}
	virtual void ProcessEntry(const TPlacedEntry& aEntry);
	int GetSizeFromBinFile( const string& fileName );
};

class CommenRomSymbolProcessUnit : public SymbolProcessUnit
{
public:
	virtual void ProcessExecutableFile(const string& aFile);
	virtual void ProcessDataFile(const string& afile);
	virtual void FlushStdOut(ostream& aOut);
	virtual void FlushSymbolContent(ostream &aOut);
	virtual void ResetContentLog();
	virtual void ProcessEntry(const TPlacedEntry& aEntry);
private:
	void ProcessArmv5File( const string& fileName, ifstream& aMap );
	void ProcessGcceOrArm4File( const string& fileName, ifstream& aMap );
	void ProcessX86File( const string& fileName, ifstream& aMap );
private:
	stringlist iStdoutLog;
	stringlist iSymbolContentLog;
	TPlacedEntry iPlacedEntry;
};

class CommenRofsSymbolProcessUnit : public SymbolProcessUnit
{
public:
	virtual void ProcessExecutableFile(const string& aFile);
	virtual void ProcessDataFile(const string& afile);
	virtual void FlushStdOut(ostream& aOut);
	virtual void FlushSymbolContent(ostream &aOut);
	virtual void ResetContentLog();
private:
	void ProcessArmv5File( const string& fileName, ifstream& aMap );
	void ProcessGcceOrArm4File( const string& fileName, ifstream& aMap );
private:
	stringlist iStdoutLog;
	stringlist iSymbolContentLog;
};

class SymbolGenerator;

class BsymRofsSymbolProcessUnit : public SymbolProcessUnit
{
public:
	BsymRofsSymbolProcessUnit(SymbolGenerator* aSymbolGeneratorPtr): iSymbolGeneratorPtr(aSymbolGeneratorPtr){}
	BsymRofsSymbolProcessUnit(){}
	virtual void ProcessExecutableFile(const string& aFile);
	virtual void ProcessDataFile(const string& afile);
	virtual void FlushStdOut(ostream& aOut);
	virtual void FlushSymbolContent(ostream &aOut);
	virtual void ResetContentLog();
	virtual void ProcessEntry(const TPlacedEntry& aEntry);
private:
	void ProcessArmv5File( const string& fileName, ifstream& aMap );
	void ProcessGcceOrArm4File( const string& fileName, ifstream& aMap );
private:
	stringlist iStdoutLog;
	MapFileInfo iMapFileInfo;
	SymbolGenerator* iSymbolGeneratorPtr;
};
#endif
