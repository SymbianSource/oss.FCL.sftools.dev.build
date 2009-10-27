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


#include <string.h>

#ifdef __VC32__
 #ifdef __MSVCDOTNET__
  #include <strstream>
  #include <iomanip>
 #else //!__MSVCDOTNET__
  #include <strstrea.h>
  #include <iomanip.h>
 #endif //__MSVCDOTNET__
#else //!__VC32__
#ifdef __TOOLS2__
 #include <sstream>
  #include <iomanip>
#else
 #include <strstream.h>
 #include <iomanip.h>
#endif 
#endif //__VC32__

#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <assert.h>

#include "e32std.h"
#include "e32std_private.h"
#include "e32rom.h"
#include "u32std.h"

#include "r_rom.h"
#include "r_obey.h"
#include "r_global.h"
#include "h_utl.h"
#include "patchdataprocessor.h"
#include "r_coreimage.h"

#define _P(word)	word, sizeof(word)-1	// match prefix, optionally followed by [HWVD]
#define _K(word)	word, 0					// match whole word

const ObeyFileKeyword ObeyFileReader::iKeywords[] =
{
	{_P("file"),		2,-2, EKeywordFile, "Executable file to be loaded into the ROM"},
	{_P("data"),		2,-2, EKeywordData, "Data file to be copied into the ROM"},
	{_P("primary"),		1+2,-2, EKeywordPrimary, "An EPOC Kernel"},
	{_P("secondary"),	2,-2, EKeywordSecondary, "?"},
	{_P("variant"),		1+2,-2, EKeywordVariant, "?"},
	{_P("extension"),	1+2,-2, EKeywordExtension, "Kernel extension loaded before the secondary"},
	{_P("device"),		1+2,-2, EKeywordDevice, "Kernel extension loaded from the ROM file system"},
	{_P("dll"),			2,-2, EKeywordDll, "Executable file whose entry point must be called"},
	{_P("filecompress"),	2,-2, EKeywordFileCompress, "Non-XIP Executable to be loaded into the ROM compressed"},
	{_P("fileuncompress"),	2,-2, EKeywordFileUncompress, "Non-XIP Executable to be loaded into the ROM uncompressed"},
	{_K("area"),	    1, 3, EKeywordArea, "Declare a relocation area"},
	{_K("align"),	    2, 1, EKeywordAlign, "Override default alignment for following file"},
	{_P("hide"),	    2, -1, EKeywordHide, "Exclude named file from ROM directory structure"},
	{_P("alias"),	    2, -2, EKeywordAlias, "Create alias for existing file in ROM directory structure"},
	{_P("rename"),	    2, -2, EKeywordRename, "Change the name of a file in the ROM directory structure"},
	{_K("singlekernel"),1, 0, EKeywordSingleKernel, "Single Kernel"},
	{_K("multikernel"),	1, 0, EKeywordMultiKernel, "Multiple Kernels"},
	{_K("bootbinary"),	1, 1, EKeywordBootBinary, "file containing the bootstrap"},
	{_K("romname"),		1, 1, EKeywordRomName, "output file for ROM image"},
	{_K("romsize"),		1, 1, EKeywordRomSize, "size of ROM image"},
	{_K("romlinearbase"),	1, 1, EKeywordRomLinearBase, "linear address of ROM image"},
	{_K("romalign"),	1, 1, EKeywordRomAlign, "default alignment of files in ROM image"},
	{_K("romchecksum"),	1, 1, EKeywordRomChecksum, "desired 32-bit checksum value for the whole ROM image"},
	{_K("kerneldataaddress"),	1, 1, EKeywordKernelDataAddress, "?"},
	{_K("kernelheapmin"),	1, 1, EKeywordKernelHeapMin, "Inital size of the kernel heap"},
	{_K("kernelheapmax"),	1, 1, EKeywordKernelHeapMax, "Maximum size of the kernel heap"},
	{_K("dataaddress"),	1, 1, EKeywordDataAddress, "?"},
	{_K("defaultstackreserve"),	1, 1, EKeywordDefaultStackReserve, "?"},
	{_K("version"),		1, 1, EKeywordVersion, "ROM version number"},
	{_K("romnameodd"),	1, 1, EKeywordRomNameOdd, "output file containing odd halfwords of ROM image"},
	{_K("romnameeven"),	1, 1, EKeywordRomNameEven, "output file containing even halfwords of ROM image"},
	{_K("srecordfilename"),	1, 1, EKeywordSRecordFileName, "output file containing ROM image in S-Record format"},
	{_K("srecordbase"),	1, 1, EKeywordSRecordBase, "Destination address for S-Record download"},
	{_K("kerneltrace"),	1, -1, EKeywordKernelTrace, "Initial value for Kernel tracing flags"},
	{_K("btrace"),	1, -1, EKeywordBTrace, "Initial value for fast-trace filter"},
	{_K("btracemode"),	1, 1, EKeywordBTraceMode, "Initial value for fast-trace mode"},
	{_K("btracebuffer"),	1, 1, EKeywordBTraceBuffer, "Initial size for fast-trace buffer"},
	{_K("collapse"),	1, 3, EKeywordCollapse, "Additional ROM optimisations"},
	{_K("time"),	    1,-1, EKeywordTime, "ROM timestamp"},
	{_K("section"),	    2, 1, EKeywordSection, "Start of replaceable section in old-style 2 section ROM"},
	{_K("extensionrom"),1+2, 1, EKeywordExtensionRom, "Start of definition of optional Extension ROM"},
	{_K("kernelromname"),1, 1, EKeywordKernelRomName, "ROM image on which extension ROM is based"},
	{_K("files"),		0, 0, EKeywordNone, 0},	// backwards compatibility, but now ignored
	{_K("rem"),			0, 0, EKeywordNone, "comment"},
	{_K("stop"),		0, 0, EKeywordNone, "Terminates OBEY file prematurely"},
	{_K("dlldatatop"),	1, 1, EKeywordDllDataTop, "Specify top of DLL data region"},
	{_K("memmodel"),	1, -1, EKeywordMemModel, "Specifies the memory model to be used at runtime"},
	{_K("nowrapper"),	1, 0, EKeywordNoWrapper, "Specifies that no ROM wrapper is required"},
	{_K("epocwrapper"),	1, 0, EKeywordEpocWrapper, "Specifies that an EPOC ROM wrapper is required"},
	{_K("coffwrapper"),	1, 0, EKeywordCoffWrapper, "Specifies that a COFF ROM wrapper is required"},
	{_K("platsecenforcement"),	1, 1, EKeywordPlatSecEnforcement, "Set Platform Security enforment on/off"},
	{_K("platsecdiagnostics"),	1, 1, EKeywordPlatSecDiagnostics, "Set Platform Security diagnostics on/off"},
	{_K("platsecprocessisolation"), 1, 1, EKeywordPlatSecProcessIsolation, "Set Platform Security process isolation on/off"},
	{_K("platsecenforcesysbin"), 1, 1, EKeywordPlatSecEnforceSysBin, "Set Platform Security process isolation on/off"},
	{_K("platsecdisabledcaps"), 1, 1, EKeywordPlatSecDisabledCaps, "Disable the listed Platform Security capabilities"},
	{_K("pagingpolicy"),	1, 1, EKeywordPagingPolicy, "Set the demand paging policy NOPAGING|DEFAULTUNPAGED|DEFAULTPAGED"},
	{_K("codepagingpolicy"),	1, 1, EKeywordCodePagingPolicy, "Set the code paging policy NOPAGING|DEFAULTUNPAGED|DEFAULTPAGED"},
	{_K("datapagingpolicy"),	1, 1, EKeywordDataPagingPolicy, "Set the data paging policy NOPAGING|DEFAULTUNPAGED|DEFAULTPAGED"},
	{_K("pagingoverride"),	1, 1, EKeywordPagingOverride, "Overide the demand paging attributes for every file in ROM, NOPAGING|DEFAULTUNPAGED|DEFAULTPAGED"},
	{_K("codepagingoverride"),	1, 1, EKeywordCodePagingOverride, "Overide the code paging attributes for every file in ROM, NOPAGING|DEFAULTUNPAGED|DEFAULTPAGED"},
	{_K("datapagingoverride"),	1, 1, EKeywordDataPagingOverride, "Overide the data paging attributes for every file in ROM, NOPAGING|DEFAULTUNPAGED|DEFAULTPAGED"},
	{_K("patchdata"), 2, 5, EKeywordPatchDllData, "Patch exported data"},
	{_K("coreimage"),	1, 1, EKeywordCoreImage, "Core image to be used for extension directory structure"},

	// things we don't normally report in the help information
	{_K("trace"),		1, 1, EKeywordTrace, "(ROMBUILD activity trace flags)"},
	{_K("unicode"),		1, 0, EKeywordUnicode, "(UNICODE rom - the default)"},
	{_K("ascii"),		1, 0, EKeywordAscii, "(Narrow rom)"},
	{_K("languages"),	1,-1, EKeywordLanguages, "(List of supported languages (for test))"},
	{_K("hardware"),	1, 1, EKeywordHardware, "(32-bit Hardware identifier (for test))"},
	{_K("debugport"),	1, 1, EKeywordDebugPort, "(Debug trace sink (magic cookie passed to ASSP/variant))"},
	{_K("compress"),	1, 0, EKeywordCompress, "Compress the ROM image"},
	{_K("demandpagingconfig"),	1, -1, EKeywordDemandPagingConfig, "Demand Paging Config [minPages] [maxPages] [ageRatio]"},
	{_K("pagedrom"),	1, 0, EKeywordPagedRom, "Build ROM immage suitable for demand paging"},
	{_K("filecompressnone"), 		2, -2, EKeywordExecutableCompressionMethodNone, "No compress the individual executable image."},
	{_K("filecompressinflate"),     2, -2, EKeywordExecutableCompressionMethodInflate,  "Inflate compression method for the individual executable image."},
	{_K("filecompressbytepair"),  	2, -2, EKeywordExecutableCompressionMethodBytePair, "Byte pair compresion method for the individual executable image."},
	{_K("kernelconfig"), 1, 2, EKeywordKernelConfig, "Set an arbitrary bit of the kernel config flags to on/off)"},
	{_K("maxunpagedsize"),	1, 1, EKeywordMaxUnpagedMemSize, "Maxinum unpaged size in ROM image. Default is no limited."},
	{_K("hcrdata") , 2, 2,EKeywordHardwareConfigRepositoryData,"HCR image data"},
	{0,0,0,0,EKeywordNone,""} 
	
};

void ObeyFileReader::KeywordHelp() // static
	{
	cout << "Obey file keywords:\n";

	const ObeyFileKeyword* k=0;
	for (k=iKeywords; k->iKeyword!=0; k++)
		{
		if (k->iHelpText==0)
			continue;
		if (k->iHelpText[0]=='(' && !H.iVerbose)
			continue;	// don't normally report things in (parentheses)

		char buf[32];
		sprintf(buf, "%-20s", k->iKeyword);
		if (k->iKeywordLength)
			memcpy(buf+k->iKeywordLength,"[HWVD]",6);
		if (H.iVerbose)
			sprintf(buf+20,"%2d",k->iNumArgs);
		cout << "    " << buf << " " << k->iHelpText << endl;
		}
	cout << endl;

	cout << "File attributes:\n";

	const FileAttributeKeyword* f=0;
	for (f=iAttributeKeywords; f->iKeyword!=0; f++)
		{
		if (f->iHelpText==0)
			continue;
		if (f->iHelpText[0]=='(' && !H.iVerbose)
			continue;	// don't normally report things in (parentheses)

		char buf[32];
		sprintf(buf, "%-20s", f->iKeyword);
		if (H.iVerbose)
			sprintf(buf+20,"%2d",k->iNumArgs);
		cout << "    " << buf << " " << f->iHelpText << endl;
		}
	cout << endl;
	}

TInt NumberOfVariants=0;

ObeyFileReader::ObeyFileReader(TText* aFileName):
//
// Constructor
//
	iMark(0), iMarkLine(0), iCurrentMark(0), iCurrentLine(0), imaxLength(0),iSuffix(0),iLine(0)
	{

	iFileName = new TText[strlen((const char *)aFileName)+1];
	strcpy((char *)iFileName,(const char *)aFileName);
	}

ObeyFileReader::~ObeyFileReader()
	{
	if (iObeyFile)
		fclose(iObeyFile);
	iObeyFile=0;
	delete [] iFileName;
	delete [] iLine;
	}

TBool ObeyFileReader::Open()
//
// Open the file & return a status
//
	{

 	iObeyFile = fopen((const char *)iFileName,"r");
	if (!iObeyFile)
		{
		Print(EError,"Cannot open obey file %s\n",iFileName);
		return EFalse;
		}
	if (SetLineLengthBuffer() != KErrNone)
	 	{
		Print(EError,"Insufficent Memory to Continue.");	
	 	return EFalse;
		}
	return ETrue;
	}

