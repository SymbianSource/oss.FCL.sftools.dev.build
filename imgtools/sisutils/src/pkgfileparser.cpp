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
#include "pkgfileparser.h"

// Parse options lookups
#define MAXTOKENLEN	30
struct SParseToken
{
	WCHAR pszOpt[MAXTOKENLEN];
	DWORD dwOpt;
};

const SParseToken KTokens[] =
{
	{L"if",		IF_TOKEN},
	{L"elseif",	ELSEIF_TOKEN},
	{L"else",	ELSE_TOKEN},
	{L"endif",	ENDIF_TOKEN},
	{L"exists",	EXISTS_TOKEN},
	{L"devprop",DEVCAP_TOKEN},
	{L"appcap",	APPCAP_TOKEN},
	{L"package",DEVCAP_TOKEN},
	{L"appprop",APPCAP_TOKEN},
	{L"not",	NOT_TOKEN},
	{L"and",	AND_TOKEN},
	{L"or",		OR_TOKEN},
	{L"type",	TYPE_TOKEN},
	{L"key",	KEY_TOKEN},
};
#define NUMPARSETOKENS (sizeof(KTokens)/sizeof(SParseToken))

/**
Constructor: PkgParser class
Initilize the parameters to data members.

@internalComponent
@released

@param aFile	- Name of the package script file
*/
PkgParser::PkgParser(String aFile) : iPkgFile(aFile), m_nLineNo(0)
{
}

/**
Destructor: PkgParser class
Deallocates the memory for data members

@internalComponent
@released
*/
PkgParser::~PkgParser()
{
	if(iPkgHandle != INVALID_HANDLE_VALUE)
	{
		::CloseHandle(iPkgHandle);
	}

	DeleteAll();
}

/**
OpenFile: Opens the package script file

@internalComponent
@released
*/
int PkgParser::OpenFile()
{
	iPkgHandle = ::CreateFileW(string2wstring(iPkgFile).data(),GENERIC_READ,0,NULL,OPEN_EXISTING,FILE_ATTRIBUTE_NORMAL,NULL);
	
	return (iPkgHandle != INVALID_HANDLE_VALUE) ? 1 : 0;
}

/**
GetEmbeddedSisList: Returns the embedded sis file list

@internalComponent
@released

@param embedSisList	- reference to sis file list structure
*/
void PkgParser::GetEmbeddedSisList(SISFILE_LIST& embedSisList)
{
	embedSisList = iEmbedSisFiles;
}

/**
GetInstallOptions: Returns the install options read from the package file

@internalComponent
@released

@param aOptions	- reference to the string list structure
*/
void PkgParser::GetInstallOptions(FILE_LIST& aOptions)
{
	aOptions = iInstallOptions;
}

/**
GetLanguageList: Returns the language list read from the package file

@internalComponent
@released

@param langList	- reference to the language list structure
*/
void PkgParser::GetLanguageList(LANGUAGE_LIST& langList)
{
	langList = iLangList;
}

/**
GetHeader: Returns the header details read from the package file

@internalComponent
@released

@param pkgHeader	- reference to the package header structure
*/
void PkgParser::GetHeader(PKG_HEADER& pkgHeader)
{
	pkgHeader = iPkgHeader;
}

/**
GetCommandList: Returns the package body details read from the package file

@internalComponent
@released

@param cmdList	- reference to the command list structure
*/
void PkgParser::GetCommandList(CMDBLOCK_LIST& cmdList)
{
	cmdList = iPkgBlock;
}

