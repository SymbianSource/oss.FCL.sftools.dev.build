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


#include "sisutils.h"
#include "sis2iby.h"

/**
Constructor: Sis2Iby class
Initilize the parameters to data members.

@internalComponent
@released

@param aFile	- SIS file name
*/
Sis2Iby::Sis2Iby(const char* aFile) : SisUtils(aFile) {
}

/**
Destructor: Sis2Iby class
Deallocates the memory for data members

@internalComponent
@released
*/
Sis2Iby::~Sis2Iby() {
	PKGFILE_MAP::iterator begin = iPkgFileMap.begin();
	PKGFILE_MAP::iterator end = iPkgFileMap.end();
	while(begin != end) {
		PPKGPARSER ptemp = 0;
		ptemp = (*begin).second;

		if(ptemp)
			delete ptemp;
		++begin;
	}
	iPkgFileMap.clear();
}

/**
ProcessSisFile: Processes the input sis file
  Invoke the DUMPSIS tool to extract the sis file contents
  Creates package parser object for each of the package file

@internalComponent
@released
*/
void Sis2Iby::ProcessSisFile() {
	TUint32 retStatus = STAT_SUCCESS;
	string sisFile = SisFileName();

	if(IsVerboseMode()) {
		cout << "Processing " << sisFile.c_str() << endl;
	}

	if(IsFileExist(sisFile)) {
		retStatus = InvokeExtractTool(sisFile);

		switch(retStatus) {
		case STAT_SUCCESS: 
			UpdatePkgFileMap(iExtractPath, sisFile); 
			break;
		case STAT_FAILURE:
			throw SisUtilsException(sisFile.c_str(), "Failed to extract SIS file");
			break ;
		}
	}
	else
		throw SisUtilsException(sisFile.c_str(), "File not found");
}

/**
GenerateOutput: Generates IBY for each of the package file

@internalComponent
@released
*/
void Sis2Iby::GenerateOutput() {
	PKGFILE_MAP::iterator begin = iPkgFileMap.begin();
	PKGFILE_MAP::iterator end = iPkgFileMap.end();
	while(begin != end) {
		GenerateIby((*begin).first, (*begin).second);
		++begin;
	}
}

/**
GenerateOutput: Generates IBY file for the given package file

@internalComponent
@released

@param aPkgFile - package file name
@param aParser - corresponding package file reader object
*/
void Sis2Iby::GenerateIby(string aPkgFile, PPKGPARSER aParser) {
	string ibyFile = iOutputPath;
	
	AppendFileName(ibyFile, aPkgFile);
	ibyFile.append(".iby");

	if( !MakeDirectory(iOutputPath) )
		throw SisUtilsException(iOutputPath.c_str(), "Failed to create path");

	if(IsVerboseMode())	{
		cout << "Generating IBY file " << ibyFile.c_str() << endl;
	}

	ibyHandle.open(ibyFile.c_str(),ios_base::out);

	if(!ibyHandle.good()) 	{
		throw SisUtilsException(ibyFile.c_str() , "Failed to create IBY file");
	}

	// Generating Header
	MakeFullPath(aPkgFile);
	ibyHandle << "\n// Generated IBY file for the package file: ";
	ibyHandle << aPkgFile;

	// Language Supported
	WriteLanguages(aParser);

	// Package Header
	WritePackageHeader(aParser);

	// Install options list
	WriteInstallOptions(aParser);

	// Package Body
	WritePackageBody(aParser);

	ibyHandle.close();
}

/**
InvokeExtractTool: Invokes the SIS file extraction tool and returns the status

@internalComponent
@released

@param sisFile - SIS file name
*/
TUint32 Sis2Iby::InvokeExtractTool(const string& aSisFile) {
	string cmdLine;

	cmdLine.append(SISEXTRACT_TOOL_NAME SISEXTRACT_TOOL_DEFOPT);

	AppendFileName(iExtractPath, aSisFile);

	cmdLine.append(SISEXTRACT_TOOL_EXTOPT);
	cmdLine.append("\"" + iExtractPath + "\" ");
	cmdLine.append(aSisFile);

	if(IsVerboseMode()) {
		cout << "Executing " << cmdLine.c_str() << endl;
	}

	return RunCommand(cmdLine.c_str());
}