TInt ObeyFileReader::SetLineLengthBuffer()
// Get the Max Line length for the given obey file and allocate the buffer.
	{
	char ch = '\0';
	TInt length = 0;
		
	Rewind();
	while ((ch = (char)fgetc(iObeyFile)) != EOF)
		{
		length++;
		if (ch == '\n')
			{
			if (length > imaxLength)
				imaxLength = length;
			length = 0;				
			}
		}
	
	if (length > imaxLength)
		imaxLength = length;
		
	if (0 == imaxLength)
		{
		Print(EError,"Empty obey file passed as input.");
		exit(-1);
		}			
	else if (imaxLength < 2)
		{
		Print(EError,"Invalid obey file passed as input.");
		exit(-1);
		}
		
	Rewind();
	iLine = new TText[imaxLength+1];
	
	if(!iLine)
		return KErrNoMemory;

	return KErrNone;
	}

void ObeyFileReader::Mark()
	{

	iMark = iCurrentMark;
	iMarkLine = iCurrentLine-1;
	}

void ObeyFileReader::MarkNext()
	{

	iMark = ftell(iObeyFile);
	iMarkLine = iCurrentLine;
	}

void ObeyFileReader::Rewind()
	{
	
	fseek(iObeyFile,iMark,SEEK_SET);
	iCurrentMark = iMark;
	iCurrentLine = iMarkLine;
	}

void ObeyFileReader::CopyWord(TInt aIndex, TText*& aString)
	{
	aString = new TText[strlen((const char *)iWord[aIndex])+1];
	strcpy((char *)aString, (const char *)iWord[aIndex]);
	}

TInt ObeyFileReader::ReadAndParseLine()
	{
	if (feof(iObeyFile))
		return KErrEof;
	iCurrentLine++;
	iCurrentMark = ftell(iObeyFile);
	iLine[0]='\0';
	fgets((char*)iLine,imaxLength+1,iObeyFile);
	iNumWords = Parse();
	return KErrNone;
	}

TInt ObeyFileReader::NextLine(TInt aPass, enum EKeyword& aKeyword)
	{

NextLine:
	TInt err = ReadAndParseLine();
	if (err == KErrEof)
		return KErrEof;
	if (iNumWords == 0 || stricmp((const char*)iWord[0], "rem")==0)
		goto NextLine;
	if (stricmp((const char*)iWord[0], "stop")==0)
		return KErrEof;

	const ObeyFileKeyword* k=0;
	for (k=iKeywords; k->iKeyword!=0; k++)
		{
		if (k->iKeywordLength == 0)
			{
			// Exact case-insensitive match on keyword
			if (stricmp((const char*)iWord[0], k->iKeyword) != 0)
				continue;
			iSuffix = 0;
			}
		else
			{
			// Prefix match
			if (strnicmp((const char*)iWord[0], k->iKeyword, k->iKeywordLength) != 0)
				continue;
			// Suffix must be empty, or a variant number in []
			iSuffix = iWord[0]+k->iKeywordLength;
			if (*iSuffix != '\0' && *iSuffix != '[')
				continue;
			}
		// found a match
		if ((k->iPass & aPass) == 0)
			goto NextLine;
		if (k->iNumArgs>=0 && (1+k->iNumArgs != iNumWords))
			{
			 
			if(EKeywordHardwareConfigRepositoryData == k->iKeywordEnum){ // preq2131 specific 
				Print(EWarning, "Incorrect number of arguments for keyword '%s' on line %d. Extra argument(s) are ignored.\n",
				iWord[0],iCurrentLine);
				aKeyword = k->iKeywordEnum;
				return KErrNone;
			}else{
				Print(EError, "Incorrect number of arguments for keyword %s on line %d.\n",
					iWord[0], iCurrentLine);
			}
			goto NextLine;
			}
		if (k->iNumArgs<0 && (1-k->iNumArgs > iNumWords))
			{
			Print(EError, "Too few arguments for keyword %s on line %d.\n",
				iWord[0], iCurrentLine);
			goto NextLine;
			}
		
		aKeyword = k->iKeywordEnum;
		return KErrNone;
		}
	if (aPass == 1)
		Print(EWarning, "Unknown keyword '%s'.  Line %d ignored\n", iWord[0], iCurrentLine);
	goto NextLine;
	}

inline TBool ObeyFileReader::IsGap(char ch)
	{
	return (ch==' ' || ch=='=' || ch=='\t');
	}

TInt ObeyFileReader::Parse()
//
// splits a line into words, and returns the number of words found
//

	{

	TUint i; 
	TText *letter=iLine;
	TText *end=iLine+strlen((char *)iLine);
	for (i=0; i<KNumWords; i++)
		iWord[i]=end;

	enum TState {EInWord, EInQuotedWord, EInGap};
	TState state=EInGap;

	i=0;
	while (i<KNumWords && letter<end)
		{
		char ch=*letter;
		if (ch==0)
			break;
		if (ch=='\n')
			{
			*letter='\0';	// remove trailing newline left by fgets
			break;
			}
		switch (state)
			{
		case EInGap:
			if (ch=='\"')
				{
				if (letter[1]!=0 && letter[1]!='\"')
					iWord[i++]=letter+1;
				state=EInQuotedWord;
				}
			else if (!IsGap(ch))
				{
				iWord[i++]=letter;
				state=EInWord;
				}
			else
				*letter=0;
			break;
		case EInWord:
			if (ch=='\"')
				{
				*letter=0;
				if (letter[1]!=0 && letter[1]!='\"')
					iWord[i++]=letter+1;
				state=EInQuotedWord;
				}
			else if (IsGap(ch))
				{
				*letter=0;
				state=EInGap;
				}
			break;
		case EInQuotedWord:
			if (ch=='\"')
				{
				*letter=0;
				state=EInGap;
				}
			break;
			}
		letter++;
		}
	return i;
	}

void ObeyFileReader::ProcessLanguages(TInt64& aLanguageMask)
	{
	TInt i=1;
	while (i<iNumWords)
		{
		char *aStr=(char *)iWord[i];
		TLanguage l=ELangTest;
		if (stricmp(aStr, "test")==0)
			l=ELangTest;
		else if (stricmp(aStr, "english")==0)
			l=ELangEnglish;
		else if (stricmp(aStr, "french")==0)
			l=ELangFrench;
		else if (stricmp(aStr, "german")==0)
			l=ELangGerman;
		else if (stricmp(aStr, "spanish")==0)
			l=ELangSpanish;
		else if (stricmp(aStr, "italian")==0)
			l=ELangItalian;
		else if (stricmp(aStr, "swedish")==0)
			l=ELangSwedish;
		else if (stricmp(aStr, "danish")==0)
			l=ELangDanish;
		else if (stricmp(aStr, "norwegian")==0)
			l=ELangNorwegian;
		else if (stricmp(aStr, "finnish")==0)
			l=ELangFinnish;
		else if (stricmp(aStr, "american")==0)
			l=ELangAmerican;
		else if (stricmp(aStr, "SwissFrench")==0)
			l=ELangSwissFrench;
		else if (stricmp(aStr, "SwissGerman")==0)
			l=ELangSwissGerman;
		else if (stricmp(aStr, "Portuguese")==0)
			l=ELangPortuguese;
		else if (stricmp(aStr, "Turkish")==0)
			l=ELangTurkish;
		else if (stricmp(aStr, "Icelandic")==0)
			l=ELangIcelandic;
		else if (stricmp(aStr, "Russian")==0)
			l=ELangRussian;
		else if (stricmp(aStr, "Hungarian")==0)
			l=ELangHungarian;
		else if (stricmp(aStr, "Dutch")==0)
			l=ELangDutch;
		else if (stricmp(aStr, "BelgianFlemish")==0)
			l=ELangBelgianFlemish;
		else if (stricmp(aStr, "Australian")==0)
			l=ELangAustralian;
		else if (stricmp(aStr, "BelgianFrench")==0)
			l=ELangBelgianFrench;
		else
			{
			Print(EError, "Unknown language '%s' on line %d", iWord[i], iCurrentLine);
			exit(666);
			}
		aLanguageMask = aLanguageMask+(1<<(TInt)l);
		i++;
		}
	}

void ObeyFileReader::ProcessTime(TInt64& aTime)
//
// Process the timestamp
//
	{
	char timebuf[256];
	if (iNumWords>2)
		sprintf(timebuf, "%s_%s", iWord[1], iWord[2]);
	else
		strcpy(timebuf, (char*)iWord[1]);

	TInt r=StringToTime(aTime, timebuf);
	if (r==KErrGeneral)
		{
		Print(EError, "incorrect format for time keyword on line %d\n", iCurrentLine);
		exit(0x670);
		}
	if (r==KErrArgument)
		{
		Print(EError, "Time out of range on line %d\n", iCurrentLine);
		exit(0x670);
		}
	}

TInt64 ObeyFileReader::iTimeNow=0;
void ObeyFileReader::TimeNow(TInt64& aTime)
	{
	if (iTimeNow==0)
		{
		TInt sysTime=time(0);					// seconds since midnight Jan 1st, 1970
		sysTime-=(30*365*24*60*60+7*24*60*60);	// seconds since midnight Jan 1st, 2000
		TInt64 daysTo2000AD=730497;
		TInt64 t=daysTo2000AD*24*3600+sysTime;	// seconds since 0000
		t=t+3600;								// BST (?)
		iTimeNow=t*1000000;						// milliseconds
		}
	aTime=iTimeNow;
	}

TInt ObeyFileReader::ProcessAlign(TInt &aAlign)
//
// Process the align keyword
//
	{

	TInt align;
	if (Val(align, Word(1)))
		return Print(EError, "Number required for 'align' keyword on line %d\n", iCurrentLine);
	aAlign=align;
	TInt i;
	for (i=4; i!=0x40000000; i<<=1)
		if (i==aAlign)
			return KErrNone;
	return Print(EError, "Alignment must be a power of 2 and bigger than 4.  Line %d\n", iCurrentLine);
	}


const FileAttributeKeyword ObeyFileReader::iAttributeKeywords[] =
{
	{"stackreserve",6	,1,1,EAttributeStackReserve, "?"},
	{"stack",3			,1,1,EAttributeStack, "?"},
	{"reloc",3			,1,1,EAttributeReloc, "?"},
	{"code-align",10	,1,1,EAttributeCodeAlign, "Additional code alignment constraint"},
	{"data-align",10	,1,1,EAttributeDataAlign, "Additional data alignment constraint"},
	{"fixed",3			,1,0,EAttributeFixed, "Relocate to a fixed address space"},
	{"attrib",3			,0,1,EAttributeAtt, "File attributes in ROM file system"},
	{"priority",3		,1,1,EAttributePriority, "Override process priority"},
	{"patched",5		,1,0,EAttributePatched, "File to be replaced in second section"},
	{_K("uid1")			,1,1,EAttributeUid1, "Override first UID"},
	{_K("uid2")			,1,1,EAttributeUid2, "Override second UID"},
	{_K("uid3")			,1,1,EAttributeUid3, "Override third UID"},
	{_K("heapmin")		,1,1,EAttributeHeapMin, "Override initial heap size"},
	{_K("heapmax")		,1,1,EAttributeHeapMax, "Override maximum heap size"},
	{_K("keepIAT")		,1,0,EAttributeKeepIAT, "(Retain old-style Import Address Table)"},
	{_K("hide")			,0,0,EAttributeHidden, "Don't record file in the ROM file system"},
	{_K("area")         ,1,1,EAttributeArea, "Relocate file to given area"},
	{_K("process")		,1,1,EAttributeProcessSpecific, "Indicate which process a DLL will attach to"},
	{_K("capability")	,1,1,EAttributeCapability, "Override capabilities"},
	{_K("preferred")	,1,0,EAttributePreferred, "Prefer this over other minor versions of same major version"},
	{_K("unpaged")		,1,0,EAttributeUnpaged, "Don't use demand paging for this file"},
	{_K("paged")		,1,0,EAttributePaged, "Use demand paging for this file"},
	{_K("unpagedcode")	,1,0,EAttributeUnpagedCode, "Don't use code paging for this file"},
	{_K("pagedcode")	,1,0,EAttributePagedCode, "Use code paging for this file"},
	{_K("unpageddata")	,1,0,EAttributeUnpagedData, "Don't use data paging for this file"},
	{_K("pageddata")	,1,0,EAttributePagedData, "Use data paging for this file"},
	{0,0,0,0,EAttributeStackReserve,0}
};

