/*
* Copyright (c) 1995-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* @internalComponent * @released
* OBY file reader and processing class Definition.
*
*/


#ifndef __R_OBEY_H__
#define __R_OBEY_H__

#define __REFERENCE_CAPABILITY_NAMES__

#include <stdio.h>
#include <e32capability.h>
#include <kernel/kernboot.h>
#include "fatdefines.h"

#include <vector>
#include <map>
#include <fstream>

using namespace std;
//
const TUint32 KNumWords=16;
//
const TInt KDefaultRomSize=0x400000;
const TInt KDefaultRomAlign=0x10;
//
typedef vector<string> StringVector ;
typedef map<string, StringVector> KeywordMap;

enum EKeyword
{
	EKeywordNone=0,	// backwards compatibility, but now ignored
	EKeywordFile,
	EKeywordData,
	EKeywordDir,
	EKeywordRofsName,
	EKeywordExtensionRofs, 
	EKeywordCoreRofsName,
	EKeywordRomSize,
	EKeywordAlias,
	EKeywordHide,
	EKeywordRename,
	EKeywordRofsSize,
	EKeywordRofsChecksum,
	EKeywordVersion,
	EKeywordTime,
	EKeywordRomChecksum,
	EKeywordTrace,
	EKeywordCoreImage,
	EKeywordRofsAutoSize,
	EKeywordFileCompress,
	EKeywordFileUncompress,
	EKeywordHideV2,
	EKeywordPatchDllData,
	EKeywordPagingOverride,
	EKeywordCodePagingOverride,
	EKeywordDataPagingOverride,
	// Added to support data drive images.
	EKeywordDataImageName,    
	EKeywordDataImageFileSystem, 
	EKeywordDataImageSize,
	EKeywordDataImageVolume,
	EKeywordDataImageSectorSize,
	EKeywordDataImageNoOfFats,
	EKeywordSmrImageName,
	EKeywordSmrFileData,
	EKeywordSmrFormatVersion,
	EKeywordSmrFlags,
	EKeywordSmrUID

};

enum EFileAttribute {
	EAttributeAtt,
	EAttributeAttExtra,
//	EAttributeCompress,
	EAttributeStack,
	EAttributeFixed,
	EAttributePriority,
	EAttributeUid1,
	EAttributeUid2,
	EAttributeUid3,
	EAttributeHeapMin,
	EAttributeHeapMax,
	EAttributeCapability,
	EAttributeUnpaged,
	EAttributePaged,
	EAttributeUnpagedCode,
	EAttributePagedCode,
	EAttributeUnpagedData,
	EAttributePagedData,
	};

#include "r_romnode.h"
#include "r_rofs.h"

class MRofsImage;
 
struct ObeyFileKeyword
	{
	const char* iKeyword;
	size_t iKeywordLength;
	TInt iPass;
	TInt iNumArgs;		// -ve means >= number
	enum EKeyword iKeywordEnum;
	const char* iHelpText;
	};

struct FileAttributeKeyword
	{
	const char* iKeyword;
	size_t iKeywordLength;
	TInt iIsFileAttribute;
	TInt iNumArgs;
	enum EFileAttribute iAttributeEnum;
	const char* iHelpText;
	};

class ObeyFileReader
	{
public:
	ObeyFileReader(const char *aFileName);
	~ObeyFileReader();

	static void KeywordHelp();

	TBool Open();
	void Mark();
	void MarkNext();
	void Rewind();

	TInt NextLine(TInt aPass, enum EKeyword& aKeyword);
	TInt NextAttribute(TInt& aIndex, TInt aHasFile, enum EFileAttribute& aKeyword, char*& aArg);

	char* DupWord(TInt aIndex) const;				// allocate copy of nth word
	TInt Count() const { return iNumWords;}				// number of words on current line
	const char* Word(TInt aIndex) const { return iWord[aIndex]; }	// return nth word as char* 
	const char* Suffix() const { return iSuffix; } 			// return unmatched suffix of word[0]
	TInt CurrentLine() const { return iCurrentLine;}				// number of words on current line
	const char* GetCurrentObeyStatement() const {return iCurrentObeyStatement;}						// return current obey statement

	void ProcessTime(TInt64& aTime);
	static void TimeNow(TInt64& aTime);
private:
	TInt ReadAndParseLine(); 
	TInt Parse();
	inline static TBool IsGap(char ch) {
		return (ch==' ' || ch=='=' || ch=='\t');
	}

	static const ObeyFileKeyword iKeywords[];
	static const FileAttributeKeyword iAttributeKeywords[];
	static TInt64 iTimeNow;

private:
	TInt iCurrentLine; 
	StringVector iLines ;
	string iFileName;
	TInt iNumWords;	
	char* iLine;
	TInt iMarkLine ;
	char* iCurrentObeyStatement;
	char iSuffix[80];
	char* iWord[KNumWords];
	};

