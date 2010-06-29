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


#ifndef __SIS2IBY_H__
#define __SIS2IBY_H__

#include "pkgfileparser.h"

#define SISEXTRACT_TOOL_NAME	"dumpsis"  // Extract tool
#define SISEXTRACT_TOOL_DEFOPT	" -x"      // Default options to the tool
#define SISEXTRACT_TOOL_EXTOPT	" -d "     // Extract path option

typedef map<string,PPKGPARSER> PKGFILE_MAP;

/** 
class Sis2Iby
	Implements the interfaces of SisUtils
	Provides methods to generate IBY file(s) from a SIS file

@internalComponent
@released
*/
class Sis2Iby : public SisUtils
{
public:
	Sis2Iby(const char* aFile);
	~Sis2Iby();

	void ProcessSisFile();
	void GenerateOutput();

private:
	void GenerateIby(string aPkgFile, PPKGPARSER aParser);
	TUint32 InvokeExtractTool(const string& aSisFile);
	void UpdatePkgFileMap(const string& aPath, const string& aFile);
	void GetFileName(const string& aName, string& aFile);
	void AppendFileName(string& aPath,string aFile);
	void NormaliseSourceFile(string& aFile, const string& aPkgFile);
	void NormaliseDestFile(string& aFile);
	void MakeFullPath(string& aFile);

	void WriteLanguages(PPKGPARSER aParser);
	void WriteFileInclusion(string aSrcFile, string aDestFile, string aPkgName, TInt aPadding);
	void WritePackageHeader(PPKGPARSER aParser);
	void WriteInstallOptions(PPKGPARSER aParser);
	void WritePackageBody(PPKGPARSER aParser);
	void WriteInstallFileList(PINSTALLFILE_LIST aFileList, PPKGPARSER aParser, TInt aPadding);
	void InsertTabs(TInt num);

	PkgParser *pkgParser;
	PKGFILE_MAP iPkgFileMap;

	ofstream ibyHandle;

	TBool IsValidE32Image(string aFile);
};

#endif //__SIS2IBY_H__