TInt ObeyFileReader::NextAttribute(TInt& aIndex, TInt aHasFile, enum EFileAttribute& aKeyword, TText*& aArg)
	{
NextAttribute:
	if (aIndex >= iNumWords)
		return KErrEof;
	TText* word=iWord[aIndex++];
	const FileAttributeKeyword* k;
	for (k=iAttributeKeywords; k->iKeyword!=0; k++)
		{
		if (k->iKeywordLength == 0)
			{
			// Exact match on keyword
			if (stricmp((const char*)word, k->iKeyword) != 0)
				continue;
			}
		else
			{
			// Prefix match
			if (strnicmp((const char*)word, k->iKeyword, k->iKeywordLength) != 0)
				continue;
			}
		// found a match
		if (k->iNumArgs>0)
			{
			TInt argIndex = aIndex;
			aIndex += k->iNumArgs;		// interface only really supports 1 argument
			if (aIndex>iNumWords)
				{
				Print(EError, "Missing argument for attribute %s on line %d\n", word, iCurrentLine);
				return KErrArgument;
				}
			aArg=iWord[argIndex];
			}
		if (k->iIsFileAttribute && !aHasFile)
			{
			Print(EError, "File attribute %s applied to non-file on line %d\n", word, iCurrentLine);
			return KErrNotSupported;
			}
		aKeyword=k->iAttributeEnum;
		return KErrNone;
		}
	Print(EWarning, "Unknown attribute '%s' skipped on line %d\n", word, iCurrentLine);
	goto NextAttribute;
	}




CObeyFile::CObeyFile(ObeyFileReader& aReader):
	iRomFileName(0),iRomOddFileName(0),iRomEvenFileName(0),
	iSRecordFileName(0),iBootFileName(0),iKernelRomName(0),
	iRomSize(0),iRomLinearBase(0xffffffff),iRomAlign(0),
	iKernDataRunAddress(0),iDataRunAddress(0),iKernelLimit(0xffffffff),
	iKernHeapMin(0),iKernHeapMax(0),iSectionStart(0),iSectionPosition(-1),
	iVersion(0,0,0),iCheckSum(0),iNumberOfPeFiles(0),iNumberOfDataFiles(0),
	iNumberOfPrimaries(0),iNumberOfExtensions(0),iNumberOfVariants(0),
	iNumberOfDevices(0),iNumberOfHCRDataFiles (0),
	//iAllVariantsMask[256],
	iPrimaries(0),iVariants(0),iExtensions(0),iDevices(0),
	iLanguage(0),iHardware(0),iTime(0),iMemModel(E_MM_Moving),iPageSize(0x1000),
	iChunkSize(0x100000),iVirtualAllocSize(0x1000),iKernelModel(ESingleKernel),
	iCollapseMode(ECollapseNone),iSRecordBase(0),iCurrentSectionNumber(0),
	iDefaultStackReserve(0),//iTraceMask[KNumTraceMaskWords];iInitialBTraceFilter[8];
	iInitialBTraceBuffer(0),iInitialBTraceMode(0),iDebugPort(0),
	iDebugPortParsed(EFalse),iRootDirectory(0),iDllDataTop(0x40000000),
	iKernelConfigFlags(0),iPagingPolicyParsed(EFalse),iCodePagingPolicyParsed(EFalse),
	iDataPagingPolicyParsed(EFalse),iPagingOverrideParsed(EFalse),
	iCodePagingOverrideParsed(EFalse),iDataPagingOverrideParsed(EFalse),
	/*iPlatSecDisabledCaps(), */iPlatSecDisabledCapsParsed(EFalse),iMaxUnpagedMemSize(0),
	iReader(aReader),iMissingFiles(0),iLastExecutable(0),iAreaSet(),iFirstFile(0),
	iCurrentFile(0),iLastVariantFile(0),iFirstDllDataEntry(0),
	iUpdatedMaxUnpagedMemSize(EFalse),iPatchData(new CPatchDataProcessor)
	{

	TUint i; 
	for (i=0; i<256; i++)
		iAllVariantsMask[i]=0;
	for (i=0; i<(TUint)KNumTraceMaskWords; i++) 
		iTraceMask[i]=0;
	for (i=0; i<sizeof(iInitialBTraceFilter)/sizeof(TUint32); i++)
		iInitialBTraceFilter[i]=0;	
	memset(&iPlatSecDisabledCaps,0,sizeof(SCapabilitySet));
	iNextFilePtrPtr = &iFirstFile;
	}

CObeyFile::~CObeyFile()
//
// Destructor
//
	{

	Release();
	delete [] iRomFileName;
	if (iRootDirectory)
		iRootDirectory->Destroy();
	delete iPatchData;
	}

void CObeyFile::Release()
//
// Free resources not needed after building a ROM
//
	{
	iAreaSet.ReleaseAllAreas();

	delete [] iBootFileName;
	delete [] iPrimaries;
	delete [] iVariants;
	delete [] iExtensions;
	delete [] iDevices;

	iBootFileName = 0;
	iPrimaries = 0;
	iVariants = 0;
	iExtensions = 0;
	iDevices = 0;
	iFirstFile = 0;
	iNextFilePtrPtr = &iFirstFile;
	}

TRomBuilderEntry *CObeyFile::FirstFile()
	{
	iCurrentFile = iFirstFile;
	return iCurrentFile;
	}

TRomBuilderEntry *CObeyFile::NextFile()
	{
	iCurrentFile = iCurrentFile ? iCurrentFile->iNext : 0;
	return iCurrentFile;
	}

/*
*Set first link in patchdata linked list
**/
void CObeyFile::SetFirstDllDataEntry(DllDataEntry* aDllDataEntry)
{
  	iFirstDllDataEntry = aDllDataEntry;
}

/*
*Get first link in patchdata linked list
**/
DllDataEntry* CObeyFile::GetFirstDllDataEntry() const
{
	return iFirstDllDataEntry;
}

TInt CObeyFile::ProcessKernelRom()
	{
	//
	// First pass through the obey file to set up key variables
	//

	iReader.Rewind();

	TInt count=0;
	enum EKeyword keyword;
	while (iReader.NextLine(1,keyword) != KErrEof)
		{
		if (keyword == EKeywordExtensionRom)
			{
			if (count==0)
				return KErrNotFound;		// no kernel ROM, just extension ROMs.
			break;
			}

		count++;
		if (! ProcessKeyword(keyword))
			return KErrGeneral;
		}

	if (!GotKeyVariables())
		return KErrGeneral;

	if (! CreateDefaultArea())
		return KErrGeneral;

	//
	// second pass to process the file specifications in the obey file building
	// up the TRomNode directory structure and the TRomBuilderEntry list
	//
	iReader.Rewind();

	iRootDirectory = new TRomNode((TText*)"");
	iLastExecutable = iRootDirectory;

	TInt align=0;
	while (iReader.NextLine(2,keyword)!=KErrEof)
		{
		if (keyword == EKeywordExtensionRom)
			break;

		switch (keyword)
			{
		case EKeywordSection:
			if (ParseSection()!=KErrNone)
				return KErrGeneral;
			break;
		case EKeywordAlign:
			if (iReader.ProcessAlign(align)!=KErrNone)
				return KErrGeneral;
			break;
		case EKeywordHide:
		case EKeywordAlias:
		case EKeywordRename:
			if (!ProcessRenaming(keyword))
				return KErrGeneral;
			break;
		case EKeywordPatchDllData:
		{
			// Collect patchdata statements to process at the end
			StringVector patchDataTokens;
			SplitPatchDataStatement(patchDataTokens); 
			iPatchData->AddPatchDataStatement(patchDataTokens);									
			break;
		}

		default:
			if (!ProcessFile(align, keyword))
				return KErrGeneral;
			align=0;
			break;
			}
		}

	if( !ParsePatchDllData())
		return KErrGeneral;

	iReader.Mark();			// ready for processing the extension rom(s)

	if (iMissingFiles!=0)
		return KErrGeneral;
	if (iNumberOfDataFiles+iNumberOfPeFiles==0)
		{
		Print(EError, "No files specified.\n");
		return KErrGeneral;
		}
	if (!CheckHardwareVariants())
		return KErrGeneral;

	return KErrNone;
	}


TInt CObeyFile::ParseSection()
//
// Process the section keyword
//
	{
	TInt currentLine = iReader.CurrentLine();
	if (iSectionPosition!=-1)
		return Print(EError, "Rom already sectioned.  Line %d\n", currentLine);
	TInt offset;
	if (Val(offset, iReader.Word(1)))
		return Print(EError, "Number required for 'section' keyword on line %d\n", currentLine);
	iSectionStart=offset+iRomLinearBase;
	if (offset>=iRomSize)
		return Print(EError, "Sectioned beyond end of Rom.  Line %d\n", currentLine);
	if (offset&0x0fff)
		return Print(EError, "Section must be on a 4K boundry.  Line %d\n", currentLine);
	iSectionPosition=iNumberOfDataFiles+iNumberOfPeFiles;
	iCurrentSectionNumber++;	
	return KErrNone;
	}

TInt CObeyFile::ParseFileAttributes(TRomNode *aNode, TRomBuilderEntry* aFile)
//
// Process any inline keywords
//
	{
	TInt currentLine = iReader.CurrentLine();
	enum EFileAttribute attribute;
	TInt r=KErrNone;
	TInt index=3;
	TText* arg=0;

	while(r==KErrNone)
		{
		r=iReader.NextAttribute(index,(aFile!=0),attribute,arg);
		if (r!=KErrNone)
			break;
		switch(attribute)
			{
		case EAttributeStackReserve:
			r=aFile->SetStackReserve(arg);
			break;
		case EAttributeStack:
			r=aFile->SetStackSize(arg);
			break;
		case EAttributeReloc:
			r=aFile->SetRelocationAddress(arg);
			break;
		case EAttributeCodeAlign:
			r=aFile->SetCodeAlignment(arg);
			break;
		case EAttributeDataAlign:
			r=aFile->SetDataAlignment(arg);
			break;
		case EAttributeFixed:
			r=aFile->SetRelocationAddress(NULL);
			break;
		case EAttributeAtt:
			r=aNode->SetAtt(arg);
			break;
		case EAttributeUid1:
			r=aFile->SetUid1(arg);
			break;
		case EAttributeUid2:
			r=aFile->SetUid2(arg);
			break;
		case EAttributeUid3:
			r=aFile->SetUid3(arg);
			break;
		case EAttributeHeapMin:
			r=aFile->SetHeapSizeMin(arg);
			break;
		case EAttributeHeapMax:
			r=aFile->SetHeapSizeMax(arg);
			break;
		case EAttributePriority:
			r=aFile->SetPriority(arg);
			break;
		case EAttributePatched:
			if (iSectionPosition!=-1)
				return Print(EError, "Not sensible to patch files in top section.  Line %d.\n", currentLine);
			aFile->iPatched=ETrue;
			break;
		case EAttributeKeepIAT:
			aFile->iOverrideFlags |= KOverrideKeepIAT;
			break;
		case EAttributeHidden:
			if (aFile->Extension())
 				return Print(EError, "Cannot hide Extension. Line %d.\n", currentLine);
			aNode->iHidden=ETrue;
			break;
		case EAttributeArea:
			{
			TRACE(TAREA, Print(EScreen, "Area Attribute: %s\n", arg));
			const Area* area = aFile->iArea;
			if (! ParseAreaAttribute(arg, currentLine, area))
				return KErrGeneral;
			}
			break;
		case EAttributeProcessSpecific:
			if (!IsValidFilePath(arg))
				{
				Print(EError, "Invalid file path for process attribute on line %d\n", currentLine);
				return KErrGeneral;
				}
			r=aFile->SetAttachProcess(arg);
			break;
		case EAttributeCapability:
			r=aFile->SetCapability(arg);
			break;
		case EAttributePreferred:
			aFile->iPreferred = ETrue;
			break;
		case EAttributeUnpaged:
			aFile->iOverrideFlags |= KOverrideCodeUnpaged | KOverrideDataUnpaged;
			aFile->iOverrideFlags &= ~(KOverrideCodePaged | KOverrideDataPaged);
			break;
		case EAttributePaged:
			aFile->iOverrideFlags |= KOverrideCodePaged | KOverrideDataPaged;
			aFile->iOverrideFlags &= ~(KOverrideCodeUnpaged | KOverrideDataUnpaged);
			break;
		case EAttributeUnpagedCode:
			aFile->iOverrideFlags |= KOverrideCodeUnpaged;
			aFile->iOverrideFlags &= ~KOverrideCodePaged;
			break;
		case EAttributePagedCode:
			aFile->iOverrideFlags |= KOverrideCodePaged;
			aFile->iOverrideFlags &= ~KOverrideCodeUnpaged;
			break;
		case EAttributeUnpagedData:
			aFile->iOverrideFlags |= KOverrideDataUnpaged;
			aFile->iOverrideFlags &= ~KOverrideDataPaged;
			break;
		case EAttributePagedData:
			aFile->iOverrideFlags |= KOverrideDataPaged;
			aFile->iOverrideFlags &= ~KOverrideDataUnpaged;
			break;

		default:
			return Print(EError, "Unrecognised keyword in file attributes on line %d.\n",currentLine);
			}
		}

	// aFile may be null if processing an extension ROM
	if (aFile && aFile->iPatched && ! aFile->iArea->IsDefault())
		{
		return Print(EError, "Relocation to area at line %d forbidden because file is patched\n", currentLine);
		}

	if (r==KErrEof)
		return KErrNone;
	return r;
	}

