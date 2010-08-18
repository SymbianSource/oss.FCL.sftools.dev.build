/*
* Copyright (c) 2008-2009 Nokia Corporation and/or its subsidiary(-ies).
* All rights reserved.
* This component and the accompanying materials are made available
* under the terms of the License "Eclipse Public License v1.0"
* which accompanies this distribution, and is available
* at the URL "http://www.eclipse.org/legal/epl-v10.htm ".
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
#include "pkgfileparser.h"
#ifdef __LINUX__ 
#include <strings.h>
#define stricmp strcasecmp
#define strnicmp strncasecmp
#endif
#include "utf16string.h"

// Parse options lookups
#define MAXTOKENLEN	30
struct SParseToken
{
	char pszOpt[MAXTOKENLEN];
	TUint32 dwOpt;
};

const SParseToken KTokens[] =
{
	{ "if",		IF_TOKEN},
	{ "elseif",	ELSEIF_TOKEN},
	{ "else",	ELSE_TOKEN},
	{ "endif",	ENDIF_TOKEN},
	{ "exists",	EXISTS_TOKEN},
	{ "devprop",DEVCAP_TOKEN},
	{ "appcap",	APPCAP_TOKEN},
	{ "package",DEVCAP_TOKEN},
	{ "appprop",APPCAP_TOKEN},
	{ "not",	NOT_TOKEN},
	{ "and",	AND_TOKEN},
	{ "or",		OR_TOKEN},
	{ "type",	TYPE_TOKEN},
	{ "key",	KEY_TOKEN},
};

#define NUMPARSETOKENS (sizeof(KTokens)/sizeof(SParseToken))

/**
Constructor: PkgParser class
Initilize the parameters to data members.

@internalComponent
@released

@param aFile	- Name of the package script file
*/
PkgParser::PkgParser(const string& aFile) : iPkgFileContent(""),iContentPos(0),iContentStr("") ,iPkgFileName(aFile),iToken(EOF_TOKEN) , iLineNumber(0){
}

/**
Destructor: PkgParser class
Deallocates the memory for data members

@internalComponent
@released
*/
PkgParser::~PkgParser() {
	 
	DeleteAll();
	
}

/**
OpenFile: Opens the package script file

@internalComponent
@released
*/
bool PkgParser::OpenFile() {
	
	UTF16String str ;
	if(!str.FromFile(iPkgFileName.c_str()))
		return false ;
	
	if(!str.ToUTF8(iContentStr)) 		 
		return false ; 
	 
	iPkgFileContent = iContentStr.c_str();
	iContentPos = 0 ;	
	return true ;
}
/** 
 * GetNextChar : iContentStr is a UTF-8 String, of which char is as follows:
 * 
 *0000-007F | 0xxxxxxx
 *0080-07FF | 110xxxxx 10xxxxxx
 *0800-FFFF | 1110xxxx 10xxxxxx 10xxxxxx
 * 10000-10FFFF | 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
 */
void PkgParser::GetNextChar() {		
	if(iContentPos < iContentStr.length()){
		if(0 == (iPkgFileContent[iContentPos] & 0x80))
			iContentPos++;
		else if(0xC0 == (iPkgFileContent[iContentPos]  & 0xE0))
			iContentPos += 2 ;
		else if(0xE0 == (iPkgFileContent[iContentPos]  & 0xF0))
			iContentPos += 3 ;
		else
			iContentPos += 4 ;
		if(iContentPos >= iContentStr.length())
			iContentPos = iContentStr.length() ;
	} 
}
/**
GetEmbeddedSisList: Returns the embedded sis file list

@internalComponent
@released

@param embedSisList	- reference to sis file list structure
*/
void PkgParser::GetEmbeddedSisList(SISFILE_LIST& embedSisList) {
	embedSisList = iEmbedSisFiles;
}

/**
GetInstallOptions: Returns the install options read from the package file

@internalComponent
@released

@param aOptions	- reference to the string list structure
*/
void PkgParser::GetInstallOptions(FILE_LIST& aOptions) {
	aOptions = iInstallOptions;
}