/**
ParsePkgFile: Parses the package file

@internalComponent
@released
*/
void PkgParser::ParsePkgFile()
{
	if(!OpenFile())
	{
		throw SisUtilsException((char*)iPkgFile.data(), "Could not open file");
	}

	GetNextChar();

	// skip unicode marker if present
	if(m_pkgChar==0xFEFF) GetNextChar();

	GetNextToken ();
	while(m_token!=EOF_TOKEN)
	{
		ParseEmbeddedBlockL();
		switch (m_token)
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
void PkgParser::ParseLanguagesL()
{
	unsigned long langCode = 0;
	unsigned long dialect = 0;
	
	while (true)
	{
		if (m_token==ALPHA_TOKEN)
		{
			langCode = PkgLanguage::GetLanguageCode(m_tokenValue.pszString);
		}
		else if (m_token==NUMERIC_TOKEN && m_tokenValue.dwNumber>=0 && m_tokenValue.dwNumber<=1000)
		{
			langCode = (m_tokenValue.dwNumber);
		}

		GetNextToken ();

		// Check if a dialect is defined
		if (m_token == '(')
		{
			GetNumericToken();
			// Modify the last added language code, combining it with dialect code
			dialect = (m_tokenValue.dwNumber);
			GetNextToken ();
			GetNextToken ();
		}
		AddLanguage(wstring2string(PkgLanguage::GetLanguageName(langCode)), langCode, dialect);

		if (m_token!=',')
			return;
		GetNextToken ();
	}
}


/**
ParseHeaderL: Parses the package header section

@internalComponent
@released
*/
void PkgParser::ParseHeaderL()
{
	if (!iLangList.size())
	{
		//No languages defined, assuming English."
		AddLanguage("EN", PkgLanguage::ELangEnglish, 0);
	}
	
	// process application names
	ExpectToken('{');
	for (WORD wNumLangs = 0; wNumLangs < iLangList.size(); wNumLangs++)
	{
		GetNextToken ();
		ExpectToken(QUOTED_STRING_TOKEN);
		iPkgHeader.pkgNameList.push_back(wstring2string(m_tokenValue.pszString));
		GetNextToken ();
		if (wNumLangs < (iLangList.size()-1) )
		{
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
	iPkgHeader.pkgUid = m_tokenValue.dwNumber;
	GetNextToken ();
	
	ExpectToken(')');
	GetNextToken ();
	ExpectToken(',');
	GetNextToken ();
	
	ExpectToken(NUMERIC_TOKEN);
	iPkgHeader.vMajor = m_tokenValue.dwNumber;
	GetNextToken ();
	ExpectToken(',');
	GetNextToken ();
	
	ExpectToken(NUMERIC_TOKEN);
	iPkgHeader.vMinor = m_tokenValue.dwNumber;
	GetNextToken ();
	ExpectToken(',');
	GetNextToken ();
	
	ExpectToken(NUMERIC_TOKEN);
	iPkgHeader.vBuild = m_tokenValue.dwNumber;
	GetNextToken ();
	
	// Parse any options
	while (m_token==',')
	{
		GetNextToken ();
		if (m_token==TYPE_TOKEN)
		{
			GetNextToken ();
			ExpectToken('=');
			GetNextToken ();
			iPkgHeader.pkgType = wstring2string(m_tokenValue.pszString);
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
void PkgParser::ParseEmbeddedBlockL ()
{
	while(m_token!=EOF_TOKEN)
	{
		switch (m_token)
		{
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
void PkgParser::ParseFileL()
{
	PCMD_BLOCK pCmdBlock = 0;
	PINSTALLFILE_LIST pFileList = 0;
	
	std::wstring sourceFile (m_tokenValue.pszString);
	
	// Linux and windows both support forward slashes so if source path is given '\' need to convert
	// in forward slash for compatibility.
	wchar_t *pBuffer = (wchar_t*)sourceFile.c_str();
	wchar_t *pCurrent = pBuffer;
	while (pBuffer && *pBuffer && (pCurrent = wcschr(pBuffer,L'\\')) != NULL)
	{
		*pCurrent = L'/';
		pBuffer = pCurrent + 1;
	}
	
	GetNextToken ();
	
	ExpectToken('-');
	GetNextToken ();
	
	ExpectToken(QUOTED_STRING_TOKEN);
	
	std::wstring destinationFile (m_tokenValue.pszString);
	
	// SWI only supports backward slashesh so need to convert destination path in backward slash if
	// user gives '/' in Linux.
	pBuffer = (wchar_t*)destinationFile.c_str();
	pCurrent = pBuffer;
	while (pBuffer && *pBuffer && (pCurrent = wcschr(pBuffer,L'/')) != NULL)
	{
		*pCurrent = L'\\';
		pBuffer = pCurrent + 1;
	}
	
	GetNextToken ();
	
	// Test for options
	if (m_token!=',')
	{
		pCmdBlock = new CMD_BLOCK;
		pFileList = new INSTALLFILE_LIST;

		pCmdBlock->cmdType = INSTALLFILE;
		pCmdBlock->iInstallFileList = pFileList;

		pFileList->langDepFlg = 0;
		pFileList->srcFiles.push_back(wstring2string(sourceFile));
		pFileList->destFile = wstring2string(destinationFile);

		iPkgBlock.push_back(pCmdBlock);
	}
	else
	{	
		bool needAdd = false;
		while(m_token==',')
		{
			GetNextToken ();
			std::wstring installOption = m_tokenValue.pszString;
			if((installOption == L"FF") || (installOption == L"FILE"))
			{
				needAdd = true;
			}
			GetNextToken ();
		}
		if (needAdd)
		{
			pCmdBlock = new CMD_BLOCK;
			pFileList = new INSTALLFILE_LIST;

			pCmdBlock->cmdType = INSTALLFILE;
			pCmdBlock->iInstallFileList = pFileList;

			pFileList->langDepFlg = 0;
			pFileList->srcFiles.push_back(wstring2string(sourceFile));
			pFileList->destFile = wstring2string(destinationFile);
		
			iPkgBlock.push_back(pCmdBlock);
		}
	}
}

/**
ParseIfBlockL: Parses the conditional installation body

@internalComponent
@released
*/
void PkgParser::ParseIfBlockL()
{
	PCMD_BLOCK pCmdBlock = 0; 

	//IF
	pCmdBlock = new CMD_BLOCK;
	pCmdBlock->cmdType = IF;
	ParseLogicalOp(pCmdBlock->cmdExpression);
	iPkgBlock.push_back(pCmdBlock);

	ParseEmbeddedBlockL ();
	
	while (m_token==ELSEIF_TOKEN)
	{
		GetNextToken ();
		//ELSEIF
		pCmdBlock = new CMD_BLOCK;
		pCmdBlock->cmdType = ELSEIF;
		ParseLogicalOp(pCmdBlock->cmdExpression);
		iPkgBlock.push_back(pCmdBlock);

		ParseEmbeddedBlockL ();
	}
	
	if (m_token==ELSE_TOKEN)
	{
		GetNextToken ();
		//ELSEIF
		pCmdBlock = new CMD_BLOCK;
		pCmdBlock->cmdType = ELSE;
		iPkgBlock.push_back(pCmdBlock);

		ParseEmbeddedBlockL ();
	}
	
	ExpectToken(ENDIF_TOKEN);
	//ENDIF
	pCmdBlock = new CMD_BLOCK;
	pCmdBlock->cmdType = ENDIF;
	iPkgBlock.push_back(pCmdBlock);

	GetNextToken ();
}

/**
ParseLogicalOp: Parses the logical expression

@internalComponent
@released
*/
void PkgParser::ParseLogicalOp (String& aExpression)
{
    ParseRelation (aExpression);
	switch (m_token)
	{
	case AND_TOKEN:
	case OR_TOKEN:
		{
			if (m_token==AND_TOKEN)
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
void PkgParser::ParseRelation(String& aExpression)
{
    ParseUnary (aExpression);
	switch (m_token)
	{
	case '=':
	case '>':
	case '<':
	case GE_TOKEN:
	case LE_TOKEN:
	case NE_TOKEN:
	case APPCAP_TOKEN:
		{
			switch (m_token)
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
void PkgParser::ParseUnary(String& aExpression)
{
    switch (m_token)
	{
	case NOT_TOKEN:
		aExpression.append(" !");
		GetNextToken ();
		ParseUnary (aExpression);
		break;
	case EXISTS_TOKEN:
	case DEVCAP_TOKEN:
		{	// 1 arg function
			int token=m_token;
			GetNextToken ();
			ExpectToken('(');
			GetNextToken ();
			if (token==EXISTS_TOKEN)
			{
				aExpression.append("EXISTS(\"");
				ExpectToken(QUOTED_STRING_TOKEN);
				GetNextToken ();
				aExpression.append(wstring2string(m_tokenValue.pszString));
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
void PkgParser::ParseFactor(String& aExpression)
{
    switch (m_token) {
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
			switch (m_token)
			{
			case QUOTED_STRING_TOKEN:
				aExpression.append("\"");
				aExpression.append(wstring2string(m_tokenValue.pszString));
				aExpression.append("\"");
				break;
			case ALPHA_TOKEN:
				if(!CompareNString(m_tokenValue.pszString,L"option",6))
				{
					aExpression.append(" defined(");
					aExpression.append(wstring2string(m_tokenValue.pszString));
					aExpression.append(") ");
				}
				else
				{
					aExpression.append(wstring2string(m_tokenValue.pszString));
				}
				break;
			case NUMERIC_TOKEN:
				{
					std::ostringstream str;

					str << "(0x" << std::setbase(16) << m_tokenValue.dwNumber << ")";
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
void PkgParser::ParsePackageL()
{
	PCMD_BLOCK pCmdBlock = 0;
	int found = 0;

	ExpectToken(QUOTED_STRING_TOKEN);

	//if the sis file already exists then skip it
	SISFILE_LIST::iterator begin = iEmbedSisFiles.begin();
	SISFILE_LIST::iterator end = iEmbedSisFiles.end();

	while(begin != end)
	{
		if((*begin).compare(wstring2string(m_tokenValue.pszString)) == 0)
		{
			found = 1;
			break;
		}
		++begin;
	}

	if(!found)
	{
		iEmbedSisFiles.push_back(wstring2string(m_tokenValue.pszString));
	}
	
	//add as a command block as well
	{
		pCmdBlock = new CMD_BLOCK;

		pCmdBlock->cmdType = PACKAGE;
		pCmdBlock->iInstallFileList = 0;
		pCmdBlock->cmdExpression = wstring2string(m_tokenValue.pszString);

		iPkgBlock.push_back(pCmdBlock);
	}


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
void PkgParser::ParseCommentL()
{
	// parse to end of line
	while (m_pkgChar && (m_pkgChar!='\n')) GetNextChar();
	GetNextToken ();
}

/**
ParseOptionsBlockL: Parses the install options section

@internalComponent
@released
*/
void PkgParser::ParseOptionsBlockL()
{
	WORD wNumLangs;
	
	ExpectToken('(');
	GetNextToken ();
	
	for (;;)
	{
		ExpectToken('{');
		GetNextToken ();
		
		wNumLangs = 0;
		while (wNumLangs < iLangList.size())
		{
			ExpectToken(QUOTED_STRING_TOKEN);
			iInstallOptions.push_back(wstring2string(m_tokenValue.pszString));
			GetNextToken ();
			if (wNumLangs < iLangList.size() - 1)
			{
				ExpectToken(',');
				GetNextToken ();
			}
			wNumLangs++;
		}
		
		ExpectToken('}');
		GetNextToken ();
		if (m_token!=',') break;
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
void PkgParser::ParsePropertyL()
{
	ExpectToken('(');
	do
	{
		GetNextToken ();
		
		ExpectToken(NUMERIC_TOKEN);
		GetNextToken ();
		ExpectToken('=');
		GetNextToken ();
		ExpectToken(NUMERIC_TOKEN);
		GetNextToken ();
	} while (m_token==',');
	ExpectToken(')');
	GetNextToken ();
}

/**
ParseVendorNameL: Parses the vendor options section

@internalComponent
@released
*/
void PkgParser::ParseVendorNameL()
{
	ExpectToken('{');
	for (WORD wNumLangs = 0; wNumLangs < iLangList.size(); wNumLangs++)
	{
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
void PkgParser::ParseLogoL()
{
	ExpectToken (QUOTED_STRING_TOKEN);
	GetNextToken ();
	ExpectToken(',');
	GetNextToken ();
	ExpectToken (QUOTED_STRING_TOKEN);
	GetNextToken ();
	if (m_token==',')
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
void PkgParser::ParseVersion()
{
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
void PkgParser::ParseDependencyL()
{
	ExpectToken(NUMERIC_TOKEN);
	GetNextToken ();
	ExpectToken(')');
	GetNextToken ();
	ExpectToken(',');

	ParseVersion();
	if (m_token == '~')
	{
		ParseVersion();
		ExpectToken(',');
	}
	
	GetNextToken ();
	ExpectToken('{');
	for (TUint numLangs = 0; numLangs < iLangList.size(); ++numLangs)
	{
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
void PkgParser::ParseVendorUniqueNameL()
{
	ExpectToken(QUOTED_STRING_TOKEN);
	GetNextToken ();
}

/**
ParseTargetDeviceL: Parses the target device name section

@internalComponent
@released
*/
void PkgParser::ParseTargetDeviceL()
{
	ExpectToken(NUMERIC_TOKEN);
	GetNextToken ();
	ExpectToken(']');
	GetNextToken ();
	ExpectToken(',');
	
	ParseVersion();
	if (m_token == '~')
	{
		ParseVersion();
		ExpectToken(',');
	}
	GetNextToken ();
	ExpectToken('{');
	
	// must do this before adding language strings	
	for (TUint numLangs = 0; numLangs < iLangList.size(); ++numLangs)
	{
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
GetNextChar: Reads the next character from the package file

@internalComponent
@released
*/
void PkgParser::GetNextChar()
{
#ifdef WIN32
	DWORD dwBytesRead;
	if (!::ReadFile(iPkgHandle, (LPVOID)&m_pkgChar, sizeof(WCHAR), &dwBytesRead, NULL) ||
		dwBytesRead!=sizeof(wchar_t))
		m_pkgChar='\0';
#else
#error "TODO: Implement this function under other OS than Windows"
#endif
}

/**
ExpectToken: Tests the current token value

@internalComponent
@released

@param aToken - expected token value
*/
void PkgParser::ExpectToken(int aToken)
{
	if (m_token!=aToken)
	{
		ParserError("Unexpected Token");
	}
}

/**
GetNextToken: Reads the next valid token from the package file

@internalComponent
@released
*/
void PkgParser::GetNextToken ()
{
	// skip any white space & newLine's
	while (m_pkgChar == '\n' || isspace(m_pkgChar) || m_pkgChar == 0xA0)
	{
		if (m_pkgChar == '\n') ++m_nLineNo;
		GetNextChar();
	}
	
	if (m_pkgChar == '\0')
		m_token=EOF_TOKEN;
	else if (IsNumericToken())
	{
		GetNumericToken();
		m_token=NUMERIC_TOKEN;
	}
	else if (isalpha(m_pkgChar))
	{ // have some alphanumeric text
		GetAlphaNumericToken();
		m_token=ALPHA_TOKEN;
		// check if it is a keyword
		for(unsigned short wLoop = 0; wLoop < NUMPARSETOKENS; wLoop++)
		{
			if(CompareTwoString(m_tokenValue.pszString,(wchar_t*)KTokens[wLoop].pszOpt) == 0)
			{
				m_token=KTokens[wLoop].dwOpt;
				break;
			}
		}
	}
	else if (m_pkgChar == '\"')
	{ // have a quoted string
		GetStringToken();
		m_token=QUOTED_STRING_TOKEN;
	}
	else if (m_pkgChar == '>')
	{
		GetNextChar();
		if (m_pkgChar == '=')
		{
			m_token=GE_TOKEN;
			GetNextChar();
		}
		else
			m_token='>';
	}
	else if (m_pkgChar == '<')
	{
		// check if start of an escaped string, e.g. <123>"abc"
		if (GetStringToken())
			m_token=QUOTED_STRING_TOKEN;
		else
		{
			GetNextChar();
			if (m_pkgChar == '=')
			{
				m_token=LE_TOKEN;
				GetNextChar();
			}
			else if (m_pkgChar == '>')
			{
				m_token=NE_TOKEN;
				GetNextChar();
			}
			else
				m_token='<';
		}
	}
	else
	{
		m_token=m_pkgChar;
		GetNextChar();
	}
}

/**
GetStringToken: Reads the string token from the package file

@internalComponent
@released
*/
bool PkgParser::GetStringToken()
{
	DWORD wCount = 0;
	bool done=false;
	bool finished=false;
	DWORD escapeChars = 0;
	
	while (!finished)
	{
		if (m_pkgChar == '\"')
		{
			GetNextChar();
			while(m_pkgChar && m_pkgChar != '\"')
			{
				if(wCount < (MAX_STRING - 1))
					m_tokenValue.pszString[wCount++] = m_pkgChar;
				else //We dont want the string with length greater than MAX_STRING to be cut off silently
					ParserError("Bad String");
				GetNextChar();
			}
			if(m_pkgChar == '\0')
				ParserError("Bad String");
			GetNextChar();
			done=true;
		}
		if (m_pkgChar == '<')
		{
			m_tokenValue.pszString[wCount] = L'\0';
			escapeChars=ParseEscapeChars();
			if (escapeChars>0)
			{
				done=true;
				wCount+=escapeChars;
				if (wCount>=MAX_STRING) wCount=MAX_STRING-1;
			}
		}
		if (escapeChars==0 || m_pkgChar != '\"')
			finished=true;
	}
	
	m_tokenValue.pszString[wCount] = L'\0';
	return done;
}

/**
ParseEscapeChars: Parses the escape sequence characters

@internalComponent
@released
*/
WORD PkgParser::ParseEscapeChars()
{
	WORD found=0;
	WCHAR temp[MAX_STRING];
#ifdef WIN32
	while (m_pkgChar == '<')
	{
		wcscpy(temp,m_tokenValue.pszString);
		DWORD fileOffset=::SetFilePointer(iPkgHandle, 0L, NULL, FILE_CURRENT);
		try
		{
			GetNextChar();
			GetNumericToken();
			if (m_pkgChar=='>')
				found++;
			else
			{
				::SetFilePointer(iPkgHandle, fileOffset, NULL, FILE_BEGIN);
				break;
			}
		}
		catch (...)
		{
			wcscpy(m_tokenValue.pszString,temp);
			::SetFilePointer(iPkgHandle, fileOffset, NULL, FILE_BEGIN);
			break;
		}
		DWORD num=m_tokenValue.dwNumber;
		// watch for CP1252 escapes which aren't appropriate for UNICODE
		if (num>=0x80 && num<=0x9F) ParserError("Invalid Escape");
		DWORD len=wcslen(temp);
		wcscpy(m_tokenValue.pszString,temp);
		if (len+2<=MAX_STRING)
		{
			m_tokenValue.pszString[len]=(WCHAR)num;
			len++;
			m_tokenValue.pszString[len]='\0';
		}
		GetNextChar();
	}
#else
#error "TODO: Implement this function under other OS than Windows"
#endif 
	return found;
}

/**
GetAlphaNumericToken: Parse an alphanumeric string from the input line

@internalComponent
@released
*/
void PkgParser::GetAlphaNumericToken()
{
	WORD wCount = 0;
	while(m_pkgChar && (isalnum(m_pkgChar) || ((m_pkgChar) == '_')))
	{
		if(wCount < (MAX_STRING - 1))
			m_tokenValue.pszString[wCount++] = m_pkgChar;
		GetNextChar();
	}
	m_tokenValue.pszString[wCount] = L'\0';
}

/**
IsNumericToken: Determines if the next lexeme is a numeric token

@internalComponent
@released
*/
bool PkgParser::IsNumericToken()
{
	bool lexemeIsNumber = false;
	if (iswdigit(m_pkgChar))
		lexemeIsNumber = true;
	else if (m_pkgChar == '+' || m_pkgChar == '-')
	{
		// we may have a number but we must look ahead one char to be certain
		
		WCHAR oldChar = m_pkgChar;
		DWORD fileOffset=::SetFilePointer(iPkgHandle, 0L, NULL, FILE_CURRENT);
		GetNextChar();
		lexemeIsNumber = iswdigit(m_pkgChar) != FALSE;
		m_pkgChar = oldChar;
		::SetFilePointer(iPkgHandle,fileOffset,NULL,FILE_BEGIN);
	}
	
	return lexemeIsNumber;
}

/**
GetNumericToken: Parse a number from the input line

@internalComponent
@released
*/
void PkgParser::GetNumericToken()
{
	WCHAR temp[MAX_STRING];
	LPWSTR end;
	bool hexString = false;
	DWORD dwBytesRead;
	DWORD fileOffset=::SetFilePointer(iPkgHandle, 0L, NULL, FILE_CURRENT);
	
	temp[0]=m_pkgChar;
	if (!::ReadFile(iPkgHandle, &temp[1], (MAX_STRING-2)*sizeof(WCHAR), &dwBytesRead, NULL) ||
		dwBytesRead==0)
		ParserError("Read failed");
	temp[1+dwBytesRead/sizeof(WCHAR)]='\0';
	hexString = (!CompareNString(temp, L"0x", 2) || !CompareNString(&temp[1], L"0x", 2));
	
	m_tokenValue.dwNumber = wcstoul(temp, &end, (hexString) ? 16 : 10);
	
	if (end==temp) ParserError("Read failed"); 
	::SetFilePointer(iPkgHandle, fileOffset+(end-temp-1)*sizeof(WCHAR), NULL, FILE_BEGIN);
	GetNextChar();
}

/**
AddLanguage: Updates the language list structure

@internalComponent
@released

@param aLang - Name of the language
@param aCode - Language code
@param aDialect - Language dialect code
*/
void PkgParser::AddLanguage(String aLang, unsigned long aCode, unsigned long aDialect)
{
	PLANG_LIST lc = new LANG_LIST;
	
	lc->langName = aLang;
	lc->langCode = aCode;
	lc->dialectCode = aDialect;

	iLangList.push_back(lc);
}

/**
DeleteAll: Deallocates memory for the data members

@internalComponent
@released
*/
void PkgParser::DeleteAll()
{
	while(iPkgBlock.size() > 0)
	{
		PCMD_BLOCK ptemp = 0;

		ptemp = iPkgBlock.front();
		iPkgBlock.pop_front();

		if(ptemp->cmdType == INSTALLFILE)
		{
			delete ptemp->iInstallFileList;
		}
		delete ptemp;
	}

	{
		LANGUAGE_LIST::iterator begin = iLangList.begin();
		LANGUAGE_LIST::iterator end = iLangList.end();
		while(begin != end)
		{
			PLANG_LIST ptemp = 0;
			ptemp = (*begin);

			if(ptemp)
				delete ptemp;
			++begin;
		}
		iLangList.clear();
	}
}

/**
ParserError: Throws exception with the given error message

@internalComponent
@released

@param msg - error message to be thrown
*/
void PkgParser::ParserError(char* msg)
{
	std::ostringstream str;

	str << (char*)iPkgFile.data() << "(" << m_nLineNo << "): " << msg;

	throw SisUtilsException("PakageFile-Parser Error", (char*)(str.str()).data());
}

/**
wstring2string: Converts wide string to string

@internalComponent
@released

@param aWide - input wide string
*/
String wstring2string (const std::wstring& aWide)
{
	int max = ::WideCharToMultiByte(CP_OEMCP,0,aWide.c_str(),aWide.length(),0,0,0,0);
	String reply;
	if (max > 0 )
	{
		char* buffer = new char [max];
		try
		{
			::WideCharToMultiByte(CP_OEMCP,0,aWide.c_str(),aWide.length(),buffer,max,0,0);
			reply = String (buffer, max);
		}
		catch (...)
		{
			throw SisUtilsException("ParserError", "wstring to string conversion failed");
		}
		delete [] buffer;
	}
	return reply;
}

/**
string2wstring: Converts string to wide string

@internalComponent
@released

@param aNarrow - input string
*/
std::wstring string2wstring (const String& aNarrow)
{
	int max = ::MultiByteToWideChar(CP_OEMCP,0,aNarrow.c_str(),aNarrow.length(),0,0);
	std::wstring reply;
	if (max > 0 )
	{
		wchar_t* buffer = new wchar_t [max];
		try
		{
			::MultiByteToWideChar(CP_OEMCP,0,aNarrow.c_str(),aNarrow.length(),buffer,max);
			reply = std::wstring (buffer, max);
		}
		catch (...)
		{
			throw SisUtilsException("ParserError", "string to wstring conversion failed");
		}
		delete [] buffer;
	}
	return reply;
}

/**
CompareTwoString: Compares two wide string

@internalComponent
@released

@param string - first string
@param option - second string
*/
int CompareTwoString(wchar_t* string ,wchar_t* option)
{
	return wcsicmp(string,option);
}

/**
CompareNString: Compares two wide string for n characters

@internalComponent
@released

@param string - first string
@param option - second string
@param len - no of wide characters to be compared
*/
int CompareNString(wchar_t* string ,wchar_t* option, int len)
{
	return wcsnicmp(string,option,len);
}