TUint32 CObeyFile::ParseVariant()
	{
	char* left=iReader.Suffix();
	if (left == 0 || *left=='\0')
		return KVariantIndependent;
	const char* right=left+strlen(left)-1;
	if (*left=='[' && *right==']')
		{
		TUint variant;
		#ifdef __TOOLS2__
		string s(left+1);
		string s2=s.substr(0,right-(left+1));
		istringstream val(s2,ios::in);
		#else
		istrstream val(left+1, right-(left+1));
		#endif
		

#if defined(__MSVCDOTNET__) || defined(__TOOLS2__)
		val >> setbase(0);
#endif //__MSVCDOTNET__

		val >> variant;
		if (val.eof() && !val.fail())
			return variant;
		}
//#endif
	Print(EError,"Syntax error in variant, %s keyword on line %d\n", iReader.Word(0), iReader.CurrentLine());
	return KVariantIndependent;
	}

TBool CObeyFile::ProcessFile(TInt aAlign, enum EKeyword aKeyword)
//
// Process a parsed line to set up one or more new TRomBuilder entry objects.
// iWord[0] = the keyword (file, primary or secondary)
// iWord[1] = the PC pathname
// iWord[2] = the EPOC pathname
// iWord[3] = start of the file attributes
//
	{

	TUint imageFlags = 0;
	TUint overrides = 0;
	TBool isPeFile = ETrue;
	TBool isResource = EFalse;
	TBool isNonXIP = EFalse;
	TUint compression = 0;
	TBool callEntryPoint = EFalse;
	TUint hardwareVariant=KVariantIndependent;
	TBool mustBeInSysBin = EFalse;
	TBool tryForSysBin = EFalse;
 	TBool warnFlag = EFalse;

	// do some validation of the keyword
	TInt currentLine = iReader.CurrentLine();

	switch (aKeyword)
		{
	case EKeywordPrimary:
		imageFlags |= KRomImageFlagPrimary;
		overrides |= KOverrideCodeUnpaged | KOverrideDataUnpaged;
		mustBeInSysBin = gPlatSecEnforceSysBin;
 		warnFlag = gEnableStdPathWarning;		
		hardwareVariant=ParseVariant();
		if (iKernelModel==ESingleKernel && !THardwareVariant(hardwareVariant).IsIndependent())
			{
			Print(EError,"Kernel must be independent in single kernel ROMs\n");
			}
		break;

	case EKeywordSecondary:
		imageFlags |= KRomImageFlagSecondary;
		mustBeInSysBin = gPlatSecEnforceSysBin;
 		warnFlag = gEnableStdPathWarning;
		hardwareVariant=ParseVariant();
		break;

	case EKeywordVariant:
		imageFlags |= KRomImageFlagVariant;
		overrides |= KOverrideCodeUnpaged | KOverrideDataUnpaged;
		mustBeInSysBin = gPlatSecEnforceSysBin;
 		warnFlag = gEnableStdPathWarning;		
		hardwareVariant=ParseVariant();
		break;

	case EKeywordExtension:
		imageFlags |= KRomImageFlagExtension;
		overrides |= KOverrideCodeUnpaged | KOverrideDataUnpaged;
		mustBeInSysBin = gPlatSecEnforceSysBin;
 		warnFlag = gEnableStdPathWarning;
		hardwareVariant=ParseVariant();
		break;

	case EKeywordDevice:
		imageFlags |= KRomImageFlagDevice;
		overrides |= KOverrideCodeUnpaged | KOverrideDataUnpaged;
		mustBeInSysBin = gPlatSecEnforceSysBin;
 		warnFlag = gEnableStdPathWarning;		
		hardwareVariant=ParseVariant();
		break;

	case EKeywordExecutableCompressionMethodBytePair:
		compression=KUidCompressionBytePair;
		
	case EKeywordExecutableCompressionMethodInflate:
	case EKeywordFileCompress:
		compression = compression ? compression : KUidCompressionDeflate;

	case EKeywordExecutableCompressionMethodNone:	
	case EKeywordFileUncompress:
		isNonXIP = ETrue;
	case EKeywordData:
		iNumberOfDataFiles++;
		isPeFile = EFalse;
		isResource = ETrue;
		hardwareVariant=ParseVariant();
		tryForSysBin = gPlatSecEnforceSysBin;
		break;	 

	case EKeywordHardwareConfigRepositoryData:
		if(iNumberOfHCRDataFiles){
			Print(EError,"Multiple keywords '%s' on line %d.\n",iReader.Word(0),currentLine);
			return EFalse ;
		}
		compression = EFalse ; 
		overrides |= KOverrideCodeUnpaged | KOverrideDataUnpaged | KOverrideHCRData;
		warnFlag = gEnableStdPathWarning;	 
		iNumberOfHCRDataFiles ++ ;
		isPeFile = EFalse;
		break;

	case EKeywordDll:
		callEntryPoint = ETrue;
		// and fall through to handling for "file"
	
	case EKeywordFile:
		{
			
		char* nname = NormaliseFileName(iReader.Word(1));
		strupr(nname);
		
		if( gCompressionMethod == 0 || NULL != strstr(nname, ".DLL") || callEntryPoint )
		{
			mustBeInSysBin = gPlatSecEnforceSysBin;
 			warnFlag = gEnableStdPathWarning;			
			hardwareVariant=ParseVariant();
		}
		else 
		{
			compression = gCompressionMethod;
			hardwareVariant=ParseVariant();
			tryForSysBin = gPlatSecEnforceSysBin;
		}
		}
		break;

	default:
		Print(EError,"Unexpected keyword '%s' on line %d.\n",iReader.Word(0),currentLine);
		return EFalse;
		}

	if (isPeFile)
		iNumberOfPeFiles++;

	// check the PC file exists
	char* nname = NormaliseFileName(iReader.Word(1));

#if defined(__MSVCDOTNET__) || defined(__TOOLS2__)
	ifstream test(nname,ios_base::binary );
#else //!__MSVCDOTNET__
	ifstream test(nname,ios::nocreate | ios::binary); 
#endif //__MSVCDOTNET__

	if (!test.is_open())
		{
		Print(EError,"Cannot open file %s for input.\n",iReader.Word(1));
		if(EKeywordHardwareConfigRepositoryData == aKeyword)
			{
			free(nname);
			return EFalse ;
			}
		iMissingFiles++;
		}
		
	if(EKeywordHardwareConfigRepositoryData == aKeyword)
		{ // check hcr file 

		TUint32 magicWord = 0;
		test.read(reinterpret_cast<char*>(&magicWord),sizeof(TUint32));
		if(0x66524348 != magicWord)
			{
			Print(EError,"Invalid hardware configuration repository data file %s .\n",iReader.Word(1));
			test.close();
			free(nname);
			return EFalse;
			}

		}
	test.close();
	free(nname);
 	

 	TBool endOfName=EFalse;
	TText *epocStartPtr=IsValidFilePath(iReader.Text(2));
	if (epocStartPtr==NULL)
		{
		Print(EError, "Invalid destination path on line %d\n",currentLine);
		return EFalse;
		}
	epocStartPtr = (TText*)NormaliseFileName((const char*)epocStartPtr);

	if(tryForSysBin)
		{
		if(strnicmp((const char*)epocStartPtr, "system\\bin\\", 11)==0)
			mustBeInSysBin = 1;
		if(strnicmp((const char*)epocStartPtr, "system\\libs\\", 12)==0)
			mustBeInSysBin = 1;
		if(strnicmp((const char*)epocStartPtr, "system\\programs\\", 16)==0)
			mustBeInSysBin = 1;
		}

	static const char sysBin[] = "sys\\bin\\";
	static const int sysBinLength = sizeof(sysBin)-1;

 	if (strnicmp((const char*)epocStartPtr, sysBin, sysBinLength)!=0)
 	{		
 		if(mustBeInSysBin)
		{
 			TInt len = strlen((char*)epocStartPtr);
 			TInt i = len;
 			while(--i>=0) if(epocStartPtr[i]=='\\') break;
 			++i;
 			char* old = (char*)epocStartPtr;
 			epocStartPtr = (TText*)malloc(sysBinLength+(len-i)+1);
 			strcpy((char*)epocStartPtr,sysBin);
 			strcat((char*)epocStartPtr,old+i);

 			Print(EDiagnostic, "%s moved to %s\n", old, epocStartPtr);
 			delete old;
		}
 		else if (warnFlag)
 		{
 			Print(EWarning, "Outside standard path at %s\n", epocStartPtr);
 		}		
 	}	

	TText *epocEndPtr=epocStartPtr;
	AUTO_FREE(epocStartPtr);	
		
	TRomNode* dir=iRootDirectory;
	TRomNode* subDir=0;
	TRomBuilderEntry *file=0;
	while (!endOfName)
		{
		endOfName = GetNextBitOfFileName(&epocEndPtr);
		if (endOfName) // file
			{
			TRomNode* alreadyExists=dir->FindInDirectory(epocStartPtr,hardwareVariant);
			if (alreadyExists) // duplicate file
				{
				Print(EError, "Duplicate file for %s on line %d\n",iReader.Word(1),iReader.CurrentLine());
				return EFalse;
				}
			file = new TRomBuilderEntry(iReader.Word(1),epocStartPtr);
			file->iRomImageFlags = imageFlags;
			file->iResource = isResource;
			file->iNonXIP = isNonXIP;
			file->iCompression = compression;
			
			file->iArea = iAreaSet.FindByName(AreaSet::KDefaultAreaName);
			file->iRomSectionNumber = iCurrentSectionNumber;
			file->iHardwareVariant = hardwareVariant;
			file->iOverrideFlags |= overrides;
			if (callEntryPoint)
				file->SetCallEntryPoint(callEntryPoint);
			file->iAlignment=aAlign;
			TUint32 uid;
			file->iBareName = SplitFileName((const char*)file->iName, uid, file->iVersionInName, file->iVersionPresentInName);
			assert(uid==0 && !(file->iVersionPresentInName & EUidPresent));
			if (strchr(file->iBareName, '{') || strchr(file->iBareName, '}'))
				{
				Print(EError, "Illegal character in name %s on line %d\n", file->iName, iReader.CurrentLine());
				delete file;
				return EFalse;
				}
			TRomNode* node=new TRomNode(epocStartPtr, file);
			if (node==0){
				delete file;
				return EFalse;
			}
				
			TInt r=ParseFileAttributes(node, file);
			if (r!=KErrNone){
				delete file;
				delete node;
				return EFalse;
			}

			TRACE(TAREA, Print(EScreen, "File %s area '%s'\n", iReader.Word(1), file->iArea->Name()));

			// Apply some specific overrides to the primary
			if (imageFlags & KRomImageFlagPrimary)
				{
				if (file->iCodeAlignment < iPageSize)
					file->iCodeAlignment = iPageSize;	// Kernel code is at least page aligned
				file->iHeapSizeMin = iKernHeapMin;
				file->iHeapSizeMax = iKernHeapMax;
				file->iOverrideFlags |= KOverrideHeapMin+KOverrideHeapMax;
				}

			if (!file->iPatched)
				dir->AddFile(node);	// to ROM directory structure, though possibly hidden
			if (isPeFile)
				TRomNode::AddExecutableFile(iLastExecutable, node);
			
			AddFile(file);
			}		 
		else // directory
			{
			subDir = dir->FindInDirectory(epocStartPtr);
			if (!subDir) // sub directory does not exist
				{
				subDir = dir->NewSubDir(epocStartPtr);
				if (!subDir)
					return EFalse;
				}
			dir=subDir;
			epocStartPtr = epocEndPtr;
			}
		}
	return ETrue;
	}


void CObeyFile::AddFile(TRomBuilderEntry* aFile)
	{
	aFile->iArea->AddFile(aFile);

	*iNextFilePtrPtr = aFile;
	iNextFilePtrPtr = &(aFile->iNext);
	}