/**
GetLanguageList: Returns the language list read from the package file

@internalComponent
@released

@param langList	- reference to the language list structure
*/
void PkgParser::GetLanguageList(LANGUAGE_LIST& langList){
	langList = iLangList;
}

/**
GetHeader: Returns the header details read from the package file

@internalComponent
@released

@param pkgHeader	- reference to the package header structure
*/
void PkgParser::GetHeader(PKG_HEADER& pkgHeader) {
	pkgHeader = iPkgHeader;
}

/**
GetCommandList: Returns the package body details read from the package file

@internalComponent
@released

@param cmdList	- reference to the command list structure
*/
void PkgParser::GetCommandList(CMDBLOCK_LIST& cmdList) {
	cmdList = iPkgBlock;
}

/**
ParsePkgFile: Parses the package file

@internalComponent
@released
*/
void PkgParser::ParsePkgFile() {
	if(!OpenFile())
		throw SisUtilsException(iPkgFileName.c_str(), "Could not open file"); 
	GetNextToken ();
	while(iToken!=EOF_TOKEN) {
		ParseEmbeddedBlockL();
		switch (iToken)
		{
		case '&':
			GetNextToken ();
			ParseLanguagesL();
			break;
		case '#':
			GetNextToken ();
			ParseHeaderL();
			break;
		case '%':
			GetNextToken ();
			ParseVendorNameL();
			break;
		case '=':
			GetNextToken ();
			ParseLogoL();
			break;
		case '(':
			GetNextToken ();
			ParseDependencyL();
			break;
		case ':':
			GetNextToken ();
			ParseVendorUniqueNameL();
			break;
		case '[':
			GetNextToken ();
			ParseTargetDeviceL();
			break;
		case EOF_TOKEN:
			break;
		default:
			ParserError("Unexpected token");
			break;
		}
	}
}

/**
ParseLanguagesL: Parses the language section

@internalComponent
@released
*/
void PkgParser::ParseLanguagesL(){
	TUint32 iLangCode = 0;
	TUint32 dialect = 0;
	
	while (true){
		if (iToken==ALPHA_TOKEN){
			iLangCode = GetLanguageCode(iTokenVal.iString);
		}
		else if (iToken==NUMERIC_TOKEN && iTokenVal.iNumber>=0 && iTokenVal.iNumber<=1000)	{
			iLangCode = (iTokenVal.iNumber);
		}

		GetNextToken ();

		// Check if a dialect is defined
		if (iToken == '(')
		{
			GetNumericToken();
			// Modify the last added language code, combining it with dialect code
			dialect = (iTokenVal.iNumber);
			GetNextToken ();
			GetNextToken ();
		}
		const char* temp = GetLanguageName(iLangCode);
		if(NULL != temp){		 
			AddLanguage(string(temp), iLangCode, dialect);
		}

		if (iToken!=',')
			return;
		GetNextToken ();
	}
}


/**
ParseHeaderL: Parses the package header section

@internalComponent
@released
*/
void PkgParser::ParseHeaderL() {
	if (!iLangList.size()) {
		//No languages defined, assuming English."
		AddLanguage("EN", PkgLanguage::ELangEnglish, 0);
	}
	
	// process application names
	ExpectToken('{');
	for (TUint16 wNumLangs = 0; wNumLangs < iLangList.size(); wNumLangs++) 	{
		GetNextToken ();
		ExpectToken(QUOTED_STRING_TOKEN);
		iPkgHeader.iPkgNames.push_back(string(iTokenVal.iString));
		GetNextToken ();
		if (wNumLangs < (iLangList.size()-1) ) {
			ExpectToken(',');
		}
	}
	ExpectToken('}');
	GetNextToken (); 
	
	ExpectToken(',');
	GetNextToken ();
	ExpectToken('(');
	GetNextToken ();
	
	ExpectToken(NUMERIC_TOKEN);
	iPkgHeader.iPkgUID = iTokenVal.iNumber;
	GetNextToken (); 
	ExpectToken(')'); 

	GetNextToken ();
	ExpectToken(',');
	GetNextToken ();
	
	ExpectToken(NUMERIC_TOKEN);
	iPkgHeader.iMajorVersion = iTokenVal.iNumber;
	GetNextToken ();
	ExpectToken(',');
	GetNextToken ();
	
	ExpectToken(NUMERIC_TOKEN);
	iPkgHeader.iMinorVersion = iTokenVal.iNumber;
	GetNextToken ();
	ExpectToken(',');
	GetNextToken ();
	
	ExpectToken(NUMERIC_TOKEN);
	iPkgHeader.iBuildVersion = iTokenVal.iNumber;
	GetNextToken ();
	
	// Parse any options
	while (iToken==',') {
		GetNextToken ();
		if (iToken==TYPE_TOKEN) {
			GetNextToken ();
			ExpectToken('=');
			GetNextToken ();
			iPkgHeader.iPkgType = iTokenVal.iString;
			GetNextToken ();
		}
		else
			GetNextToken ();
	}
}

