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
Sis2Iby::Sis2Iby(char* aFile) : SisUtils(aFile)
{
}

/**
Destructor: Sis2Iby class
Deallocates the memory for data members

@internalComponent
@released
*/
Sis2Iby::~Sis2Iby()
{
	PKGFILE_MAP::iterator begin = iPkgFileMap.begin();
	PKGFILE_MAP::iterator end = iPkgFileMap.end();
	while(begin != end)
	{
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
void Sis2Iby::ProcessSisFile()
{
	TUint32 retStatus = STAT_SUCCESS;
	String sisFile = SisFileName();

	if(IsVerboseMode())
	{
		std::cout << "Processing " << (char*)sisFile.data() << std::endl;
	}

	if(IsFileExist(sisFile))
	{
		retStatus = InvokeExtractTool(sisFile);

		switch(retStatus)
		{
		case STAT_SUCCESS:
			{
				UpdatePkgFileMap(iExtractPath, sisFile);
			}
			break;
		case STAT_FAILURE:
			{
				throw SisUtilsException((char*)sisFile.data(), "Failed to extract SIS file");
			}
		}
	}
	else
		throw SisUtilsException((char*)sisFile.data(), "File not found");
}

/**
GenerateOutput: Generates IBY for each of the package file

@internalComponent
@released
*/
void Sis2Iby::GenerateOutput()
{
	PKGFILE_MAP::iterator begin = iPkgFileMap.begin();
	PKGFILE_MAP::iterator end = iPkgFileMap.end();
	while(begin != end)
	{
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
void Sis2Iby::GenerateIby(String aPkgFile, PPKGPARSER aParser)
{
	String ibyFile = iOutputPath;
	
	AppendFileName(ibyFile, aPkgFile);
	ibyFile.append(".iby");

	if( !MakeDirectory(iOutputPath) )
		throw SisUtilsException((char*)iOutputPath.data(), "Failed to create path");

	if(IsVerboseMode())
	{
		std::cout << "Generating IBY file " << (char*)ibyFile.data() << std::endl;
	}

	ibyHandle.open((char*)ibyFile.data(),(std::ios::out));

	if(!ibyHandle.good())
	{
		throw SisUtilsException((char*)ibyFile.data(), "Failed to create IBY file");
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
TUint32 Sis2Iby::InvokeExtractTool(String sisFile)
{
	String cmdLine;

	cmdLine.append(SISEXTRACT_TOOL_NAME SISEXTRACT_TOOL_DEFOPT);

	AppendFileName(iExtractPath, sisFile);

	cmdLine.append(SISEXTRACT_TOOL_EXTOPT);
	cmdLine.append("\"" + iExtractPath + "\" ");
	cmdLine.append(sisFile);

	if(IsVerboseMode())
	{
		std::cout << "Executing " << (char*)cmdLine.data() << std::endl;
	}

	return RunCommand(cmdLine);
}

/**
UpdatePkgFileMap: Update the package file map by getting the embedded sis file list from the parser object

@internalComponent
@released

@param aPath - Extract path
@param aFile - SIS file name
*/
void Sis2Iby::UpdatePkgFileMap(String aPath, String aFile)
{
	String pkgFileName;
	std::list<String> sisList;

	// main pkg file
	pkgFileName = aPath;
	AppendFileName(pkgFileName, aFile);
	pkgFileName.append(".pkg");

	// create an instance for the pkg file parser
	// get the embedded sis file list
	// add each as pkg file into the list
	pkgParser = 0;
	if( IsFileExist(pkgFileName) )
	{
		pkgParser = new PkgParser(pkgFileName);

		if(pkgParser)
		{
			pkgParser->ParsePkgFile();

			iPkgFileMap[pkgFileName] = pkgParser;

			pkgParser->GetEmbeddedSisList(sisList);
			SISFILE_LIST::iterator begin = sisList.begin();
			SISFILE_LIST::iterator end = sisList.end();

			while(begin != end)
			{
				String currPath = aPath;

				currPath.append(PATHSEPARATOR);
				GetFileName((*begin), currPath);
				UpdatePkgFileMap(currPath, (*begin));

				++begin;
			}
		}
		else
			throw SisUtilsException((char*)pkgFileName.data(), "Could not create parser object");
	}
	else
		throw SisUtilsException((char*)pkgFileName.data(), "File not found");
}

/**
WriteLanguages: Writes language section in the IBY file

@internalComponent
@released

@param aParser - Package file parser object
*/
void Sis2Iby::WriteLanguages(PPKGPARSER aParser)
{
	LANGUAGE_LIST lanMap;
	PLANG_LIST langCode;

	aParser->GetLanguageList(lanMap);
	ibyHandle << "\n// Languages: ";

	LANGUAGE_LIST::iterator begin = lanMap.begin();
	LANGUAGE_LIST::iterator end = lanMap.end();

	while(begin != end)
	{
		langCode = (*begin);

		ibyHandle << " " << langCode->langName;
		ibyHandle << "(" << langCode->langCode;

		if(langCode->dialectCode)
		{
			ibyHandle << "-" << langCode->dialectCode;
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
void Sis2Iby::WritePackageHeader(PPKGPARSER aParser)
{
	PKG_HEADER pkgHeader;
	std::list<String> pkgList;
	std::ostringstream str;

	aParser->GetHeader(pkgHeader);

	ibyHandle << "\n// Header: ";

	pkgList = pkgHeader.pkgNameList;
	while(pkgList.size())
	{
		ibyHandle << "\"" << pkgList.front() << "\" ";
		pkgList.pop_front();
	}

	str << "(0x" << std::setbase(16) << pkgHeader.pkgUid << ")";

	ibyHandle << str.str();
}

/**
WriteInstallOptions: Writes install option section in the IBY file

@internalComponent
@released

@param aParser - Package file parser object
*/
void Sis2Iby::WriteInstallOptions(PPKGPARSER aParser)
{
	std::list<String> optList;
	String ibyName;

	aParser->GetInstallOptions(optList);
	SISFILE_LIST::iterator begin = optList.begin();
	SISFILE_LIST::iterator end = optList.end();

	if(begin != end)
	{
		ibyHandle << "\n// Install Options: ";
	}

	while(begin != end)
	{
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
void Sis2Iby::InsertTabs(int num)
{
	ibyHandle << "\n";
	while(num--)
	{
		ibyHandle << "  ";
	}
}

/**
WritePackageBody: Writes package body details in the IBY file

@internalComponent
@released

@param aParser - Package file parser object
*/
void Sis2Iby::WritePackageBody(PPKGPARSER aParser)
{
	CMDBLOCK_LIST cmdList;
	PCMD_BLOCK cmd;
	int pad = 0;

	ibyHandle << "\n\n";
	aParser->GetCommandList(cmdList);

	CMDBLOCK_LIST::iterator begin = cmdList.begin();
	CMDBLOCK_LIST::iterator end = cmdList.end();

	while(begin != end)
	{
		cmd = (*begin);

		switch(cmd->cmdType)
		{
		case IF:
			{
				InsertTabs(pad);
				ibyHandle << "#if " << cmd->cmdExpression;
				pad++;
			}
			break;
		case ELSEIF:
			{
				InsertTabs(pad-1);
				ibyHandle << "#elif " << cmd->cmdExpression;
			}
			break;
		case ELSE:
			{
				InsertTabs(pad-1);
				ibyHandle << "#else";
			}
			break;
		case ENDIF:
			{
				--pad;
				InsertTabs(pad);
				ibyHandle << "#endif";
			}
			break;
		case INSTALLFILE:
			{
				WriteInstallFileList(cmd->iInstallFileList, aParser, pad);
			}
			break;
		case PACKAGE:
			{
				InsertTabs(pad);
				ibyHandle << "#include " << "\"" << cmd->cmdExpression << "\"";
			}
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
void Sis2Iby::WriteFileInclusion(String aSrcFile, String aDestFile, String aPkgName, int pad)
{
	NormaliseSourceFile(aSrcFile, aPkgName);

	InsertTabs(pad);
	if(IsValidE32Image(aSrcFile))
	{
		ibyHandle << "file = ";
	}
	else
	{
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
void Sis2Iby::WriteInstallFileList(PINSTALLFILE_LIST aFileList, PPKGPARSER aParser, int pad)
{
	WriteFileInclusion(aFileList->srcFiles.front(), aFileList->destFile, aParser->GetPkgFileName(), pad);
}

/**
AppendFileName: Appends file name to the given path

@internalComponent
@released

@param aPath - Source path
@param aFile - File name
*/
void Sis2Iby::AppendFileName(String& aPath, String aFile)
{
	TUint pos = 0;

	TrimQuotes(aPath);
	TrimQuotes(aFile);

	pos = aPath.rfind(PATHSEPARATOR);
	if(pos == String::npos)
	{
		aPath.append(PATHSEPARATOR);
	}

	if(pos < (aPath.length()-1))
	{
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
void Sis2Iby::GetFileName(String aName, String& aFile)
{
	TUint spos = 0, epos = 0;

	spos = aName.rfind(PATHSEPARATOR);
	if(spos != String::npos)
	{
		spos += 1;
	}
	else
	{
		spos = 0;
	}

	epos = aName.rfind(".");
	if(epos == String::npos)
	{
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
void Sis2Iby::MakeFullPath(String& aFile)
{
#ifdef WIN32
	char fPath[_MAX_PATH];

	if( _fullpath(fPath, (char*)aFile.data(), _MAX_PATH) != NULL )
	{
		aFile.assign(fPath);
	}
#else
#error "TODO: Implement this function under other OS than Windows"
#endif
	return;
}

/**
NormaliseSourceFile: Normalise the source file with its absolute path

@internalComponent
@released

@param aFile - Input file name
@param aPkgFile - Package file path
*/
void Sis2Iby::NormaliseSourceFile(String& aFile, String aPkgFile)
{
	String result;
	TUint pos = 0;

	pos = aPkgFile.rfind(PATHSEPARATOR);
	if(pos != String::npos)
	{
		result = aPkgFile.substr(0,pos);
	}
	else
	{
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
void Sis2Iby::NormaliseDestFile(String& aFile)
{
	TUint pos = 0;

	/** Comment by KunXu to fix DEF122540 on 18 Jun 2008
	pos = aFile.find("$:");
	if(pos != String::npos)
	{
		aFile.replace(pos, 2, "");
	}

	pos = aFile.find("!:");
	if(pos != String::npos)
	{
		aFile.replace(pos, 2, "");
	}
	**/

	/** Add by KunXu to fix DEF122540 on 18 Jun 2008 **/
	/** Ignore any drive indication in the filename to generate an iby file **/
	/** Begin **/
	pos = aFile.find(":");
	if (1 == pos)
	{
		char chFirst = aFile[0];
		if ('$' == chFirst || '!' == chFirst || (chFirst >='a' && chFirst <='z') || (chFirst >='A' && chFirst <='Z'))
		{
			aFile.replace(0, 2, "");
		}
	}
	/** End **/

	aFile = "\"" + aFile + "\"";
}

/**
IsValidE32Image: Checks whether the given file is E32 image

@internalComponent
@released

@param aFile - Input file name
*/
TBool Sis2Iby::IsValidE32Image(String aFile)
{
	std::ifstream aIfs;
	TInt8 aSig[5];
	TUint32 e32SigOffset = 0x10, fileSize = 0;
	TBool validE32 = EFalse;

	TrimQuotes(aFile);

	aIfs.open(aFile.c_str(), std::ios::in | std::ios::binary);

	if( !aIfs.is_open() )
	{
		throw SisUtilsException((char*)aFile.data(), "Cannot open file");
	}

	aIfs.seekg(0,std::ios::end);
	fileSize = aIfs.tellg();
	if(fileSize > 20)
	{
		aIfs.seekg(e32SigOffset,std::ios::beg);
		aIfs.read((char*)aSig, 4);
		aSig[4] = '\0';

		if(!strcmp((char*)aSig, "EPOC"))
		{
			validE32 = ETrue;
		}
	}

	aIfs.close();

	return validE32;
}
