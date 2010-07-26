/*
* Copyright (c) 2009 Nokia Corporation and/or its subsidiary(-ies).
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
*
*/

#include "utf16string.h"
#ifdef __LINUX__
#include <iconv.h>
#elif defined(WIN32)
#ifdef _STLP_INTERNAL_WINDOWS_H
#define __INTERLOCKED_DECLARED
#endif
#include <windows.h>
#endif
UTF16String::UTF16String() :iData(0), iLength(0){
}
UTF16String::UTF16String(const UTF16String& aRight){
	iLength = aRight.iLength ;
	iData = new TUint16[iLength + 1];
	memcpy(iData,aRight.iData, iLength << 1);
	iData[iLength] = 0;
}
UTF16String::UTF16String(const string& aUtf8Str){
	iData = 0 ;
	iLength = 0 ;
	Assign(aUtf8Str.c_str(),aUtf8Str.length());
}
UTF16String::UTF16String(const TUint16* aUtf16Str,TInt aLength /* = -1*/){
	
	if(aLength < 0){
		aLength = 0 ;
		const TUint16* p = aUtf16Str ;
		while(*p){
			p++ ;
			aLength ++ ;
		}
	}
	if(aLength > 0){		
		iLength = aLength ;
		aLength <<= 1 ;
		iData = new TUint16[iLength + 1] ;
		memcpy(iData,aUtf16Str,aLength);
		iData[iLength] = 0;
	}else{
		iData = 0 ;
		iLength = 0 ;
	}
	
}
UTF16String::UTF16String(const char* aUtf8Str,TInt aLength /*= -1 */){
	iData = 0 ;
	iLength = 0 ;	
	Assign(aUtf8Str,aLength);
}	
UTF16String::~UTF16String(){
	if(iData)
		delete []iData ;
}	