/**
ParseEmbeddedBlockL: Parses the package body block

@internalComponent
@released
*/
void PkgParser::ParseEmbeddedBlockL () {
	while(iToken!=EOF_TOKEN) {
		switch (iToken) {
		case QUOTED_STRING_TOKEN:
			ParseFileL ();
			break;
		case '@':
			GetNextToken ();
			ParsePackageL ();
			break;
		case '!':
			GetNextToken ();
			ParseOptionsBlockL();
			break;
		case '+':
			GetNextToken ();
			ParsePropertyL ();
			break;
		case IF_TOKEN:
			GetNextToken ();
			ParseIfBlockL ();
			break;
		case ';' :
			ParseCommentL ();
			break;
		default :
			return;
		}
	}
}

/**
ParseFileL: Parses the file list section

@internalComponent
@released
*/
void PkgParser::ParseFileL() {
	PCMD_BLOCK pCmdBlock = 0;
	PINSTALLFILE_LIST pFileList = 0;
	
	string sourceFile (iTokenVal.iString);
	
	// Linux and windows both support forward slashes so if source path is given '\' need to convert
	// in forward slash for compatibility.
	char* pBuffer = const_cast<char*>(sourceFile.data());
	char* pCurrent = pBuffer;
	while (pBuffer && *pBuffer && (pCurrent = strchr(pBuffer,'\\')) != NULL) {
		*pCurrent = '/';
		pBuffer = pCurrent + 1;
	}
	
	GetNextToken ();
	
	ExpectToken('-');
	GetNextToken ();
	
	ExpectToken(QUOTED_STRING_TOKEN);
	
	string destinationFile (iTokenVal.iString);
	
	// SWI only supports backward slashesh so need to convert destination path in backward slash if
	// user gives '/' in Linux.
	pBuffer = const_cast<char*>(destinationFile.data());
	pCurrent = pBuffer;
	while (pBuffer && *pBuffer && (pCurrent = strchr(pBuffer,'/')) != NULL) {
		*pCurrent = '\\';
		pBuffer = pCurrent + 1;
	}
	
	GetNextToken ();
	
	// Test for options
	if (iToken!=',') {
		pCmdBlock = new CMD_BLOCK;
		pFileList = new INSTALLFILE_LIST;

		pCmdBlock->iCmdType = INSTALLFILE;
		pCmdBlock->iInstallFileList = pFileList;

		pFileList->iLangDepFlag = 0;
		pFileList->iSourceFiles.push_back(sourceFile);
		pFileList->iDestFile = destinationFile;

		iPkgBlock.push_back(pCmdBlock);
	}
	else {	
		bool needAdd = false;
		while(iToken==',') {
			GetNextToken ();
			string installOption = iTokenVal.iString;
			if((installOption == "FF") || (installOption == "FILE")) {
				needAdd = true;
			}
			GetNextToken ();
		}
		if (needAdd) {
			pCmdBlock = new CMD_BLOCK;
			pFileList = new INSTALLFILE_LIST;

			pCmdBlock->iCmdType = INSTALLFILE;
			pCmdBlock->iInstallFileList = pFileList;

			pFileList->iLangDepFlag = 0;
			pFileList->iSourceFiles.push_back(sourceFile);
			pFileList->iDestFile = destinationFile;
		
			iPkgBlock.push_back(pCmdBlock);
		}
	}
}

