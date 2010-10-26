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
using namespace std;


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
};

class CommenSymbolProcessUnit : public SymbolProcessUnit
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
	int GetSizeFromBinFile( const string& fileName );
private:
	stringlist iStdoutLog;
	stringlist iSymbolContentLog;
};
#endif