/**
UpdatePkgFileMap: Update the package file map by getting the embedded sis file list from the parser object

@internalComponent
@released

@param aPath - Extract path
@param aFile - SIS file name
*/
void Sis2Iby::UpdatePkgFileMap(const string& aPath, const string& aFile) {
	string pkgFileName;
	list<string> sisList;

	// main pkg file
	pkgFileName = aPath;
	AppendFileName(pkgFileName, aFile);
	pkgFileName.append(".pkg");

	// create an instance for the pkg file parser
	// get the embedded sis file list
	// add each as pkg file into the list
	pkgParser = 0;
	if( IsFileExist(pkgFileName) ) {
		pkgParser = new PkgParser(pkgFileName);

		if(pkgParser) {
			pkgParser->ParsePkgFile();

			iPkgFileMap[pkgFileName] = pkgParser;

			pkgParser->GetEmbeddedSisList(sisList);
			SISFILE_LIST::iterator begin = sisList.begin();
			SISFILE_LIST::iterator end = sisList.end();

			while(begin != end) {
				string currPath = aPath;

				currPath.append(PATHSEPARATOR);
				GetFileName((*begin), currPath);
				UpdatePkgFileMap(currPath, (*begin));

				++begin;
			}
		}
		else
			throw SisUtilsException(pkgFileName.c_str(), "Could not create parser object");
	}
	else
		throw SisUtilsException(pkgFileName.c_str(), "File not found");
}

/**
WriteLanguages: Writes language section in the IBY file

@internalComponent
@released

@param aParser - Package file parser object
*/
void Sis2Iby::WriteLanguages(PPKGPARSER aParser) {
	LANGUAGE_LIST lanMap;
	PLANG_LIST iLangCode;

	aParser->GetLanguageList(lanMap);
	ibyHandle << "\n// Languages: ";

	LANGUAGE_LIST::iterator begin = lanMap.begin();
	LANGUAGE_LIST::iterator end = lanMap.end();

	while(begin != end) {
		iLangCode = (*begin);

		ibyHandle << " " << iLangCode->iLangName;
		ibyHandle << "(" << iLangCode->iLangCode;

		if(iLangCode->iDialectCode) {
			ibyHandle << "-" << iLangCode->iDialectCode;
		}
		ibyHandle << ")";

		++begin;
	}
}

/**
WritePackageHeader: Writes package header section in the IBY file

@internalComponent
@released

@param aParser - Package file parser object
*/
void Sis2Iby::WritePackageHeader(PPKGPARSER aParser) {
	PKG_HEADER pkgHeader;
	list<string> pkgList;
	ostringstream str;

	aParser->GetHeader(pkgHeader);

	ibyHandle << "\n// Header: ";

	pkgList = pkgHeader.iPkgNames;
	while(pkgList.size())
	{
		ibyHandle << "\"" << pkgList.front() << "\" ";
		pkgList.pop_front();
	}

	str << "(0x" << setbase(16) << pkgHeader.iPkgUID << ")";

	ibyHandle << str.str();
}

/**
WriteInstallOptions: Writes install option section in the IBY file

@internalComponent
@released

@param aParser - Package file parser object
*/
void Sis2Iby::WriteInstallOptions(PPKGPARSER aParser) {
	list<string> optList;
	string ibyName;

	aParser->GetInstallOptions(optList);
	SISFILE_LIST::iterator begin = optList.begin();
	SISFILE_LIST::iterator end = optList.end();

	if(begin != end) {
		ibyHandle << "\n// Install Options: ";
	}

	while(begin != end) {
		ibyHandle << " \"" << (*begin) << "\"";
		++begin;
	}
}

/**
InsertTabs: Inserts spaces for indentation in the output IBY file

@internalComponent
@released

@param num - num of spaces to be inserted
*/
void Sis2Iby::InsertTabs(TInt num) {
	ibyHandle << "\n";
	while(num--) {
		ibyHandle << "  ";
	}
}

/**
WritePackageBody: Writes package body details in the IBY file

@internalComponent
@released

@param aParser - Package file parser object
*/
void Sis2Iby::WritePackageBody(PPKGPARSER aParser) {
	CMDBLOCK_LIST cmdList;
	PCMD_BLOCK cmd;
	TInt pad = 0;

	ibyHandle << "\n\n";
	aParser->GetCommandList(cmdList);

	CMDBLOCK_LIST::iterator begin = cmdList.begin();
	CMDBLOCK_LIST::iterator end = cmdList.end();

	while(begin != end) {
		cmd = (*begin);

		switch(cmd->iCmdType)
		{
		case IF:			 
			InsertTabs(pad);
			ibyHandle << "#if " << cmd->iCmdExpr;
			pad++;
			 
			break;
		case ELSEIF:			
			InsertTabs(pad-1);
			ibyHandle << "#elif " << cmd->iCmdExpr;			
			break;
		case ELSE:		
			InsertTabs(pad-1);
			ibyHandle << "#else";			
			break;
		case ENDIF:			
			--pad;
			InsertTabs(pad);
			ibyHandle << "#endif";			
			break;
		case INSTALLFILE:			
			WriteInstallFileList(cmd->iInstallFileList, aParser, pad);			
			break;
		case PACKAGE:			
			InsertTabs(pad);
			ibyHandle << "#include " << "\"" << cmd->iCmdExpr << "\"";			
			break;
		}

		++begin;
	}
}