/**
ParseIfBlockL: Parses the conditional installation body

@internalComponent
@released
*/
void PkgParser::ParseIfBlockL() {
	PCMD_BLOCK pCmdBlock = 0; 

	//IF
	pCmdBlock = new CMD_BLOCK;
	pCmdBlock->iCmdType = IF;
	ParseLogicalOp(pCmdBlock->iCmdExpr);
	iPkgBlock.push_back(pCmdBlock);

	ParseEmbeddedBlockL ();
	
	while (iToken==ELSEIF_TOKEN){
		GetNextToken ();
		//ELSEIF
		pCmdBlock = new CMD_BLOCK;
		pCmdBlock->iCmdType = ELSEIF;
		ParseLogicalOp(pCmdBlock->iCmdExpr);
		iPkgBlock.push_back(pCmdBlock);

		ParseEmbeddedBlockL ();
	}
	
	if (iToken==ELSE_TOKEN) {
		GetNextToken ();
		//ELSEIF
		pCmdBlock = new CMD_BLOCK;
		pCmdBlock->iCmdType = ELSE;
		iPkgBlock.push_back(pCmdBlock);

		ParseEmbeddedBlockL ();
	}
	
	ExpectToken(ENDIF_TOKEN);
	//ENDIF
	pCmdBlock = new CMD_BLOCK;
	pCmdBlock->iCmdType = ENDIF;
	iPkgBlock.push_back(pCmdBlock);

	GetNextToken ();
}

/**
ParseLogicalOp: Parses the logical expression

@internalComponent
@released
*/
void PkgParser::ParseLogicalOp (string& aExpression) {
    ParseRelation (aExpression);
	switch (iToken) {
	case AND_TOKEN:
	case OR_TOKEN:
		{
			if (iToken==AND_TOKEN)
				aExpression.append(" && ");
			else
				aExpression.append(" || ");
			GetNextToken ();
			ParseLogicalOp (aExpression);
		}
		break;
	}
}

/**
ParseRelation: Parses the relational expression

@internalComponent
@released
*/
void PkgParser::ParseRelation(string& aExpression) {
    ParseUnary (aExpression);
	switch (iToken)
	{
	case '=':
	case '>':
	case '<':
	case GE_TOKEN:
	case LE_TOKEN:
	case NE_TOKEN:
	case APPCAP_TOKEN:
		{
			switch (iToken)
			{
			case '=':
				aExpression.append(" == ");
				break;
			case '>':
				aExpression.append(" > ");
				break;
			case '<':
				aExpression.append(" < ");
				break;
			case GE_TOKEN:
				aExpression.append(" >= ");
				break;
			case LE_TOKEN:
				aExpression.append(" <= ");
				break;
			case NE_TOKEN:
				aExpression.append(" != ");
				break;
			case APPCAP_TOKEN:
				aExpression.append(" APPPROP ");
				break;
			}
			GetNextToken ();
			ParseUnary (aExpression);
			break;
		}
	}
}

/**
ParseUnary: Parses the unary expression

@internalComponent
@released
*/
void PkgParser::ParseUnary(string& aExpression) {
    switch (iToken) 	{
	case NOT_TOKEN:
		aExpression.append(" !");
		GetNextToken ();
		ParseUnary (aExpression);
		break;
	case EXISTS_TOKEN:
	case DEVCAP_TOKEN:
		{	// 1 arg function
			TInt token=iToken;
			GetNextToken ();
			ExpectToken('(');
			GetNextToken ();
			if (token==EXISTS_TOKEN)
			{
				aExpression.append("EXISTS(\"");
				ExpectToken(QUOTED_STRING_TOKEN);
				GetNextToken ();
				aExpression.append(string(iTokenVal.iString));
				aExpression.append("\")");
			}
			else
			{
				aExpression.append("DEVCAP(");
				ParseUnary (aExpression);
				aExpression.append(")");
			}
			ExpectToken(')');
			GetNextToken ();
			break;
		}
	default:
		ParseFactor (aExpression);
		break;
	}
}

