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
#ifndef WIN32
#include <strings.h>
#define stricmp strcasecmp
#define strnicmp strncasecmp
#endif
// Language options
static const SKeyword KLanguages [] = 
{
	{ "EN", PkgLanguage::ELangEnglish },
	{ "FR", PkgLanguage::ELangFrench},
	{ "GE", PkgLanguage::ELangGerman},
	{ "SP", PkgLanguage::ELangSpanish},
	{ "IT", PkgLanguage::ELangItalian},
	{ "SW", PkgLanguage::ELangSwedish},
	{ "DA", PkgLanguage::ELangDanish},
	{ "NO", PkgLanguage::ELangNorwegian},
	{ "FI", PkgLanguage::ELangFinnish},
	{ "AM", PkgLanguage::ELangAmerican},
	{ "SF", PkgLanguage::ELangSwissFrench},
	{ "SG", PkgLanguage::ELangSwissGerman},
	{ "PO", PkgLanguage::ELangPortuguese},
	{ "TU", PkgLanguage::ELangTurkish},
	{ "IC", PkgLanguage::ELangIcelandic},
	{ "RU", PkgLanguage::ELangRussian},
	{ "HU", PkgLanguage::ELangHungarian},
	{ "DU", PkgLanguage::ELangDutch},
	{ "BL", PkgLanguage::ELangBelgianFlemish},
	{ "AU", PkgLanguage::ELangAustralian},
	{ "BF", PkgLanguage::ELangBelgianFrench},
	{ "AS", PkgLanguage::ELangAustrian},
	{ "NZ", PkgLanguage::ELangNewZealand},
	{ "IF", PkgLanguage::ELangInternationalFrench},
	{ "CS", PkgLanguage::ELangCzech},
	{ "SK", PkgLanguage::ELangSlovak},
	{ "PL", PkgLanguage::ELangPolish},
	{ "SL", PkgLanguage::ELangSlovenian},
	{ "TC", PkgLanguage::ELangTaiwanChinese},
	{ "HK", PkgLanguage::ELangHongKongChinese},
	{ "ZH", PkgLanguage::ELangPrcChinese},
	{ "JA", PkgLanguage::ELangJapanese},
	{ "TH", PkgLanguage::ELangThai},
		  
	{ "AF", PkgLanguage::ELangAfrikaans },
	{ "SQ", PkgLanguage::ELangAlbanian },
	{ "AH", PkgLanguage::ELangAmharic },
	{ "AR", PkgLanguage::ELangArabic },
	{ "HY", PkgLanguage::ELangArmenian },
	{ "TL", PkgLanguage::ELangTagalog },
	{ "BE", PkgLanguage::ELangBelarussian },
	{ "BN", PkgLanguage::ELangBengali },
	{ "BG", PkgLanguage::ELangBulgarian },
	{ "MY", PkgLanguage::ELangBurmese },
	{ "CA", PkgLanguage::ELangCatalan },
	{ "HR", PkgLanguage::ELangCroatian },
	{ "CE", PkgLanguage::ELangCanadianEnglish },
	{ "IE", PkgLanguage::ELangInternationalEnglish },
	{ "SA", PkgLanguage::ELangSouthAfricanEnglish },
	{ "ET", PkgLanguage::ELangEstonian },
	{ "FA", PkgLanguage::ELangFarsi },
	{ "CF", PkgLanguage::ELangCanadianFrench },
	{ "GD", PkgLanguage::ELangScotsGaelic },
	{ "KA", PkgLanguage::ELangGeorgian },
	{ "EL", PkgLanguage::ELangGreek },
	{ "CG", PkgLanguage::ELangCyprusGreek },
	{ "GU", PkgLanguage::ELangGujarati },
	{ "HE", PkgLanguage::ELangHebrew },
	{ "HI", PkgLanguage::ELangHindi },
	{ "IN", PkgLanguage::ELangIndonesian },
	{ "GA", PkgLanguage::ELangIrish },
	{ "SZ", PkgLanguage::ELangSwissItalian },
	{ "KN", PkgLanguage::ELangKannada },
	{ "KK", PkgLanguage::ELangKazakh },
	{ "KM", PkgLanguage::ELangKhmer },
	{ "KO", PkgLanguage::ELangKorean },
	{ "LO", PkgLanguage::ELangLao },
	{ "LV", PkgLanguage::ELangLatvian },
	{ "LT", PkgLanguage::ELangLithuanian },
	{ "MK", PkgLanguage::ELangMacedonian },
	{ "MS", PkgLanguage::ELangMalay },
	{ "ML", PkgLanguage::ELangMalayalam },
	{ "MR", PkgLanguage::ELangMarathi },
	{ "MO", PkgLanguage::ELangMoldavian },
	{ "MN", PkgLanguage::ELangMongolian },
	{ "NN", PkgLanguage::ELangNorwegianNynorsk },
	{ "BP", PkgLanguage::ELangBrazilianPortuguese },
	{ "PA", PkgLanguage::ELangPunjabi },
	{ "RO", PkgLanguage::ELangRomanian },
	{ "SR", PkgLanguage::ELangSerbian },
	{ "SI", PkgLanguage::ELangSinhalese },
	{ "SO", PkgLanguage::ELangSomali },
	{ "OS", PkgLanguage::ELangInternationalSpanish },
	{ "LS", PkgLanguage::ELangLatinAmericanSpanish },
	{ "SH", PkgLanguage::ELangSwahili },
	{ "FS", PkgLanguage::ELangFinlandSwedish },
	//{"??", PkgLanguage::ELangReserved1 },
	{ "TA", PkgLanguage::ELangTamil },
	{ "TE", PkgLanguage::ELangTelugu },
	{ "BO", PkgLanguage::ELangTibetan },
	{ "TI", PkgLanguage::ELangTigrinya },
	{ "CT", PkgLanguage::ELangCyprusTurkish },
	{ "TK", PkgLanguage::ELangTurkmen },
	{ "UK", PkgLanguage::ELangUkrainian },
	{ "UR", PkgLanguage::ELangUrdu },
	//{"??", PkgLanguage::ELangReserved2 },
	{ "VI", PkgLanguage::ELangVietnamese },
	{ "CY", PkgLanguage::ELangWelsh },
	{ "ZU", PkgLanguage::ELangZulu },
	{ "BA", PkgLanguage::ELangBasque },
	{ "GL", PkgLanguage::ELangGalician },
	//{"??", PkgLanguage::ELangOther },
	//{"??", PkgLanguage::ELangNone  }
	
	{ NULL, PkgLanguage::ELangNone }
	
};

#define NUMLANGUAGES (sizeof(KLanguages)/sizeof(SKeyword))

/**
GetLanguageCode: Returns the languge code for the given language

@internalComponent
@released

@param aLang  - Name of the language
*/
TUint32 GetLanguageCode(const char* aLang) {
	TInt index = NUMLANGUAGES - 1;

	while(index--){
		if(!stricmp(KLanguages[index].iName,aLang))
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
const char* GetLanguageName(TUint32 aCode) {
	
	TInt index = NUMLANGUAGES - 1;
	while(index--) {
		if(KLanguages[index].iId == aCode)
			return KLanguages[index].iName;
	}

	return NULL;
}