TBool CObeyFile::ProcessRenaming(enum EKeyword aKeyword)
	{
	TUint hardwareVariant=ParseVariant();

	// find existing file
	TBool endOfName=EFalse;

	// Store the current name and new name to maintain renamed file map
	String currentName=iReader.Word(1);
	String newName=iReader.Word(2);

	TText *epocStartPtr=IsValidFilePath(iReader.Text(1));
	if (epocStartPtr==NULL)
		{
		Print(EError, "Invalid source path on line %d\n",iReader.CurrentLine());
		return EFalse;
		}
	epocStartPtr = (TText*)NormaliseFileName((const char*)epocStartPtr);
	TText *epocEndPtr=epocStartPtr;
	AUTO_FREE(epocStartPtr);

	char saved_srcname[257];
	strcpy(saved_srcname, iReader.Word(1));

	TRomNode* dir=iRootDirectory;
	TRomNode* existingFile=0;
	while (!endOfName)
		{
		endOfName = GetNextBitOfFileName(&epocEndPtr);
		if (endOfName) // file
			{
			existingFile=dir->FindInDirectory(epocStartPtr,hardwareVariant);
			if (existingFile)
				{
				TInt fileCount=0;
				TInt dirCount=0;
				existingFile->CountDirectory(fileCount, dirCount);
				if (dirCount != 0 || fileCount != 0)
					{
					Print(EError, "Keyword %s not applicable to directories - line %d\n",iReader.Word(0),iReader.CurrentLine());
					return EFalse;
					}
				}
			}
		else // directory
			{
			TRomNode* subDir = dir->FindInDirectory(epocStartPtr);
			if (!subDir) // sub directory does not exist
				break;
			dir=subDir;
			epocStartPtr = epocEndPtr;
			}
		}
	if (aKeyword == EKeywordHide)
		{
		if (!existingFile)
			{
			Print(EWarning, "Hiding non-existent file %s on line %d\n", 
				saved_srcname, iReader.CurrentLine());
			// Just a warning, as we've achieved the right overall effect.
			}
		else
			{
			existingFile->iHidden = ETrue;
			}
		return ETrue;
		}

	if (!existingFile)
		{
		Print(EError, "Can't %s non-existent source file %s on line %d\n",
			iReader.Word(0), saved_srcname, iReader.CurrentLine());
		return EFalse;
		}

	epocStartPtr=IsValidFilePath(iReader.Text(2));
	epocEndPtr=epocStartPtr;
	endOfName=EFalse;
	if (epocStartPtr==NULL)
		{
		Print(EError, "Invalid destination path on line %d\n",iReader.CurrentLine());
		return EFalse;
		}

	TRomNode* newdir=iRootDirectory;
	while (!endOfName)
		{
		endOfName = GetNextBitOfFileName(&epocEndPtr);
		if (endOfName) // file
			{
			TRomNode* alreadyExists=newdir->FindInDirectory(epocStartPtr,existingFile->HardwareVariant());
			if (alreadyExists) // duplicate file
				{
				Print(EError, "Duplicate file for %s on line %d\n",saved_srcname,iReader.CurrentLine());
				return EFalse;
				}
			}
		else // directory
			{
			TRomNode* subDir = newdir->FindInDirectory(epocStartPtr);
			if (!subDir) // sub directory does not exist
				{
				subDir = newdir->NewSubDir(epocStartPtr);
				if (!subDir)
					return EFalse;
				}
			newdir=subDir;
			epocStartPtr = epocEndPtr;
			}
		}

	if (aKeyword == EKeywordRename)
		{
		// rename => remove existingFile and insert into tree at new place
		// has no effect on the iNextExecutable or iNextNodeForSameFile links

		TInt r=ParseFileAttributes(existingFile, existingFile->iRomFile->iRbEntry);
		if (r!=KErrNone)
			return EFalse;
		r = existingFile->Rename(dir, newdir, epocStartPtr);
		if (r==KErrBadName)
			{
			Print(EError, "Bad name %s at line %d\n", epocStartPtr, iReader.CurrentLine());
			return EFalse;
			}
		else if (r==KErrArgument)
			{
			Print(EError, "Version in name %s does not match version in file header at line %d\n", epocStartPtr, iReader.CurrentLine());
			return EFalse;
			}
		// Store the current and new name of file in the renamed file map.
		iPatchData->AddToRenamedFileMap(currentName, newName);
		return ETrue;
		}
	
	// alias => create new TRomNode entry and insert into tree

	TRomNode* node = new TRomNode(epocStartPtr, existingFile);
	if (node == 0)
		{
		Print(EError, "Out of memory\n");
		return EFalse;
		}

	TInt r = node->Alias(existingFile, iLastExecutable);
	if (r==KErrBadName)
		{
		Print(EError, "Bad name %s at line %d\n", epocStartPtr, iReader.CurrentLine());
		return EFalse;
		}
	else if (r==KErrArgument)
		{
		Print(EError, "Version in name %s does not match version in file header at line %d\n", epocStartPtr, iReader.CurrentLine());
		return EFalse;
		}
	r=ParseFileAttributes(node, 0);
	if (r!=KErrNone)
		return EFalse;

	newdir->AddFile(node);	// to ROM directory structure, though possibly hidden

	return ETrue;
	}


TInt ParsePagingPolicy(const char* policy)
	{
	if(stricmp(policy,"NOPAGING")==0)
		return EKernelConfigPagingPolicyNoPaging;
	else if (stricmp(policy,"ALWAYSPAGE")==0)
		return EKernelConfigPagingPolicyAlwaysPage;
	else if(stricmp(policy,"DEFAULTUNPAGED")==0)
		return EKernelConfigPagingPolicyDefaultUnpaged;
	else if(stricmp(policy,"DEFAULTPAGED")==0)
		return EKernelConfigPagingPolicyDefaultPaged;
	return KErrArgument;
	}