/**
ParseFactor: Parses the expression factor

@internalComponent
@released
*/
void PkgParser::ParseFactor(string& aExpression) {
    switch (iToken) {
	case '(':
		{
			aExpression.append("(");
			GetNextToken ();
			ParseLogicalOp (aExpression); 
			ExpectToken(')'); 
			aExpression.append(")");
		}
		break;
	case QUOTED_STRING_TOKEN:
	case ALPHA_TOKEN:
	case NUMERIC_TOKEN:
		{
			switch (iToken)
			{
			case QUOTED_STRING_TOKEN:
				aExpression.append("\"");
				aExpression.append(iTokenVal.iString);
				aExpression.append("\"");
				break;
			case ALPHA_TOKEN:
				if(!strnicmp(iTokenVal.iString,"option",6)) {
					aExpression.append(" defined(");
					aExpression.append(iTokenVal.iString); 
					ExpectToken(')'); 
				}
				else {
					aExpression.append(iTokenVal.iString);
				}
				break;
			case NUMERIC_TOKEN:
				{
					ostringstream str;

					str << "(0x" << setbase(16) << iTokenVal.iNumber << ")";
					aExpression.append(str.str());
				}
				break;
			}
		}
		break;
	default:
		ParserError("ErrBadCondFormat");
	}
	GetNextToken ();
}


/**
ParsePackageL: Parses the embedded package section

@internalComponent
@released
*/
void PkgParser::ParsePackageL() {
	PCMD_BLOCK pCmdBlock = 0;
	TInt found = 0;

	ExpectToken(QUOTED_STRING_TOKEN);

	//if the sis file already exists then skip it
	SISFILE_LIST::iterator begin = iEmbedSisFiles.begin();
	SISFILE_LIST::iterator end = iEmbedSisFiles.end();

	while(begin != end) {
		if((*begin) == iTokenVal.iString) {
			found = 1;
			break;
		}
		++begin;
	}

	if(!found)
		iEmbedSisFiles.push_back(string(iTokenVal.iString));
		
	//add as a command block as well
	 
	pCmdBlock = new CMD_BLOCK;

	pCmdBlock->iCmdType = PACKAGE;
	pCmdBlock->iInstallFileList = 0;
	pCmdBlock->iCmdExpr = iTokenVal.iString;

	iPkgBlock.push_back(pCmdBlock);
	 


	GetNextToken ();

	ExpectToken(',');
	GetNextToken ();
	ExpectToken('(');
	GetNextToken ();
	ExpectToken(NUMERIC_TOKEN);
	GetNextToken ();
	ExpectToken(')');
	GetNextToken ();
}

/**
ParseCommentL: Parses the comment section
  Parses a comment line (Does nothing, just throws the line away)

@internalComponent
@released
*/
void PkgParser::ParseCommentL() {
	// parse to end of line
	while (GetCurChar() && (GetCurChar()!='\n')) GetNextChar();
	GetNextToken ();
}

/**
ParseOptionsBlockL: Parses the install options section

@internalComponent
@released
*/
void PkgParser::ParseOptionsBlockL() {
	TUint16 wNumLangs;
	
	ExpectToken('(');
	GetNextToken ();
	
	for (;;){
		ExpectToken('{');
		GetNextToken ();
		
		wNumLangs = 0;
		while (wNumLangs < iLangList.size()){
			ExpectToken(QUOTED_STRING_TOKEN);
			iInstallOptions.push_back(string(iTokenVal.iString));
			GetNextToken ();
			if (wNumLangs < iLangList.size() - 1){
				ExpectToken(',');
				GetNextToken ();
			}
			wNumLangs++;
		}
		
		ExpectToken('}');
		GetNextToken ();
		if (iToken!=',') break;
		GetNextToken ();
	}
	ExpectToken(')'); 
	GetNextToken ();	
}

