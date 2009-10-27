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

typedef std::map<String,PPKGPARSER> PKGFILE_MAP;

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
	Sis2Iby(char* aFile);
	~Sis2Iby();

	void ProcessSisFile();
	void GenerateOutput();

private:
	void GenerateIby(String aPkgFile, PPKGPARSER aParser);
	TUint32 InvokeExtractTool(String sisFile);
	void UpdatePkgFileMap(String aPath, String aFile);
	void GetFileName(String aName, String& aFile);
	void AppendFileName(String& aPath, String aFile);
	void NormaliseSourceFile(String& aFile, String aPkgFile);
	void NormaliseDestFile(String& aFile);
	void MakeFullPath(String& aFile);

	void WriteLanguages(PPKGPARSER aParser);
	void WriteFileInclusion(String aSrcFile, String aDestFile, String aPkgName, int pad);
	void WritePackageHeader(PPKGPARSER aParser);
	void WriteInstallOptions(PPKGPARSER aParser);
	void WritePackageBody(PPKGPARSER aParser);
	void WriteInstallFileList(PINSTALLFILE_LIST aFileList, PPKGPARSER aParser, int pad);
	void InsertTabs(int num);

	PkgParser *pkgParser;
	PKGFILE_MAP iPkgFileMap;

	std::ofstream ibyHandle;

	TBool IsValidE32Image(String aFile);
};

#endif //__SIS2IBY_H__