TBool CObeyFile::ProcessKeyword(enum EKeyword aKeyword)
	{
	TUint hardwareVariant=KVariantIndependent;

	#ifdef __TOOLS2__
	istringstream val(iReader.Word(1));
	#else
	istrstream val(iReader.Word(1),strlen(iReader.Word(1)));
	#endif

#if defined(__MSVCDOTNET__) || defined (__TOOLS2__)
	val >> setbase(0);
#endif //__MSVCDOTNET__

	TBool success = ETrue;

	switch (aKeyword)
		{
	case EKeywordUnicode:
		Unicode=ETrue;
		break;
	case EKeywordAscii:
		Unicode=EFalse;
		break;

	case EKeywordSingleKernel:
		iKernelModel=ESingleKernel;
		break;
	case EKeywordMultiKernel:
		iKernelModel=EMultipleKernels;
		break;

	case EKeywordBootBinary:
		iReader.CopyWord(1, iBootFileName);
		break;
	case EKeywordRomName:
		iReader.CopyWord(1, iRomFileName);
		break;
	case EKeywordRomNameOdd:
		iReader.CopyWord(1, iRomOddFileName);
		break;
	case EKeywordRomNameEven:
		iReader.CopyWord(1, iRomEvenFileName);
		break;
	case EKeywordSRecordFileName:
		iReader.CopyWord(1, iSRecordFileName);
		break;

	case EKeywordRomLinearBase:
		val >> iRomLinearBase;
		break;
	case EKeywordRomSize:
		val >> iRomSize;
		break;
	case EKeywordRomAlign:
		val >> iRomAlign;
		break;
	case EKeywordKernelDataAddress:
		val >> iKernDataRunAddress;
		break;
	case EKeywordKernelHeapMin:
		val >> iKernHeapMin;
		break;
	case EKeywordKernelHeapMax:
		val >> iKernHeapMax;
		break;
	case EKeywordDataAddress:
		val >> iDataRunAddress;
		break;
	case EKeywordDefaultStackReserve:
		val >> iDefaultStackReserve;
		break;
	case EKeywordVersion:
		val >> iVersion;
		break;
	case EKeywordSRecordBase:
		val >> iSRecordBase;
		break;
	case EKeywordRomChecksum:
		val >> iCheckSum;
		break;
	case EKeywordHardware:
		val >> iHardware;
		break;
	case EKeywordLanguages:
		iReader.ProcessLanguages(iLanguage);
		break;
	case EKeywordTime:
		iReader.ProcessTime(iTime);
		break;
	case EKeywordDllDataTop:
		val >> iDllDataTop;
		break;

	case EKeywordMemModel:
		{
		char* arg1=iReader.Word(1);
		char* arg2=iReader.Word(2);
		char* arg3=iReader.Word(3);
		char* arg4=iReader.Word(4);
		if (strnicmp(arg1, "moving", 6)==0)
			iMemModel=E_MM_Moving;
		else if (strnicmp(arg1, "direct", 6)==0)
			iMemModel=E_MM_Direct;
		else if (strnicmp(arg1, "multiple", 8)==0)
			iMemModel=E_MM_Multiple;
		else if (strnicmp(arg1, "flexible", 8)==0)
			iMemModel=E_MM_Flexible;
		else
			{
			Print(EError, "Unknown memory model specified\n");
			success = EFalse;
			}
		if (strlen(arg2))
			{
			#ifdef __TOOLS2__
			istringstream arg2s(arg2);
			#else
			istrstream arg2s(arg2,strlen(arg2));
			#endif

#if defined(__MSVCDOTNET__) || defined(__TOOLS2__)
			arg2s >> setbase(0);
#endif //__MSVCDOTNET__

			arg2s >> iChunkSize;
			}
		if (iMemModel!=E_MM_Direct && strlen(arg3))
			{
				#ifdef __TOOLS2__
			istringstream arg3s(arg3);
			#else
			istrstream arg3s(arg3,strlen(arg3));
			#endif

#if defined(__MSVCDOTNET__) || defined(__TOOLS2__)
			arg3s >> setbase(0);
#endif //__MSVCDOTNET__

			arg3s >> iPageSize;
			}
		else if (iMemModel==E_MM_Direct)
			iPageSize=iChunkSize;
		if (iMemModel!=E_MM_Direct && strlen(arg4))
			{
			#ifdef __TOOLS2__
			istringstream arg4s(arg4);
			#else
			istrstream arg4s(arg4,strlen(arg4));
			#endif

#if defined(__MSVCDOTNET__) || defined(__TOOLS2__)
			arg4s >> setbase(0);
#endif //__MSVCDOTNET__

			arg4s >> iVirtualAllocSize;
			}
		else
			iVirtualAllocSize = iPageSize;
		
		break;
		}
	case EKeywordNoWrapper:
		if (gHeaderType<0)
			gHeaderType=0;
		break;
	case EKeywordEpocWrapper:
		if (gHeaderType<0)
			gHeaderType=1;
		break;
	case EKeywordCoffWrapper:
		if (gHeaderType<0)
			gHeaderType=2;
		break;

	case EKeywordPlatSecEnforcement:
		ParseBoolArg(gPlatSecEnforcement,iReader.Word(1));
		if(gPlatSecEnforcement)
			iKernelConfigFlags |= EKernelConfigPlatSecEnforcement;
		else
			iKernelConfigFlags &= ~EKernelConfigPlatSecEnforcement;
		break;
	case EKeywordPlatSecDiagnostics:
		ParseBoolArg(gPlatSecDiagnostics,iReader.Word(1));
		if(gPlatSecDiagnostics)
			iKernelConfigFlags |= EKernelConfigPlatSecDiagnostics;
		else
			iKernelConfigFlags &= ~EKernelConfigPlatSecDiagnostics;
		break;
	case EKeywordPlatSecProcessIsolation:
		{
		TInt processIsolation;
		ParseBoolArg(processIsolation,iReader.Word(1));
		if(processIsolation)
			iKernelConfigFlags |= EKernelConfigPlatSecProcessIsolation;
		else
			iKernelConfigFlags &= ~EKernelConfigPlatSecProcessIsolation;
		break;
		}
	case EKeywordPlatSecEnforceSysBin:
		{
		ParseBoolArg(gPlatSecEnforceSysBin,iReader.Word(1));
		if(gPlatSecEnforceSysBin)
			iKernelConfigFlags |= EKernelConfigPlatSecEnforceSysBin;
		else
			iKernelConfigFlags &= ~EKernelConfigPlatSecEnforceSysBin;
		break;
		}
	case EKeywordPlatSecDisabledCaps:
		if(iPlatSecDisabledCapsParsed)
			Print(EWarning, "PlatSecDisabledCaps redefined - previous values lost\n");
		{
		ParseCapabilitiesArg(iPlatSecDisabledCaps, iReader.Word(1));
		gPlatSecDisabledCaps = iPlatSecDisabledCaps;
		iPlatSecDisabledCapsParsed=ETrue;
		}
		break;
	case EKeywordPagingPolicy:
		{
		if(iPagingPolicyParsed)
			Print(EWarning, "PagingPolicy redefined - previous PagingPolicy values lost\n");
		if(iDataPagingPolicyParsed)
			Print(EWarning, "PagingPolicy defined - previous DataPagingPolicy values lost\n");
		if(iCodePagingPolicyParsed)
			Print(EWarning, "PagingPolicy defined - previous DataPagingPolicy values lost\n");
		iPagingPolicyParsed = true;
		iKernelConfigFlags &= ~(EKernelConfigCodePagingPolicyMask|EKernelConfigDataPagingPolicyMask);
		TInt policy = ParsePagingPolicy(iReader.Word(1));
		if(policy<0)
			{
			Print(EError,"Unrecognised option for PAGINGPOLICY keyword\n");
			success = false;
			}
		else 	{
#ifndef SYMBIAN_WRITABLE_DATA_PAGING
			if ((policy != EKernelConfigPagingPolicyNoPaging) && (iMemModel == E_MM_Flexible))
				Print(EWarning, "SYMBIAN_WRITABLE_DATA_PAPING is not defined. Writable data paging is not warranted on this version of Symbian.");
#endif
			iKernelConfigFlags |= policy << EKernelConfigCodePagingPolicyShift;
			iKernelConfigFlags |= policy << EKernelConfigDataPagingPolicyShift;
			}
		}
		break;
	case EKeywordCodePagingPolicy:
		{
		if(iCodePagingPolicyParsed)
			Print(EWarning, "CodePagingPolicy redefined - previous CodePagingPolicy values lost\n");
		if(iPagingPolicyParsed)
			Print(EWarning, "CodePagingPolicy defined - previous PagingPolicy values lost\n");
		iCodePagingPolicyParsed = true;
		iKernelConfigFlags &= ~EKernelConfigCodePagingPolicyMask;
		TInt policy = ParsePagingPolicy(iReader.Word(1));
		if(policy<0)
			{
			Print(EError,"Unrecognised option for CODEPAGINGPOLICY keyword\n");
			success = false;
			}
		else
			iKernelConfigFlags |= policy << EKernelConfigCodePagingPolicyShift;
		}
		break;
	case EKeywordDataPagingPolicy:
		{
		if(iDataPagingPolicyParsed)
			Print(EWarning, "DataPagingPolicy redefined - previous DataPagingPolicy values lost\n");
		if(iPagingPolicyParsed)
			Print(EWarning, "DataPagingPolicy defined - previous PagingPolicy values lost\n");
		iDataPagingPolicyParsed = true;
		iKernelConfigFlags &= ~EKernelConfigDataPagingPolicyMask;
		TInt policy = ParsePagingPolicy(iReader.Word(1));
		if(policy<0)
			{
			Print(EError,"Unrecognised option for DATAPAGINGPOLICY keyword\n");
			success = false;
			}
		else
#ifndef SYMBIAN_WRITABLE_DATA_PAGING
			if ((policy != EKernelConfigPagingPolicyNoPaging) && (iMemModel == E_MM_Flexible))
				Print(EWarning, "SYMBIAN_WRITABLE_DATA_PAPING is not defined. Writable data paging is not warranted on this version of Symbian.");
#endif
			iKernelConfigFlags |= policy << EKernelConfigDataPagingPolicyShift;
		}
		break;
	case EKeywordPagingOverride:
		{
		if(iPagingOverrideParsed)
			Print(EWarning, "PagingOverride redefined - previous PagingOverride values lost\n");
		if(iCodePagingOverrideParsed)
			Print(EWarning, "PagingOverride defined - previous CodePagingOverride valus lost\n");
		if(iDataPagingOverrideParsed)
			Print(EWarning, "PagingOverride defined - previous DataPagingOverride values lostn");
		iPagingOverrideParsed = true;
		TInt policy = ParsePagingPolicy(iReader.Word(1));
		if(policy<0)
			{
			Print(EError,"Unrecognised option for PAGINGOVERRIDE keyword\n");
			success = false;
			}
		else
			{
			gCodePagingOverride = policy;
			gDataPagingOverride = policy;
			}
		}
		break;
	case EKeywordCodePagingOverride:
		{
		if(iCodePagingOverrideParsed)
			Print(EWarning, "CodePagingOverride redefined - previous CodePagingOverride values lost\n");
		if(iPagingOverrideParsed)
			Print(EWarning, "CodePagingOverride defined - previous PagingOverride values lost\n");
		iCodePagingOverrideParsed = true;
		TInt policy = ParsePagingPolicy(iReader.Word(1));
		if(policy<0)
			{
			Print(EError,"Unrecognised option for CODEPAGINGOVERRIDE keyword\n");
			success = false;
			}
		else
			gCodePagingOverride = policy;
		}
		break;
	case EKeywordDataPagingOverride:
		{
		if(iDataPagingOverrideParsed)
			Print(EWarning, "DataPagingOverride redefined - previous DataPagingOverride values lost\n");
		if(iPagingOverrideParsed)
			Print(EWarning, "DataPagingOverride defined - previous PagingOverride values lost\n");
		iDataPagingOverrideParsed = true;
		TInt policy = ParsePagingPolicy(iReader.Word(1));
		if(policy<0)
			{
			Print(EError,"Unrecognised option for DATAPAGINGOVERRIDE keyword\n");
			success = false;
			}
		else
			gDataPagingOverride = policy;
		}
		break;
	case EKeywordDemandPagingConfig:
		{
		memset(&gDemandPagingConfig,0,sizeof(gDemandPagingConfig));
		val >> gDemandPagingConfig.iMinPages;
		if(strlen(iReader.Word(2)))
			{
			#ifdef __TOOLS2__
			istringstream val(iReader.Word(2));
			#else
			istrstream val(iReader.Word(2),strlen(iReader.Word(2)));
		    #endif
			val >> gDemandPagingConfig.iMaxPages;
			if(strlen(iReader.Word(3)))
				{
				#ifdef __TOOLS2__
				istringstream val(iReader.Word(3));
				#else
				istrstream val(iReader.Word(3),strlen(iReader.Word(3)));
				#endif
				val >> gDemandPagingConfig.iYoungOldRatio;
				for(int i=0; i<=2; i++)
					{
					if(!strlen(iReader.Word(4+i)))
						break;
					#ifdef __TOOLS2__
					istringstream val(iReader.Word(4+i));
					#else
					istrstream val(iReader.Word(4+i),strlen(iReader.Word(4+i)));
					#endif
					val >> gDemandPagingConfig.iSpare[i];
					}
				}
			}
		if(gDemandPagingConfig.iMaxPages && gDemandPagingConfig.iMaxPages<gDemandPagingConfig.iMinPages)
			{
			Print(EError,"DemandPagingConfig maxPages must be >= minPages\n");
			success = EFalse;
			break;
			}
		}
		break;
	case EKeywordPagedRom:
		gPagedRom = ETrue;
		break;

	case EKeywordTrace:
		val >> TraceMask;
		break;

	case EKeywordKernelTrace:
		{
		TInt i;
		val >> iTraceMask[0];
		i=1;
		while(strlen(iReader.Word(i+1)) && i<KNumTraceMaskWords)
			{
			#ifdef __TOOLS2__
			istringstream val(iReader.Word(i+1));
			#else
			istrstream val(iReader.Word(i+1),strlen(iReader.Word(i+1)));
			#endif
			#if defined(__MSVCDOTNET__) || defined (__TOOLS2__)
 				val >> setbase(0);
			#endif
			val >> iTraceMask[i];
			++i;
			}
		}
		break;

	case EKeywordBTrace:
		{
		TUint i; 
		val >> iInitialBTraceFilter[0];
		i=1;
		while(strlen(iReader.Word(i+1)) && i<sizeof(iInitialBTraceFilter)/sizeof(TUint32))
			{
			#ifdef __TOOLS2__
			istringstream val(iReader.Word(i+1));
			#else
			istrstream val(iReader.Word(i+1),strlen(iReader.Word(i+1)));
			#endif
			#if defined(__MSVCDOTNET__) || defined (__TOOLS2__)
 				val >> setbase(0);
			#endif
			val >> iInitialBTraceFilter[i];
			++i;
			}
		}
		break;

	case EKeywordBTraceMode:
		val >> iInitialBTraceMode;
		break;

	case EKeywordBTraceBuffer:
		val >> iInitialBTraceBuffer;
		break;

	case EKeywordDebugPort:
		if (iDebugPortParsed)
			Print(EWarning, "DEBUGPORT redefined - previous value lost\n");
		val >> iDebugPort;
		iDebugPortParsed = ETrue;
		break;

	case EKeywordCompress:
		gEnableCompress=ETrue; // Set ROM Compression on.
		break;

	case EKeywordCollapse:
		if (strnicmp(iReader.Word(1), "arm", 3)!=0 || strnicmp(iReader.Word(2), "gcc", 3)!=0)
			{
			Print(EWarning, "COLLAPSE only supported for ARM and GCC - keyword ignored\n");
			}
		else
			{
			TInt cm;
			#ifdef __TOOLS2__
			istringstream cmval(iReader.Word(3));
			#else
			istrstream cmval(iReader.Word(3),strlen(iReader.Word(3)));
			#endif

#if defined(__MSVCDOTNET__) || defined(__TOOLS2__)
			cmval >> setbase(0);
#endif //__MSVCDOTNET__

			cmval>>cm;
			if (cm<0 || cm>ECollapseAllChainBranches)
				{
				Print(EWarning, "COLLAPSE mode unrecognised - keyword ignored\n");
				}
			else
				iCollapseMode=cm;
			}
		break;

	case EKeywordPrimary:
		iNumberOfPrimaries++;
		break;
	case EKeywordVariant:
		hardwareVariant=ParseVariant();
		if (THardwareVariant(hardwareVariant).IsVariant())
			{
			iNumberOfVariants++;
			TUint layer=THardwareVariant(hardwareVariant).Layer();
			TUint vmask=THardwareVariant(hardwareVariant).VMask();
			iAllVariantsMask[layer] |= vmask;
			}
		else
			{
			Print(EError,"Variant DLLs must belong to variant layer - line %d\n", iReader.CurrentLine());
			break;
			}

		break;
	case EKeywordExtension:
		iNumberOfExtensions++;
		break;
	case EKeywordDevice:
		iNumberOfDevices++;
		break;

	case EKeywordKernelRomName:
		Print(EError,"Keyword '%s' only valid in extension ROMs - line %d\n", iReader.Word(0), iReader.CurrentLine());
		break;

	case EKeywordArea:
		if(! ParseAreaKeyword())
			success = EFalse;
		break;

	case EKeywordExecutableCompressionMethodNone:
		gCompressionMethod = 0;
		break;
		
	case EKeywordExecutableCompressionMethodInflate:
		gCompressionMethod = KUidCompressionDeflate;
		break;
		
	case EKeywordExecutableCompressionMethodBytePair:
		gCompressionMethod = KUidCompressionBytePair;
		break;
		
	case EKeywordKernelConfig:
		{
		TInt bit, setTo;
		val >> bit;
		if(bit<0 || bit>31)
			{
			Print(EError,"KernelConfig bit must be between 0 and 31\n");
			success = EFalse;
			break;
			}
		if(ParseBoolArg(setTo,iReader.Word(2))!=KErrNone)
			{
			success = EFalse;
			break;
			}
		if(setTo)
			iKernelConfigFlags |= 1<<bit;
		else
			iKernelConfigFlags &= ~(1<<bit);
		break;
		}
		
	case EKeywordMaxUnpagedMemSize:
		{
		TInt unpagedSize = -1;
		val >> unpagedSize;
			
		if (!val || unpagedSize < 0)
			{
			Print(EWarning, "Invalid value of MaxUnpagedSize (0 to 0x7FFFFFFF) - value ignored\n");
			break;
			}
			
		iMaxUnpagedMemSize = unpagedSize;
		
		if(iUpdatedMaxUnpagedMemSize)
			{
			Print(EWarning, "MaxUnpagedSize redefined - previous values lost\n");
			}
		else
			{
			iUpdatedMaxUnpagedMemSize = ETrue;
			}
		
		break;
		}

	default:
		// unexpected keyword iReader.Word(0)
		break;
		}

	return success;
	}

TBool CObeyFile::GotKeyVariables()
//
// Checks that the obeyfile has supplied enough variables to continue
//
   	{

	TBool retVal=ETrue;

	// Mandatory keywords

	if (iRomFileName==0)
		{
		Print(EAlways,"The name of the ROM has not been supplied.\n");
		Print(EAlways,"Use the keyword \"romname\".\n");
		retVal = EFalse;
		}
	if (iBootFileName==0)
		{
		Print(EAlways,"The name of the bootstrap binary has not been supplied.\n");
		Print(EAlways,"Use the keyword \"bootbinary\".\n");
		retVal = EFalse;
		}
	if (iRomLinearBase==0xFFFFFFFF)
		{
		Print(EAlways,"The base linear address of the ROM has not been supplied.\n");
		Print(EAlways,"Use the keyword \"romlinearbase\".\n");
		retVal = EFalse;
		}
	if (iRomSize==0)
		{
		Print(EAlways,"The size of the ROM has not been supplied.\n");
		Print(EAlways,"Use the keyword \"romsize\".\n");
		retVal = EFalse;
		}
	if (iKernDataRunAddress==0)
		{
		Print(EAlways,"The address for the kernel's data section has not been supplied.\n");
		Print(EAlways,"Use the keyword \"kerneldataaddress\".\n");
		retVal = EFalse;
		}

	// Validation
	if (iNumberOfPrimaries>1 && iKernelModel==ESingleKernel)
		{
		Print(EError,"More than one primary in single-kernel ROM\n");
		retVal = EFalse;
		}
	if (iNumberOfPrimaries==0)
		{
		Print(EError,"No primary file specified\n");
		retVal = EFalse;
		}
	if (iNumberOfVariants==0)
		{
		Print(EError,"No variants specified\n");
		retVal = EFalse;
		}
	if(iNumberOfHCRDataFiles > 1)
		{
		Print(EError,"More than one hcr data files in ROM.\n");
		retVal = EFalse ;
		}
	// Warn about enabling data paging on OS versions where's it's not officially supported
#ifndef SYMBIAN_WRITABLE_DATA_PAGING
	if (iMemModel == E_MM_Flexible &&
		(iKernelConfigFlags & EKernelConfigDataPagingPolicyMask) != EKernelConfigDataPagingPolicyNoPaging)
		{
		Print(EWarning, "Writable data paging is not warranted on this version of Symbian OS.");
		}
#endif
	
	// Apply defaults as necessary
	TheRomLinearAddress=iRomLinearBase;

	if (iDataRunAddress==0)
		{
		iDataRunAddress=0x400000;
		Print(EWarning,"The address for a running ROM app's data section (keyword \"dataaddress\") has not been supplied.\n");
		Print(EWarning,"Will use the default value of 0x%0x.\n", iDataRunAddress);
		retVal = EFalse;
		}
	if (iRomAlign==0)
		{
		iRomAlign=0x1000;
		Print(EWarning,"The ROM section alignment (keyword \"romalign\") has not been supplied.\n");
		Print(EWarning,"Will use the default value of 0x%0x.\n", iRomAlign);
		}
	if (iRomAlign&0x3)
		{
		Print(EWarning, "Rounding rom alignment to multiple of 4.\n");
		iRomAlign=(iRomAlign+0x3)&0xfffffffc;
		}
	if (iKernHeapMin==0)
	 	{
	 	iKernHeapMin=0x10000;
		Print(EWarning,"The kernel heap min size (keyword \"kernelheapmin\") has not been supplied.\n");
		Print(EWarning,"Will use the default value of 0x%0x.\n", iKernHeapMin);
		}
	if (iKernHeapMax==0)
	 	{
	 	iKernHeapMax=0x100000;
		Print(EWarning,"The kernel heap max size (keyword \"kernelheapmax\") has not been supplied.\n");
		Print(EWarning,"Will use the default value of 0x%0x.\n", iKernHeapMax);
		}

	if (iTime==0)
		{
		Print(ELog, "No timestamp specified. Using current time...\n");
		ObeyFileReader::TimeNow(iTime);
		}

	Print(ELog, "\nCreating Rom image %s\n", iRomFileName);
	Print(ELog, "MemModel: %1d\nChunkSize: %08x\nPageSize: %08x\n", iMemModel, iChunkSize, iPageSize);
	return retVal;
	}


