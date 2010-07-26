/*
* Copyright (c) 2009 - 2010 Nokia Corporation and/or its subsidiary(-ies).
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
* configpaging mainfile to do configpaging in buildrom.
*
*/

#include <boost/regex.hpp>
#include <string>
#include <iostream>
#include <map>
#include <vector>
#include <fstream>
#include <malloc.h>

using namespace std;
using namespace boost ;

typedef const char* const_str ;

static const string NULL_STRING("");
static const char CONSTANT_UNPAGED[] = "unpaged";
static const char CONSTANT_PAGED[] = "paged";
static const char CONSTANT_UNPAGEDCODE[] = "unpagedcode";
static const char CONSTANT_PAGEDCODE[]	= "pagedcode";
static const char CONSTANT_UNPAGEDDATA[] = "unpageddata";
static const char CONSTANT_PAGEDDATA[] = "pageddata";
#ifdef WIN32 
static const char CONSTANT_CONFIG_PATH[] = "epoc32\\rom\\configpaging\\";
static string epocroot("\\");
static const char SLASH_CHAR = '\\';
#else
#include <strings.h>
#define strnicmp strncasecmp
#define _alloca alloca
static const char CONSTANT_CONFIG_PATH[] = "epoc32/rom/configpaging/";
static string epocroot("/");
static const char SLASH_CHAR = '/';
#endif 
static const char CONSTANT_CONFIG_FILE[] = "configpaging.cfg" ;
#define is_undef(s)		(0 == s.length())
static const int MAJOR_VERSION = 1;
static const int MINOR_VERSION = 2;
static const int BUILD_NUMBER  = 0;
static const char COPYRIGHT[]="Copyright (c) 2010 Nokia Corporation.";
struct ListElement{  
	const_str code ;
	const_str data ;	 
}; 


static string configlist ;
static regex e0("^(file|data|dll|secondary)(=|\\s+)",regex::perl|regex::icase);
static regex e1("^(code|data)?pagingoverride=(.*)\\s*",regex::perl);
static regex e2("^(un)?paged(code|data)?(\\s+(un)?paged(code|data)?)?:",regex::perl);
static regex e3("^include\\s*\"(.*)\"",regex::perl);
static regex e4("(\\S+)(\\s+(un)?paged(code|data)?(\\s+(un)?paged(code|data)?)?)?",regex::perl);
static regex e5("\\b(un)?paged(data)?\\b\\s*$",regex::perl|regex::icase);
static regex e6("\\b(un)?paged(code)?\\b\\s*$",regex::perl|regex::icase); 
static regex e7("\\b(un)?paged(code|data)?\\b",regex::perl|regex::icase); 
//static regex e8("tool=|\\s+)",regex::perl|regex::icase);

 