/**
ParsePropertyL: Parses the capability options section

@internalComponent
@released
*/
void PkgParser::ParsePropertyL() {
	ExpectToken('(');
	do {
		GetNextToken ();		
		ExpectToken(NUMERIC_TOKEN);
		GetNextToken ();
		ExpectToken('=');
		GetNextToken ();
		ExpectToken(NUMERIC_TOKEN);
		GetNextToken ();
	} while (iToken==','); 
	ExpectToken(')'); 
	GetNextToken ();
}

/**
ParseVendorNameL: Parses the vendor options section

@internalComponent
@released
*/
void PkgParser::ParseVendorNameL() {
	ExpectToken('{');
	for (TUint16 wNumLangs = 0; wNumLangs < iLangList.size(); wNumLangs++) {
		GetNextToken ();
		ExpectToken(QUOTED_STRING_TOKEN);
		GetNextToken ();
		if (wNumLangs < iLangList.size() -1 )
		{
			ExpectToken(',');
		}
	}
	ExpectToken('}');
	GetNextToken ();
}

/**
ParseLogoL: Parses the logo options section

@internalComponent
@released
*/
void PkgParser::ParseLogoL() {
	ExpectToken (QUOTED_STRING_TOKEN);
	GetNextToken ();
	ExpectToken(',');
	GetNextToken ();
	ExpectToken (QUOTED_STRING_TOKEN);
	GetNextToken ();
	if (iToken==',')
	{
		GetNextToken ();
		ExpectToken (QUOTED_STRING_TOKEN);
		GetNextToken ();
	}
}

/**
ParseVersion: Parses the version details

@internalComponent
@released
*/
void PkgParser::ParseVersion() {
	GetNextToken();
	ExpectToken(NUMERIC_TOKEN);

	GetNextToken();
	ExpectToken(',');
	GetNextToken();
	ExpectToken(NUMERIC_TOKEN);

	GetNextToken();
	ExpectToken(',');
	GetNextToken();
	ExpectToken(NUMERIC_TOKEN);

	GetNextToken();
}

/**
ParseDependencyL: Parses the dependency package section

@internalComponent
@released
*/
void PkgParser::ParseDependencyL() {
	ExpectToken(NUMERIC_TOKEN);
	GetNextToken (); 
	ExpectToken(')'); 
	GetNextToken ();
	ExpectToken(',');

	ParseVersion();
	if (iToken == '~') {
		ParseVersion();
		ExpectToken(',');
	}
	
	GetNextToken ();
	ExpectToken('{');
	for (TUint numLangs = 0; numLangs < iLangList.size(); ++numLangs) {
		GetNextToken ();
		ExpectToken(QUOTED_STRING_TOKEN);
		GetNextToken ();
		if (numLangs < (iLangList.size() - 1))
			ExpectToken(',');
	}
	ExpectToken('}');
	GetNextToken ();
}

/**
ParseVendorUniqueNameL: Parses the vendor unique name section

@internalComponent
@released
*/
void PkgParser::ParseVendorUniqueNameL() {
	ExpectToken(QUOTED_STRING_TOKEN);
	GetNextToken ();
}

/**
ParseTargetDeviceL: Parses the target device name section

@internalComponent
@released
*/
void PkgParser::ParseTargetDeviceL() {
	ExpectToken(NUMERIC_TOKEN);
	GetNextToken ();
	ExpectToken(']');
	GetNextToken ();
	ExpectToken(',');
	
	ParseVersion();
	if (iToken == '~') {
		ParseVersion();
		ExpectToken(',');
	}
	GetNextToken ();
	ExpectToken('{');
	
	// must do this before adding language strings	
	for (TUint numLangs = 0; numLangs < iLangList.size(); ++numLangs) {
		GetNextToken ();
		ExpectToken(QUOTED_STRING_TOKEN);
		GetNextToken ();
		if (numLangs < (iLangList.size() - 1))
			ExpectToken(',');
	}
	ExpectToken('}');
	GetNextToken ();
}
 

 