TText *CObeyFile::IsValidFilePath(TText *aPath)
//
// Check the path is valid
//
	{
	// skip leading "\"
	if (*aPath=='\\')
		aPath++;
	if (*aPath==0)
		return NULL; // file ends in a backslash

	TText *p=aPath;
	TInt len=0;
	FOREVER
		{
		if (*p==0)
			return (len ? aPath : NULL);
		if (*p=='\\')
			{
			if (len==0)
				return NULL;
			len=0;
			}
		len++;
		p++;
		}
	}

TBool CObeyFile::GetNextBitOfFileName(TText **epocEndPtr)
//
// Move the end pointer past the next directory separator, replacing it with 0
//
	{
	while (**epocEndPtr != '\\') // until reach the directory separator
		{
		if (**epocEndPtr==0) // if reach end of string, return TRUE, it's the filename
			return ETrue;
		(*epocEndPtr)++;
		}
	**epocEndPtr=0; // overwrite the directory separator with a 0
	(*epocEndPtr)++; // point past the 0 ready for the next one
	return EFalse;
	}


TBool CObeyFile::CheckHardwareVariants()
	{
	iPrimaries=new TRomBuilderEntry*[iNumberOfPrimaries];
	iVariants=new TRomBuilderEntry*[iNumberOfVariants];
	THardwareVariant* primaryHwVariants=new THardwareVariant[iNumberOfPrimaries];
	TInt nVar=0;
	TRomBuilderEntry* current=FirstFile();
	THardwareVariant* variantHwVariants=new THardwareVariant[iNumberOfVariants];
	while(current)
		{
		if (current->Variant())
			{
			TInt i;
			for(i=0; i<nVar; i++)
				{
				if (!current->iHardwareVariant.MutuallyExclusive(variantHwVariants[i]))
					{
					delete[] variantHwVariants;
					delete[] primaryHwVariants;
					Print(EError,"Variants not mutually exclusive\n");
					return EFalse;
					}
				}
			iVariants[nVar]=current;
			variantHwVariants[nVar++]=current->iHardwareVariant;
			}
		current=NextFile();
		}
	delete[] variantHwVariants;
	nVar=0;
	current=FirstFile();
	while(current)
		{
		TInt i;
		for (i=0; i<iNumberOfVariants; i++)
			{
			if (iVariants[i]->iHardwareVariant<=current->iHardwareVariant)
				break;
			}
		if (i==iNumberOfVariants)
			{
			Print(EError,"File %s[%08x] does not correspond to any variant\n",
									current->iName,TUint(current->iHardwareVariant));
			delete[] primaryHwVariants;
			return EFalse;
			}
		if (current->Primary())
			{
			for(i=0; i<nVar; i++)
				{
				if (!current->iHardwareVariant.MutuallyExclusive(primaryHwVariants[i]))
					{
					delete[] primaryHwVariants;
					Print(EError,"Primaries not mutually exclusive\n");
					return EFalse;
					}
				}
			iPrimaries[nVar]=current;
			primaryHwVariants[nVar++]=current->iHardwareVariant;
			}
		current=NextFile();
		}
	delete[] primaryHwVariants;
	if (iNumberOfExtensions)
		{
		nVar=0;
		iExtensions=new TRomBuilderEntry*[iNumberOfExtensions];
		TRomBuilderEntry* current=FirstFile();
		while(current)
			{
			if (current->Extension())
				{
				if (current->iHardwareVariant.IsVariant())
					{
					TUint layer=current->iHardwareVariant.Layer();
					TUint vmask=current->iHardwareVariant.VMask();
					if ((iAllVariantsMask[layer]&vmask)==0)
						{
						Print(EError,"Variant-layer extension %s has no corresponding variant DLL\n",current->iName);
						return EFalse;
						}
					}
				iExtensions[nVar++]=current;
				}
			current=NextFile();
			}
		}
	if (iNumberOfDevices)
		{
		nVar=0;
		iDevices=new TRomBuilderEntry*[iNumberOfDevices];
		TRomBuilderEntry* current=FirstFile();
		while(current)
			{
			if (current->Device())
				{
				if (current->iHardwareVariant.IsVariant())
					{
					TUint layer=current->iHardwareVariant.Layer();
					TUint vmask=current->iHardwareVariant.VMask();
					if ((iAllVariantsMask[layer]&vmask)==0)
						{
						Print(EError,"Variant-layer device %s has no corresponding variant DLL\n",current->iName);
						return EFalse;
						}
					}
				iDevices[nVar++]=current;
				}
			current=NextFile();
			}
		}
	NumberOfVariants=iNumberOfVariants;
	return ETrue;
	}


TInt CObeyFile::ProcessExtensionRom(MRomImage*& aKernelRom)
	{
	//
	// First pass through the obey file to set up key variables
	//

	iReader.Rewind();

	enum EKeyword keyword;

	// Deal with the "extensionrom" keyword, which should be first
	
	if (iReader.NextLine(1,keyword) != KErrNone)
		return KErrEof;
	if (keyword != EKeywordExtensionRom)
		return Print(EError, "Unexpected keyword '%s' at start of extension rom - line %d\n",
			iReader.Word(0), iReader.CurrentLine());
	
	iReader.CopyWord(1, iRomFileName);
	Print(ELog, "\n========================================================\n");
	Print(ELog, "Extension ROM %s starting at line %d\n\n", iRomFileName, iReader.CurrentLine());

	iReader.MarkNext();		// so that we rewind to the line after the extensionrom keyword

	while (iReader.NextLine(1,keyword) != KErrEof)
		{
		if (keyword == EKeywordExtensionRom)
			break;
		ProcessExtensionKeyword(keyword);
		}

	if (!GotExtensionVariables(aKernelRom))
		return KErrGeneral;

	if (! CreateDefaultArea())
		return KErrGeneral;

	//
	// second pass to process the file specifications in the obey file building
	// up the TRomNode directory structure and the TRomBuilderEntry list
	//
	iReader.Rewind();

	if (aKernelRom==0)
		return Print(EError, "Option to extend a kernel ROM image not yet implemented\n");
	iLastExecutable = 0;
	iRootDirectory = aKernelRom->CopyDirectory(iLastExecutable);


	TInt align=0;
	while (iReader.NextLine(2,keyword)!=KErrEof)
		{
		if (keyword == EKeywordExtensionRom)
			break;

		switch (keyword)
			{
		case EKeywordSection:
		case EKeywordArea:
		case EKeywordPrimary:
		case EKeywordSecondary:
		case EKeywordExtension:
		case EKeywordDevice:
		case EKeywordVariant:
		case EKeywordHardwareConfigRepositoryData:
			Print(EError, "Keyword '%s' not supported in extension ROMs - line %d\n",
				iReader.Word(0), iReader.CurrentLine());
			break;

		case EKeywordAlign:
			if (iReader.ProcessAlign(align)!=KErrNone)
				return KErrGeneral;
			break;

		case EKeywordHide:
		case EKeywordAlias:
		case EKeywordRename:
			if (!ProcessRenaming(keyword))
				return KErrGeneral;
			break;
		case EKeywordPatchDllData:
		{
			// Collect patchdata statements to process at the end
			StringVector patchDataTokens;
			SplitPatchDataStatement(patchDataTokens); 
			iPatchData->AddPatchDataStatement(patchDataTokens);										
			break;
		}

		default:
			if (!ProcessFile(align, keyword))
				return KErrGeneral;
			align=0;
			break;
			}
		}

	if( !ParsePatchDllData())
		return KErrGeneral;

	iReader.Mark();			// ready for processing the next extension rom(s)

	if (iMissingFiles!=0)
		return KErrGeneral;
	if (iNumberOfDataFiles+iNumberOfPeFiles==0)
		{
		Print(EError, "No files specified.\n");
		return KErrGeneral;
		}
	return KErrNone;
	}

void CObeyFile::ProcessExtensionKeyword(enum EKeyword aKeyword)
	{
	#ifdef __TOOLS2__
	istringstream val(iReader.Word(1));
	#else
	istrstream val(iReader.Word(1),strlen(iReader.Word(1)));
	#endif
	

#if defined(__MSVCDOTNET__) || defined(__TOOLS2__)
	val >> setbase(0);
#endif //__MSVCDOTNET__

	switch (aKeyword)
		{
	case EKeywordKernelRomName:
		iReader.CopyWord(1, iKernelRomName);
		return;
	case EKeywordRomNameOdd:
		iReader.CopyWord(1, iRomOddFileName);
		return;
	case EKeywordRomNameEven:
		iReader.CopyWord(1, iRomEvenFileName);
		return;
	case EKeywordSRecordFileName:
		iReader.CopyWord(1, iSRecordFileName);
		return;

	case EKeywordRomLinearBase:
		val >> iRomLinearBase;
		return;
	case EKeywordRomSize:
		val >> iRomSize;
		return;
	case EKeywordRomAlign:
		val >> iRomAlign;
		return;

	case EKeywordDataAddress:
		val >> iDataRunAddress;
		return;
	case EKeywordDefaultStackReserve:
		val >> iDefaultStackReserve;
		return;
	case EKeywordVersion:
		val >> iVersion;
		return;
	case EKeywordSRecordBase:
		val >> iSRecordBase;
		return;
	case EKeywordRomChecksum:
		val >> iCheckSum;
		return;
	case EKeywordTime:
		iReader.ProcessTime(iTime);
		return;

	case EKeywordTrace:
		val >> TraceMask;
		return;

	case EKeywordCollapse:
		if (strnicmp(iReader.Word(1), "arm", 3)!=0 || strnicmp(iReader.Word(2), "gcc", 3)!=0)
			{
			Print(EWarning, "COLLAPSE only supported for ARM and GCC - keyword ignored\n");
			}
		else
			{
			TInt cm;
			#ifdef __TOOLS2__
			istringstream cmval(iReader.Word(3));
			#else
			istrstream cmval(iReader.Word(3),strlen(iReader.Word(3)));
			#endif

#if defined(__MSVCDOTNET__) || defined(__TOOLS2__)
			cmval >> setbase(0);
#endif //__MSVCDOTNET__

			cmval>>cm;
			if (cm<0 || cm>ECollapseAllChainBranches)
				{
				Print(EWarning, "COLLAPSE mode unrecognised - keyword ignored\n");
				}
			else
				{
				Print(EWarning, "COLLAPSE not currently supported for extension roms\n");
				}
			}
		return;

	case EKeywordCoreImage:
		//Already handled, skip it
		return;

	default:
		Print(EError,"Keyword '%s' not valid in extension ROMs - line %d\n", iReader.Word(0), iReader.CurrentLine());
		break;
		}
	return;
	}