static bool is_obystatement(const char* aLine) {	 
	if(!strnicmp(aLine,"file",4)|| !strnicmp(aLine,"data",4))
		aLine += 4 ;
	else if(!strnicmp(aLine,"dll",3))
		aLine += 3;
	else if(!strnicmp(aLine,"secondary",9))
		aLine += 9 ;
	else
		return false ;

	return (*aLine =='=' || *aLine == ' '|| *aLine == '\t');
 
}
static void trim(string& aStr){

	char* data = const_cast<char*>(aStr.data());
	int length = aStr.length();
	int firstIndex = 0 ;
	int lastIndex = length - 1;
	// remove ending blanks	
	while(lastIndex >= 0 && (data[lastIndex] == ' ' || data[lastIndex] == '\t')){
		lastIndex -- ;
	}

	// remove heading blanks	
	while((firstIndex < lastIndex ) && (data[firstIndex] == ' ' || data[firstIndex] == '\t')){
		firstIndex ++ ;
	}	
	lastIndex++ ;
	if(lastIndex < length){
		aStr.erase(lastIndex,length - lastIndex);
	}
	if(firstIndex > 0){
		aStr.erase(0,firstIndex);
	}
}
static void make_lower(char* aStr,size_t aLength){

	for(size_t i = 0 ; i < aLength ; i++){
		if(aStr[i] >= 'A' && aStr[i] <= 'Z')
			aStr[i] |= 0x20 ;
	}
}
static bool readConfigFile(const_str& aCodePagingRef, const_str& aDataPagingRef,
		map<string,ListElement>& aListRef, const_str aFileName ) {
	ifstream is(aFileName, ios_base::binary | ios_base::in);
	if(!is.is_open()){
		cerr<< "Can not open \""<< aFileName << "\" for reading.\n";
		return false ;
	}
	const_str filecodepaging = "";
	const_str filedatapaging = "";
	match_results<string::const_iterator> what;

	is.seekg(0,ios::end);
	size_t size = is.tellg();
	is.seekg(0,ios::beg);

	char *buf = new char[size + 1];
	is.read(buf,size);
	buf[size] = '\n' ;

	char* end = buf + size ;
	char* lineStart = buf ;
	int lfcr ;
	string line ;

	while(lineStart < end ){
		// trim left ;
		while(*lineStart == ' ' || *lineStart == '\t' ){
			lineStart++ ;
		}
		char* lineEnd = lineStart;
		while(*lineEnd != '\r' && *lineEnd != '\n'){
			lineEnd++ ;
		}
		if(*lineEnd == '\r' && lineEnd[1] == '\n')
			lfcr = 2 ;
		else
			lfcr = 1 ;

		*lineEnd = 0 ;
		// empty line or comment
		if(lineEnd == lineStart || *lineStart == '#' ){
			lineStart = lineEnd + lfcr ;
			continue ;
		}
		size_t lenOfLine = lineEnd - lineStart;
		make_lower(lineStart,lenOfLine);
		line.assign(lineStart,lenOfLine);
			
		if(regex_search(line, what, e1)){
			string r1 = what[1].str();
			string r2 = what[2].str(); 
			if(is_undef(r1)){ //if ($1 eq undef)
				if(r2 == "defaultpaged"){
					aCodePagingRef = CONSTANT_PAGED ;
				} else if(r2 == "defaultunpaged"){
					aCodePagingRef = CONSTANT_UNPAGED ;
					aDataPagingRef = CONSTANT_UNPAGED;
				}else{
					cerr << "Configpaging Warning: invalid pagingoverride setting: "<< r2 <<"\n" ;
				}
			}else if(r1 == "code"){
				if(r2 == "defaultpaged"){
					aCodePagingRef = CONSTANT_PAGED ; 
				} else if(r2 == "defaultunpaged"){
					aCodePagingRef = CONSTANT_UNPAGED ; 
				}else{
					cerr << "Configpaging Warning: invalid codepagingoverride setting: "<< r2 <<"\n" ;
				}
			}
			else if(r1 == "data" ){
				if(r2 == "defaultpaged"){
					aDataPagingRef = CONSTANT_PAGED ; 
				} else if(r2 == "defaultunpaged"){
					aDataPagingRef = CONSTANT_UNPAGED ; 
				}else{
					cerr << "Configpaging Warning: invalid datapagingoverride setting: "<< r2 <<"\n" ;
				}
			}
		}// check e1
		else if(regex_search(line, what, e2)){
			string r1 = what[1].str();
			string r2 = what[2].str();	
			string r3 = what[3].str();	
			string r4 = what[4].str();	
			string r5 = what[5].str();   
			filecodepaging = "";
			filedatapaging = "";
			if (is_undef(r1)) {
				if (is_undef(r2)) {
					filecodepaging = CONSTANT_PAGED;
				}else if (r2 == "code") {
					filecodepaging = CONSTANT_PAGED;
				} else if(r2 == "data") {
					filedatapaging = CONSTANT_PAGED;
				} else {
					cerr << "Configpaging Warning: unrecognized line: "<< lineStart << "\n";
				}
			} else if (r1 == "un"){
				if (is_undef(r2)) { //$2 eq undef
					filecodepaging = CONSTANT_UNPAGED;
					filedatapaging = CONSTANT_UNPAGED;
				}else if (r2 == "code") {
					filecodepaging = CONSTANT_UNPAGED;
				} else if(r2 == "data") {
					filedatapaging = CONSTANT_UNPAGED;
				} else {
					cerr << "Configpaging Warning: unrecognized line: "<< lineStart << "\n";
				}
			} else {
				cerr << "Configpaging Warning: unrecognized line: "<< lineStart << "\n";
			}
			if (r3.length() > 0){		//$3 ne undef
				if (is_undef(r4)) {
					if (is_undef(r5)) {
						filecodepaging = CONSTANT_PAGED;
					}else if (r5 == "code") {
						filecodepaging = CONSTANT_PAGED;
					} else if(r5 == "data") {
						filedatapaging = CONSTANT_PAGED;
					} else {
						cerr << "Configpaging Warning: unrecognized line: "<< lineStart << "\n";
					}
				} else if (r4 == "un") {
					if (is_undef(r5)) {
						filecodepaging = CONSTANT_UNPAGED;
						filedatapaging = CONSTANT_UNPAGED;
					}else if (r5 == "code") {
						filecodepaging = CONSTANT_UNPAGED;
					} else if(r5 == "data") {
						filedatapaging = CONSTANT_UNPAGED;
					} else {
						cerr << "Configpaging Warning: unrecognized line: "<< lineStart << "\n";
					}
				} else {
					 cerr << "Configpaging Warning: unrecognized line: "<< lineStart << "\n";
				}
			}
		}
		else if(regex_search(line, what, e3)){
			string filename = epocroot + CONSTANT_CONFIG_PATH;
			filename += what[1].str();
			readConfigFile(aCodePagingRef, aDataPagingRef, aListRef, filename.c_str()); 
		}
		else if(regex_search(line, what, e4)){
			string r1 = what[1].str();
			string r2 = what[2].str();	
			string r3 = what[3].str();	
			string r4 = what[4].str();	
			string r5 = what[5].str();	
			string r6 = what[6].str();	
			string r7 = what[7].str(); 
			ListElement element = {aCodePagingRef, aDataPagingRef};
			if (is_undef(r2)){ //($2 eq undef){
				if (0 != *filecodepaging){//filecodepaging ne "") 
					element.code = filecodepaging;	//$element{code} = $filecodepaging;
				}
				if ( 0 != *filedatapaging){//$filedatapaging ne "") 
					element.data = filedatapaging ;//element.data = $filedatapaging;
				}
			} else {
				if (is_undef(r4)){//$4 eq undef
					if (is_undef(r3)) {//$3 eq undef
						element.code = CONSTANT_PAGED; 
					} else if (r3 == "un") {
						element.code = CONSTANT_UNPAGED; 
						element.data = CONSTANT_UNPAGED; 
					}
				} else if (r4 == "code") {
					if (is_undef(r3)) {
						element.code = CONSTANT_PAGED;
					} else if (r3 == "un") {
						element.code = CONSTANT_UNPAGED;
					}
				} else if (r4 == "data") {
					if (is_undef(r3)) {
						element.data = CONSTANT_PAGED;
					} else if (r3 == "un") {
						element.data = CONSTANT_UNPAGED;
					}
				} else {
					cerr << "Configpaging Warning: unrecognized attribute in line: "<< lineStart << "\n";
				}
				if (r5.length() > 0){//$5 ne undef
					if (is_undef(r7)){ //$7 eq undef
						if (is_undef(r6)) { //$6 eq undef
							element.code = CONSTANT_PAGED; 
						} else if (r6 == "un") {
							element.code = CONSTANT_UNPAGED; 
							element.data = CONSTANT_UNPAGED; 
						}
					} else if (r7 == "code") {
						if (is_undef(r6)) {
							element.code = CONSTANT_PAGED;
						} else if (r6 == "un") {
							element.code = CONSTANT_UNPAGED;
						}
					} else if (r7 == "data") {
						if (is_undef(r6)) {
							element.data = CONSTANT_PAGED;
						} else if (r6 == "un") {
							element.data = CONSTANT_UNPAGED;
						}
					} else {
						cerr << "Configpaging Warning: unrecognized attribute in line: "<< lineStart << "\n";
					}
				}
			}	
			//$$listref{$1} = \%element;
			aListRef.insert(pair<string,ListElement>(r1,element));
		}
		lineStart = lineEnd + lfcr ;
	}

	delete []buf ;
	is.close(); 
	
	return true ;
}