/**
WriteFileInclusion: Writes installable file details in the IBY file

@internalComponent
@released

@param aSrcFile - Name of the source file
@param aDestFile - Name of the destination file
@param aPkgName - Name of the package file
*/
void Sis2Iby::WriteFileInclusion(string aSrcFile, string aDestFile, string aPkgName, TInt aPadding) {
	NormaliseSourceFile(aSrcFile, aPkgName);

	InsertTabs(aPadding);
	if(IsValidE32Image(aSrcFile)){
		ibyHandle << "file = ";
	}
	else {
		ibyHandle << "data = ";
	}

	ibyHandle << aSrcFile << " ";
	NormaliseDestFile(aDestFile);
	ibyHandle << aDestFile;
}

/**
WriteInstallFileList: Writes installable file details in the IBY file

@internalComponent
@released

@param aFileList - Installable file list structure
@param aParser - Package file parser object
@param pad - Number of spaces for indentation purpose
*/
void Sis2Iby::WriteInstallFileList(PINSTALLFILE_LIST aFileList, PPKGPARSER aParser, TInt aPadding) {
	WriteFileInclusion(aFileList->iSourceFiles.front(), aFileList->iDestFile, aParser->GetPkgFileName(), aPadding);
}

/**
AppendFileName: Appends file name to the given path

@internalComponent
@released

@param aPath - Source path
@param aFile - File name
*/
void Sis2Iby::AppendFileName(string& aPath, string aFile) {
	TUint pos = 0;

	TrimQuotes(aPath);
	TrimQuotes(aFile);

	pos = aPath.rfind(PATHSEPARATOR);
	if(pos == string::npos) {
		aPath.append(PATHSEPARATOR);
	}

	if(pos < (aPath.length() - 1)) {
		aPath.append(PATHSEPARATOR);
	}

	GetFileName(aFile, aPath);
	return;
}

/**
GetFileName: Returns the base file name

@internalComponent
@released

@param aName - Input file name
@param aFile - Output parameter to hold the return value
*/
void Sis2Iby::GetFileName(const string& aName, string& aFile) {
	TUint spos = 0, epos = 0;

	spos = aName.rfind(PATHSEPARATOR);
	if(spos != string::npos) {
		spos += 1;
	}
	else {
		spos = 0;
	}

	epos = aName.rfind(".");
	if(epos == string::npos) {
		epos = aName.size();
	}

	aFile.append(aName.substr(spos, (epos-spos)));
}

/**
MakeFullPath: Returns the absolute path of the given file

@internalComponent
@released

@param aFile - Input file name
*/
#ifndef _MAX_PATH
#define _MAX_PATH 1024
#endif
void Sis2Iby::MakeFullPath(string& aFile) {
 
	char path[_MAX_PATH];
	if( _fullpath(path, aFile.c_str(), _MAX_PATH) != NULL ) {
		aFile.assign(path);
	}

}

/**
NormaliseSourceFile: Normalise the source file with its absolute path

@internalComponent
@released

@param aFile - Input file name
@param aPkgFile - Package file path
*/
void Sis2Iby::NormaliseSourceFile(string& aFile, const string& aPkgFile) {
	string result;
	TUint pos = 0;

	pos = aPkgFile.rfind(PATHSEPARATOR);
	if(pos != string::npos) {
		result = aPkgFile.substr(0,pos);
	}
	else {
		result = ".";
	}

	result.append(PATHSEPARATOR);
	result.append(aFile);

	MakeFullPath(result);

	aFile = "\"" + result + "\"";
}

/**
NormaliseDestFile: Normalise the destination file

@internalComponent
@released

@param aFile - Input file name
*/
void Sis2Iby::NormaliseDestFile(string& aFile) {
	TUint pos = 0; 
	pos = aFile.find(":");
	if (1 == pos) {
		char chFirst = aFile[0];
		if ('$' == chFirst || '!' == chFirst || (chFirst >='a' && chFirst <='z') || (chFirst >='A' && chFirst <='Z')) {
			aFile.replace(0, 2, "");
		}
	}
 

	aFile = "\"" + aFile + "\"";
}

/**
IsValidE32Image: Checks whether the given file is E32 image

@internalComponent
@released

@param aFile - Input file name
*/
TBool Sis2Iby::IsValidE32Image(string aFile) {
	ifstream file;
	char sig[5];
	TUint32 e32SigOffset = 0x10, fileSize = 0;
	TBool validE32 = EFalse;

	TrimQuotes(aFile);

	file.open(aFile.c_str(), ios_base::in | ios_base::binary);

	if( !file.is_open() ) {
		throw SisUtilsException(aFile.c_str(), "Cannot open file");
	}

	file.seekg(0,ios_base::end);
	fileSize = file.tellg();
	if(fileSize > 20) {
		file.seekg(e32SigOffset,ios_base::beg);
		file.read(sig, 4);
		sig[4] = '\0';

		if(!strcmp(sig, "EPOC")) {
			validE32 = ETrue;
		}
	}

	file.close();
	return validE32;
}
