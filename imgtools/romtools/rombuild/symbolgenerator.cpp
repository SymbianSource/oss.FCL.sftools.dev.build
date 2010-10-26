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

#include <e32rom.h>
#include <algorithm>
#include "symbolgenerator.h"
#include "r_rom.h"
#include <string.h>
#include "h_utl.h"
typedef boost::unique_lock<boost::mutex>  scoped_lock ;
typedef boost::lock_guard<boost::mutex> guarded_lock ;

SymbolGenerator::SymbolGenerator(const char* aSymbolFileName, int aMultiThreadsCount/* = 1*/) :
iOutput(aSymbolFileName,ios_base::out |ios_base::binary |  ios_base::trunc) {
	if(iOutput.is_open()){
		if(aMultiThreadsCount < 1)
			aMultiThreadsCount = 1;
		 
		for(int i = 0 ; i < aMultiThreadsCount ; i++){		
			iThreads.add_thread(new boost::thread(ThreadFunc,this));
		}
	}
	else {
		cerr << "\nWarning: Can't write data to \""<<aSymbolFileName << "\" ! \nPlease make sure this file is not locked by other application or you have write permission!"<<endl;
	} 
}
void SymbolGenerator::WaitThreads() {
	iThreads.join_all(); 
}
SymbolGenerator::~SymbolGenerator() {
	if(iOutput.is_open()){		
		iOutput.flush();
		iOutput.close();
	}
	for(vector<char*>::iterator i = iErrMsgs.begin() ; i != iErrMsgs.end() ; i++){
		char* msg = *i ;
		cerr << msg ;
		delete []msg ;
	}
	iErrMsgs.clear(); 
}

void SymbolGenerator::AddEntry(const SymGenContext& aEntry){
	if(iOutput.is_open()){
		guarded_lock lock(iQueueMutex); 		 
		iEntries.push(aEntry);		
		iCond.notify_all();
	}
}
void SymbolGenerator::ThreadFunc(SymbolGenerator* aInst) {		
		SymGenContext entry ;
		while(1){ 
			entry.iFileName = 0;
			if(1) {
				scoped_lock lock(aInst->iQueueMutex);
				while(aInst->iEntries.empty()){
						aInst->iCond.wait(lock);
				}
				entry = aInst->iEntries.front();
				if(0 == entry.iFileName)  // end , exit
					return ;
					
				aInst->iEntries.pop();
			}
			aInst->ProcessEntry(entry);
		}
		
}
#define MAX_LINE_LENGTH 65535 
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
bool SymbolGenerator::ProcessEntry(const SymGenContext& aContext) {	
	size_t allocBytes ;
	if(aContext.iExecutable ) {
		string mapFileName(aContext.iFileName);	
		mapFileName += ".map";
		ifstream ifs(mapFileName.c_str());
		if(!ifs.is_open()){
			int index = mapFileName.length() - 5 ;
			int count = 1 ;
			while(index > 0 && mapFileName.at(index) != '.'){
				index -- ;
				count ++ ;
			}
			mapFileName.erase(index,count);
			ifs.open(mapFileName.c_str());
		}
		if(!ifs.is_open()){		
			guarded_lock lock(iFileMutex);
			allocBytes = mapFileName.length() + 60 ;
			char* msg = new char[ allocBytes] ;
			snprintf(msg,allocBytes,"\nWarning: Can't open \"%s.map\"\n",aContext.iFileName );
			iErrMsgs.push_back(msg);
			msg = new char[allocBytes] ;
			int n = snprintf(msg,allocBytes,"%08x    %04x    %s\r\n",(unsigned int)aContext.iCodeAddress,(unsigned int)aContext.iTotalSize,aContext.iFileName);			
			iOutput.write(msg,n);
			iOutput.flush();
			return false ;
		} 
		if(!ifs.good()) ifs.clear();
		char buffer[100]; 
		*buffer = 0;
		//See if we're dealing with the RVCT output
		ifs.getline(buffer,100);
		if(!ifs.good()) { 
			ifs.close();
			guarded_lock lock(iFileMutex);
			allocBytes = mapFileName.length() + 60;
			char* msg = new char[allocBytes] ; 
			snprintf(msg,allocBytes,"\nWarning: File \"%s\" is opened yet can not be read!",mapFileName.c_str());
			iErrMsgs.push_back(msg);  
			return false ;			 
		}
		if(strncmp(buffer,"ARM Linker",10) == 0){  			
			return ProcessARMV5Map(ifs,aContext);
		}
		// See if we're dealing with the GCC output
		else if ( 0 == strncmp(buffer,"Archive member included",23)){ 
			return ProcessGCCMap(ifs,aContext);
		}
		else { // Must be x86 output
			ifs.seekg(0,ios_base::beg);
			return ProcessX86Map(ifs,aContext);		
		}
	}
	else {
		const char* fileName = aContext.iFileName;	  
		size_t len = strlen(fileName);
		size_t index = len - 1;
		while(index > 0 && (fileName[index] != '\\' && fileName[index] != '/'))
			index -- ;
		const char* basename = fileName + index + 1  ;		
		allocBytes = (len << 1) + 40 ;
		char* msg = new char[allocBytes] ;
		int n = snprintf(msg,allocBytes,"\r\nFrom    %s\r\n\r\n%08x    0000    %s\r\n", fileName ,(unsigned int)aContext.iDataAddress,basename);	
		guarded_lock lock(iFileMutex);
		iOutput.write(msg,n);
		iOutput.flush();
		delete []msg ;
		return true ;
	}
	return true ;
}
struct ArmSymbolInfo {
	string name ;
	TUint size ;
	string section ;
};
typedef multimap<TUint32,ArmSymbolInfo> ArmSymMap ;
 