/**
GetNextToken: Reads the next valid token from the package file

@internalComponent
@released
*/
void PkgParser::GetNextToken () {
	// skip any white space & newLine's
	while (GetCurChar() == '\n' || isspace(GetCurChar()) || GetCurChar() == (char)0xA0) {
		if (GetCurChar() == '\n') ++iLineNumber;
		GetNextChar();
	}
	
	if (GetCurChar() == '\0')
		iToken=EOF_TOKEN;
	else if (IsNumericToken()){
		GetNumericToken();
		iToken=NUMERIC_TOKEN;
	}
	else if (isalpha(GetCurChar())){ // have some alphanumeric text
		GetAlphaNumericToken();
		iToken=ALPHA_TOKEN;
		// check if it is a keyword
		for(unsigned short wLoop = 0; wLoop < NUMPARSETOKENS; wLoop++){
			if(stricmp(iTokenVal.iString,KTokens[wLoop].pszOpt) == 0){
				iToken=KTokens[wLoop].dwOpt;
				break;
			}
		}
	}
	else if (GetCurChar() == '\"')	{ // have a quoted string
		GetStringToken();
		iToken=QUOTED_STRING_TOKEN;
	}
	else if (GetCurChar() == '>')	{
		GetNextChar();
		if (GetCurChar() == '='){
			iToken=GE_TOKEN;
			GetNextChar();
		}
		else
			iToken='>';
	}
	else if (GetCurChar() == '<'){
		// check if start of an escaped string, e.g. <123>"abc"
		if (GetStringToken())
			iToken=QUOTED_STRING_TOKEN;
		else{
			GetNextChar();
			if (GetCurChar() == '='){
				iToken=LE_TOKEN;
				GetNextChar();
			}
			else if (GetCurChar() == '>'){
				iToken=NE_TOKEN;
				GetNextChar();
			}
			else
				iToken='<';
		}
	}
	else{
		iToken=GetCurChar();
		GetNextChar();
	}
}

/**
GetStringToken: Reads the string token from the package file

@internalComponent
@released
*/
bool PkgParser::GetStringToken() {
	TUint32 wCount = 0;
	bool done=false;
	bool finished=false;
	TUint32 escapeChars = 0;
	
	while (!finished){
		if (GetCurChar() == '\"'){
			GetNextChar();
			while(GetCurChar() && GetCurChar() != '\"'){
				if(wCount < (MAX_STRING - 1))
					iTokenVal.iString[wCount++] = GetCurChar();
				else //We dont want the string with length greater than MAX_STRING to be cut off silently
					ParserError("Bad string");
				GetNextChar();
			}
			if(GetCurChar() == '\0')
				ParserError("Bad string");
			GetNextChar();
			done=true;
		}
		if (GetCurChar() == '<'){
			iTokenVal.iString[wCount] = L'\0';
			escapeChars=ParseEscapeChars();
			if (escapeChars>0)
			{
				done=true;
				wCount+=escapeChars;
				if (wCount>=MAX_STRING) wCount=MAX_STRING-1;
			}
		}
		if (escapeChars==0 || GetCurChar() != '\"')
			finished=true;
	}
	
	iTokenVal.iString[wCount] = L'\0';
	return done;
}

/**
ParseEscapeChars: Parses the escape sequence characters

@internalComponent
@released
*/
TUint16 PkgParser::ParseEscapeChars() {
	TUint16 found=0;
	char temp[MAX_STRING];
 
	while (GetCurChar() == '<'){
		strcpy(temp,iTokenVal.iString);
		TUint savedPos = iContentPos ;	
		try	{
			GetNextChar();
			GetNumericToken();
			if (GetCurChar()=='>')
				found++;
			else {
				iContentPos = savedPos ;
				break;
			}
		}
		catch (...)	{
			strcpy(iTokenVal.iString,temp);
			iContentPos = savedPos ;
			break;
		}
		TUint32 num=iTokenVal.iNumber;
		// watch for CP1252 escapes which aren't appropriate for UNICODE
		if (num>=0x80 && num<=0x9F) ParserError("Invalid Escape");
		TUint32 len=strlen(temp);
		memcpy(iTokenVal.iString,temp, len + 1);
		if ((len + 2) <= MAX_STRING){
			iTokenVal.iString[len]= static_cast<char>(num);
			len++;
			iTokenVal.iString[len]='\0';
		}
		GetNextChar();
	}
 
	return found;
}

