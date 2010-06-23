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
*
*/


#ifndef __R_OBEY_H__
#define __R_OBEY_H__

#define __REFERENCE_CAPABILITY_NAMES__
 
#include <e32capability.h>
#include <vector>
#include <map>
#include <fstream>
using namespace std;

#include "r_rom.h"
#include "r_areaset.h"
 
 

const TUint32 KNumWords=16;
//
const TInt KDefaultRomSize=0x400000;
const TInt KDefaultRomLinearBase=0x50000000;
const TInt KDefaultRomAlign=0x1000;
const TUint32 KDefaultDataRunAddress = 0x400000;
//
typedef vector<string> StringVector ;
 

enum EFileAttribute
	{
	EAttributeStackReserve,
	EAttributeStack,
	EAttributeReloc,
	EAttributeCodeAlign,
	EAttributeDataAlign,
	EAttributeFixed,
	EAttributeAtt,
	EAttributePriority,
	EAttributePatched,
	EAttributeUid1,
	EAttributeUid2,
	EAttributeUid3,
	EAttributeHeapMin,
	EAttributeHeapMax,
	EAttributeHidden,
	EAttributeKeepIAT,
	EAttributeArea,
	EAttributeProcessSpecific,
	EAttributeCapability,
	EAttributePreferred,
	EAttributeUnpaged,
	EAttributePaged,
	EAttributeUnpagedCode,
	EAttributePagedCode,
	EAttributeUnpagedData,
	EAttributePagedData,
	};
enum EKeyword 
	{
	EKeywordNone=0,	// backwards compatibility, but now ignored
	EKeywordFile,
	EKeywordData,
	EKeywordPrimary,
	EKeywordSecondary,
	EKeywordVariant,
	EKeywordExtension,
	EKeywordDevice,
	EKeywordDll,
	EKeywordFileCompress,
	EKeywordFileUncompress,
	EKeywordArea,
	EKeywordAlign,
	EKeywordUnicode,
	EKeywordAscii,
	EKeywordSingleKernel,
	EKeywordMultiKernel,
	EKeywordBootBinary,
	EKeywordRomName,
	EKeywordRomSize,
	EKeywordRomLinearBase,
	EKeywordRomAlign,
	EKeywordRomChecksum,
	EKeywordKernelDataAddress,
	EKeywordKernelHeapMin,
	EKeywordKernelHeapMax,
	EKeywordDataAddress,
	EKeywordDllDataTop,
	EKeywordDefaultStackReserve,
	EKeywordVersion,
	EKeywordLanguages,
	EKeywordHardware,
	EKeywordRomNameOdd,
	EKeywordRomNameEven,
	EKeywordSRecordFileName,
	EKeywordSRecordBase,
	EKeywordTrace,
	EKeywordKernelTrace,
	EKeywordBTrace,
	EKeywordBTraceMode,
	EKeywordBTraceBuffer,
	EKeywordCollapse,
	EKeywordTime,
	EKeywordSection,
	EKeywordExtensionRom,
	EKeywordKernelRomName,
	EKeywordAlias,
	EKeywordHide,
	EKeywordRename,
	EKeywordDebugPort,
	EKeywordCompress,
	EKeywordMemModel,
	EKeywordNoWrapper,
	EKeywordEpocWrapper,
	EKeywordCoffWrapper,
	EKeywordPlatSecEnforcement,
	EKeywordPlatSecDiagnostics,
	EKeywordPlatSecProcessIsolation,
	EKeywordPlatSecEnforceSysBin,
	EKeywordPlatSecDisabledCaps,
	EKeywordPagingPolicy,
	EKeywordCodePagingPolicy,
	EKeywordDataPagingPolicy,
	EKeywordPagingOverride,
	EKeywordCodePagingOverride,
	EKeywordDataPagingOverride,
	EKeywordDemandPagingConfig,
	EKeywordPagedRom,
	EKeywordPatchDllData,
	EKeywordExecutableCompressionMethodNone,
	EKeywordExecutableCompressionMethodInflate,
	EKeywordExecutableCompressionMethodBytePair,
	EKeywordCoreImage,
	EKeywordKernelConfig,
	EKeywordMaxUnpagedMemSize,
	EKeywordHardwareConfigRepositoryData ,
	};
enum TCollapseMode
	{
	ECollapseNone=0,
	ECollapseImportThunksOnly=1,
	ECollapseImportThunksAndVtables=2,
	ECollapseAllChainBranches=3,
	};

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
class CObeyFile;
class ObeyFileReader
	{
public:
	ObeyFileReader(const char* aFileName);
	~ObeyFileReader();

	static void KeywordHelp();

	TBool Open();
	void Mark();
	void MarkNext();
	void Rewind();

	TInt NextLine(TInt aPass, enum EKeyword& aKeyword);
	TInt NextAttribute(TInt& aIndex, TInt aHasFile, enum EFileAttribute& aKeyword, char*& aArg);

	char* DupWord(TInt aIndex) const ;				// allocate copy of nth word
	TInt Count() const { return iNumWords;}				// number of words on current line
	const char* Word(TInt aIndex) const  { return iWord[aIndex]; }	// return nth word as char* 
	const char* Suffix() const { return iSuffix; }			// return unmatched suffix of word[0]
	TInt CurrentLine() const { return iCurrentLine;}				// number of words on current line

	TInt ProcessAlign(TInt& aAlign);
	void ProcessLanguages(TInt64& aLanguageMask);
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
protected:
	string iFileName;	
private:
	TInt iCurrentLine; 
	StringVector iLines ;
	TInt iNumWords;	
	char* iLine;
	TInt iMarkLine ;
	 
	char iSuffix[80];
	char* iWord[KNumWords];
friend class CObeyFile;
	};

