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
* Rofsbuild Obey file class and its reader class.
*
*/
 
#include <strstream>
#include <iomanip>
 
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <assert.h>
#include <errno.h>

#include <e32std.h>
#include <e32std_private.h>
#include <e32rom.h>
#include <u32std.h>
#include <f32file.h>

#include "h_utl.h"
#include "r_obey.h"
#include "r_coreimage.h"
#include "patchdataprocessor.h"
#include "fatimagegenerator.h" 
#include "r_driveimage.h"

extern TInt gCodePagingOverride;
extern TInt gDataPagingOverride;
extern ECompression gCompress;
extern TBool gEnableStdPathWarning; // Default to not warn if destination path provided for a file is not in standard path.
extern TBool gKeepGoing;


#define _P(word)	word, sizeof(word)-1	// match prefix, optionally followed by [HWVD]
#define _K(word)	word, 0					// match whole word
static char* const NullString = "" ;
const ObeyFileKeyword ObeyFileReader::iKeywords[] =
{
	{_K("file"),		2,-2, EKeywordFile, "File to be copied into ROFS"},
	{_K("data"),		2,-2, EKeywordData, "same as file"},
	{_K("dir"),         2,1, EKeywordDir, "Directory to be created into FAT image"},

	{_K("rofsname"),	1, 1, EKeywordRofsName, "output file for ROFS image"},
	{_K("romsize"),		1, 1, EKeywordRomSize, "size of ROM image"}, 
	{_P("hide"),	    2, -1, EKeywordHide, "Exclude named file from ROM directory structure"},
	{_P("alias"),	    2, -2, EKeywordAlias, "Create alias for existing file in ROM directory structure"},
	{_P("rename"),	    2, -2, EKeywordRename, "Change the name of a file in the ROM directory structure"},
	{_K("rofssize"),		1, 1, EKeywordRofsSize, "maximum size of ROFS image"},
	{_K("romchecksum"),	1, 1, EKeywordRofsChecksum, "desired 32-bit checksum value for the whole image"},
	{_K("version"),		1, 1, EKeywordVersion, "ROFS image version number"},
	{_K("time"),	    1,-1, EKeywordTime, "ROFS image timestamp"},
	{_K("extensionrofs"),1+2, 1, EKeywordExtensionRofs, "Start of definition of optional Extension ROFS"},
	{_K("extensionrofsname"),1, 1, EKeywordCoreRofsName, "ROFS image on which extension ROFS is based"},
	{_K("rem"),			0, 0, EKeywordNone, "comment"},
	{_K("stop"),		0, 0, EKeywordNone, "Terminates OBEY file prematurely"},
	{_K("romchecksum"),	1, 1, EKeywordRomChecksum, "desired 32-bit checksum value for the whole ROFS image"},
	{_K("coreimage"),	1, 1, EKeywordCoreImage, "Core image to be used for extension directory structure"},
	{_K("autosize"),	1, 1, EKeywordRofsAutoSize, "Automatically adjust maximum image size to actual used"},
	{_K("pagingoverride"),	1, 1, EKeywordPagingOverride, "Overide the demand paging attributes for every file in ROM, NOPAGING|DEFAULTUNPAGED|DEFAULTPAGED"},
	{_K("codepagingoverride"),	1, 1, EKeywordCodePagingOverride, "Overide the code paging attributes for every file in ROM, NOPAGING|DEFAULTUNPAGED|DEFAULTPAGED"},
	{_K("datapagingoverride"),	1, 1, EKeywordDataPagingOverride, "Overide the data paging attributes for every file in ROM, NOPAGING|DEFAULTUNPAGED|DEFAULTPAGED"},
	{_K("dataimagename"),1, 1,EKeywordDataImageName, "Data Drive image file name"},
	{_K("dataimagefilesystem"),1, 1,EKeywordDataImageFileSystem, "Drive image file system format"},
	{_K("dataimagesize"),1, 1,EKeywordDataImageSize, "Maximum size of Data Drive image"},
	{_K("volume"),1, -1,EKeywordDataImageVolume, "Volume Label of Data Drive image"},
	{_K("sectorsize"),1, 1,EKeywordDataImageSectorSize, "Sector size(in bytes) of Data Drive image"},
	{_K("fattable"),1, 1,EKeywordDataImageNoOfFats, "Number of FATs in the Data Drive image"},
	// things we don't normally report in the help information
	{_K("trace"),		1, 1, EKeywordTrace, "(ROMBUILD activity trace flags)"},
	{_K("filecompress"),2, -2,EKeywordFileCompress,"Non-XIP Executable to be loaded into the ROM compressed" },
	{_K("fileuncompress"),2, -2,EKeywordFileUncompress,"Non-XIP Executable to be loaded into the ROM uncompressed" },
	{_K("patchdata"),2, 5,EKeywordPatchDllData, "Patch exported data"},
	{_K("imagename"), 1, 1, EKeywordSmrImageName, "output file for SMR image"},
	{_K("hcrdata"), 1, 1, EKeywordSmrFileData, "file data for HCR SMR image"},
	{_K("formatversion"), 1, 1, EKeywordSmrFormatVersion, "format version for HCR SMR image"},
	{_K("payloadflags"), 1, 1, EKeywordSmrFlags, "payload flags for the HCR SMR image"},
	{_K("payloaduid"), 1, 1, EKeywordSmrUID, "payload UID for the HCR SMR image"},
	{0,0,0,0,EKeywordNone,""}
};