class CPatchDataProcessor;
// Configurable FAT attributes


class CObeyFile
	{
public:
	char* iRomFileName;
	char* iExtensionRofsName;
	char* iKernelRofsName;
	TInt iRomSize;
	TVersion iVersion;
	TUint32 iCheckSum;
	TInt iNumberOfFiles;
	TInt64 iTime;
	TRomNode* iRootDirectory;
	TInt iNumberOfDataFiles;
	// Added to support Data Drive Images.
	char* iDriveFileName; 
	char* iDriveFileFormat;
	ConfigurableFatAttributes iConfigurableFatAttributes;

private:
	ObeyFileReader& iReader;
	TInt iMissingFiles;
	TRomNode* iLastExecutable;

	TRomBuilderEntry* iFirstFile;
	TRomBuilderEntry** iNextFilePtrPtr;
	TRomBuilderEntry* iCurrentFile;
	KeywordMap iKeyValues;

public:
	CObeyFile(ObeyFileReader& aReader);
	~CObeyFile();
	void Release();
	TInt ProcessRofs();
	TInt ProcessExtensionRofs(MRofsImage* info);
	TInt ProcessDataDrive();		//	Process the data drive obey file.
	TRomBuilderEntry *FirstFile();
	TRomBuilderEntry *NextFile();
	char* ProcessCoreImage() const;
	void SkipToExtension();
	TBool AutoSize() const {return iAutoSize ;}
	TUint32 AutoPageSize() const {return iAutoPageSize;} 
	TBool Process();
 
	StringVector getValues(const string& aKey);

private:
	TBool ProcessFile(TInt aAlign, enum EKeyword aKeyword);
	TBool ProcessDriveFile(enum EKeyword aKeyword);               
	TBool ProcessRenaming(enum EKeyword aKeyword);
	TBool ProcessKeyword(enum EKeyword aKeyword);
	TBool ProcessDriveKeyword(enum EKeyword aKeyword);
	void ProcessExtensionKeyword(enum EKeyword aKeyword);
	TInt ParseFileAttributes(TRomNode* aNode, TRomBuilderEntry* aFile, enum EKeyword aKeyword);
	TInt ParseSection();
	TBool ParsePatchDllData();
	TBool GotKeyVariables();
	TBool GotKeyDriveVariables();			// To check the data drive mandatory variables. 
	TBool GotExtensionVariables(MRofsImage* aRom);
	void AddFile(TRomBuilderEntry* aFile);

	TInt SetStackSize(TRomNode* aNode, const char *aStr);
	TInt SetHeapSizeMin(TRomNode* aNode, const char *aStr);
	TInt SetHeapSizeMax(TRomNode* aNode, const char *aStr);
	TInt SetCapability(TRomNode* aNode, const char *aStr);
	TInt SetUid1(TRomNode* aNode, const char *aStr);
	TInt SetUid2(TRomNode* aNode, const char *aStr);
	TInt SetUid3(TRomNode* aNode, const char *aStr);
	TInt SetPriority(TRomNode* aNode, const char *aStr);
	
	static TBool GetNextBitOfFileName(char*& epocEndPtr);
	static const char *IsValidFilePath(const char *aPath);
	static const char* IsValidDirPath(const char* aPath);

	TBool iAutoSize;
	TUint32 iAutoPageSize;
	TBool iPagingOverrideParsed;
	TBool iCodePagingOverrideParsed;
	TBool iDataPagingOverrideParsed;
public:
	CPatchDataProcessor* iPatchData;	
	void SplitPatchDataStatement(StringVector& aPatchDataTokens);	
	};


#endif
