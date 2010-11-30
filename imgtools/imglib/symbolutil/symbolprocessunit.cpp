/*
* Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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
#include <boost/regex.hpp>
#include "symbolprocessunit.h"
#include "e32image.h"
#include "symbolgenerator.h"
#include "h_utl.h"

#ifdef _MSC_VER
#define snprintf _snprintf
#endif 
#define MAX_LINE 65535

#if defined(__LINUX__)
#define PATH_SEPARATOR '/'
#else
#define PATH_SEPARATOR '\\'
#endif

void SymbolProcessUnit::ProcessEntry(const TPlacedEntry& aEntry)
{
	if(aEntry.iFileName == "")
		return;
	else if(aEntry.iExecutable)
		ProcessExecutableFile(aEntry.iFileName);
	else
		ProcessDataFile(aEntry.iFileName);
}
void SymbolProcessUnit::FlushStdOut(stringlist& aList)
{
	for(int i = 0; i < (int) iStdoutLog.size(); i++)
	{
		aList.push_back(iStdoutLog[i]);
	}
}
// CommenRomSymbolProcessUnit start

void CommenRomSymbolProcessUnit::FlushSymbolContent(ostream &aOut)
{
	for(int i = 0; i < (int) iSymbolContentLog.size(); i++)
	{
		aOut << iSymbolContentLog[i];
	}
}

void CommenRomSymbolProcessUnit::ResetContentLog()
{
	iStdoutLog.clear();
	iSymbolContentLog.clear();
}

void CommenRomSymbolProcessUnit::ProcessEntry(const TPlacedEntry& aEntry)
{
	iPlacedEntry = aEntry;
	SymbolProcessUnit::ProcessEntry(aEntry);
}

void CommenRomSymbolProcessUnit::ProcessExecutableFile(const string& aFile)
{
	ResetContentLog();
	char str[MAX_LINE];
	string outString;
	outString = "\nFrom    ";
	outString += aFile + "\n\n";
	iSymbolContentLog.push_back(outString);
	string mapFile2 = aFile+".map";
	size_t dot = aFile.rfind('.');
	string mapFile = aFile.substr(0,dot)+".map";
	ifstream fMap;
	fMap.open(mapFile2.c_str());
	if(!fMap.is_open()) {
		fMap.open(mapFile.c_str());
	}

	if(!fMap.is_open()) {
		sprintf(str, "\nWarning: Can't open \"%s\" or \"%s\"\n",mapFile2.c_str(),mapFile.c_str());
		iStdoutLog.push_back(str);
	    memset(str,0,sizeof(str));
	    sprintf(str, "%08x    %04x    ", (unsigned int)iPlacedEntry.iCodeAddress, (unsigned int)iPlacedEntry.iTotalSize);
	    outString = str;
	    outString += aFile.substr(aFile.rfind(PATH_SEPARATOR)+1)+"\n";
	    iSymbolContentLog.push_back(outString);
	}
	else {
	    if(!fMap.good()) fMap.clear();
	    char buffer[100];
	    fMap.getline(buffer, 100);
	    boost::regex regARMV5("ARM Linker", boost::regex::icase);
	    boost::regex regGCCEoARMV4("Archive member included", boost::regex::icase);
	    boost::cmatch what;
	    if(regex_search(buffer, what, regARMV5)) {
	        ProcessArmv5File(aFile, fMap);
	    }
	    else if(regex_search(buffer, what, regGCCEoARMV4)) {
	        ProcessGcceOrArm4File(aFile, fMap);
	    }
	    else {
		fMap.seekg(0, ios_base::beg);
		ProcessX86File(aFile, fMap);
	    }
	}
}

void CommenRomSymbolProcessUnit::ProcessDataFile(const string& aFile)
{
	ResetContentLog();
	char str[MAX_LINE];
	memset(str,0,sizeof(str));
	string basename = aFile.substr(aFile.rfind(PATH_SEPARATOR)+1);
	sprintf(str, "\nFrom    %s\n\n%08x    0000    %s\n", aFile.c_str(), (unsigned int) iPlacedEntry.iDataAddress, basename.c_str());
	iSymbolContentLog.push_back(str);
}

struct ArmSymbolInfo {
	string name ;
	TUint size ;
	string section ;
};
typedef multimap<TUint32,ArmSymbolInfo> ArmSymMap ;

#define SKIP_WS(p)	 while((*p) == ' ' ||  (*p) == '\t') (p)++ 
#define FIND_WS(p)	 while((*p) != ' ' &&  (*p) != '\t' && (*p) != 0) (p)++ 
static void split(char* str, vector<char*>& result) {
	result.clear();
	while(*str) {
		SKIP_WS(str);
		char* saved = str ; 
		FIND_WS(str);
		bool end = (0 == *str);
		*str = 0 ; 
		if(saved != str)
			result.push_back(saved);		
		if(!end) str ++ ; 
	}	 
}
static void make_lower(char* str){
	while(*str){
		if(*str >= 'A' && *str >= 'Z') {
			*str += ('a' - 'A');
		}
		str++;
	}
}

void CommenRomSymbolProcessUnit::ProcessArmv5File(const string& aFile, ifstream& aMap)
{
	string symName ; 
	ArmSymMap symbols ; 
	vector<char*> words ;
	ArmSymbolInfo info;
	char* lineStart ;
	char buffer[MAX_LINE];  
	while(aMap.good() && (!aMap.eof())){
		*buffer = 0;
		aMap.getline(buffer,MAX_LINE);
		lineStart = buffer ;
		SKIP_WS(lineStart);	 
		if(strstr(lineStart,"Global Symbols"))
			break ;
		char* armstamp = strstr(lineStart,"ARM Code");
		if(0 == armstamp)
			armstamp = strstr(lineStart,"Thumb Code") ;
		if(0 == armstamp) continue ; 
		*(armstamp - 1) = 0 ;
		
		char* hexStr = lineStart ;
		char* nameEnd;
		while(1) {
			hexStr = strstr(hexStr,"0x");
			if(0 == hexStr) break ; 		
			nameEnd = hexStr - 1;
			if(*nameEnd == ' ' || *nameEnd == '\t') break ;
			hexStr += 2 ;
		}	 
		if(0 == hexStr) continue ; 	
		while(nameEnd > lineStart && (*nameEnd == ' ' || *nameEnd == '\t'))
			nameEnd -- ;
		
		nameEnd[1] = 0;
		info.name = lineStart;		
		char* temp ;
		TUint32 addr = strtoul(hexStr + 2,&temp,16);
		char* decStr ;
		if(*armstamp == 'A')
			decStr = armstamp + 9 ;
		else 
			decStr = armstamp + 11 ;
		SKIP_WS(decStr);
		info.size = strtoul(decStr,&temp,10);
		SKIP_WS(temp);
		info.section = temp;
		if(info.section.find("(StubCode)") != string::npos )
			info.size = 8 ; 			
		if(addr > 0){
			symbols.insert(pair<TUint32,ArmSymbolInfo>(addr,info));
		}
	}	 
	size_t lenOfFileName = iPlacedEntry.iFileName.length();
	while(aMap.good() && (!aMap.eof())){
		*buffer = 0;
		aMap.getline(buffer,MAX_LINE);
		lineStart = buffer ;
		SKIP_WS(lineStart); 
		char* hexStr = lineStart ;
		char* nameEnd;
		while(1) {
			hexStr = strstr(hexStr,"0x");
			if(0 == hexStr) break ; 		
			nameEnd = hexStr - 1;
			if(*nameEnd == ' ' || *nameEnd == '\t') 
				break ;
			hexStr += 2 ;
		}	 
		if(0 == hexStr) continue ; 
		while(nameEnd > lineStart && (*nameEnd == ' ' || *nameEnd == '\t')){
			nameEnd -- ;
		}
		nameEnd[1] = 0;
		info.name = lineStart; 
		char *temp ;
		TUint32 addr = strtoul(hexStr + 2,&temp,16);
		while(*temp < '0' || *temp > '9' )//[^\d]*
			temp++ ;
		char* decStr = temp ;
		info.size = strtoul(decStr,&temp,10);
		SKIP_WS(temp);
		info.section = temp;
		if(info.section.find("(StubCode)") != string::npos )
			info.size = 8 ; 
		if(addr > 0){
			symbols.insert(pair<TUint32,ArmSymbolInfo>(addr,info));
		} 
	}
	
	TUint32 textSectAddr = 0x00008000;  // .text gets linked at 0x00008000
	TUint32 dataSectAddr = 0x00400000 ; // .data gets linked at 0x00400000
	vector<pair<int,char*> > lines ;	
	size_t allocBytes;
	for( ArmSymMap::iterator it = symbols.begin(); it != symbols.end() ; it++){
		TUint32 thisAddr = it->first ;
		TUint32 romAddr ;
		ArmSymbolInfo& info = it->second; 
		if (thisAddr >= textSectAddr && thisAddr <= (textSectAddr + iPlacedEntry.iTextSize)) {
				romAddr = thisAddr - textSectAddr + iPlacedEntry.iCodeAddress ;
		} 
		else if ( iPlacedEntry.iDataAddress && 
			( thisAddr >= dataSectAddr && thisAddr <= (dataSectAddr + iPlacedEntry.iTextSize))) {
			romAddr = thisAddr-dataSectAddr + iPlacedEntry.iDataBssLinearBase;
		} 
		else if ( iPlacedEntry.iDataBssLinearBase && 
			( thisAddr >= dataSectAddr && thisAddr <= (dataSectAddr+ iPlacedEntry.iTotalDataSize))) {
			romAddr = thisAddr - dataSectAddr + iPlacedEntry.iDataBssLinearBase;
		} 
		else { 
			allocBytes = info.name.length() + 60;
			char* msg = new char[allocBytes] ;
			snprintf(msg,allocBytes,"\r\nWarning: Symbol %s @ 0x%08x not in text or data segments\r\n", \
				info.name.c_str() ,(unsigned int)thisAddr) ; 
			iStdoutLog.push_back(msg);	
			allocBytes = lenOfFileName + 80;
			msg = new char[allocBytes];
			snprintf(msg,allocBytes,"Warning:  The map file for binary %s is out-of-sync with the binary itself\r\n\r\n",iPlacedEntry.iFileName.c_str());
			iStdoutLog.push_back(msg);	
			continue ;
		}
		allocBytes =  info.section.length() + info.name.length() + 140;
		char* outputLine = new char[allocBytes];
		int len = snprintf(outputLine,allocBytes,"%08x    %04x    %-40s  %s\r\n",(unsigned int)romAddr,info.size,
			info.name.c_str(),info.section.c_str()); 
		if((size_t)len > allocBytes) {
			allocBytes = len + 4 ;
			delete []outputLine;
			outputLine = new char[allocBytes];
			len = snprintf(outputLine,allocBytes,"%08x    %04x    %-40s  %s\r\n",(unsigned int)romAddr,info.size,
			info.name.c_str(),info.section.c_str()); 
		}
		lines.push_back(pair<int,char*>(len,outputLine));
	 
	} 

	for (vector<pair<int,char*> >::iterator i = lines.begin() ; i < lines.end(); i ++ ) {
		char* line = i->second; 
		iSymbolContentLog.push_back(line);
		delete[] line;
	}
}

template<typename M, typename K,typename V> 
static void put_to_map(M& m,const K& k, const V& v) {
	typedef typename M::iterator iterator;
	iterator it = m.find(k);
	if(m.end() == it){
		m.insert(pair<K,V>(k,v));
	}
	else { 
		it->second = v ;
	}	
}

void CommenRomSymbolProcessUnit::ProcessGcceOrArm4File(const string& aFile, ifstream& aMap)
{
	char* lineStart; 
	vector<char*> words ;
	char buffer[MAX_LINE];
	while(aMap.good() && (!aMap.eof())){
		aMap.getline(buffer,MAX_LINE);
		lineStart = buffer ;
		SKIP_WS(lineStart);
		if( 0 == strncmp(lineStart,".text",5)) {
			lineStart += 5;
			break ;
		}		
	}
	split(lineStart,words);
	TUint32 codeAddr , codeSize;
	size_t allocBytes ;
	if(words.size() != 2 ||
	KErrNone != Val(codeAddr,words.at(0)) || 
	KErrNone != Val(codeSize,words.at(1))) {
		allocBytes = iPlacedEntry.iFileName.length() + 60;
		char* msg = new char[allocBytes];
		snprintf(msg,allocBytes,"\nError: Can't get .text section info for \"%s\"\r\n",iPlacedEntry.iFileName.c_str());
		iStdoutLog.push_back(msg);
		return;
	}
	map<TUint32,string> symbols ;
	TUint32 stubHex = 0;
	//Slurp symbols 'til the end of the text section
	while(aMap.good() && (!aMap.eof())){
		aMap.getline(buffer,MAX_LINE);
		lineStart = buffer ;
		SKIP_WS(lineStart); 
		if(0 == *lineStart) break ; //blank line marks the end of the text section
		
		// .text <addr> <len>  <library(member)>
		// .text$something
		//       <addr> <len>  <library(member)>
		//       <addr> <len>  LONG 0x0
		// (/^\s(\.text)?\s+(0x\w+)\s+(0x\w+)\s+(.*)$/io)	 
		if(strncmp(lineStart,".text",5) == 0){
			lineStart += 5 ;
			SKIP_WS(lineStart);
		}
		char* hex1 = NULL ;
		char* hex2 = NULL ;
		char* strAfterhex1 = NULL ;
		TUint32 addr,size ;
		if(strncmp(lineStart,"0x",2) == 0){
			hex1 = lineStart + 2;
			char* temp ;
			addr = strtoul(hex1,&temp,16);
			SKIP_WS(temp);
			strAfterhex1 = temp ;
			if(strncmp(temp,"0x",2) == 0){
				hex2 = temp + 2 ;
			}
		}
		if(NULL != hex2){
			char* libraryfile ;
			size = strtoul(hex2,&libraryfile,16);
			SKIP_WS(libraryfile);  
			TUint32 key = addr + size ;
			put_to_map(symbols,key,string(""));//impossible symbol as end marker 
			make_lower(libraryfile); 
			// EUSER.LIB(ds01423.o)
			// EUSER.LIB(C:/TEMP/d1000s_01423.o)
			size_t len = strlen(libraryfile);
			char* p1 = strstr(libraryfile,".lib(");
			if(NULL == p1) 
				continue ; 
			p1 += 5;
			if(strcmp(libraryfile + len - 3,".o)")!= 0)
				continue ;		 
			len -= 3 ;
			libraryfile[len] = 0; 
			if(EFalse == IsValidNumber(libraryfile + len - 5))
				continue ;
			len -= 7 ;
			if('_' == libraryfile[len])
				len -- ;
			if('s' != libraryfile[len])
				continue ;		 
			char* p2 = libraryfile + len - 1;
			while(p2 > p1 ) { 
				if(*p2 < '0' || *p2 > '9')
					break ;
				p2 -- ;
			}
			if(*p2 != 'd') 
				continue ;
			stubHex = addr ;
		}
		else if(NULL != hex1 && NULL != strAfterhex1){ 
			//#  <addr>  <symbol name possibly including spaces>
			//(/^\s+(\w+)\s\s+([a-zA-Z_].+)/o) 			 
			char* symName = strAfterhex1; 
			if((*symName >= 'A' && *symName <= 'Z') ||
				(*symName >= 'a' && *symName <= 'z') || *symName == '_') {				 
				string symbol(symName);
				if(addr == stubHex) 
					symbol.insert(0,"stub ");
			 
				put_to_map(symbols,addr,symbol);
				 
			}			
		}		
	}  
	map<TUint32,string>::iterator it = symbols.begin();
	TUint32 lastAddr = it->first;
	string lastSymName = it->second;
	vector<pair<int,char*> >lines ;
	it ++ ;
	while(it != symbols.end()) {		
		TUint32 addr = it->first ; 
		unsigned int fixedupAddr = lastAddr - codeAddr + iPlacedEntry.iCodeAddress;
		TUint size = addr - lastAddr ;
		if(!lastSymName.empty()) {
			allocBytes = lastSymName.length() + 40;
			char* outputLine = new char[allocBytes];
			int n = snprintf(outputLine,allocBytes,"%08x    %04x    %s\r\n", fixedupAddr,size,lastSymName.c_str()); 
			lines.push_back(pair<int,char*>(n,outputLine));
		}		
		lastAddr = addr ;
		lastSymName = it->second;
		it ++ ;
	}
	
	vector<pair<int,char*> >::iterator i; 
	for ( i = lines.begin() ; i < lines.end(); i ++ ) {
		char* line = i->second ;
		iSymbolContentLog.push_back(line);
		delete []line ;
	}
}

void CommenRomSymbolProcessUnit::ProcessX86File(const string& aFile, ifstream& aMap)
{
	char buffer[MAX_LINE]; 
	char* lineStart; 
	while(aMap.good() && (!aMap.eof())){
		aMap.getline(buffer,MAX_LINE);
		lineStart = buffer ;
		SKIP_WS(lineStart);
		if( 0 == strncmp(lineStart,"Address",7)) { 
			break ;
		}		
	}
	aMap.getline(buffer,MAX_LINE);
	string lastName ;
	TUint32 lastAddr = 0;
	size_t allocBytes ;
	vector<pair<int, char*> >lines ;
	while(aMap.good() && (!aMap.eof())){
		aMap.getline(buffer,MAX_LINE);
		lineStart = buffer ;
		SKIP_WS(lineStart);
		if(0 != strncmp(lineStart,"0001:",5))
			break ;		 
		char* end ; 
		TUint32 addr = strtoul(lineStart + 5,&end,16);
		char* name = end + 1;
		SKIP_WS(name);
		end = name + 1;
		FIND_WS(end);
		*end = 0 ;
		if(!lastName.empty()){
			unsigned int size = addr - lastAddr ; 
			unsigned int romAddr = lastAddr + iPlacedEntry.iCodeAddress;
			allocBytes = lastName.length() + 40;
			char* outputLine = new char[allocBytes];
			int n = snprintf(outputLine,allocBytes,"%08x    %04x    %s\r\n",romAddr,size,lastName.c_str());
			lines.push_back(pair<int, char*>(n,outputLine));
		}
		lastName = name;
		lastAddr = addr;		
	}

	vector<pair<int,char*> >::iterator it; 
	for ( it = lines.begin() ; it < lines.end(); it ++ ) {
		char* line = it->second  ;
		iSymbolContentLog.push_back(line);
		delete []line ;
	}	
	if(!lastName.empty()){
		allocBytes = lastName.length() + 40 ;
		char* outputLine = new char[allocBytes];
		unsigned int romAddr = lastAddr + iPlacedEntry.iCodeAddress;
		snprintf(outputLine,allocBytes,"%08x    0000    %s\r\n",romAddr,lastName.c_str());
		iSymbolContentLog.push_back(outputLine);
		delete []outputLine ;
	}
}
// CommenRomSymbolProcessUnit end
// CommenRofsSymbolProcessUnit start 
void CommenRofsSymbolProcessUnit::ProcessExecutableFile(const string& aFile)
{
	ResetContentLog();
	char str[MAX_LINE];
	string outString;
	outString = "\nFrom    ";
	outString += aFile + "\n\n";
	iSymbolContentLog.push_back(outString);
	string mapFile2 = aFile+".map";
	size_t dot = aFile.rfind('.');
	string mapFile = aFile.substr(0,dot)+".map";
	ifstream fMap;
	fMap.open(mapFile2.c_str());
	if(!fMap.is_open()) {
		fMap.open(mapFile.c_str());
	}

	if(!fMap.is_open()) {
		sprintf(str, "%s\nWarning: Can't open \"%s\" or \"%s\"\n",aFile.c_str(),mapFile2.c_str(),mapFile.c_str());
		iStdoutLog.push_back(str);
	    int binSize = GetSizeFromBinFile(aFile);
	    memset(str,0,sizeof(str));
	    sprintf(str,"%04x", binSize);
	    outString = "00000000    ";
	    outString += str;
	    outString += "    ";
	    outString += aFile.substr(aFile.rfind(PATH_SEPARATOR)+1)+"\n";
	    iSymbolContentLog.push_back(outString);
	}
	else {
		if(!fMap.good()) fMap.clear();
	    boost::regex regARMV5("ARMV5", boost::regex::icase);
	    boost::regex regGCCEoARMV4("(GCCE|ARMV4)", boost::regex::icase);
	    boost::cmatch what;
	    if(regex_search(aFile.c_str(), what, regARMV5)) {
	        ProcessArmv5File(aFile, fMap);
	    }
	    else if(regex_search(aFile.c_str(), what, regGCCEoARMV4)) {
	        ProcessGcceOrArm4File(aFile, fMap);
	    }
	    else {
	        sprintf(str, "\nWarning: cannot determine linker type used to create %s\n",aFile.c_str());
	        iStdoutLog.push_back(str);
	        outString = "00000000    0000    ";
	        outString += aFile.substr(aFile.rfind(PATH_SEPARATOR)+1)+"\n";
	        iSymbolContentLog.push_back(outString);
	        }
	    }
}
void CommenRofsSymbolProcessUnit::ProcessDataFile(const string& aFile)
{
	ResetContentLog();
	string line = "\nFrom    "+aFile+"\n\n00000000    0000    "+aFile.substr(aFile.rfind(PATH_SEPARATOR)+1)+"\n";
	iSymbolContentLog.push_back(line);
}
void CommenRofsSymbolProcessUnit::FlushSymbolContent(ostream &aOut)
{
	for(int i = 0; i < (int) iSymbolContentLog.size(); i++)
	{
		aOut << iSymbolContentLog[i];
	}
}
void CommenRofsSymbolProcessUnit::ResetContentLog()
{
	iStdoutLog.clear();
	iSymbolContentLog.clear();
}
void CommenRofsSymbolProcessUnit::ProcessArmv5File( const string& fileName, ifstream& aMap ){
    aMap.seekg (0, ios::beg);
    char str[MAX_LINE];
    char outbuffer[MAX_LINE];
    string outString;
    aMap.getline(str,MAX_LINE);
    boost::cmatch what;
    boost::regex reg("^ARM Linker");
    if(!regex_search(str, what, reg)) {
        sprintf(outbuffer, "\nWarning: expecting %s to be generated by ARM linker\n", fileName.c_str());
        iStdoutLog.push_back(outbuffer);
        outString = "00000000    0000    "+fileName.substr(fileName.rfind(PATH_SEPARATOR)+1)+"\n";
        iSymbolContentLog.push_back(outString);
    }
    reg.assign("Global Symbols");
    while(aMap.getline(str,MAX_LINE)) {
        if(regex_search(str, what, reg)) {
            break;
        }
    }

    reg.assign("^\\s*(.+)\\s*0x(\\S+)\\s+[^\\d]*(\\d+)\\s+(.*)$");
    string sSym,sTmp,sSection;
    unsigned int addr,size,baseOffset = 0;
    map<unsigned int,string> syms;
    char symString[MAX_LINE];
    while(aMap.getline(str,MAX_LINE)) {
        if(regex_search(str, what, reg)) {
            sSym.assign(what[1].first,what[1].second-what[1].first);
            sTmp.assign(what[2].first,what[2].second-what[2].first);
            addr = strtol(sTmp.c_str(), NULL, 16);
            sTmp.assign(what[3].first,what[3].second-what[3].first);
            size = strtol(sTmp.c_str(), NULL, 10);
            sSection.assign(what[4].first,what[4].second-what[4].first);
            if(sSection.find("(StubCode)") != string::npos)
                size = 8;
            if(addr > 0) {
                memset(symString,0,sizeof(symString));
                sprintf(symString,"%04x    ",size);
                outString = symString;
                outString += sSym+" ";
                outString += sSection;
                if(baseOffset == 0)
                    baseOffset = addr;
                unsigned int k = addr - baseOffset;
                if( (syms.find(k) == syms.end()) || size != 0)
                    syms[k] = outString;
            }
            // end of addr>0
        }
        // end of regex_search
    }

    map<unsigned int,string>::iterator it;
    for(it = syms.begin(); it != syms.end(); it++) {
        memset(str,0,sizeof(str));
        sprintf(str,"%08x",it->first);
        outString = str;
        outString += "    ";
        outString += it->second+"\n";
        iSymbolContentLog.push_back(outString);
    }
}
void CommenRofsSymbolProcessUnit::ProcessGcceOrArm4File( const string& fileName, ifstream& aMap ){
    aMap.seekg (0, ios_base::beg);
    char str[MAX_LINE];
    char outbuffer[MAX_LINE];
    aMap.getline(str,MAX_LINE);
    boost::cmatch what;
    boost::regex reg("^\\.text\\s+");
    while(aMap.getline(str,MAX_LINE)) {
        if(regex_search(str, what, reg)) {
            break;
        }
    }

    reg.assign("^\\.text\\s+(\\w+)\\s+\\w+");
    if(!regex_search(str, what, reg)) {
        sprintf(outbuffer, "ERROR: Can't get .text section info for \"%s\"\n",fileName.c_str());
        iStdoutLog.push_back(outbuffer);
    }
    else {
        string sTmp, sLibFile;
        sTmp.assign(what[1].first,what[1].second-what[1].first);
        unsigned int imgText = strtol(sTmp.c_str(), NULL, 16);

        reg.assign("^LONG 0x.*", boost::regex::icase);
        boost::cmatch what1;
        boost::regex reg1("^\\s(\\.text)?\\s+(0x\\w+)\\s+(0x\\w+)\\s+(.*)$", boost::regex::icase);
        boost::regex reg2("^\\s+(\\w+)\\s\\s+([a-zA-Z_].+)", boost::regex::icase);
        boost::regex reg3(".*lib\\(.*d\\d*s_?\\d{5}.o\\)$", boost::regex::icase);

        map<unsigned int,string> syms;
        unsigned int addr, len, stubhex;

        while(aMap.getline(str,MAX_LINE)) {
            if(strlen(str) == 0)
                break;
            else if(regex_search(str, what, reg1)) {
                sLibFile.assign(what[4].first,what[4].second-what[4].first);
                if(!regex_search(sLibFile.c_str(), what1, reg)) {
                    sTmp.assign(what[2].first,what[2].second-what[2].first);
                    addr = strtol(sTmp.c_str(), NULL, 16);
                    sTmp.assign(what[3].first,what[3].second-what[3].first);
                    len = strtol(sTmp.c_str(), NULL, 16);
                    syms[addr+len] = "";
                    if(regex_search(sLibFile.c_str(), what, reg3)) {
                        stubhex = addr;
                    }
                }
            }
            else if(regex_search(str, what, reg2)) {
                sTmp.assign(what[1].first,what[1].second-what[1].first);
                addr = strtol(sTmp.c_str(), NULL, 16);
                sTmp.assign(what[2].first,what[2].second-what[2].first);
                syms[addr] = (addr == stubhex)? ("stub "+sTmp) : sTmp;
            }
        }

        map<unsigned int,string>::iterator it = syms.begin();
        map<unsigned int,string>::iterator itp = it++;
        string outString;
        for(; it != syms.end(); itp = it++) {
            if(itp->second != "") {
                memset(str,0,sizeof(str));
                sprintf(str,"%08x    %04x    ",(itp->first-imgText), (it->first-itp->first));
                outString = str;
                outString += it->second+"\n";
                iSymbolContentLog.push_back(outString);
            }
        }
    }
}
// CommenRofsSymbolProcessUnit end
int SymbolProcessUnit::GetSizeFromBinFile( const string& fileName ){
    TInt ret = 0;
    //char outbuffer[MAX_LINE];
    ifstream aIf(fileName.c_str(), ios_base::binary);
    if( !aIf.is_open() ) {
        printf("Warning: Cannot open file %s\n", fileName.c_str());
        //iStdoutLog.push_back(outbuffer);
    }
    else {
        E32ImageFile e32Image;
        TUint32 aSz;

        aIf.seekg(0,ios_base::end);
        aSz = aIf.tellg();

        e32Image.Adjust(aSz);
        e32Image.iFileSize = aSz;

        aIf.seekg(0,ios_base::beg);
        aIf >> e32Image;
        ret = e32Image.iOrigHdr->iCodeSize;
    }
    return ret;
}

// for BSym
void BsymRofsSymbolProcessUnit::ProcessEntry(const TPlacedEntry& aEntry)
{
	SymbolProcessUnit::ProcessEntry(aEntry);
	if(aEntry.iFileName == "")
		return;
	else if(aEntry.iExecutable)
		ProcessExecutableFile(aEntry.iFileName);
	else
		ProcessDataFile(aEntry.iFileName);
	iMapFileInfo.iDbgUnitPCEntry.iPCName = aEntry.iFileName;
	iMapFileInfo.iDbgUnitPCEntry.iDevName = aEntry.iDevFileName;
}

void BsymRofsSymbolProcessUnit::ProcessExecutableFile(const string& aFile)
{
	ResetContentLog();
	char str[MAX_LINE];
	string mapFile2 = aFile+".map";
	size_t dot = aFile.rfind('.');
	string mapFile = aFile.substr(0,dot)+".map";
	ifstream fMap;
	fMap.open(mapFile2.c_str());
	if(!fMap.is_open()) {
		fMap.open(mapFile.c_str());
	}

	if(!fMap.is_open()) {
		sprintf(str, "%s\nWarning: Can't open \"%s\" or \"%s\"\n",aFile.c_str(),mapFile2.c_str(),mapFile.c_str());
		iStdoutLog.push_back(str);
	    int binSize = GetSizeFromBinFile(aFile);
	    TSymbolPCEntry tmpEntry;
	    tmpEntry.iSymbolEntry.iAddress = 0;
	    tmpEntry.iSymbolEntry.iLength = binSize;
	    tmpEntry.iName = aFile.substr(aFile.rfind(PATH_SEPARATOR)+1);
	    iMapFileInfo.iSymbolPCEntrySet.push_back(tmpEntry);
	    iMapFileInfo.iDbgUnitPCEntry.iDbgUnitEntry.iDataSymbolCount++;
	}
	else {
		if(!fMap.good()) fMap.clear();
	    boost::regex regARMV5("ARMV5", boost::regex::icase);
	    boost::regex regGCCEoARMV4("(GCCE|ARMV4)", boost::regex::icase);
	    boost::cmatch what;
	    if(regex_search(aFile.c_str(), what, regARMV5)) {
	        ProcessArmv5File(aFile, fMap);
	    }
	    else if(regex_search(aFile.c_str(), what, regGCCEoARMV4)) {
	        ProcessGcceOrArm4File(aFile, fMap);
	    }
	    else {
	        sprintf(str, "\nWarning: cannot determine linker type used to create %s\n",aFile.c_str());
	        iStdoutLog.push_back(str);
	    	TSymbolPCEntry tmpEntry;
	    	tmpEntry.iSymbolEntry.iAddress = 0;
	    	tmpEntry.iSymbolEntry.iLength = 0;
	    	tmpEntry.iName = aFile.substr(aFile.rfind(PATH_SEPARATOR)+1);
	    	iMapFileInfo.iSymbolPCEntrySet.push_back(tmpEntry);
	    	iMapFileInfo.iDbgUnitPCEntry.iDbgUnitEntry.iDataSymbolCount++;
	        }
	    }
}
void BsymRofsSymbolProcessUnit::ProcessDataFile(const string& aFile)
{
	ResetContentLog();
	TSymbolPCEntry tmpEntry;
	tmpEntry.iSymbolEntry.iAddress = 0;
	tmpEntry.iSymbolEntry.iLength = 0;
	tmpEntry.iName = aFile.substr(aFile.rfind(PATH_SEPARATOR)+1);
	iMapFileInfo.iSymbolPCEntrySet.push_back(tmpEntry);
	iMapFileInfo.iDbgUnitPCEntry.iDbgUnitEntry.iDataSymbolCount++;
}
void BsymRofsSymbolProcessUnit::FlushSymbolContent(ostream &aOut)
{
	iSymbolGeneratorPtr->AppendMapFileInfo(iMapFileInfo);
}
void BsymRofsSymbolProcessUnit::ResetContentLog()
{
	iStdoutLog.clear();
	iMapFileInfo.iDbgUnitPCEntry.iPCName = "";
	iMapFileInfo.iDbgUnitPCEntry.iDevName = "";
	iMapFileInfo.iDbgUnitPCEntry.iDbgUnitEntry.Reset();
	iMapFileInfo.iSymbolPCEntrySet.clear();
}
void BsymRofsSymbolProcessUnit::ProcessArmv5File( const string& fileName, ifstream& aMap ){
    aMap.seekg (0, ios::beg);
    char str[MAX_LINE];
    char outbuffer[MAX_LINE];
    aMap.getline(str,MAX_LINE);
    boost::cmatch what;
    boost::regex reg("^ARM Linker");
    if(!regex_search(str, what, reg)) {
        sprintf(outbuffer, "\nWarning: expecting %s to be generated by ARM linker\n", fileName.c_str());
        iStdoutLog.push_back(outbuffer);
	return;
    }
    reg.assign("Global Symbols");
    boost::regex bss_search("^\\s*\\.bss\\s*0x(\\S+)\\s*.*$");
    bool hasValue = false;
    string bssStart;
    TUint32 bssSection = 0;
    while(aMap.getline(str,MAX_LINE)) {
	if(!hasValue && regex_search(str, what, bss_search))
	{
	    hasValue = true;
            bssStart.assign(what[1].first,what[1].second-what[1].first);
	}
        if(regex_search(str, what, reg)) {
            break;
        }
    }
    if(!bssStart.empty())
    {
	bssSection = strtol(bssStart.c_str(), NULL, 16);
    }
    reg.assign("^\\s*(.+)\\s*0x(\\S+)\\s+[^\\d]*(\\d+)\\s+(.*)$");
    string sSym,sTmp,sSection,scopeName, symName;
    boost::regex regScope("^\\s*(\\w+)\\s*::\\s*(.*)$");
    unsigned int addr,size,baseOffset = 0;
    map<unsigned int, TSymbolPCEntry> syms;
    TUint32 dataStart = 0x400000;
    while(aMap.getline(str,MAX_LINE)) {
        if(regex_search(str, what, reg)) {
            sSym.assign(what[1].first,what[1].second-what[1].first);
            sTmp.assign(what[2].first,what[2].second-what[2].first);
            addr = strtol(sTmp.c_str(), NULL, 16);
            sTmp.assign(what[3].first,what[3].second-what[3].first);
            size = strtol(sTmp.c_str(), NULL, 10);
            sSection.assign(what[4].first,what[4].second-what[4].first);
            if(sSection.find("(StubCode)") != string::npos)
                size = 8;
            if(addr > 0) {
                if(baseOffset == 0)
                    baseOffset = addr;
                unsigned int k = addr - baseOffset;
                if( (syms.find(k) == syms.end()) || size != 0)
                {
                	TSymbolPCEntry tmpEntry;
                	if(regex_search(sSym.c_str(), what, regScope))
                	{
                		scopeName.assign(what[1].first, what[1].second-what[1].first);
                		symName.assign(what[2].first, what[2].second-what[2].first);
                		tmpEntry.iScopeName = scopeName;
                		tmpEntry.iName = symName;
                		tmpEntry.iSecName = sSection;
                	}
                	else
                	{
                		tmpEntry.iScopeName = "";
                		tmpEntry.iName = sSym;
                		tmpEntry.iSecName = sSection;
                	}
                	tmpEntry.iSymbolEntry.iAddress = k;
                	tmpEntry.iSymbolEntry.iLength = size;
			syms[k]=tmpEntry;
                }

            }
            // end of addr>0
        }
        // end of regex_search
    }

    map<unsigned int, TSymbolPCEntry>::iterator it;
    for(it = syms.begin(); it != syms.end(); it++) {
	    unsigned int addr = it->first;
	    if(addr < dataStart)
	    {
	        iMapFileInfo.iDbgUnitPCEntry.iDbgUnitEntry.iCodeSymbolCount++;
	    }
	    else
	    {
	        if(bssSection > 0 && addr >= bssSection)
		{
		    iMapFileInfo.iDbgUnitPCEntry.iDbgUnitEntry.iBssSymbolCount++;
	        }
		else
	        {
		    iMapFileInfo.iDbgUnitPCEntry.iDbgUnitEntry.iDataSymbolCount++;
	        }
	    }
            iMapFileInfo.iSymbolPCEntrySet.push_back(it->second);
    }
}
void BsymRofsSymbolProcessUnit::ProcessGcceOrArm4File( const string& fileName, ifstream& aMap ){
    aMap.seekg (0, ios_base::beg);
    char str[MAX_LINE];
    char outbuffer[MAX_LINE];
    aMap.getline(str,MAX_LINE);
    boost::cmatch what;
    boost::regex reg("^\\.text\\s+");
    while(aMap.getline(str,MAX_LINE)) {
        if(regex_search(str, what, reg)) {
            break;
        }
    }

    reg.assign("^\\.text\\s+(\\w+)\\s+\\w+");
    if(!regex_search(str, what, reg)) {
        sprintf(outbuffer, "ERROR: Can't get .text section info for \"%s\"\n",fileName.c_str());
        iStdoutLog.push_back(outbuffer);
    }
    else {
        string sTmp, sLibFile;
        sTmp.assign(what[1].first,what[1].second-what[1].first);
        unsigned int imgText = strtol(sTmp.c_str(), NULL, 16);

        reg.assign("^LONG 0x.*", boost::regex::icase);
        boost::cmatch what1;
        boost::regex reg1("^\\s(\\.text)?\\s+(0x\\w+)\\s+(0x\\w+)\\s+(.*)$", boost::regex::icase);
        boost::regex reg2("^\\s+(\\w+)\\s\\s+([a-zA-Z_].+)", boost::regex::icase);
        boost::regex reg3(".*lib\\(.*d\\d*s_?\\d{5}.o\\)$", boost::regex::icase);

        map<unsigned int,string> syms;
        unsigned int addr, len, stubhex;

        while(aMap.getline(str,MAX_LINE)) {
            if(strlen(str) == 0)
                break;
            else if(regex_search(str, what, reg1)) {
                sLibFile.assign(what[4].first,what[4].second-what[4].first);
                if(!regex_search(sLibFile.c_str(), what1, reg)) {
                    sTmp.assign(what[2].first,what[2].second-what[2].first);
                    addr = strtol(sTmp.c_str(), NULL, 16);
                    sTmp.assign(what[3].first,what[3].second-what[3].first);
                    len = strtol(sTmp.c_str(), NULL, 16);
                    syms[addr+len] = "";
                    if(regex_search(sLibFile.c_str(), what, reg3)) {
                        stubhex = addr;
                    }
                }
            }
            else if(regex_search(str, what, reg2)) {
                sTmp.assign(what[1].first,what[1].second-what[1].first);
                addr = strtol(sTmp.c_str(), NULL, 16);
                sTmp.assign(what[2].first,what[2].second-what[2].first);
                syms[addr] = (addr == stubhex)? ("stub "+sTmp) : sTmp;
            }
        }

        map<unsigned int,string>::iterator it = syms.begin();
        map<unsigned int,string>::iterator itp = it++;
        TSymbolPCEntry tmpSymbolEntry;
        for(; it != syms.end(); itp = it++) {
           if(itp->second != "") {
                tmpSymbolEntry.iSymbolEntry.iAddress = itp->first-imgText;
                tmpSymbolEntry.iSymbolEntry.iLength = it->first-itp->first;
                tmpSymbolEntry.iName = it->second;
		iMapFileInfo.iDbgUnitPCEntry.iDbgUnitEntry.iCodeSymbolCount++;
                iMapFileInfo.iSymbolPCEntrySet.push_back(tmpSymbolEntry);
            }
        }
    }
}

// BsymRomSymbolProcessUnit start

void BsymRomSymbolProcessUnit::ProcessEntry(const TPlacedEntry& aEntry)
{
	iPlacedEntry = aEntry;
	SymbolProcessUnit::ProcessEntry(aEntry);
	iMapFileInfo.iDbgUnitPCEntry.iPCName = aEntry.iFileName;
	iMapFileInfo.iDbgUnitPCEntry.iDevName = aEntry.iDevFileName;
}

void BsymRomSymbolProcessUnit::ProcessExecutableFile(const string& aFile)
{
	ResetContentLog();
	char str[MAX_LINE];
	string mapFile2 = aFile+".map";
	size_t dot = aFile.rfind('.');
	string mapFile = aFile.substr(0,dot)+".map";
	ifstream fMap;
	fMap.open(mapFile2.c_str());
	if(!fMap.is_open()) {
		fMap.open(mapFile.c_str());
	}
	if(!fMap.is_open()) {
		sprintf(str, "\nWarning: Can't open \"%s\" or \"%s\"\n",mapFile2.c_str(),mapFile.c_str());
		iStdoutLog.push_back(str);
	    TSymbolPCEntry tmpEntry;
	    tmpEntry.iSymbolEntry.iAddress = iPlacedEntry.iCodeAddress;
	    tmpEntry.iSymbolEntry.iLength = iPlacedEntry.iTotalSize;
	    tmpEntry.iName = aFile.substr(aFile.rfind(PATH_SEPARATOR)+1);
		iMapFileInfo.iSymbolPCEntrySet.push_back(tmpEntry);
	    iMapFileInfo.iDbgUnitPCEntry.iDbgUnitEntry.iDataSymbolCount++;
	}
	else {
	    if(!fMap.good()) fMap.clear();
	    char buffer[100];
	    fMap.getline(buffer, 100);
	    boost::regex regARMV5("ARM Linker", boost::regex::icase);
	    boost::regex regGCCEoARMV4("Archive member included", boost::regex::icase);
	    boost::cmatch what;
	    if(regex_search(buffer, what, regARMV5)) {
	        ProcessArmv5File(aFile, fMap);
	    }
	    else if(regex_search(buffer, what, regGCCEoARMV4)) {
	        ProcessGcceOrArm4File(aFile, fMap);
	    }
	    else {
		fMap.seekg(0, ios_base::beg);
		ProcessX86File(aFile, fMap);
	    }
	}
}

void BsymRomSymbolProcessUnit::ProcessArmv5File(const string& fileName, ifstream& aMap)
{
	string symName ; 
	ArmSymMap symbols ; 
	vector<char*> words ;
	ArmSymbolInfo info;
	char* lineStart ;
	char buffer[MAX_LINE];  
	while(aMap.good() && (!aMap.eof())){
		*buffer = 0;
		aMap.getline(buffer,MAX_LINE);
		lineStart = buffer ;
		SKIP_WS(lineStart);	 
		if(strstr(lineStart,"Global Symbols"))
			break ;
		char* armstamp = strstr(lineStart,"ARM Code");
		if(0 == armstamp)
			armstamp = strstr(lineStart,"Thumb Code") ;
		if(0 == armstamp) continue ; 
		*(armstamp - 1) = 0 ;
		
		char* hexStr = lineStart ;
		char* nameEnd;
		while(1) {
			hexStr = strstr(hexStr,"0x");
			if(0 == hexStr) break ; 		
			nameEnd = hexStr - 1;
			if(*nameEnd == ' ' || *nameEnd == '\t') break ;
			hexStr += 2 ;
		}	 
		if(0 == hexStr) continue ; 	
		while(nameEnd > lineStart && (*nameEnd == ' ' || *nameEnd == '\t'))
			nameEnd -- ;
		
		nameEnd[1] = 0;
		info.name = lineStart;		
		char* temp ;
		TUint32 addr = strtoul(hexStr + 2,&temp,16);
		char* decStr ;
		if(*armstamp == 'A')
			decStr = armstamp + 9 ;
		else 
			decStr = armstamp + 11 ;
		SKIP_WS(decStr);
		info.size = strtoul(decStr,&temp,10);
		SKIP_WS(temp);
		info.section = temp;
		if(info.section.find("(StubCode)") != string::npos )
			info.size = 8 ; 			
		if(addr > 0){
			symbols.insert(pair<TUint32,ArmSymbolInfo>(addr,info));
		}
	}	 
	size_t lenOfFileName = iPlacedEntry.iFileName.length();
	while(aMap.good() && (!aMap.eof())){
		*buffer = 0;
		aMap.getline(buffer,MAX_LINE);
		lineStart = buffer ;
		SKIP_WS(lineStart); 
		char* hexStr = lineStart ;
		char* nameEnd;
		while(1) {
			hexStr = strstr(hexStr,"0x");
			if(0 == hexStr) break ; 		
			nameEnd = hexStr - 1;
			if(*nameEnd == ' ' || *nameEnd == '\t') 
				break ;
			hexStr += 2 ;
		}	 
		if(0 == hexStr) continue ; 
		while(nameEnd > lineStart && (*nameEnd == ' ' || *nameEnd == '\t')){
			nameEnd -- ;
		}
		nameEnd[1] = 0;
		info.name = lineStart; 
		char *temp ;
		TUint32 addr = strtoul(hexStr + 2,&temp,16);
		while(*temp < '0' || *temp > '9' )//[^\d]*
			temp++ ;
		char* decStr = temp ;
		info.size = strtoul(decStr,&temp,10);
		SKIP_WS(temp);
		info.section = temp;
		if(info.section.find("(StubCode)") != string::npos )
			info.size = 8 ; 
		if(addr > 0){
			symbols.insert(pair<TUint32,ArmSymbolInfo>(addr,info));
		} 
	}
	
	TUint32 textSectAddr = 0x00008000;  // .text gets linked at 0x00008000
	TUint32 dataSectAddr = 0x00400000 ; // .data gets linked at 0x00400000
	size_t allocBytes;
	boost::regex regScope("^\\s*(\\w+)\\s*::\\s*(.*)$");
	boost::cmatch what;
	for( ArmSymMap::iterator it = symbols.begin(); it != symbols.end() ; it++){
		TSymbolPCEntry tmpEntry;
		TUint32 thisAddr = it->first ;
		TUint32 romAddr ;
		ArmSymbolInfo& info = it->second; 
		if (thisAddr >= textSectAddr && thisAddr <= (textSectAddr + iPlacedEntry.iTextSize)) {
			romAddr = thisAddr - textSectAddr + iPlacedEntry.iCodeAddress ;
			tmpEntry.iSymbolEntry.iAddress = romAddr;
			iMapFileInfo.iDbgUnitPCEntry.iDbgUnitEntry.iCodeSymbolCount++;
		} 
		else if ( iPlacedEntry.iDataAddress && 
			( thisAddr >= dataSectAddr && thisAddr <= (dataSectAddr + iPlacedEntry.iTextSize))) {
			romAddr = thisAddr-dataSectAddr + iPlacedEntry.iDataBssLinearBase;
			tmpEntry.iSymbolEntry.iAddress = romAddr;
			iMapFileInfo.iDbgUnitPCEntry.iDbgUnitEntry.iDataSymbolCount++;
		} 
		else if ( iPlacedEntry.iDataBssLinearBase && 
			( thisAddr >= dataSectAddr && thisAddr <= (dataSectAddr+ iPlacedEntry.iTotalDataSize))) {
			romAddr = thisAddr - dataSectAddr + iPlacedEntry.iDataBssLinearBase;
			tmpEntry.iSymbolEntry.iAddress = romAddr;
			iMapFileInfo.iDbgUnitPCEntry.iDbgUnitEntry.iBssSymbolCount++;
		} 
		else { 
			allocBytes = info.name.length() + 60;
			char* msg = new char[allocBytes] ;
			snprintf(msg,allocBytes,"\r\nWarning: Symbol %s @ 0x%08x not in text or data segments\r\n", \
				info.name.c_str() ,(unsigned int)thisAddr) ; 
			iStdoutLog.push_back(msg);	
			allocBytes = lenOfFileName + 80;
			msg = new char[allocBytes];
			snprintf(msg,allocBytes,"Warning:  The map file for binary %s is out-of-sync with the binary itself\r\n\r\n",iPlacedEntry.iFileName.c_str());
			iStdoutLog.push_back(msg);	
			continue ;
		}
		tmpEntry.iSymbolEntry.iLength = info.size;
		if(regex_search(info.name.c_str(), what, regScope))
		{
			tmpEntry.iScopeName.assign(what[1].first, what[1].second-what[1].first);
			tmpEntry.iName.assign(what[2].first, what[2].second-what[2].first);
		}
		else
		{
			tmpEntry.iScopeName = "";
			tmpEntry.iName = info.name;
		}
		tmpEntry.iSecName = info.section;
		iMapFileInfo.iSymbolPCEntrySet.push_back(tmpEntry);
	} 
}

void BsymRomSymbolProcessUnit::ProcessGcceOrArm4File(const string& fileName, ifstream& aMap)
{
	char* lineStart; 
	vector<char*> words ;
	char buffer[MAX_LINE];
	while(aMap.good() && (!aMap.eof())){
		aMap.getline(buffer,MAX_LINE);
		lineStart = buffer ;
		SKIP_WS(lineStart);
		if( 0 == strncmp(lineStart,".text",5)) {
			lineStart += 5;
			break ;
		}		
	}
	split(lineStart,words);
	TUint32 codeAddr , codeSize;
	size_t allocBytes ;
	if(words.size() != 2 ||
	KErrNone != Val(codeAddr,words.at(0)) || 
	KErrNone != Val(codeSize,words.at(1))) {
		allocBytes = iPlacedEntry.iFileName.length() + 60;
		char* msg = new char[allocBytes];
		snprintf(msg,allocBytes,"\nError: Can't get .text section info for \"%s\"\r\n",iPlacedEntry.iFileName.c_str());
		iStdoutLog.push_back(msg);
		return;
	}
	map<TUint32,string> symbols ;
	TUint32 stubHex = 0;
	//Slurp symbols 'til the end of the text section
	while(aMap.good() && (!aMap.eof())){
		aMap.getline(buffer,MAX_LINE);
		lineStart = buffer ;
		SKIP_WS(lineStart); 
		if(0 == *lineStart) break ; //blank line marks the end of the text section
		
		// .text <addr> <len>  <library(member)>
		// .text$something
		//       <addr> <len>  <library(member)>
		//       <addr> <len>  LONG 0x0
		// (/^\s(\.text)?\s+(0x\w+)\s+(0x\w+)\s+(.*)$/io)	 
		if(strncmp(lineStart,".text",5) == 0){
			lineStart += 5 ;
			SKIP_WS(lineStart);
		}
		char* hex1 = NULL ;
		char* hex2 = NULL ;
		char* strAfterhex1 = NULL ;
		TUint32 addr,size ;
		if(strncmp(lineStart,"0x",2) == 0){
			hex1 = lineStart + 2;
			char* temp ;
			addr = strtoul(hex1,&temp,16);
			SKIP_WS(temp);
			strAfterhex1 = temp ;
			if(strncmp(temp,"0x",2) == 0){
				hex2 = temp + 2 ;
			}
		}
		if(NULL != hex2){
			char* libraryfile ;
			size = strtoul(hex2,&libraryfile,16);
			SKIP_WS(libraryfile);  
			TUint32 key = addr + size ;
			put_to_map(symbols,key,string(""));//impossible symbol as end marker 
			make_lower(libraryfile); 
			size_t len = strlen(libraryfile);
			char* p1 = strstr(libraryfile,".lib(");
			if(NULL == p1) 
				continue ; 
			p1 += 5;
			if(strcmp(libraryfile + len - 3,".o)")!= 0)
				continue ;		 
			len -= 3 ;
			libraryfile[len] = 0; 
			if(EFalse == IsValidNumber(libraryfile + len - 5))
				continue ;
			len -= 7 ;
			if('_' == libraryfile[len])
				len -- ;
			if('s' != libraryfile[len])
				continue ;		 
			char* p2 = libraryfile + len - 1;
			while(p2 > p1 ) { 
				if(*p2 < '0' || *p2 > '9')
					break ;
				p2 -- ;
			}
			if(*p2 != 'd') 
				continue ;
			stubHex = addr ;
		}
		else if(NULL != hex1 && NULL != strAfterhex1){ 
			//#  <addr>  <symbol name possibly including spaces>
			//(/^\s+(\w+)\s\s+([a-zA-Z_].+)/o) 			 
			char* symName = strAfterhex1; 
			if((*symName >= 'A' && *symName <= 'Z') ||
				(*symName >= 'a' && *symName <= 'z') || *symName == '_') {				 
				string symbol(symName);
				if(addr == stubHex) 
					symbol.insert(0,"stub ");
			 
				put_to_map(symbols,addr,symbol);
			}			
		}		
	}  
	map<TUint32,string>::iterator it = symbols.begin();
	TUint32 lastAddr = it->first;
	string lastSymName = it->second;
	vector<pair<int,char*> >lines ;
	it ++ ;
	while(it != symbols.end()) {
		TSymbolPCEntry tmpEntry;		
		TUint32 addr = it->first ; 
		unsigned int fixedupAddr = lastAddr - codeAddr + iPlacedEntry.iCodeAddress;
		TUint size = addr - lastAddr ;
		if(!lastSymName.empty()) {
			tmpEntry.iSymbolEntry.iAddress = fixedupAddr;
			tmpEntry.iSymbolEntry.iLength = size;
			tmpEntry.iScopeName = "";
			tmpEntry.iName = lastSymName;
			tmpEntry.iSecName = "";
			iMapFileInfo.iDbgUnitPCEntry.iDbgUnitEntry.iCodeSymbolCount++;
		}		
		lastAddr = addr ;
		lastSymName = it->second;
		it ++ ;
	}
}

void BsymRomSymbolProcessUnit::ProcessX86File(const string& fileName, ifstream& aMap)
{
	char buffer[MAX_LINE]; 
	char* lineStart; 
	while(aMap.good() && (!aMap.eof())){
		aMap.getline(buffer,MAX_LINE);
		lineStart = buffer ;
		SKIP_WS(lineStart);
		if( 0 == strncmp(lineStart,"Address",7)) { 
			break ;
		}		
	}
	aMap.getline(buffer,MAX_LINE);
	string lastName ;
	TUint32 lastAddr = 0;
	vector<pair<int, char*> >lines ;
	while(aMap.good() && (!aMap.eof())){
		TSymbolPCEntry tmpEntry;
		aMap.getline(buffer,MAX_LINE);
		lineStart = buffer ;
		SKIP_WS(lineStart);
		if(0 != strncmp(lineStart,"0001:",5))
			break ;		 
		char* end ; 
		TUint32 addr = strtoul(lineStart + 5,&end,16);
		char* name = end + 1;
		SKIP_WS(name);
		end = name + 1;
		FIND_WS(end);
		*end = 0 ;
		if(!lastName.empty()){
			unsigned int size = addr - lastAddr ; 
			unsigned int romAddr = lastAddr + iPlacedEntry.iCodeAddress;
			tmpEntry.iSymbolEntry.iAddress = romAddr;
			tmpEntry.iSymbolEntry.iLength = size;
			tmpEntry.iName = lastName;
			iMapFileInfo.iSymbolPCEntrySet.push_back(tmpEntry);
			iMapFileInfo.iDbgUnitPCEntry.iDbgUnitEntry.iCodeSymbolCount++;
		}
		lastName = name;
		lastAddr = addr;		
	}
	if(!lastName.empty()){
		TSymbolPCEntry tmpEntry;
		unsigned int romAddr = lastAddr + iPlacedEntry.iCodeAddress;
		tmpEntry.iSymbolEntry.iAddress = romAddr;
		tmpEntry.iSymbolEntry.iLength = 0;
		tmpEntry.iName = lastName;
		iMapFileInfo.iSymbolPCEntrySet.push_back(tmpEntry);
		iMapFileInfo.iDbgUnitPCEntry.iDbgUnitEntry.iCodeSymbolCount++;
	}
}

void BsymRomSymbolProcessUnit::FlushSymbolContent(ostream &aOut)
{
	iSymbolGeneratorPtr->AppendMapFileInfo(iMapFileInfo);
}

void BsymRomSymbolProcessUnit::ResetContentLog()
{
	iStdoutLog.clear();
	iMapFileInfo.iDbgUnitPCEntry.iPCName = "";
	iMapFileInfo.iDbgUnitPCEntry.iDevName = "";
	iMapFileInfo.iDbgUnitPCEntry.iDbgUnitEntry.Reset();
	iMapFileInfo.iSymbolPCEntrySet.clear();
}

void BsymRomSymbolProcessUnit::ProcessDataFile(const string& aFile)
{
	ResetContentLog();
	string basename = aFile.substr(aFile.rfind(PATH_SEPARATOR)+1);
	TSymbolPCEntry tmpEntry;
	tmpEntry.iSymbolEntry.iAddress = iPlacedEntry.iDataAddress;
	tmpEntry.iSymbolEntry.iLength = 0;
	tmpEntry.iName = basename;
	iMapFileInfo.iSymbolPCEntrySet.push_back(tmpEntry);
	iMapFileInfo.iDbgUnitPCEntry.iDbgUnitEntry.iDataSymbolCount++;
}