/**
GetAlphaNumericToken: Parse an alphanumeric string from the input line

@internalComponent
@released
*/
void PkgParser::GetAlphaNumericToken()
{
	size_t length = 0;
	TUint savedPos = iContentPos ;	
	TUint bound = iContentStr.length();
	while((iContentPos < bound) && 
		(isalnum(iPkgFileContent[iContentPos]) || (iPkgFileContent[iContentPos] == '_'))) {
		iContentPos ++ ;
		if(length < (MAX_STRING - 1)) length ++ ; 
	}
	memcpy(iTokenVal.iString,&iPkgFileContent[savedPos],length);	
	iTokenVal.iString[length] = 0;
}

/**
IsNumericToken: Determines if the next lexeme is a numeric token

@internalComponent
@released
*/
bool PkgParser::IsNumericToken() { 
	char ch = iPkgFileContent[iContentPos];
	if (isdigit(ch))
		return true ;
	else if (ch == '+' || ch == '-'){
		// we may have a number but we must look ahead one char to be certain	
		return isdigit(iPkgFileContent[iContentPos + 1]) != 0; 
	}	
	return false ;
}

/**
GetNumericToken: Parse a number from the input line

@internalComponent
@released
*/
void PkgParser::GetNumericToken() {
	 
	int base = 10; 
	const char* temp = &iPkgFileContent[iContentPos] ;
	if(*temp == '0' &&( temp[1] == 'x' || temp[1] == 'X')){
		base = 16 ;
		temp += 2;
	}
	char *end = const_cast<char*>(temp) ;
	iTokenVal.iNumber = strtoul(temp, &end, base);
	iContentPos = end - iPkgFileContent ;
}

/**
AddLanguage: Updates the language list structure

@internalComponent
@released

@param aLang - Name of the language
@param aCode - Language code
@param aDialect - Language dialect code
*/
void PkgParser::AddLanguage(const string& aLang, TUint32 aCode, TUint32 aDialect) {
	PLANG_LIST lc = new LANG_LIST;
	
	lc->iLangName = aLang;
	lc->iLangCode = aCode;
	lc->iDialectCode = aDialect;

	iLangList.push_back(lc);
}

/**
DeleteAll: Deallocates memory for the data members

@internalComponent
@released
*/
void PkgParser::DeleteAll() {
	while(iPkgBlock.size() > 0){
		PCMD_BLOCK ptemp = 0;

		ptemp = iPkgBlock.front();
		iPkgBlock.pop_front();

		if(ptemp->iCmdType == INSTALLFILE)
		{
			delete ptemp->iInstallFileList;
		}
		delete ptemp;
	}


	LANGUAGE_LIST::iterator begin = iLangList.begin();
	LANGUAGE_LIST::iterator end = iLangList.end();
	while(begin != end)	{
		PLANG_LIST ptemp = 0;
		ptemp = (*begin);

		if(ptemp)
			delete ptemp;
		++begin;
	}
	iLangList.clear(); 
	iPkgFileContent = "" ;
	iContentPos = 0 ;
	iContentStr.clear(); 
	
}

/**
ParserError: Throws exception with the given error message

@internalComponent
@released

@param msg - error message to be thrown
*/
void PkgParser::ParserError(const char* aMsg) {
	ostringstream str;
	str << iPkgFileName.c_str() << "(" << iLineNumber << "): " << aMsg;
	throw SisUtilsException("PakageFile-Parser Error", str.str().c_str());
}
