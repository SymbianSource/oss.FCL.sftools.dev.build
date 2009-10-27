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
#include "pkglanguage.h"
#include "pkgfileparser.h"

// Language options
static const SKeyword KLanguages [] = 
{
	{ L"EN", PkgLanguage::ELangEnglish },
	{ L"FR", PkgLanguage::ELangFrench},
	{ L"GE", PkgLanguage::ELangGerman},
	{ L"SP", PkgLanguage::ELangSpanish},
	{ L"IT", PkgLanguage::ELangItalian},
	{ L"SW", PkgLanguage::ELangSwedish},
	{ L"DA", PkgLanguage::ELangDanish},
	{ L"NO", PkgLanguage::ELangNorwegian},
	{ L"FI", PkgLanguage::ELangFinnish},
	{ L"AM", PkgLanguage::ELangAmerican},
	{ L"SF", PkgLanguage::ELangSwissFrench},
	{ L"SG", PkgLanguage::ELangSwissGerman},
	{ L"PO", PkgLanguage::ELangPortuguese},
	{ L"TU", PkgLanguage::ELangTurkish},
	{ L"IC", PkgLanguage::ELangIcelandic},
	{ L"RU", PkgLanguage::ELangRussian},
	{ L"HU", PkgLanguage::ELangHungarian},
	{ L"DU", PkgLanguage::ELangDutch},
	{ L"BL", PkgLanguage::ELangBelgianFlemish},
	{ L"AU", PkgLanguage::ELangAustralian},
	{ L"BF", PkgLanguage::ELangBelgianFrench},
	{ L"AS", PkgLanguage::ELangAustrian},
	{ L"NZ", PkgLanguage::ELangNewZealand},
	{ L"IF", PkgLanguage::ELangInternationalFrench},
	{ L"CS", PkgLanguage::ELangCzech},
	{ L"SK", PkgLanguage::ELangSlovak},
	{ L"PL", PkgLanguage::ELangPolish},
	{ L"SL", PkgLanguage::ELangSlovenian},
	{ L"TC", PkgLanguage::ELangTaiwanChinese},
	{ L"HK", PkgLanguage::ELangHongKongChinese},
	{ L"ZH", PkgLanguage::ELangPrcChinese},
	{ L"JA", PkgLanguage::ELangJapanese},
	{ L"TH", PkgLanguage::ELangThai},
		  
	{ L"AF", PkgLanguage::ELangAfrikaans },
	{ L"SQ", PkgLanguage::ELangAlbanian },
	{ L"AH", PkgLanguage::ELangAmharic },
	{ L"AR", PkgLanguage::ELangArabic },
	{ L"HY", PkgLanguage::ELangArmenian },
	{ L"TL", PkgLanguage::ELangTagalog },
	{ L"BE", PkgLanguage::ELangBelarussian },
	{ L"BN", PkgLanguage::ELangBengali },
	{ L"BG", PkgLanguage::ELangBulgarian },
	{ L"MY", PkgLanguage::ELangBurmese },
	{ L"CA", PkgLanguage::ELangCatalan },
	{ L"HR", PkgLanguage::ELangCroatian },
	{ L"CE", PkgLanguage::ELangCanadianEnglish },
	{ L"IE", PkgLanguage::ELangInternationalEnglish },
	{ L"SA", PkgLanguage::ELangSouthAfricanEnglish },
	{ L"ET", PkgLanguage::ELangEstonian },
	{ L"FA", PkgLanguage::ELangFarsi },
	{ L"CF", PkgLanguage::ELangCanadianFrench },
	{ L"GD", PkgLanguage::ELangScotsGaelic },
	{ L"KA", PkgLanguage::ELangGeorgian },
	{ L"EL", PkgLanguage::ELangGreek },
	{ L"CG", PkgLanguage::ELangCyprusGreek },
	{ L"GU", PkgLanguage::ELangGujarati },
	{ L"HE", PkgLanguage::ELangHebrew },
	{ L"HI", PkgLanguage::ELangHindi },
	{ L"IN", PkgLanguage::ELangIndonesian },
	{ L"GA", PkgLanguage::ELangIrish },
	{ L"SZ", PkgLanguage::ELangSwissItalian },
	{ L"KN", PkgLanguage::ELangKannada },
	{ L"KK", PkgLanguage::ELangKazakh },
	{ L"KM", PkgLanguage::ELangKhmer },
	{ L"KO", PkgLanguage::ELangKorean },
	{ L"LO", PkgLanguage::ELangLao },
	{ L"LV", PkgLanguage::ELangLatvian },
	{ L"LT", PkgLanguage::ELangLithuanian },
	{ L"MK", PkgLanguage::ELangMacedonian },
	{ L"MS", PkgLanguage::ELangMalay },
	{ L"ML", PkgLanguage::ELangMalayalam },
	{ L"MR", PkgLanguage::ELangMarathi },
	{ L"MO", PkgLanguage::ELangMoldavian },
	{ L"MN", PkgLanguage::ELangMongolian },
	{ L"NN", PkgLanguage::ELangNorwegianNynorsk },
	{ L"BP", PkgLanguage::ELangBrazilianPortuguese },
	{ L"PA", PkgLanguage::ELangPunjabi },
	{ L"RO", PkgLanguage::ELangRomanian },
	{ L"SR", PkgLanguage::ELangSerbian },
	{ L"SI", PkgLanguage::ELangSinhalese },
	{ L"SO", PkgLanguage::ELangSomali },
	{ L"OS", PkgLanguage::ELangInternationalSpanish },
	{ L"LS", PkgLanguage::ELangLatinAmericanSpanish },
	{ L"SH", PkgLanguage::ELangSwahili },
	{ L"FS", PkgLanguage::ELangFinlandSwedish },
	//{L"??", PkgLanguage::ELangReserved1 },
	{ L"TA", PkgLanguage::ELangTamil },
	{ L"TE", PkgLanguage::ELangTelugu },
	{ L"BO", PkgLanguage::ELangTibetan },
	{ L"TI", PkgLanguage::ELangTigrinya },
	{ L"CT", PkgLanguage::ELangCyprusTurkish },
	{ L"TK", PkgLanguage::ELangTurkmen },
	{ L"UK", PkgLanguage::ELangUkrainian },
	{ L"UR", PkgLanguage::ELangUrdu },
	//{L"??", PkgLanguage::ELangReserved2 },
	{ L"VI", PkgLanguage::ELangVietnamese },
	{ L"CY", PkgLanguage::ELangWelsh },
	{ L"ZU", PkgLanguage::ELangZulu },
	{ L"BA", PkgLanguage::ELangBasque },
	{ L"GL", PkgLanguage::ELangGalician },
	//{L"??", PkgLanguage::ELangOther },
	//{L"??", PkgLanguage::ELangNone  }
	
	{ NULL, PkgLanguage::ELangNone }
	
};

#define NUMLANGUAGES (sizeof(KLanguages)/sizeof(SKeyword))

/**
GetLanguageCode: Returns the languge code for the given language

@internalComponent
@released

@param aLang  - Name of the language
*/
unsigned long PkgLanguage::GetLanguageCode(std::wstring aLang)
{
	int index = NUMLANGUAGES - 1;

	while(index--)
	{
		if(!CompareTwoString(KLanguages[index].iName, (wchar_t*)aLang.data()))
			return KLanguages[index].iId;
	}

	return PkgLanguage::ELangNone;
}

/**
GetLanguageName: Returns the languge name for the given language code

@internalComponent
@released

@param aCode  - Language code
*/
std::wstring PkgLanguage::GetLanguageName(unsigned long aCode)
{
	int index = NUMLANGUAGES - 1;

	while(index--)
	{
		if(KLanguages[index].iId == aCode)
			return KLanguages[index].iName;
	}

	return NULL;
}