static bool match_icase(const string& a, const string& b){
	int la = a.length();
	int lb = b.length();
	char *copyOfA = (char*)_alloca(la+2);
	*copyOfA = ' ';
	copyOfA++ ;
	memcpy(copyOfA ,a.c_str(),la);
	copyOfA[la] = 0;
	char* end = &copyOfA[la];
	make_lower(copyOfA,la);
	while(copyOfA < end){
		char *found = strstr(copyOfA,b.c_str()); 
		if(0 == found)
			return false ;
		if((found[-1] == ' ' || found[-1] == '\\'|| found[-1] == '/'|| found[-1] == '\t' || found[-1] == '"'|| found[-1] == '=') &&
					( found[lb] == ' '|| found[lb] == '\t' || found[lb] == '"'|| found[lb] == '\0'))
			return true ;
		copyOfA = found + lb ;		 
	}

	return false ;
}

static void configpaging_single(){

	const_str codepaging="";
	const_str datapaging="";
	map<string, ListElement> list ;
	vector<string> keys ;//my @keys;
    string line ;

	cerr << "configpaging.exe: Modifying demand paging configuration using "<< configlist <<"\n";
	readConfigFile(codepaging, datapaging, list, configlist.c_str());
	match_results<string::const_iterator> what;
	string codepagingadd ,datapagingadd ;
	while(true){
		getline(cin,line); 		 
		if(cin.eof()) break ;
		if(line == ":q") break ;
		trim(line);
		const char* lineData = line.data();
		if(*lineData == '#' ){
			cout << lineData << "\n" ;
			continue ;
		}		 
		int length = line.length();
		if( length > 2){
			//check rem 			
			if((lineData[0] == 'R' || lineData[0] == 'r' ) && (lineData[1] == 'E' || lineData[1] == 'e' ) && (lineData[2] == 'M' || lineData[2] == 'm' )){
				cout << lineData << "\n" ;
				continue ;
			}
		}
		codepagingadd = "";
		datapagingadd = ""; 

		if(is_obystatement(lineData)){
			for( map<string,ListElement>::iterator it  = list.begin() ; it != list.end() ; it++){
				if(match_icase(line,it->first) ){
					if (it->second.code == CONSTANT_PAGED ){ 
						codepagingadd += " " ;
						codepagingadd += CONSTANT_PAGEDCODE;
					} else if (it->second.code == CONSTANT_UNPAGED) {  
						codepagingadd += " " ;
						codepagingadd += CONSTANT_UNPAGEDCODE;
					} 
					if (it->second.data == CONSTANT_PAGED) {  
						datapagingadd += " " ;
						datapagingadd += CONSTANT_PAGEDDATA;
					} else if  (it->second.data == CONSTANT_UNPAGED) {  
						datapagingadd += " " ;
						datapagingadd += CONSTANT_UNPAGEDDATA;
					}
					break ;
				}
			}//for 
			if (codepagingadd.length() == 0 && 0 != *codepaging) {//!$codepagingadd and $codepaging
				codepagingadd = " " ;
				codepagingadd += codepaging ;
				codepagingadd += "code";
			}
			if (datapagingadd.length() == 0 &&  0 != *datapaging) { //!$datapagingadd and $datapaging
				datapagingadd = " " ;
				datapagingadd += datapaging ;
				datapagingadd += "data";
					}
			if (codepagingadd.length() > 0 && datapagingadd.length() == 0){ //$codepagingadd and !$datapagingadd
				if (regex_search(line,what,e5)){  //$line =~ /\b(un)?paged(data)?\b\s*$/) { //$line =~ /\b(un)?paged(data)?\b\s*$/
					datapagingadd = " " ;
					if(what[1].length() > 0)
					{
						datapagingadd += what[1].str();
						datapagingadd += "pageddata";
					}
				}
			} else if (datapagingadd.length() > 0 && codepagingadd.length() == 0) {//$datapagingadd and !$codepagingadd
				if (regex_search(line,what,e6)){
					codepagingadd = " " ;
					codepagingadd += what[1].str();
					codepagingadd += "pagedcode";
				}
			}
			if (datapagingadd.length() > 0 || datapagingadd.length() > 0) { // $datapagingadd or $datapagingadd
				line = regex_replace(line,e7,NULL_STRING);
			} 
		}
		cout << line << codepagingadd << datapagingadd  << "\n";

	}
}
// 
int main(int argc , char* argv[]) {
 
	char* tmp = getenv("EPOCROOT"); 
	if(tmp && *tmp)
		epocroot = string(tmp);
	char ch = epocroot.at(epocroot.length() - 1);
	if(ch != '\\' && ch != '/')
		epocroot += SLASH_CHAR;
	
	if(argc > 1 ){
		char* arg = argv[1];
		if('-' == *arg && (arg[1] | 0x20) == 'v'){
			cout << "configpaging - The paging configuration plugin for BUILDROM V" ;
			cout << MAJOR_VERSION << "."<< MINOR_VERSION << "." << BUILD_NUMBER<< endl;			
			cout << COPYRIGHT << endl << endl; 
			return 0;
		}
		configlist = epocroot + CONSTANT_CONFIG_PATH; 
		configlist += string(arg);
	}
	else{
		configlist = epocroot + CONSTANT_CONFIG_PATH;
		configlist += CONSTANT_CONFIG_FILE;
	}
	configpaging_single(); 	

	return 0;
}
 