class CPatchDataProcessor;
class DllDataEntry;

class CObeyFile
	{
public:
	char* iRomFileName;
	char* iRomOddFileName;
	char* iRomEvenFileName;
	char* iSRecordFileName;
	char* iBootFileName;
	char* iKernelRomName;
	TInt iRomSize;
	TUint32 iRomLinearBase;
	TUint32 iRomAlign;
	TUint32 iKernDataRunAddress;
	TUint32 iDataRunAddress;
	TUint32 iKernelLimit;
	TUint32 iKernHeapMin;
	TUint32 iKernHeapMax;
	TUint32 iSectionStart;
	TInt iSectionPosition;
	TVersion iVersion;
	TUint32 iCheckSum;
	TInt iNumberOfPeFiles;
	TInt iNumberOfDataFiles;
	TInt iNumberOfPrimaries;
	TInt iNumberOfExtensions;
	TInt iNumberOfVariants;
	TInt iNumberOfDevices;
	TInt iNumberOfHCRDataFiles ;
	TUint iAllVariantsMask[256];
	TRomBuilderEntry** iPrimaries;
	TRomBuilderEntry** iVariants;
	TRomBuilderEntry** iExtensions;
	TRomBuilderEntry** iDevices;
	TInt64 iLanguage;
	TUint32 iHardware;
	TInt64 iTime;
	TMemModel iMemModel;
	TInt iPageSize;
	TInt iChunkSize;
	TInt iVirtualAllocSize;
	TKernelModel iKernelModel;
	TInt iCollapseMode;
	TUint32 iSRecordBase;
	TInt iCurrentSectionNumber;
	TInt iDefaultStackReserve;
	TUint32 iTraceMask[KNumTraceMaskWords];			// Pass through to the kernel tracemask
	TUint32 iInitialBTraceFilter[8];
	TInt iInitialBTraceBuffer;
	TInt iInitialBTraceMode;
	TUint32 iDebugPort;
	TBool iDebugPortParsed;
	TRomNode* iRootDirectory;
	TUint32 iDllDataTop;
	TUint32 iKernelConfigFlags;
	TBool iPagingPolicyParsed;
	TBool iCodePagingPolicyParsed;
	TBool iDataPagingPolicyParsed;
	TBool iPagingOverrideParsed;
	TBool iCodePagingOverrideParsed;
	TBool iDataPagingOverrideParsed;
	SCapabilitySet iPlatSecDisabledCaps;
	TBool iPlatSecDisabledCapsParsed;
	TInt iMaxUnpagedMemSize;		// Max unpaged memory size, 0 = no limits
private:
	ObeyFileReader& iReader;
	TInt iMissingFiles;
	TRomNode* iLastExecutable;
	AreaSet iAreaSet;

	TRomBuilderEntry* iFirstFile;
	TRomBuilderEntry** iNextFilePtrPtr;
	TRomBuilderEntry* iCurrentFile;
	TRomBuilderEntry* iLastVariantFile;
	DllDataEntry* iFirstDllDataEntry;
	TBool iUpdatedMaxUnpagedMemSize;		// ETure = iMaxUnpagedMemSize has been set

public:
	CObeyFile(ObeyFileReader& aReader);
	~CObeyFile();
	void Release();
	TInt ProcessKernelRom();
	TInt ProcessExtensionRom(MRomImage*& aKernelRom);
	TRomBuilderEntry *FirstFile();
	TRomBuilderEntry *NextFile();
	const AreaSet& SetArea() const ; 
 	DllDataEntry* GetFirstDllDataEntry() const;
	void SetFirstDllDataEntry(DllDataEntry* aDllDataEntry);

	int SkipToExtension();
	char* ProcessCoreImage();
	const char* GetFileName() const ;

private:
	TBool CheckHardwareVariants();
	TBool ProcessFile(TInt aAlign, enum EKeyword aKeyword);
	TBool ProcessRenaming(enum EKeyword aKeyword);
	TBool ProcessKeyword(enum EKeyword aKeyword);
	TBool ParsePatchDllData();
	void ProcessExtensionKeyword(enum EKeyword aKeyword);
	TInt ParseFileAttributes(TRomNode* aNode, TRomBuilderEntry* aFile);
	TInt ParseSection();
	TUint32 ParseVariant();
	TBool GotKeyVariables();
	TBool GotExtensionVariables(MRomImage*& aRom);
	TBool GetNextBitOfFileName(char*& epocEndPtr);
	const char* IsValidFilePath(const char* aPath);
	void AddFile(TRomBuilderEntry* aFile);

	// Area-related methods
	TBool CreateDefaultArea();
	TBool ParseAreaKeyword();
	TBool ParseAreaAttribute(const char* aArg, TInt aLineNumber, const Area*& aArea);
	TBool AddAreaAndHandleError(const char* aName, TLinAddr aDestBaseAddr, TUint aLength, TInt aLineNumber = -1);

public:
	CPatchDataProcessor* iPatchData;	
	void SplitPatchDataStatement(StringVector& aPatchDataTokens);	
	};


inline const AreaSet& CObeyFile::SetArea() const {
	return iAreaSet;
}
inline const char* CObeyFile::GetFileName() const {
	return iReader.iFileName.c_str();
}
#endif