TBool CObeyFile::GotExtensionVariables(MRomImage*& aRom)
//
// Checks that the obeyfile has supplied enough variables to continue
//
   	{

	TBool retVal=ETrue;
	TText* kernelRomName = iKernelRomName;

	// Mandatory keywords

	if (iRomSize==0)
		{
		Print(EAlways,"The size of the extension ROM has not been supplied.\n");
		Print(EAlways,"Use the keyword \"romsize\".\n");
		retVal = EFalse;
		}

	// keywords we need if we don't already have a ROM image to work from

	if (aRom==0)
		{
		if (iKernelRomName==0)
			{
			Print(EAlways,"The name of the kernel ROM has not been supplied.\n");
			Print(EAlways,"Use the keyword \"kernelromname\".\n");
			retVal = EFalse;
			}
		if (iRomLinearBase==0xFFFFFFFF)
			{
			Print(EAlways,"The base linear address of the ROM has not been supplied.\n");
			Print(EAlways,"Use the keyword \"romlinearbase\".\n");
			retVal = EFalse;
			}
		}
	else
		{
		if (iKernelRomName != 0)
			{
			Print(EWarning,"Keyword \"kernelromname\") ignored.\n");
			}
		kernelRomName = aRom->RomFileName();
		}

	// validation

	// Apply defaults as necessary

	if (iRomLinearBase==0xFFFFFFFF && aRom!=0)
		{
		iRomLinearBase = aRom->RomBase() + aRom->RomSize();
		Print(ELog,"Assuming extension ROM is contiguous with kernel ROM\n");
		Print(ELog,"Setting romlinearbase to 0x%08x\n", iRomLinearBase);
		}
	TheRomLinearAddress=iRomLinearBase;

	if (iDataRunAddress==0)
		{
		iDataRunAddress= aRom->DataRunAddress();
		Print(EWarning,"The address for a running ROM app's data section (keyword \"dataaddress\") has not been supplied.\n");
		Print(EWarning,"Will use the default value of 0x%0x.\n", iDataRunAddress);
		}
	if (iRomAlign==0)
		{
		iRomAlign = aRom->RomAlign();
		Print(EWarning,"The ROM section alignment (keyword \"romalign\") has not been supplied.\n");
		Print(EWarning,"Will use the default value of 0x%0x.\n", iRomAlign);
		}
	if (iRomAlign&0x3)
		{
		Print(EWarning, "Rounding rom alignment to multiple of 4.\n");
		iRomAlign=(iRomAlign+0x3)&0xfffffffc;
		}
	if (iTime==0)
		{
		Print(ELog, "No timestamp specified. Using current time...\n");
		ObeyFileReader::TimeNow(iTime);
		}

	// fix up "*" in romname
	TText newname[256];
	TText* p=newname;
	TText* q=iRomFileName;
	TText c;

	while ((c=*q++)!='\0')
		{
		if (c!='*')
			{
			*p++=c;
			continue;
			}
		TText *r=kernelRomName;
		while ((c=*r++)!='\0')
			*p++=c;
		}
	*p = '\0';
	free(iRomFileName);
	iRomFileName = (TText*)strdup((char*)newname);

	Print(ELog, "\nCreating Rom image %s\n", iRomFileName);
	return retVal;
	}


////////////////////////////////////////////////////////////////////////
// AREA RELATED CODE
////////////////////////////////////////////////////////////////////////

/**
 Process an area declaration.
 */

TBool CObeyFile::ParseAreaKeyword()
	{
	const char* name = iReader.Word(1);
	TLinAddr start;
	TUint length;
	if(Val(start, iReader.Word(2)) != KErrNone || Val(length, iReader.Word(3)) != KErrNone)
		{
		Print(EError, "Line %d: Wrong area specification: Should be <name> <start address> <length>\n",
			  iReader.CurrentLine());
		return EFalse;
		}

	if (! AddAreaAndHandleError(name, start, length, iReader.CurrentLine()))
		return EFalse;

	return ETrue;
	}


/**
 Process an "area=xxx" file attribute.
 */

TBool CObeyFile::ParseAreaAttribute(const TText* aArg, TInt aLineNumber, const Area*& aArea)
	{
	if (iSectionPosition != -1)
		{
		Print(EError, "Line %d: Relocation to area forbidden in second section\n", aLineNumber);
		return EFalse;
		}

	aArea = iAreaSet.FindByName(reinterpret_cast<const char*>(aArg));
	if (aArea == 0)
		{
		Print(EError, "Line %d: Attempt to use an unknown area named '%s'\n", aLineNumber, aArg);
		return EFalse;
		}

	return ETrue;
	}


TBool CObeyFile::CreateDefaultArea()
	{
	return AddAreaAndHandleError(AreaSet::KDefaultAreaName, iRomLinearBase, iRomSize);
	}


TBool CObeyFile::AddAreaAndHandleError(const char* aName, TLinAddr aDestBaseAddr, TUint aLength, TInt aLineNumber)
	{
	TBool added = EFalse;
	
	const char lineInfoFmt[] = "Line %d:";
	char lineInfo[sizeof(lineInfoFmt)+10];
	if (aLineNumber > 0)
		sprintf(lineInfo, lineInfoFmt, aLineNumber);
	else
		lineInfo[0] = '\0';

	const char* overlappingArea;
	switch (iAreaSet.AddArea(aName, aDestBaseAddr, aLength, overlappingArea))
		{
	case AreaSet::EAdded:
		TRACE(TAREA, Print(EScreen, "Area '%s' added to AreaSet\n", aName));
		added = ETrue;
		break;
	case AreaSet::EOverlap:
		Print(EError, "%s Area '%s' collides with area '%s'\n", lineInfo, aName, overlappingArea);
		break;
	case AreaSet::EDuplicateName:
		Print(EError, "%s Name '%s' already reserved for another area\n", lineInfo, aName);
		break;
	case AreaSet::EOverflow:
		Print(EError, "%s Area overflow (0x%X+0x%X > 0x%X)\n", lineInfo, aDestBaseAddr, aLength, -1);
		break;
	default:
		assert(0);				// can't happen
		}

	return added;
	}

TInt getNumber(TText*);


// Fuction to split patchdata statement 
void CObeyFile::SplitPatchDataStatement(StringVector& aPatchDataTokens)
{
	// Get the value of symbol size, address/ordinal and new value 
	// to be patched from the patchdata statement.
	// Syntax of patchdata statements is as follows:
	// 1)	patchdata dll_name  ordinal OrdinalNumber size_in_bytes   new_value 
	// 2)   patchdata dll_name  addr    Address       size_in_bytes   new_value
	for(TInt count=1; count<=5; count++)	
	{
		aPatchDataTokens.push_back(iReader.Word(count));
	}

	// Store the the value of current line which will be used
	// when displaying error messages.
	OutputStringStream outStrStream;
	outStrStream << iReader.CurrentLine();
    aPatchDataTokens.push_back(outStrStream.str());	
}

TBool CObeyFile::ParsePatchDllData()
{
	// Get the list of patchdata statements
	VectorOfStringVector patchDataStatements=iPatchData->GetPatchDataStatements();
	// Get the list of renamed file map
	MapOfString RenamedFileMap=iPatchData->GetRenamedFileMap();
	DllDataEntry *aDllDataEntry=NULL;

	for(TUint count=0; count<patchDataStatements.size(); count++)
	{
		StringVector strVector = patchDataStatements.at(count);
		String filename=strVector.at(0);
		String lineNoStr = strVector.at(5);
		TUint lineNo=getNumber(((TText*)lineNoStr.c_str()));
		TRomNode* existingFile = NULL;
			
		do
		{			
			TUint hardwareVariant=ParseVariant();
			TRomNode* dir=iRootDirectory;		
			TBool endOfName=EFalse;

			TText *epocStartPtr=IsValidFilePath((TText*)filename.c_str());
			if (epocStartPtr==NULL)
			{
				Print(EError, "Invalid source path on line %d\n",lineNo);
				return EFalse;
			}
			epocStartPtr = (TText*)NormaliseFileName((const char*)epocStartPtr);
			TText *epocEndPtr=epocStartPtr;

			while (!endOfName)
			{
				endOfName = GetNextBitOfFileName(&epocEndPtr);
				if (endOfName) // file
				{
					existingFile=dir->FindInDirectory(epocStartPtr,hardwareVariant,TRUE);
					if (existingFile)
					{
						TInt fileCount=0;
						TInt dirCount=0;
						existingFile->CountDirectory(fileCount, dirCount);
						if (dirCount != 0 || fileCount != 0)
						{
							Print(EError, "Keyword %s not applicable to directories - line %d\n","patchdata",lineNo);
							return EFalse;
						}
					}
				}
				else // directory
				{
					TRomNode* subDir = dir->FindInDirectory(epocStartPtr);
					if (!subDir) // sub directory does not exist
						break;
					dir=subDir;
					epocStartPtr = epocEndPtr;
				}
			}

			if( !existingFile )
			{
				MapOfStringIterator RenamedFileMapIterator;

				// If the E32Image file to be patched is not included then check if the
				// file was renamed.
				if ((RenamedFileMapIterator=RenamedFileMap.find(filename)) != RenamedFileMap.end())
					filename = (*RenamedFileMapIterator).second; 
				else
				{
					Print(EError, "File %s not found - line %d\n", filename.c_str(), lineNo);
					return EFalse;
				}
			}
		}while(!existingFile);

		TUint32 aSize, aOrdinal, aNewValue, aOffset;
		TLinAddr aDataAddr;

		aOrdinal = (TUint32)-1;
		aDataAddr = (TUint32)-1;
		aOffset = 0;

		String symbolSize = strVector.at(3);
		aSize = getNumber((TText*)symbolSize.c_str());
		String aValue = strVector.at(4);
		aNewValue = getNumber( (TText*)aValue.c_str());

		DllDataEntry *dataEntry = new DllDataEntry(aSize, aNewValue);

		// Set the address of the data or the ordinal number specified in OBY statement.
		String keyword = strVector.at(1);
		String keywordValue = strVector.at(2);

		/* Check for +OFFSET at the end of the ordinal number or address */
		TUint plus = keywordValue.find("+",0);
		if (plus != std::string::npos)
		{
			/* Get the offset that we found after the + sign */
			String offset = keywordValue.substr(plus+1);
			aOffset = getNumber((TText*)offset.c_str());

			keywordValue.resize(plus);		
		}
		if(stricmp ((char*)keyword.c_str(), "addr") == 0)
			aDataAddr = getNumber((TText*)keywordValue.c_str());
		
		else 
			 aOrdinal = getNumber((TText*)keywordValue.c_str());
		
		dataEntry->iDataAddress = aDataAddr;
		dataEntry->iOrdinal = aOrdinal;
		dataEntry->iOffset = aOffset;
		dataEntry->iRomNode = existingFile;

		if (aDllDataEntry==NULL)
		{
			// Set the first node of the patchdata linked list
			aDllDataEntry = dataEntry;
			SetFirstDllDataEntry(aDllDataEntry);
		}
		else
		{
			// Add the new node at the end of linked list
			aDllDataEntry->AddDllDataEntry(dataEntry);
			aDllDataEntry = aDllDataEntry->NextDllDataEntry();
		}
	}
	return ETrue;
}

int CObeyFile::SkipToExtension()
{
	int found = 0;

	iReader.Rewind();
	enum EKeyword keyword;
	while (iReader.NextLine(1,keyword) != KErrEof)
	{
		if (keyword == EKeywordExtensionRom)
		{
			found = 1;
			iReader.Mark(); // ready for processing extension
			break;
		}
	}

	if(!found)
	{
		Print(EError, "Coreimage option requires valid \"extensionrom\" keyword\n");
	}

	return found;
}

TText* CObeyFile::ProcessCoreImage()
{
	// check for coreimage keyword and return filename
	iReader.Rewind();
	enum EKeyword keyword;
	TText* coreImageFileName = 0;

	iRomAlign = KDefaultRomAlign;
	iDataRunAddress = KDefaultDataRunAddress;

	while (iReader.NextLine(1,keyword) != KErrEof)
	{
		if (keyword == EKeywordCoreImage)
		{
#if defined(__TOOLS2__) && defined (_STLP_THREADS)
			istringstream val(iReader.Word(1),(ios_base::in+ios_base::out));	  
#elif __TOOLS2__
			istringstream val(iReader.Word(1),(std::_Ios_Openmode)(ios_base::in+ios_base::out));
#else
			istrstream val(iReader.Word(1),strlen(iReader.Word(1)));
#endif
			iReader.CopyWord(1, coreImageFileName);
			break;
		}
		else if ((keyword == EKeywordRomAlign) || (keyword == EKeywordDataAddress))
		{
#ifdef __TOOLS2__
			istringstream val(iReader.Word(1));
#else
			istrstream val(iReader.Word(1),strlen(iReader.Word(1)));
#endif
#if defined(__MSVCDOTNET__) || defined(__TOOLS2__)
	val >> setbase(0);
#endif //__MSVCDOTNET__
			if(keyword == EKeywordRomAlign)
			{
				val >> iRomAlign;
			}
			else
			{
				val >> iDataRunAddress;
			}
		}
	}

	if (iRomAlign&0x3)
	{
		//Rounding rom alignment to multiple of 4
		iRomAlign=(iRomAlign+0x3)&0xfffffffc;
	}

	return coreImageFileName;
}