UTF16String& UTF16String::operator = (const UTF16String& aRight){
	if(&aRight != this){
		if(iData) 
			delete []iData ; 
		iLength = aRight.iLength ;
		iData = new TUint16[iLength + 1];
		memcpy(iData,aRight.iData, iLength << 1);
		iData[iLength] = 0;
	}
	return *this;
}
bool UTF16String::FromFile(const char* aFileName){
	if(!aFileName || !(*aFileName))
		return false ;
	ifstream ifs(aFileName,ios_base::in + ios_base::binary); 	
	if(!ifs.is_open())
		return false ;
	
	ifs.seekg(0,ios_base::end);
	size_t length = ifs.tellg();
	if((length % 2) == 1 ){
		ifs.close() ;
		return false ;
	}
	ifs.seekg(0,ios_base::beg);
	TUint16 hdr ;
	size_t readLen = length - sizeof(hdr) ;
	length >>= 1 ;	
	TUint16 *newData = new TUint16[length + 1];
	ifs.read(reinterpret_cast<char*>(&hdr),sizeof(hdr));		
	if(hdr == 0xFEFF){ 
		ifs.read(reinterpret_cast<char*>(newData),readLen);
		length -- ;
	}
	else{		 
		*newData = hdr ;
		ifs.read(reinterpret_cast<char*>(&newData[1]),readLen);
	} 
	ifs.close();
	iLength = length ;
	if(iData)
		delete []iData ;
	iData = newData ;
	iData[iLength] = 0;	
	return true ;
}
/**
* aResult will not changed on error
*/
bool UTF16String::ToUTF8(string& aResult) const {
	if(IsEmpty()){
		aResult = "";
		return true;
	}
	size_t bufLen = (iLength + 1) << 2 ;
	char* buffer = new char[bufLen] ;
#ifdef WIN32
	int r = WideCharToMultiByte(CP_UTF8,0,reinterpret_cast<WCHAR*>(iData),iLength,buffer,bufLen,NULL,NULL);
	if(r < 0){
		delete []buffer ;
		return false ;
	}
	buffer[r] = 0;
	aResult.assign(buffer,r);
#else
	iconv_t it = iconv_open("UTF-8","UTF-16");
	if((iconv_t)(-1) == it){ 
		return  false;
	}
	char* bufferEnd = buffer ;
	char* in_ptr = reinterpret_cast<char*>(iData);
	size_t in_len = iLength << 1 ;
	iconv(it,&in_ptr,&in_len ,&bufferEnd,&bufLen);
	iconv_close(it);
	*bufferEnd = 0 ;
	size_t length = bufferEnd - buffer ;
	aResult.assign(buffer,length);
#endif
	delete []buffer ;
	return true ;
}
bool UTF16String::Assign(const char* aUtf8Str,TInt aLength /* = -1*/) {
	if(0 == aUtf8Str) return false ;	
	if(aLength < 0) aLength = strlen(aUtf8Str); 
		
#ifdef WIN32
	size_t newLength = aLength + 1;
	TUint16* newData = new TUint16[newLength];
	int r = MultiByteToWideChar(CP_UTF8,0,aUtf8Str,aLength,reinterpret_cast<WCHAR*>(newData),newLength);
	if(r < 0){
		delete []newData ;
		return false ;
	}
	iLength = r ;	
#else
	char* forFree = 0 ;
	if(aUtf8Str[aLength - 1] != 0){
		forFree = new char[aLength + 1];
		memcpy(forFree,aUtf8Str,aLength );
		forFree[aLength] = 0;
		aUtf8Str = forFree ;
	}
	iconv_t it = iconv_open("UTF-16","UTF-8");
	if((iconv_t)(-1) == it){ 
		 
		return  false;
	}
	size_t newLength = aLength + 2;
	TUint16* newData = new TUint16[newLength];
	newLength <<= 1;
	char* out_ptr = reinterpret_cast<char*>(newData);
	size_t in_len = aLength ;
	char* in_ptr = const_cast<char*>(aUtf8Str);
	iconv(it,&in_ptr,&in_len ,&out_ptr ,&newLength);
	newLength = out_ptr - reinterpret_cast<char*>(newData);
	iconv_close(it);
	if(newLength % 2 == 1){ //should not be possible
		delete []newData;
		return false ;
	}
	iLength = (newLength >> 1) ;
	if(forFree)
		delete []forFree;
#endif
	newData[iLength] = 0 ;
	if(iData){
		delete []iData ;
	}
	iData = newData ;	
	if(*iData == 0xFEFF)
		iLength -- ;
	
	return true ;
}
static const TUint16 NullUInt16Str[1] = {0};
const TUint16* UTF16String::c_str() const {
	if(0 == iData)
		return NullUInt16Str;
	else if(0xFEFF != *iData)
		return iData ;
	else
		return iData + 1;
}
///
/// aUtf16Str must end with '\0'
/// 
int UTF16String::Compare(const TUint16* aUtf16Str) const {
	if(!aUtf16Str || !(*aUtf16Str))
		return (iLength > 0) ? 1 : 0; 
	size_t i ;
	for(i = 0 ; aUtf16Str[i] != 0 ; i++) { 
		if( iData[i] > aUtf16Str[i])
			return 1;
		else if(iData[i] < aUtf16Str[i])
			return -1 ;
	}
	return (i < iLength) ? 1 : 0 ; 
}
///
/// aUtf16Str must end with '\0'
/// 
int UTF16String::CompareNoCase(const TUint16* aUtf16Str) const {
	if(!aUtf16Str || !(*aUtf16Str))
		return (iLength > 0) ? 1 : 0; 
	size_t i ;
	TUint16 a, b;
	for(i = 0 ; aUtf16Str[i] != 0 ; i++) { 
		a = iData[i];
		b = aUtf16Str[i] ;
		if( a >= 'A' && a <= 'Z') a |= 0x20 ;
		if( b >= 'A' && b <= 'Z') b |= 0x20 ;
			
		if( a > b )
			return 1;
		else if( a < b )
			return -1 ;
	}
	return (i < iLength) ? 1 : 0 ; 
}
TUint16* UTF16String::Alloc(size_t aNewLen) {
	TUint16* newData = new TUint16[aNewLen + 1] ;
	if(!newData) return 0;
	if(iData) delete []iData ;
	
	iLength = aNewLen ;
	iData = newData ;
	*iData = 0 ;
	iData[aNewLen] = 0;
	return iData;
}