bool SymbolGenerator::ProcessARMV5Map(ifstream& aStream, const SymGenContext& aContext) {	
	string symName ; 
	ArmSymMap symbols ; 
	vector<char*> words ;
	ArmSymbolInfo info;
	char* lineStart ;
	char buffer[MAX_LINE_LENGTH];  
	while(aStream.good() && (!aStream.eof())){
		*buffer = 0;
		aStream.getline(buffer,MAX_LINE_LENGTH);
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
	size_t lenOfFileName = strlen(aContext.iFileName);
	while(aStream.good() && (!aStream.eof())){
		*buffer = 0;
		aStream.getline(buffer,MAX_LINE_LENGTH);
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
		if (thisAddr >= textSectAddr && thisAddr <= (textSectAddr + aContext.iTextSize)) {
				romAddr = thisAddr - textSectAddr + aContext.iCodeAddress ;
		} 
		else if ( aContext.iDataAddress && 
			( thisAddr >= dataSectAddr && thisAddr <= (dataSectAddr + aContext.iTextSize))) {
			romAddr = thisAddr-dataSectAddr + aContext.iDataBssLinearBase;
		} 
		else if ( aContext.iDataBssLinearBase && 
			( thisAddr >= dataSectAddr && thisAddr <= (dataSectAddr+ aContext.iTotalDataSize))) {
			romAddr = thisAddr - dataSectAddr + aContext.iDataBssLinearBase;
		} 
		else { 
			guarded_lock  lock(iFileMutex);
			allocBytes = info.name.length() + 60;
			char* msg = new char[allocBytes] ;
			snprintf(msg,allocBytes,"\r\nWarning: Symbol %s @ 0x%08x not in text or data segments\r\n", \
				info.name.c_str() ,(unsigned int)thisAddr) ; 
			iErrMsgs.push_back(msg);	
			allocBytes = lenOfFileName + 80;
			msg = new char[allocBytes];
			snprintf(msg,allocBytes,"Warning:  The map file for binary %s is out-of-sync with the binary itself\r\n\r\n",aContext.iFileName);
			iErrMsgs.push_back(msg);	
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
	guarded_lock lock(iFileMutex);	
	allocBytes = lenOfFileName + 40;
	char* outputLine = new char[allocBytes];
	int n = snprintf(outputLine,allocBytes,"\r\nFrom    %s\r\n\r\n",aContext.iFileName); 
	iOutput.write(outputLine,n);
	delete []outputLine ;
	for (vector<pair<int,char*> >::iterator i = lines.begin() ; i < lines.end(); i ++ ) {
		int len = i->first ;
		char* line = i->second; 
		iOutput.write(line,len);
		delete []line ;
	}	
	iOutput.flush();
	return true ;
		
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
bool  SymbolGenerator::ProcessGCCMap(ifstream& aStream, const SymGenContext& aContext){
 	char* lineStart; 
	vector<char*> words ;
	char buffer[MAX_LINE_LENGTH];
	while(aStream.good() && (!aStream.eof())){
		aStream.getline(buffer,MAX_LINE_LENGTH);
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
		allocBytes = strlen(aContext.iFileName) + 60;
		char* msg = new char[allocBytes];
		snprintf(msg,allocBytes,"\nError: Can't get .text section info for \"%s\"\r\n",aContext.iFileName);
		guarded_lock lock(iFileMutex);
		iErrMsgs.push_back(msg);
		return false ;
	}
	map<TUint32,string> symbols ;
	TUint32 stubHex = 0;
	//Slurp symbols 'til the end of the text section
	while(aStream.good() && (!aStream.eof())){
		aStream.getline(buffer,MAX_LINE_LENGTH);
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
		unsigned int fixedupAddr = lastAddr - codeAddr + aContext.iCodeAddress;
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
	
	guarded_lock lock(iFileMutex);
	allocBytes = strlen(aContext.iFileName) + 40;
	char* outputLine = new char[allocBytes];
	int n = snprintf(outputLine,allocBytes,"\r\nFrom    %s\r\n\r\n",aContext.iFileName); 
	iOutput.write(outputLine,n);
	delete []outputLine ;
	vector<pair<int,char*> >::iterator i; 
	for ( i = lines.begin() ; i < lines.end(); i ++ ) {
		int len = i->first ;
		char* line = i->second ;
		iOutput.write(line,len);
		delete []line ;
	}
	iOutput.flush();	
	return true ;
}
bool SymbolGenerator::ProcessX86Map(ifstream& aStream, const SymGenContext& aContext) {
	char buffer[MAX_LINE_LENGTH]; 
	char* lineStart; 
	while(aStream.good() && (!aStream.eof())){
		aStream.getline(buffer,MAX_LINE_LENGTH);
		lineStart = buffer ;
		SKIP_WS(lineStart);
		if( 0 == strncmp(lineStart,"Address",7)) { 
			break ;
		}		
	}
	aStream.getline(buffer,MAX_LINE_LENGTH);
	string lastName ;
	TUint32 lastAddr = 0;
	size_t allocBytes ;
	vector<pair<int, char*> >lines ;
	while(aStream.good() && (!aStream.eof())){
		aStream.getline(buffer,MAX_LINE_LENGTH);
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
			unsigned int romAddr = lastAddr + aContext.iCodeAddress;
			allocBytes = lastName.length() + 40;
			char* outputLine = new char[allocBytes];
			int n = snprintf(outputLine,allocBytes,"%08x    %04x    %s\r\n",romAddr,size,lastName.c_str());
			lines.push_back(pair<int, char*>(n,outputLine));
		}		
	}
	guarded_lock lock(iFileMutex);
	allocBytes = strlen(aContext.iFileName) + 40;
	char* outputLine = new char[allocBytes];
	int n = snprintf(outputLine,allocBytes,"\r\nFrom    %s\r\n\r\n",aContext.iFileName); 
	iOutput.write(outputLine,n);
	delete []outputLine ;
	vector<pair<int,char*> >::iterator it; 
	for ( it = lines.begin() ; it < lines.end(); it ++ ) {
		int len = it->first ;
		char* line = it->second  ;
		iOutput.write(line,len);
		delete []line ;
	}	
	if(!lastName.empty()){
		allocBytes = lastName.length() + 40 ;
		outputLine = new char[allocBytes];
		unsigned int romAddr = lastAddr + aContext.iCodeAddress;
		n = snprintf(outputLine,allocBytes,"%08x    0000    %s\r\n",romAddr,lastName.c_str());
		iOutput.write(outputLine,n);
		delete []outputLine ;
	}
	iOutput.flush();
	return false ;
}
