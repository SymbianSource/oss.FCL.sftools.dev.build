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

#ifdef _MSC_VER
#pragma warning(disable:4503)
#endif

#if defined(__MSVCDOTNET__) || defined(__TOOLS2__)
#include <fstream>
#else
#include <fstream.h>
#endif

#include <stdio.h>
#include <e32capability.h>

#ifdef _L
#undef _L
#endif

#include <vector>
#include <map>
#include <kernel/kernboot.h>

//
const TUint32 KNumWords=16;
//
const TInt KDefaultRomSize=0x400000;
const TInt KDefaultRomAlign=0x10;
//

typedef std::string String;
typedef std::vector<String> StringVector;
typedef std::map<String, StringVector> KeywordMap;

enum EKeyword
{
	EKeywordNone=0,	// backwards compatibility, but now ignored
	EKeywordFile,
	EKeywordData,
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
	ObeyFileReader(TText *aFileName);
	~ObeyFileReader();

	static void KeywordHelp();

	TBool Open();
	void Mark();
	void MarkNext();
	void Rewind();

	TInt NextLine(TInt aPass, enum EKeyword& aKeyword);
	TInt NextAttribute(TInt& aIndex, TInt aHasFile, enum EFileAttribute& aKeyword, TText*& aArg);

	void CopyWord(TInt aIndex, TText*& aString);				// allocate copy of nth word
	TInt Count() { return iNumWords;}				// number of words on current line
	char* Word(TInt aIndex) { return (char*)iWord[aIndex]; }	// return nth word as char*
	TText* Text(TInt aIndex) { return iWord[aIndex]; }			// return nth word as TText*
	char* Suffix() { return (char*)iSuffix; }			// return unmatched suffix of word[0]
	TInt CurrentLine() { return iCurrentLine;}				// number of words on current line
	TText* GetCurrentObeyStatement() const;						// return current obey statement

	void ProcessTime(TInt64& aTime);

	static void TimeNow(TInt64& aTime);
private:
	TInt ReadAndParseLine();
	TInt SetLineLengthBuffer();
	TInt Parse();
	inline TBool IsGap(char ch);

	static const ObeyFileKeyword iKeywords[];
	static const FileAttributeKeyword iAttributeKeywords[];
	static TInt64 iTimeNow;

private:
	FILE* iObeyFile;
	long iMark;
	TInt iMarkLine;
	long iCurrentMark;
	TInt iCurrentLine;
	TInt imaxLength;
	TText* iFileName;
	TInt iNumWords;
	TText* iWord[KNumWords];
	TText* iSuffix;
	TText* iLine;
	TText* iCurrentObeyStatement;
	};

class CPatchDataProcessor;
struct ConfigurableFatAttributes;

class CObeyFile
	{
public:
	TText *iRomFileName;
	TText *iExtensionRofsName;
	TText *iKernelRofsName;
	TInt iRomSize;
	TVersion iVersion;
	TUint32 iCheckSum;
	TInt iNumberOfFiles;
	TInt64 iTime;
	TRomNode* iRootDirectory;
	TInt iNumberOfDataFiles;
	// Added to support Data Drive Images.
	TText* iDriveFileName;
	TInt64 iDataSize;
	TText* iDriveFileFormat;
	ConfigurableFatAttributes* iConfigurableFatAttributes;

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
	TText* ProcessCoreImage();
	void SkipToExtension();
	TBool AutoSize();
	TUint32 AutoPageSize();
	TBool Process();
	StringVector getValues(const String& aKey);

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
	TBool GetNextBitOfFileName(TText **epocEndPtr);
	TText *IsValidFilePath(TText *aPath);
	void AddFile(TRomBuilderEntry* aFile);

	TInt SetStackSize(TRomNode* aNode, TText *aStr);
	TInt SetHeapSizeMin(TRomNode* aNode, TText *aStr);
	TInt SetHeapSizeMax(TRomNode* aNode, TText *aStr);
	TInt SetCapability(TRomNode* aNode, TText *aStr);
	TInt SetUid1(TRomNode* aNode, TText *aStr);
	TInt SetUid2(TRomNode* aNode, TText *aStr);
	TInt SetUid3(TRomNode* aNode, TText *aStr);
	TInt SetPriority(TRomNode* aNode, TText *aStr);

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
