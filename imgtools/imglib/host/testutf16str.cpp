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
*
*/
#include "UTF16String.h"
#include <iostream>
#include <fstream>
#include <string>
using namespace std ;

#ifdef __LINUX__
#define stricmp strcasecmp
#endif

void PrintHelp(){
	cout <<  "Syntax: TestUTF16Str  <-[mbtou|utomb] > -i inputfilename -o outputfilename "<<endl; 
	cout << "	mbtou is by default."<<endl;
}
int main(int argc, char* argv[]){
	const char* input = 0 ;
	const char* output = 0 ;
	if(argc < 5){
		PrintHelp();
		return 1;
	}
	bool mbtou = true ;
	int i = 1;
	while(i < argc){
		if('-' == *argv[i] || '/' == *argv[i]){
			if(!stricmp(&(argv[i][1]),"utomb"))
				mbtou = false ;
			else if((argv[i][1] | 0x20) == 'i'){
				i++ ;
				if(i < argc)
					input = argv[i];
			}
			else if((argv[i][1] | 0x20) == 'o'){
				i++ ;
				if(i < argc)
					output = argv[i];
			}
			else if(stricmp(&(argv[i][1]),"mbtou")){
				cerr << "Unrecognized option "<< argv[i] << endl ;
			}				
		}
		else {
			cerr << "Unrecognized option "<< argv[i] << endl ;
		}
		i++ ;			
	}
	if(!input || !output){
		PrintHelp();
		return 2;
	}
	fstream ifs(input, ios_base::in + ios_base::binary);	
	if(!ifs.is_open()){
		cerr << "Cannot open \""<< input << "\" for reading."<<endl ;
		return 3;
	}
	fstream ofs(output, ios_base::out + ios_base::binary + ios_base::trunc);
	if(!ofs.is_open()){
		cerr << "Cannot open \""<< output << "\" for writing."<<endl ;
		ifs.close();
		return 4;
	}
	ifs.seekg(0,ios_base::end);
	size_t length = ifs.tellg();
	ifs.seekg(0,ios_base::beg);
	char* buffer = new char[length + 2];
	ifs.read(buffer,length);
	buffer[length] = 0 ;
	buffer[length + 1] = 0 ;
	ifs.close();
	static unsigned char const utf16FileHdr[2] = {0xFF,0xFE};
	static unsigned char const utf8FileHdr[3] = {0xEF,0xBB,0xBF};
	if(mbtou){
		char* mbstr = buffer ;
		if(length > 3){
			if(memcmp(buffer,utf8FileHdr,sizeof(utf8FileHdr)) == 0){
				mbstr += 3;
				length -= 3 ;
			}
		}
		UTF16String theStr(mbstr , length);
		if(length > 0 && theStr.IsEmpty()){
			cerr << "Convert Error[From UTF8 To UTF16]."<<endl ;
		}
		else{
			length = theStr.length() << 1;			
			ofs.write(reinterpret_cast<const char*>(utf16FileHdr),sizeof(utf16FileHdr));
			ofs.write(reinterpret_cast<const char*>(theStr.c_str()),length);
			cout << "Done."<<endl ;
		}		
	}
	else{
		TUint16* unistr = reinterpret_cast<TUint16*>(buffer);
		length >>= 1;
		if(*unistr == 0xFEFF){
			unistr ++ ;
			length -- ;		
		}
		UTF16String theStr(unistr , length);
		string mbstr ;
		if(!theStr.ToUTF8(mbstr)){
			cerr << "Convert Error[From UTF16 To UTF8]."<<endl ;
		}else{
			//ofs.write(reinterpret_cast<const char*>(utf8FileHdr),sizeof(utf8FileHdr));
			ofs.write(mbstr.c_str(),mbstr.length());
			cout << "Done."<<endl ;
		}
	}
	ofs.close();	
	delete []buffer ;	
	return 0;
}