void ObeyFileReader::KeywordHelp() { // static

	cout << "Obey file keywords:\n";

	const ObeyFileKeyword* k=0;
	for (k=iKeywords; k->iKeyword!=0; k++)
	{
		if (k->iHelpText == 0)
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
		if (f->iHelpText == 0)
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

ObeyFileReader::ObeyFileReader(const char* aFileName):iCurrentLine(0),
iFileName(aFileName),iNumWords(0),iLine(0),iMarkLine(0),iCurrentObeyStatement(0)	{  
	for(TUint i = 0 ; i < KNumWords ; i++)
		iWord[i] = NullString;
	*iSuffix = 0 ; 
}

ObeyFileReader::~ObeyFileReader() {	  
	if(iCurrentObeyStatement) {
		delete []iCurrentObeyStatement;
		iCurrentObeyStatement = 0 ;
	}
	if(iLine) {
		delete []iLine; 
		iLine = 0 ;
	}
}

//
// Open the file & return a status
//
TBool ObeyFileReader::Open() {     
	ifstream ifs(iFileName.c_str(),ios_base::in + ios_base::binary);
	if (!ifs.is_open()) {
		Print(EError,"Cannot open obey file %s\n",iFileName.c_str());
		return EFalse;
	}
	iLines.clear();
	if(iLine){
		delete []iLine;
		iLine = 0 ;
	}		
	ifs.seekg(0,ios_base::end);
	size_t length = ifs.tellg();
	char* buffer = new char[length + 2];
	if (0 == buffer) {
		Print(EError,"Insufficent Memory to Continue.");	
		ifs.close();
		return EFalse;
	}
	ifs.seekg(0,ios_base::beg);
	ifs.read(buffer,length);
	size_t readcout = ifs.gcount() ;
	if(readcout != length){ 	
		Print(EError,"Cannot Read All of File.");	
		delete []buffer ;
		ifs.close();
		return EFalse;
	}
	buffer[length] = '\n';
	buffer[length + 1] = 0 ;
	ifs.close();
	char* lineStart = buffer ;
	char* end = buffer + length ;
	string line ;
	size_t maxLengthOfLine = 0 ;
	while(lineStart < end){
		while(*lineStart == ' ' || *lineStart == '\t') //trimleft 
			lineStart ++ ;		
		char* lineEnd = lineStart ;	 
		while(*lineEnd != '\r' && *lineEnd != '\n')
			lineEnd ++ ;
		if(strnicmp(lineStart,"REM",3) == 0){
			line = "" ; // REMOVE "REM ... "
		}
		else {
			TInt lastIndex = lineEnd - lineStart - 1;
			while(lastIndex >= 0 &&  // trimright
				(lineStart[lastIndex] == ' ' || lineStart[lastIndex] == '\t'))
				lastIndex -- ;			
			if(lastIndex >= 0)
				line.assign(lineStart,lastIndex + 1);
			else
				line = "";
		}
		if(line.length() > maxLengthOfLine)
			maxLengthOfLine = line.length();
		iLines.push_back(line);
		if(*lineEnd == '\r') {
			if(lineEnd[1] == '\n')
				lineStart = lineEnd + 2 ;
			else
				lineStart = lineEnd + 1 ;
		}
		else // '\n'
			lineStart = lineEnd + 1 ;
	}	
	delete []buffer ;
	iLine = new char[maxLengthOfLine + 1];
	iCurrentObeyStatement = new char[maxLengthOfLine + 1];
	*iCurrentObeyStatement = 0 ;
	*iLine = 0 ;
	iCurrentLine = 0 ;
	iMarkLine = 0 ;
	return ETrue;
}

void ObeyFileReader::Mark()	{ 
	iMarkLine = iCurrentLine - 1;
}

void ObeyFileReader::MarkNext() { 
	iMarkLine = iCurrentLine;
}

void ObeyFileReader::Rewind() {
	iCurrentLine = iMarkLine;
}

char* ObeyFileReader::DupWord(TInt aIndex) const {
	char* retVal = 0 ;
	if(aIndex >= 0 && aIndex < (TInt)KNumWords){
		size_t len = strlen(iWord[aIndex]) + 1;
		retVal = new char[len];
		if(retVal)
			memcpy(retVal,iWord[aIndex],len);
	} 
	return retVal ;
}

TInt ObeyFileReader::ReadAndParseLine() {
	if (iCurrentLine >= (TInt)iLines.size())
		return KErrEof;
	iCurrentLine++; 	
	iNumWords = Parse();
	return KErrNone;
}

TInt ObeyFileReader::NextLine(TInt aPass, enum EKeyword& aKeyword) {

NextLine:
	TInt err = ReadAndParseLine();
	if (err == KErrEof)
		return KErrEof;
	if(iNumWords == 0)
		goto NextLine;
	if (stricmp(iWord[0], "stop")==0)
		return KErrEof;

	const ObeyFileKeyword* k=0;
	for (k=iKeywords; k->iKeyword!=0; k++) {
		if (k->iKeywordLength == 0) {
			// Exact case-insensitive match on keyword
			if (stricmp(iWord[0], k->iKeyword) != 0)
				continue;
			*iSuffix = 0;
		}
		else {
			// Prefix match
			if (strnicmp(iWord[0], k->iKeyword, k->iKeywordLength) != 0)
				continue;
			// Suffix must be empty, or a variant number in []
			strncpy(iSuffix,iWord[0] + k->iKeywordLength,80);
			if (*iSuffix != '\0' && *iSuffix != '[')
				continue;
		}
		// found a match
		if ((k->iPass & aPass) == 0)
			goto NextLine;
		if (k->iNumArgs>=0 && (1+k->iNumArgs != iNumWords)) {
			Print(EError, "Incorrect number of arguments for keyword %s on line %d.\n",
				iWord[0], iCurrentLine);
			goto NextLine;
		}
		if (k->iNumArgs<0 && (1-k->iNumArgs > iNumWords)) {
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

//
// splits a line into words, and returns the number of words found
// 
TInt ObeyFileReader::Parse() {

	for (TUint i = 0; i < KNumWords; i++)
		iWord[i] = NullString;

	enum TState {EInWord, EInQuotedWord, EInGap};
	TState state = EInGap;
	const string& line = iLines[iCurrentLine - 1]; 	
	size_t len = line.length();	
	memcpy(iLine,line.c_str(),len);
	memcpy(iCurrentObeyStatement,iLine,len);
	iLine[len] = 0 ; 
	iCurrentObeyStatement[len] = 0 ;
	TUint i = 0;
	char* linestr = iLine;
	while (i < KNumWords && *linestr != 0) {	 
		switch (state)
		{
		case EInGap:
			if (*linestr =='\"') {
				if (linestr[1] != 0 && linestr[1]!='\"')
					iWord[i++] = linestr + 1;
				state = EInQuotedWord;
			}
			else if (!IsGap(*linestr)) {
				iWord[i++] = linestr;
				state=EInWord;
			}
			else
				*linestr=0;
			break;
		case EInWord:
			if (*linestr == '\"') {
				*linestr = 0;
				if (linestr[1] != 0 && linestr[1] != '\"')
					iWord[i++] = linestr+1;
				state=EInQuotedWord;
			}
			else if (IsGap(*linestr)) {
				*linestr=0;
				state=EInGap;
			}
			break;
		case EInQuotedWord:
			if (*linestr == '\"'){
				*linestr = 0;
				state = EInGap;
			}
			break;
		}
		linestr++;
	}
	return i;
}

//
// Process the timestamp
//
void ObeyFileReader::ProcessTime(TInt64& aTime) {
	char timebuf[256];
	if (iNumWords>2)
		sprintf(timebuf, "%s_%s", iWord[1], iWord[2]);
	else
		strncpy(timebuf, iWord[1],256);

	TInt r = StringToTime(aTime, timebuf);
	if (r==KErrGeneral) {
		Print(EError, "incorrect format for time keyword on line %d\n", iCurrentLine);
		exit(0x670);
	}
	if (r==KErrArgument){
		Print(EError, "Time out of range on line %d\n", iCurrentLine);
		exit(0x670);
	}
}

TInt64 ObeyFileReader::iTimeNow = 0;
void ObeyFileReader::TimeNow(TInt64& aTime) {
	if (iTimeNow==0) {
		TInt sysTime = time(0);					// seconds since midnight Jan 1st, 1970
		sysTime -= (30*365*24*60*60+7*24*60*60);	// seconds since midnight Jan 1st, 2000
		TInt64 daysTo2000AD=730497;
		TInt64 t=daysTo2000AD*24*3600+sysTime;	// seconds since 0000
		t = t+3600;								// BST (?)
		iTimeNow=t*1000000;						// milliseconds
	}
	aTime=iTimeNow;
}

 

// File attributes.


const FileAttributeKeyword ObeyFileReader::iAttributeKeywords[] =
{
	{"attrib",3			,0,1,EAttributeAtt, "File attributes in ROM file system"},
	{"exattrib",3		,0,1,EAttributeAttExtra, "File extra attributes in ROM file system"}, 
	{"stack",3			,1,1,EAttributeStack, "?"},
	{"fixed",3			,1,0,EAttributeFixed, "Relocate to a fixed address space"},
	{"priority",3		,1,1,EAttributePriority, "Override process priority"},
	{_K("uid1")			,1,1,EAttributeUid1, "Override first UID"},
	{_K("uid2")			,1,1,EAttributeUid2, "Override second UID"},
	{_K("uid3")			,1,1,EAttributeUid3, "Override third UID"},
	{_K("heapmin")		,1,1,EAttributeHeapMin, "Override initial heap size"},
	{_K("heapmax")		,1,1,EAttributeHeapMax, "Override maximum heap size"},
	{_K("capability")	,1,1,EAttributeCapability, "Override capabilities"},
	{_K("unpaged")		,1,0,EAttributeUnpaged, "Don't page code or data for this file"},
	{_K("paged")		,1,0,EAttributePaged, "Page code and data for this file"},
	{_K("unpagedcode")	,1,0,EAttributeUnpagedCode, "Don't page code for this file"},
	{_K("pagedcode")	,1,0,EAttributePagedCode, "Page code for this file"},
	{_K("unpageddata")	,1,0,EAttributeUnpagedData, "Don't page data for this file"},
	{_K("pageddata")	,1,0,EAttributePagedData, "Page data for this file"},
	{0,0,0,0,EAttributeAtt,0}
};

TInt ObeyFileReader::NextAttribute(TInt& aIndex, TInt aHasFile, enum EFileAttribute& aKeyword, char*& aArg)
{
NextAttribute:
	if (aIndex >= iNumWords)
		return KErrEof;
	char* word=iWord[aIndex++];
	const FileAttributeKeyword* k;
	for (k=iAttributeKeywords; k->iKeyword!=0; k++)
	{
		if (k->iKeywordLength == 0)
		{
			// Exact match on keyword
			if (stricmp(word, k->iKeyword) != 0)
				continue;
		}
		else
		{
			// Prefix match
			if (strnicmp(word, k->iKeyword, k->iKeywordLength) != 0)
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



/**
Constructor:
1.Obey file instance.
2.used by both rofs and datadrive image.

@param aReader - obey file reader object.
*/
CObeyFile::CObeyFile(ObeyFileReader& aReader):
iRomFileName(NULL),
iExtensionRofsName(0),
iKernelRofsName(0),
iRomSize(0),
iVersion(0,0,0),
iCheckSum(0),
iNumberOfFiles(0),
iTime(0),
iRootDirectory(0),
iNumberOfDataFiles(0),
iDriveFileName(0), 
iDriveFileFormat(0), 
iReader(aReader), 
iMissingFiles(0), 
iLastExecutable(0),
iFirstFile(0), 	
iCurrentFile(0),
iAutoSize(EFalse),
iAutoPageSize(4096),
iPagingOverrideParsed(0),
iCodePagingOverrideParsed(0),
iDataPagingOverrideParsed(0),
iPatchData(new CPatchDataProcessor)
{
	iNextFilePtrPtr = &iFirstFile ;
}

/**
Obey file Destructor.
1.Release the tree memory.
2.Release all allocated memory if any.
*/
CObeyFile::~CObeyFile() {
	if(iDriveFileName){
		delete[] iDriveFileName;					
		iDriveFileName = 0 ;
	}
	if(iDriveFileFormat) {
		delete[] iDriveFileFormat;
		iDriveFileFormat = 0 ;
	}
	iRootDirectory->deleteTheFirstNode();                
	iRootDirectory->InitializeCount();

	Release();
	if(iRomFileName){ 
		delete [] iRomFileName;
		iRomFileName = 0 ;
	}
	if (iRootDirectory)
		iRootDirectory->Destroy(); 
	if(iPatchData)
		delete iPatchData;
}

//
// Free resources not needed after building a ROM
//
void CObeyFile::Release() {
	iFirstFile = 0;
	iNextFilePtrPtr = &iFirstFile;
}

TRomBuilderEntry *CObeyFile::FirstFile() {
	iCurrentFile = iFirstFile;
	return iCurrentFile;
}

TRomBuilderEntry *CObeyFile::NextFile() {
	iCurrentFile = iCurrentFile ? iCurrentFile->iNext : 0;
	return iCurrentFile;
}

char* CObeyFile::ProcessCoreImage() const {
	// check for coreimage keyword and return filename	 
	enum EKeyword keyword;
	char* coreImageFileName = 0;
	iReader.Rewind();
	while (iReader.NextLine(1,keyword) != KErrEof) {
		if (keyword == EKeywordCoreImage) {  			  
			coreImageFileName = iReader.DupWord(1);	
			iReader.MarkNext();
			break;
		}
	}
	return coreImageFileName;
}

void CObeyFile::SkipToExtension() {
	iReader.Rewind();
	enum EKeyword keyword;
	while (iReader.NextLine(1,keyword) != KErrEof) {
		if (keyword == EKeywordExtensionRofs) {
			iReader.Mark(); // ready for processing extension
			break;
		}
	}
}

TInt CObeyFile::ProcessRofs() {
	
	//
	// First pass through the obey file to set up key variables
	//

	iReader.Rewind();

	TInt count=0;
	enum EKeyword keyword;
	while (iReader.NextLine(1,keyword) != KErrEof) {
		if (keyword == EKeywordExtensionRofs){
			if (count==0)
				return KErrNotFound;		// no core ROFS, just extension ROFSs.
			break;
		}

		count++;
		if (! ProcessKeyword(keyword))
			return KErrGeneral;
	}

	if (!GotKeyVariables())
		return KErrGeneral;

	//
	// second pass to process the file specifications in the obey file building
	// up the TRomNode directory structure and the TRomBuilderEntry list
	//
	iReader.Rewind();

	iRootDirectory = new TRomNode("");
	iLastExecutable = iRootDirectory;

	TInt align=0;
	while (iReader.NextLine(2,keyword)!=KErrEof) {
		if (keyword == EKeywordExtensionRofs)
			break;

		if (keyword == EKeywordHide)
			keyword = EKeywordHideV2;

		switch (keyword) 
		{
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

	if(!ParsePatchDllData())
		return KErrGeneral;
	iReader.Mark();			// ready for processing the extension rom(s)

	if (iMissingFiles!=0) {
		return KErrGeneral;
	}
	if ( 0 == iNumberOfFiles ){
		Print(EError, "No files specified.\n");
		return KErrGeneral;
	}

	return KErrNone;
}

TBool CObeyFile::Process() {
	TBool result = ETrue;
	iReader.Rewind();
	enum EKeyword keyword;
	while(iReader.NextLine(1, keyword) != KErrEof){
		string key = iReader.Word(0);
		string value = iReader.Word(1);
		if(iKeyValues.find(key) != iKeyValues.end()){
			iKeyValues[key].push_back(value);
		}
		else {
			StringVector values;
			values.push_back(value);
			iKeyValues[key]=values;
		}


	}
	return result;
}
StringVector CObeyFile::getValues(const string& aKey) {
	StringVector values;
	if(iKeyValues.find(aKey) != iKeyValues.end()){
		values = iKeyValues[aKey];
	}
	return values;
}

/**
Process drive obey file and construct the tree.

@return - Return the status,
'KErrnone' for Success,
'KErrGeneral' for failure (required keywords not there in obey file or failed
to construct the tree).
*/
TInt CObeyFile::ProcessDataDrive() {
	iReader.Rewind();
	enum EKeyword keyword;

	// First pass through the obey file to set up key variables
	while (iReader.NextLine(1,keyword) != KErrEof) {
		if (!ProcessDriveKeyword(keyword))			
			return KErrGeneral;
	}

	if (!GotKeyDriveVariables())
		return KErrGeneral;

	// Second pass to process the file specifications in the obey file.
	// Build the TRomNode directory structure and the TRomBuilderEntry list
	iReader.Rewind();
	iRootDirectory = new TRomNode("//");					
	iLastExecutable = iRootDirectory;

	while(iReader.NextLine(2,keyword)!=KErrEof) {
		switch (keyword) 
		{
		case EKeywordPatchDllData:
			{	// Collect patchdata statements to process at the end
				StringVector patchDataTokens;
				SplitPatchDataStatement(patchDataTokens); 				
				iPatchData->AddPatchDataStatement(patchDataTokens);									
				break;
			}

		case EKeywordHide:						
		case EKeywordFile:
		case EKeywordDir:
		case EKeywordData:
		case EKeywordFileCompress:
		case EKeywordFileUncompress:
			if (!ProcessDriveFile(keyword))
				return KErrGeneral;
			break;

		default:							
			break;
		}
	}

	if(!ParsePatchDllData())
		return KErrGeneral;
	if (iMissingFiles) {
		Print(EError, "Source Files Missing.\n");
		return KErrGeneral;
	}
	if (!iNumberOfFiles)
		Print(EWarning,"No files specified.\n");

	return KErrNone;
}


/**
Process and stores the keyword information.

@param aKeyword - keyword to update its value to variables.
@return - Return the status i.e Success,
*/
TBool CObeyFile::ProcessDriveKeyword(enum EKeyword aKeyword) {

	TBool success = ETrue;
	switch (aKeyword)
	{
	case EKeywordDataImageName:
		iDriveFileName = iReader.DupWord(1);
		break;
	case EKeywordDataImageFileSystem:
		iDriveFileFormat = iReader.DupWord(1);
		break;
	case EKeywordDataImageSize:
		{
			const char* bigString = iReader.Word(1);
			if(*bigString == '\0')
			{
				Print(EWarning,"Not a valid Image Size. Default size is considered\n");		
				break;
			}
 
			Val(iConfigurableFatAttributes.iImageSize,bigString); 
		}
		break;
	case EKeywordDataImageVolume:
		{				
			// Get the volume label provided by using "volume" keyword.
			// e.g. vlolume = NO NAME
			string volumeLabel = iReader.GetCurrentObeyStatement();
			string volumeLabelKeyword = "volume";

			TUint position = volumeLabel.find(volumeLabelKeyword.c_str(),0,volumeLabelKeyword.size());
			position += volumeLabelKeyword.size();
			if (volumeLabel.find('=',position) != string::npos) {
				position=volumeLabel.find('=',position);
				++position;
			}								

			position = volumeLabel.find_first_not_of(' ',position);
			if (position != string::npos) {
				volumeLabel = volumeLabel.substr(position);

				// Remove the new line character from the end
				position = volumeLabel.find_first_of("\r\n");
				if (position != string::npos)
					volumeLabel = volumeLabel.substr(0,position);
				size_t length = volumeLabel.length() ;
				if(length > 11) 
						length = 11 ;
				memcpy(iConfigurableFatAttributes.iDriveVolumeLabel,volumeLabel.c_str(),length) ;
				while(length != 11)
					iConfigurableFatAttributes.iDriveVolumeLabel[length++] = ' ';
				iConfigurableFatAttributes.iDriveVolumeLabel[length] = 0;
			}
			else {
				Print(EWarning,"Value for Volume Label is not provided. Default value is considered.\n");
			}
			break;
		}
	case EKeywordDataImageSectorSize:
		{
			const char* bigString = iReader.Word(1);
			TInt sectorSize = atoi(bigString);
			if(sectorSize <= 0)	{
				Print(EWarning,"Invalid Sector Size value. Default value is considered.\n");
			}
			else {
				iConfigurableFatAttributes.iDriveSectorSize = atoi(bigString);
			}
		}			
		break;
	case EKeywordDataImageNoOfFats:
		{
			const char* bigString = iReader.Word(1);
			TInt noOfFats = atoi(bigString);
			if (noOfFats <=0)
				Print(EWarning,"Invalid No of FATs specified. Default value is considered.\n");
			else
				iConfigurableFatAttributes.iDriveNoOfFATs = atoi(bigString);			
		}			
		break;			
	default:
		// unexpected keyword iReader.Word(0), keep going.
		break;
	}
	return success;
}


/**
Checks whether obeyfile has supplied enough variables to continue.

@return - Return the status 
ETrue - Supplied valid values,
EFalse- Not valied values.
*/
TBool CObeyFile::GotKeyDriveVariables() {

	TBool retVal=ETrue;

	// Mandatory keywords
	if (iDriveFileName==0) {                                                  
		Print(EError,"The name of the image file has not been supplied.\n");
		Print(EError,"Use the keyword \"dataimagename\".\n");
		retVal = EFalse;
	}
	// Check for '-'ve entered value.
	if(iConfigurableFatAttributes.iImageSize <= 0){
		Print(EWarning,"Image Size should be positive. Default size is Considered.\n");
	}

	// File system format.
	if(iDriveFileFormat==0) {
		Print(EError,"The name of the file system not been supplied.\n");
		Print(EError,"Use the keyword \"dataimagefilesystem\".\n");
		retVal = EFalse;
	}

	// Checking the validity of file system format.
	if(iDriveFileFormat){		 
		if(stricmp(iDriveFileFormat,"FAT16") && stricmp(iDriveFileFormat,"FAT32")) {
			Print(EError,"The name of the file system not supported : %s\n",iDriveFileFormat);
			retVal = EFalse;
		}
	}
	if(retVal)
		Print(ELog,"\nCreating Data Drive image : %s\n", iDriveFileName);

	return retVal;
}

/**
Process a parsed line to set up one or more new TRomBuilder entry objects.

@param  - obey file keyword.
// iWord[0] = the keyword (file,)      
// iWord[1] = the PC pathname
// iWord[2] = the EPOC pathname
// iWord[3] = start of the file attributes

@return - Return the status 
ETrue - Successful generation of tree.
EFalse- Fail to generate the tree.
*/
TBool CObeyFile::ProcessDriveFile(enum EKeyword aKeyword) {

	TBool isPeFile = ETrue;
	TBool aFileCompressOption, aFileUncompressOption;

	TInt epocPathStart=2;
	aFileCompressOption = aFileUncompressOption = EFalse;
	// do some validation of the keyword
	TInt currentLine = iReader.CurrentLine();

	switch (aKeyword)
	{
	case EKeywordData:
	case EKeywordDir:
	case EKeywordHide:
		isPeFile = EFalse;
		break;

	case EKeywordFile:
		break;

	case EKeywordFileCompress:
		aFileCompressOption = ETrue;
		break;

	case EKeywordFileUncompress:
		aFileUncompressOption = ETrue;
		break;

	default:
		return EFalse;
	}

	if (aKeyword!=EKeywordHide && aKeyword!=EKeywordDir) {
		// check the PC file exists
		char* nname = NormaliseFileName(iReader.Word(1));		  
		ifstream test(nname);
		if(!test.is_open()){
			Print(EError,"Cannot open file %s for input.\n",iReader.Word(1));
			iMissingFiles++;
		}
		test.close();
		delete []nname ;												
		 
	}
	else
		epocPathStart=1;   

	if(aKeyword != EKeywordDir)
		iNumberOfFiles++;

	TBool endOfName=EFalse;
	const char *epocStartPtr;
	if(aKeyword != EKeywordDir)
		epocStartPtr = IsValidFilePath(iReader.Word(epocPathStart));
	else
		epocStartPtr = IsValidDirPath(iReader.Word(epocPathStart));
	char *epocEndPtr = const_cast<char*>(epocStartPtr);

	if (epocStartPtr == NULL) {
		Print(EError, "Invalid destination path on line %d\n",currentLine);
		return EFalse;
	}

	TRomNode* dir=iRootDirectory;
	TRomNode* subDir=0;
	TRomBuilderEntry *file=0;      

	while (!endOfName) {
		endOfName = GetNextBitOfFileName(epocEndPtr);      
		if (endOfName && (aKeyword!=EKeywordDir)) { // file
			TRomNode* alreadyExists=dir->FindInDirectory(epocStartPtr);
			if ((aKeyword != EKeywordHide) && alreadyExists) { // duplicate file		
				if (gKeepGoing) {
					Print(EWarning, "Duplicate file for %s on line %d, will be ignored\n",iReader.Word(1),iReader.CurrentLine());
					iNumberOfFiles--;
					return ETrue;
				}
				else {	
					Print(EError, "Duplicate file for %s on line %d\n",iReader.Word(1),iReader.CurrentLine());
					return EFalse;
				}
			}
			else if((aKeyword == EKeywordHide) && (alreadyExists)) { 
				alreadyExists->iEntry->iHidden = ETrue;
				alreadyExists->iHidden = ETrue;
				return ETrue;
			}
			else if((aKeyword == EKeywordHide) && (!alreadyExists)) {
				Print(EWarning, "Hiding non-existent file %s on line %d\n",iReader.Word(1),iReader.CurrentLine());
				return ETrue;
			}

			file = new TRomBuilderEntry(iReader.Word(1), epocStartPtr);                   
			file->iExecutable=isPeFile;
			if( aFileCompressOption ) {
				file->iCompressEnabled = ECompressionCompress;
			}
			else if(aFileUncompressOption )	{
				file->iCompressEnabled = ECompressionUncompress;
			}

			TRomNode* node=new TRomNode(epocStartPtr, file);
			if (node==0)
				return EFalse;

			TInt r=ParseFileAttributes(node, file, aKeyword);         
			if (r!=KErrNone)
				return EFalse;

			if(gCompress != ECompressionUnknown) {
				node->iFileUpdate = ETrue;
			}

			if((node->iOverride) || (aFileCompressOption) || (aFileUncompressOption)) {
				node->iFileUpdate = ETrue;
			}

			dir->AddFile(node);	// to drive directory structure.
		}		 
		else {
			// directory
			//for directory creation, given /sys/bin/, it's possible to reach 0 at the end, just ignore that...
			if(!*epocStartPtr)
				break;

			subDir = dir->FindInDirectory(epocStartPtr);      
			if (!subDir){ // sub directory does not exist			
				if(aKeyword==EKeywordHide) {
					Print(EWarning, "Hiding non-existent file %s on line %d\n",
						iReader.Word(1),iReader.CurrentLine());
					return ETrue;
				}
				subDir = dir->NewSubDir(epocStartPtr);
				if (!subDir)
					return EFalse;
			}
			dir=subDir;
			epocStartPtr = epocEndPtr;
		}  // end of else.
	}
	return ETrue;
}


TInt CObeyFile::SetStackSize(TRomNode *aNode, const char* aStr) {
	if (EFalse == IsValidNumber(aStr))
		return Print(EError, "Number required as argument for keyword 'stack'.\n"); 
	TInt size ;
	TInt err = Val(size,aStr);
	if(KErrNone == err){
		aNode->SetStackSize(size );
	}
	return err;
}

TInt CObeyFile::SetHeapSizeMin(TRomNode *aNode, const char* aStr) {
	if (EFalse == IsValidNumber(aStr))
		return Print(EError, "Number required as argument for keyword 'heapmin'.\n");
	TInt size ;
	TInt err = Val(size,aStr);
	if(KErrNone == err){
		aNode->SetHeapSizeMin(size );
	}
	return err;	 
}

TInt CObeyFile::SetHeapSizeMax(TRomNode *aNode, const char* aStr) {
	if (EFalse == IsValidNumber(aStr))
		return Print(EError, "Number required as argument for keyword 'heapmax'.\n");
	TInt size ;
	TInt err = Val(size,aStr);
	if(KErrNone == err){
		aNode->SetHeapSizeMax(size );
	}
	return err;	
	 
}

TInt CObeyFile::SetCapability(TRomNode *aNode, const char* aStr) {
	if ( IsValidNumber(aStr)){
		Print(EDiagnostic,"Old style numeric CAPABILTY specification ignored.\n");
		return KErrNone;
	}
	SCapabilitySet cap;
	TInt r = ParseCapabilitiesArg(cap, (char*)aStr);
	if( KErrNone == r ) {
		aNode->SetCapability( cap );
	}
	return r;
}

TInt CObeyFile::SetPriority(TRomNode *aNode, const char* aStr) {
	TProcessPriority priority;	
	
	if ( IsValidNumber(aStr)) {
		TUint32 temp = 0;
		Val(temp,aStr) ;
		priority = (TProcessPriority)temp ; 
	}
	else {	 
		if (stricmp(aStr, "low")==0)
			priority=EPriorityLow;
		else if (strnicmp(aStr, "background", 4)==0)
			priority=EPriorityBackground;
		else if (strnicmp(aStr, "foreground", 4)==0)
			priority=EPriorityForeground;
		else if (stricmp(aStr, "high")==0)
			priority=EPriorityHigh;
		else if (strnicmp(aStr, "windowserver",3)==0)
			priority=EPriorityWindowServer;
		else if (strnicmp(aStr, "fileserver",4)==0)
			priority=EPriorityFileServer;
		else if (strnicmp(aStr, "realtimeserver",4)==0)
			priority=EPriorityRealTimeServer;
		else if (strnicmp(aStr, "supervisor",3)==0)
			priority=EPrioritySupervisor;
		else
			return Print(EError, "Unrecognised priority keyword.\n");
	}
	if (priority<EPriorityLow || priority>EPrioritySupervisor)
		return Print(EError, "Priority out of range.\n");

	aNode->SetPriority( priority );
	return KErrNone;
}

TInt CObeyFile::SetUid1(TRomNode *aNode, const char* aStr){
	if (EFalse == IsValidNumber(aStr))
		return Print(EError, "Number required as argument for keyword 'uid1'.\n");
	TInt size ;
	TInt err = Val(size,aStr);
	if(KErrNone == err){
		aNode->SetUid1(size );
	}
	return err;		 
}
TInt CObeyFile::SetUid2(TRomNode *aNode, const char* aStr) {
	if (EFalse == IsValidNumber(aStr))
		return Print(EError, "Number required as argument for keyword 'uid2'.\n");
	TInt size ;
	TInt err = Val(size,aStr);
	if(KErrNone == err){
		aNode->SetUid2(size );
	}
	return err;	
}
TInt CObeyFile::SetUid3(TRomNode *aNode, const char* aStr) {
	if (EFalse == IsValidNumber(aStr))
		return Print(EError, "Number required as argument for keyword 'uid3'.\n");
	TInt size ;
	TInt err = Val(size,aStr);
	if(KErrNone == err){
		aNode->SetUid3(size );
	}
	return err;	
}

//
// Process any inline keywords
//
TInt CObeyFile::ParseFileAttributes(TRomNode *aNode, TRomBuilderEntry* aFile, enum EKeyword aKeyword) {
	TInt currentLine = iReader.CurrentLine();
	enum EFileAttribute attribute;
	TInt r=KErrNone;
	TInt index=3;
	char* arg=0;

	while(r==KErrNone) {
		r=iReader.NextAttribute(index,(aFile!=0),attribute,arg);
		if (r!=KErrNone)
			break;
		switch(attribute)
		{
		case EAttributeAtt:
			r=aNode->SetAtt(arg);
			break;
		case EAttributeAttExtra:
			r=aNode->SetAttExtra(arg, aFile, aKeyword);
			break;
		case EAttributeStack:
			r=SetStackSize(aNode, arg);
			break;
		case EAttributeFixed:
			aNode->SetFixed();
			r = KErrNone;
			break;
		case EAttributeUid1:
			r=SetUid1(aNode, arg);
			break;
		case EAttributeUid2:
			r=SetUid2(aNode, arg);
			break;
		case EAttributeUid3:
			r=SetUid3(aNode, arg);
			break;
		case EAttributeHeapMin:
			r=SetHeapSizeMin(aNode, arg);
			break;
		case EAttributeHeapMax:
			r=SetHeapSizeMax(aNode, arg);
			break;
		case EAttributePriority:
			r=SetPriority(aNode, arg);
			break;
		case EAttributeCapability:
			r=SetCapability(aNode, arg);
			break;
		case EAttributeUnpaged:
			aNode->iOverride |= KOverrideCodeUnpaged|KOverrideDataUnpaged;
			aNode->iOverride &= ~(KOverrideCodePaged|KOverrideDataPaged);
			break;
		case EAttributePaged:
			aNode->iOverride |= KOverrideCodePaged;
			aNode->iOverride &= ~(KOverrideCodeUnpaged);
			break;
		case EAttributeUnpagedCode:
			aNode->iOverride |= KOverrideCodeUnpaged;
			aNode->iOverride &= ~KOverrideCodePaged;
			break;
		case EAttributePagedCode:
			aNode->iOverride |= KOverrideCodePaged;
			aNode->iOverride &= ~KOverrideCodeUnpaged;
			break;
		case EAttributeUnpagedData:
			aNode->iOverride |= KOverrideDataUnpaged;
			aNode->iOverride &= ~KOverrideDataPaged;
			break;
		case EAttributePagedData:
			aNode->iOverride |= KOverrideDataPaged;
			aNode->iOverride &= ~KOverrideDataUnpaged;
			break;
		default:
			return Print(EError, "Unrecognised keyword in file attributes on line %d.\n",currentLine);
		}
	}

	if (r==KErrEof)
		return KErrNone;
	return r;
}

//
// Process a parsed line to set up one or more new TRomBuilder entry objects.
// iWord[0] = the keyword (file, primary or secondary)
// iWord[1] = the PC pathname
// iWord[2] = the EPOC pathname
// iWord[3] = start of the file attributes
//
TBool CObeyFile::ProcessFile(TInt /*aAlign*/, enum EKeyword aKeyword){

	TBool isPeFile = ETrue;
	TBool aFileCompressOption, aFileUncompressOption;
	TInt epocPathStart=2;
	aFileCompressOption = aFileUncompressOption = EFalse;
	TBool warnFlag = EFalse;
	static const char aStdPath[] = "SYS\\BIN\\";
	static const int sysBinLength = sizeof(aStdPath)-1;

	// do some validation of the keyword
	TInt currentLine = iReader.CurrentLine();
	switch (aKeyword)
	{
	case EKeywordData:
	case EKeywordHideV2:
		iNumberOfDataFiles++;
		isPeFile = EFalse;
		break;

	case EKeywordFile:
		warnFlag = gEnableStdPathWarning;
		break;
	case EKeywordFileCompress:
		aFileCompressOption = ETrue;
		warnFlag = gEnableStdPathWarning;
		break;
	case EKeywordFileUncompress:
		aFileUncompressOption = ETrue;
		warnFlag = gEnableStdPathWarning;
		break;

	default:
		Print(EError,"Unexpected keyword '%s' on line %d.\n",iReader.Word(0),currentLine);
		return EFalse;
	}

	if (aKeyword!=EKeywordHideV2) {

		// check the PC file exists
		char* nname = NormaliseFileName(iReader.Word(1)); 
		ifstream test(nname);
		if (!test) {
			Print(EError,"Cannot open file %s for input.\n",iReader.Word(1));
			iMissingFiles++;
		}
		test.close();
		delete []nname;
	}
	else
		epocPathStart=1;

	iNumberOfFiles++;


	TBool endOfName=EFalse;
	const char *epocStartPtr=IsValidFilePath(iReader.Word(epocPathStart));
	char *epocEndPtr=const_cast<char*>(epocStartPtr);
	if (epocStartPtr==NULL) {
		Print(EError, "Invalid destination path on line %d\n",currentLine);
		return EFalse;
	}
	if(warnFlag){	// Check for the std destination path(for executables) as per platsec.	
		if(strnicmp(aStdPath,epocStartPtr,sysBinLength) != 0) {
			Print(EWarning,"Invalid destination path on line %d. \"%s\" \n",currentLine,epocStartPtr);
		}
	}

	TRomNode* dir=iRootDirectory;
	TRomNode* subDir=0;
	TRomBuilderEntry *file=0;
	while (!endOfName) {
		endOfName = GetNextBitOfFileName(epocEndPtr);
		if (endOfName) {// file		
			TRomNode* alreadyExists=dir->FindInDirectory(epocStartPtr);
			/*
			* The EKeywordHideV2 keyword is used to indicate that:
			*	1. if the file exists in the same image and then hidden, mark it hidden
			*	2. if the file exists in another image, but in this (ROFS) image, it is
			*		required to hide that file, create a 0 length file entry setting the 'hide'
			*		flag so that at runtime, file gets hidden in the composite filesystem.
			*/
			if ((aKeyword != EKeywordHideV2) && alreadyExists){ // duplicate file		
				if(gKeepGoing){	
					Print(EWarning, "Duplicate file for %s on line %d, will be ignored\n",iReader.Word(1),iReader.CurrentLine());
					switch (aKeyword)
					{
					case EKeywordData:
					case EKeywordHideV2:
						iNumberOfDataFiles--;
					default:
						break;
					}
					iNumberOfFiles--;	 	
					return ETrue;
				}
				else {					
					Print(EError, "Duplicate file for %s on line %d\n",iReader.Word(1),iReader.CurrentLine());
					return EFalse;
				}
			}

			TBool aHidden = aKeyword==EKeywordHideV2;
			/* The file is only marked hidden and hence the source file name isn't known 
			* here as hide statement says :
			*	hide <filename as in ROM>
			* Therefore, create TRomBuilderEntry with iFileName as 0 for hidden file when
			* the file doesn't exist in the same ROM image. Otherwise, the src file name
			* is known because of alreadyExists (which comes from the 'file'/'data' statement).
			*/
			if(aHidden)
				file = new TRomBuilderEntry(0, epocStartPtr);
			else
				file = new TRomBuilderEntry(iReader.Word(1), epocStartPtr);
			file->iExecutable=isPeFile;
			file->iHidden= aHidden;
			if( aFileCompressOption ){
				file->iCompressEnabled = ECompressionCompress;
			}
			else if(aFileUncompressOption )	{
				file->iCompressEnabled = ECompressionUncompress;
			}
			TRomNode* node=new TRomNode(epocStartPtr, file);
			if (node==0)
				return EFalse;
			TInt r=ParseFileAttributes(node, file, aKeyword);
			if (r!=KErrNone)
				return EFalse;

			dir->AddFile(node);	// to ROFS directory structure
			AddFile(file);		// to our list of files
		}		 
		else { // directory		
			subDir = dir->FindInDirectory(epocStartPtr);
			if (!subDir) { // sub directory does not exist			
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


TBool CObeyFile::ProcessRenaming(enum EKeyword aKeyword) {

	// find existing file
	TBool endOfName=EFalse;
	const char *epocStartPtr=IsValidFilePath(iReader.Word(1));

	// Store the current name and new name to maintain renamed file map
	string currentName=iReader.Word(1);
	string newName=iReader.Word(2);

	char *epocEndPtr= const_cast<char*>(epocStartPtr);
	if (epocStartPtr == NULL) {
		Print(EError, "Invalid source path on line %d\n",iReader.CurrentLine());
		return EFalse;
	}

	char saved_srcname[257];
	strncpy(saved_srcname, iReader.Word(1),257);

	TRomNode* dir=iRootDirectory;
	TRomNode* existingFile=0;
	while (!endOfName){
		endOfName = GetNextBitOfFileName(epocEndPtr);
		if (endOfName) { // file
			existingFile=dir->FindInDirectory(epocStartPtr);
			if (existingFile) {
				TInt fileCount=0;
				TInt dirCount=0;
				existingFile->CountDirectory(fileCount, dirCount);
				if (dirCount != 0 || fileCount != 0) {
					Print(EError, "Keyword %s not applicable to directories - line %d\n",
						iReader.Word(0),iReader.CurrentLine());
					return EFalse;
				}
			}
		}
		else { // directory		
			TRomNode* subDir = dir->FindInDirectory(epocStartPtr);
			if (!subDir) // sub directory does not exist
				break;
			dir=subDir;
			epocStartPtr = epocEndPtr;
		}
	}
	if (aKeyword == EKeywordHide) {
		/*
		* The EKeywordHide keyword is used to indicate that if the file exists in 
		* the primary ROFS image and then hidden in extension ROFS, mark it hidden.
		*/
		if (!existingFile) {
			Print(EWarning, "Hiding non-existent file %s on line %d\n", 
				saved_srcname, iReader.CurrentLine());
			// Just a warning, as we've achieved the right overall effect.
		}
		else if (existingFile->iFileStartOffset==(TUint)KFileHidden){
			Print(EWarning, "Hiding already hidden file %s on line %d\n", 
				saved_srcname, iReader.CurrentLine());
			// We will igrore this request, otherwise it will "undelete" it.
		}
		else {
			//hidden files will not be placed to the image
			existingFile->iHidden = ETrue;
		}
		return ETrue;
	}

	if (!existingFile) {
		Print(EError, "Can't %s non-existent source file %s on line %d\n",
			iReader.Word(0), saved_srcname, iReader.CurrentLine());
		return EFalse;
	}

	epocStartPtr = IsValidFilePath(iReader.Word(2));
	epocEndPtr = const_cast<char*>(epocStartPtr);
	endOfName = EFalse;
	if (epocStartPtr == NULL) {
		Print(EError, "Invalid destination path on line %d\n",iReader.CurrentLine());
		return EFalse;
	}

	TRomNode* newdir=iRootDirectory;
	while (!endOfName) {
		endOfName = GetNextBitOfFileName(epocEndPtr);
		if (endOfName) {// file		
			TRomNode* alreadyExists=newdir->FindInDirectory(epocStartPtr);
			if (alreadyExists && !(alreadyExists->iHidden)) {// duplicate file	
				if(gKeepGoing){
					Print(EWarning, "Duplicate file for %s on line %d, renaming will be skipped\n",saved_srcname,iReader.CurrentLine());
					return ETrue;
				}
				else {							
					Print(EError, "Duplicate file for %s on line %d\n",saved_srcname,iReader.CurrentLine());
					return EFalse;
				}
			}
		}
		else { // directory		
			TRomNode* subDir = newdir->FindInDirectory(epocStartPtr);
			if (!subDir) {// sub directory does not exist			
				subDir = newdir->NewSubDir(epocStartPtr);
				if (!subDir)
					return EFalse;
			}
			newdir=subDir;
			epocStartPtr = epocEndPtr;
		}
	}

	if (aKeyword == EKeywordRename) {
		// rename => remove existingFile and insert into tree at new place
		// has no effect on the iNextExecutable or iNextNodeForSameFile links
		TInt r=ParseFileAttributes(existingFile, existingFile->iEntry, aKeyword);
		if (r!=KErrNone)
			return EFalse;
		existingFile->Rename(dir, newdir, epocStartPtr);
		// Store the current and new name of file in the renamed file map.
		iPatchData->AddToRenamedFileMap(currentName, newName);
		return ETrue;
	}

	// alias => create new TRomNode entry and insert into tree
	TRomNode* node = new TRomNode(epocStartPtr, 0);
	if (node == 0) {
		Print(EError, "Out of memory\n");
		return EFalse;
	}
	node->Alias(existingFile);
	TInt r=ParseFileAttributes(node, 0, aKeyword);
	if (r!=KErrNone)
		return EFalse;
	newdir->AddFile(node);	// to ROFS directory structure, though possibly hidden
	return ETrue;
}

TInt ParsePagingPolicy(const char* policy){
	if(stricmp(policy,"NOPAGING") == 0)
		return EKernelConfigPagingPolicyNoPaging;
	else if (stricmp(policy,"ALWAYSPAGE") == 0)
		return EKernelConfigPagingPolicyAlwaysPage;
	else if(stricmp(policy,"DEFAULTUNPAGED") == 0)
		return EKernelConfigPagingPolicyDefaultUnpaged;
	else if(stricmp(policy,"DEFAULTPAGED") == 0)
		return EKernelConfigPagingPolicyDefaultPaged;
	return KErrArgument;
}

TBool CObeyFile::ProcessKeyword(enum EKeyword aKeyword) { 

	TBool success = ETrue;
	switch (aKeyword)
	{
	case EKeywordRofsName:
		iRomFileName = iReader.DupWord(1);
		break;
	case EKeywordRofsSize:
		Val(iRomSize,iReader.Word(1));
		break;
	case EKeywordVersion:
		{
			istringstream val(iReader.Word(1)); 
			val >> iVersion;
		}
		break;
	case EKeywordRofsChecksum:
		Val(iCheckSum,iReader.Word(1));
		break;
	case EKeywordTime:
		iReader.ProcessTime(iTime);
		break;
	case EKeywordPagingOverride:
		{
			if(iPagingOverrideParsed)
				Print(EWarning, "PagingOverride redefined - previous PagingOverride values lost\n");
			if(iCodePagingOverrideParsed)
				Print(EWarning, "PagingOverride defined - previous CodePagingOverride values lost\n");
			iPagingOverrideParsed = true;
			TInt policy = ParsePagingPolicy(iReader.Word(1));
			if(policy < 0) {
				Print(EError,"Unrecognized option for PAGINGOVERRIDE keyword\n");
				success = false;
			}
			else {
				gCodePagingOverride = policy;
				if((policy == EKernelConfigPagingPolicyNoPaging) || (policy == EKernelConfigPagingPolicyDefaultUnpaged))
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
				Print(EError,"Unrecognized option for CODEPAGINGOVERRIDE keyword\n");
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
/*			if(iPagingOverrideParsed){
				Print(EError, "DataPagingOverride defined - previous PagingOverride values lost\n");
				success = false;
				break;
			}
*/
			iDataPagingOverrideParsed = true;
			TInt policy = ParsePagingPolicy(iReader.Word(1));
			if(policy < 0) {
				Print(EError,"Unrecognized option for DATAPAGINGOVERRIDE keyword\n");
				success = false;
			}
			else
				gDataPagingOverride = policy;
		}
		break;
	case EKeywordRofsAutoSize:
		iAutoSize = ETrue;
		Val(iAutoPageSize,iReader.Word(1));
		break;
	default:
		// unexpected keyword iReader.Word(0)
		break;
	}

	return success;
}
//
// Checks that the obeyfile has supplied enough variables to continue
//
TBool CObeyFile::GotKeyVariables() {

	TBool retVal=ETrue;
	// Mandatory keywords
	if (iRomFileName == 0) {
		Print(EAlways,"The name of the image file has not been supplied.\n");
		Print(EAlways,"Use the keyword \"rofsname\".\n");
		retVal = EFalse;
	}
	if (iRomSize == 0) {
		Print(EAlways,"The size of the image has not been supplied.\n");
		Print(EAlways,"Use the keyword \"rofssize\".\n");
		retVal = EFalse;
	}
	// Apply defaults as necessary
	if (iTime == 0)	{
		Print(ELog, "No timestamp specified. Using current time...\n");
		ObeyFileReader::TimeNow(iTime);
	}
	Print(ELog, "\nCreating Rofs image %s\n", iRomFileName);
	return retVal;
}

//
// Check the path is valid
//
const char* CObeyFile::IsValidFilePath(const char* aPath) {
	// skip leading "\"
	if (*aPath == '/' || *aPath == '\\')
		aPath++;
	if (*aPath == 0)
		return NULL; // file ends in a backslash

	const char *p = aPath;
	TInt len=0;
	while(*p) {			
		if (*p == '/' || *p == '\\') {
			if (len == 0)
				return NULL;
			len=0;
			p++;
			continue;

		}
		len++;
		p++;
	}
	return (len ? aPath : NULL);
}

const char* CObeyFile::IsValidDirPath(const char* aPath)
{
	const char* walker = aPath;

	//validate path...
	while(*walker)
	{
		if(((*walker=='/') || (*walker=='\\')) && ((*(walker+1)=='/') || (*(walker+1)=='\\')))
			return (const char*)0;
		walker++;
	}

	if((*aPath=='/') || (*aPath=='\\'))
		aPath++;

	return aPath;
}

//
// Move the end pointer past the next directory separator, replacing it with 0
//
TBool CObeyFile::GetNextBitOfFileName(char*& epocEndPtr) {
	while (*epocEndPtr != '/' && *epocEndPtr != '\\'){ // until reach the directory separator		
		if (*epocEndPtr == 0) // if reach end of string, return TRUE, it's the filename
			return ETrue;
		epocEndPtr++;
	}
	*epocEndPtr = 0; // overwrite the directory separator with a 0
	epocEndPtr++; // point past the 0 ready for the next one
	return EFalse;
}

void CObeyFile::AddFile(TRomBuilderEntry* aFile) {
	*iNextFilePtrPtr = aFile;
	iNextFilePtrPtr = &(aFile->iNext);
}

//
// First pass through the obey file to set up key variables
//
TInt CObeyFile::ProcessExtensionRofs(MRofsImage* aKernelRom) { 
	
	iReader.Rewind();
	enum EKeyword keyword;

	// Deal with the "extensionrofs" keyword, which should be first
	// however, you may've found "time" before it.
	while(iReader.NextLine(1,keyword) != KErrEof) {
		if(EKeywordExtensionRofs == keyword)
			break ;		
	}
	if(EKeywordExtensionRofs != keyword) return KErrEof;
	iRomFileName = iReader.DupWord(1);
	Print(ELog, "\n========================================================\n");
	Print(ELog, "Extension ROFS %s starting at line %d\n\n", iRomFileName, iReader.CurrentLine());

	iReader.MarkNext();		// so that we rewind to the line after the extensionrom keyword

	while (iReader.NextLine(1,keyword) != KErrEof) {
		if (keyword == EKeywordExtensionRofs)
			break;
		ProcessExtensionKeyword(keyword);
	}

	if (!GotExtensionVariables(aKernelRom))
		return KErrGeneral;

	// second pass to process the file specifications in the obey file building
	// up the TRomNode directory structure and the TRomBuilderEntry list
	//
	iReader.Rewind();

	//
	if (aKernelRom == 0)
		return Print(EError, "Option to extend a kernel ROFS image not yet implemented\n");

	iRootDirectory = new TRomNode("");

	iLastExecutable = 0;

	(aKernelRom->RootDirectory())->deleteTheFirstNode();


	iRootDirectory = aKernelRom->CopyDirectory(iLastExecutable);
	aKernelRom->SetRootDirectory(iRootDirectory);


	TInt align=0;
	while (iReader.NextLine(2,keyword)!=KErrEof) {
		if (keyword == EKeywordExtensionRofs)
			break;

		switch (keyword)
		{
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
	
	if(!ParsePatchDllData() )
		return KErrGeneral;

	iReader.MarkNext();			// ready for processing the next extension rom(s)

	if (iMissingFiles!=0)
		return KErrGeneral;
	if (iNumberOfFiles == 0) {
		Print(EError, "No files specified.\n");
		return KErrGeneral;
	}
	return KErrNone;
}
void CObeyFile::ProcessExtensionKeyword(enum EKeyword aKeyword)	{ 

	switch (aKeyword)
	{
	case EKeywordCoreRofsName:
		iKernelRofsName = iReader.DupWord(1);
		return;
	case EKeywordRofsSize:
		Val(iRomSize,iReader.Word(1));
		return;
	case EKeywordVersion:
		{
			istringstream val(iReader.Word(1)); 
			val >> iVersion;
		}
		return;
	case EKeywordRomChecksum:
		Val(iCheckSum,iReader.Word(1)); //--
		return;
	case EKeywordTime:
		iReader.ProcessTime(iTime);
		return;
	case EKeywordRofsAutoSize:
		iAutoSize = ETrue;
		Val(iAutoPageSize , iReader.Word(1)); 
		return;
	default:
		Print(EError,"Keyword '%s' not valid in extension ROFS - line %d\n", iReader.Word(0), iReader.CurrentLine());
		break;
	}
	return;
}
//
// Checks that the obeyfile has supplied enough variables to continue
//
TBool CObeyFile::GotExtensionVariables(MRofsImage* aRom) {

	TBool retVal=ETrue;
	const char* kernelRofsName = iKernelRofsName;

	// Mandatory keywords

	if (iRomSize == 0){
		Print(EAlways,"The size of the extension ROFS has not been supplied.\n");
		Print(EAlways,"Use the keyword \"rofssize\".\n");
		retVal = EFalse;
	}

	// keywords we need if we don't already have a ROFS image to work from
	if (aRom == 0) {
		if (iKernelRofsName == 0) {
			Print(EAlways,"The name of the core ROFS has not been supplied.\n");
			Print(EAlways,"Use the keyword \"rofsname\".\n");
			retVal = EFalse;
		}
	}
	else {
		if (iKernelRofsName != 0){
			Print(EWarning,"Keyword \"rofsname\" ignored.\n");
		}
		kernelRofsName = aRom->RomFileName();
	}

	// validation
	// Apply defaults as necessary
	if (iTime == 0)	{
		Print(ELog, "No timestamp specified. Using current time...\n");
		ObeyFileReader::TimeNow(iTime);
	}

	// fix up "*" in rofsname
	char newname[256];
	char* p=newname;
	char* q=iRomFileName;
	char c;

	while ((c=*q++)!='\0'){
		if (c!='*') {
			*p++=c;
			continue;
		}
		const char *r = kernelRofsName;
		while ((c=*r++)!='\0')
			*p++=c;
	}
	*p++ = '\0';
	delete []iRomFileName;
	size_t len = p - newname ;
	iRomFileName = new char[len];
	memcpy(iRomFileName,newname,len);
	Print(ELog, "\nCreating ROFS image %s\n", iRomFileName);
	return retVal;
}

// Fuction to split patchdata statement 
void CObeyFile::SplitPatchDataStatement(StringVector& aPatchDataTokens) {
	// Get the value of symbol size, address/ordinal and new value 
	// to be patched from the patchdata statement.
	// Syntax of patchdata statements is as follows:
	// 1)	patchdata dll_name  ordinal OrdinalNumber size_in_bytes   new_value 
	// 2)   patchdata dll_name  addr    Address       size_in_bytes   new_value
	for(TInt count=1; count<=5; count++) {
		aPatchDataTokens.push_back(iReader.Word(count));
	}

	// Store the the value of current line which will be used
	// when displaying error messages.
	ostringstream outStrStream;
	outStrStream<<iReader.CurrentLine();
	aPatchDataTokens.push_back(outStrStream.str());
}

TBool CObeyFile::ParsePatchDllData() {
	// Get the list of patchdata statements
	VectorOfStringVector patchDataStatements=iPatchData->GetPatchDataStatements();
	// Get the list of renamed file map
	MapOfString RenamedFileMap=iPatchData->GetRenamedFileMap();

	for(TUint count=0; count < patchDataStatements.size(); count++) {
		
		StringVector strVector = patchDataStatements.at(count);
		string filename=strVector.at(0);
		string lineNoStr = strVector.at(5);
		TUint lineNo = 0 ;
		Val(lineNo,lineNoStr.c_str());
		TRomNode* existingFile = NULL;

		do {
			TRomNode* dir=iRootDirectory;			
			TBool endOfName=EFalse; 
			
			if (!IsValidFilePath(filename.c_str())) {
				Print(EError, "Invalid source path on line %d\n",lineNo);
				return EFalse;
			}
			char* epocStartPtr =NormaliseFileName(filename.c_str());
			char* savedPtr = epocStartPtr;
			if(*epocStartPtr == '/' ||*epocStartPtr == '\\')
				epocStartPtr++ ;
			char* epocEndPtr = epocStartPtr;

			while (!endOfName) {
				endOfName = GetNextBitOfFileName(epocEndPtr);
				if (endOfName) {// file				
					existingFile=dir->FindInDirectory(epocStartPtr);
					if (existingFile) {
						TInt fileCount=0;
						TInt dirCount=0;
						existingFile->CountDirectory(fileCount, dirCount);
						if (dirCount != 0 || fileCount != 0) {
							Print(EError, "Keyword %s not applicable to directories - line %d\n","patchdata",lineNo);
							return EFalse;
						}
					}
				}
				else {// directory				
					TRomNode* subDir = dir->FindInDirectory(epocStartPtr);
					if (!subDir) // sub directory does not exist
						break;
					dir=subDir;
					epocStartPtr = epocEndPtr;
				}
			}
			delete []savedPtr;

			if(!existingFile) {
				// If the E32Image file to be patched is not included then check if the
				// file was renamed.
				MapOfStringIterator RenamedFileMapIterator;
				if ((RenamedFileMapIterator=RenamedFileMap.find(filename)) != RenamedFileMap.end())
					filename = (*RenamedFileMapIterator).second; 				
				else {
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

		string symbolSize=strVector.at(3);
		Val(aSize,symbolSize.c_str());
		string aValue=strVector.at(4);
		Val(aNewValue,aValue.c_str());		

		DllDataEntry *dataEntry = new DllDataEntry(aSize, aNewValue);

		// Set the address of the data or the ordinal number specified in OBY statement.
		string keyword=strVector.at(1);
		string keywordValue=strVector.at(2);

		/* Check for +OFFSET at the end of the ordinal number or address */
		TUint plus = keywordValue.find("+",0);
		if (plus != string::npos) {
			/* Get the offset that we found after the + sign */
			string offset = keywordValue.substr(plus+1);
			Val(aOffset,offset.c_str());

			keywordValue.resize(plus);		
		}
		if(stricmp (keyword.c_str(), "addr") == 0)
			Val(aDataAddr,keywordValue.c_str());

		else 
			Val(aOrdinal,keywordValue.c_str());

		dataEntry->iDataAddress = aDataAddr;
		dataEntry->iOrdinal = aOrdinal;
		dataEntry->iOffset = aOffset;

		existingFile->SetDllData();

		DllDataEntry *aDllDataEntry= existingFile->iEntry->GetFirstDllDataEntry();
		if (aDllDataEntry == NULL) {
			// Set the first node of the patchdata linked list
			aDllDataEntry=dataEntry;
			existingFile->iEntry->SetFirstDllDataEntry(aDllDataEntry);
		}
		else {
			// Goto the last node
			while((aDllDataEntry->NextDllDataEntry()) != NULL) {
				aDllDataEntry = aDllDataEntry->NextDllDataEntry();
			}
			// Add the new node at the end of linked list
			aDllDataEntry->AddDllDataEntry(dataEntry);			
		}
	}
	return ETrue;
}
