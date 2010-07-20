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
#include "fsnode.h"
#include "fatdefines.h"
#include "utf16string.h"
#include <stdio.h> 
#include <iostream>
#include <iomanip>
#include <stdio.h> 
#include <stdlib.h> 
 
#include <ctype.h> 
 

#ifdef __LINUX__
#include <dirent.h> 
#include <sys/stat.h>
#include <unistd.h>
#define SPLIT_CHAR '/'
#else
#include <io.h> 
#include <direct.h> //TODO: check under MinGW4 + stlport 5.2
#include <conio.h> 
#define SPLIT_CHAR '\\'
#endif
 
using namespace std;

const TUint KBytesPerEntry = 13 ;

static inline bool is_a_long_file_name_char(unsigned char ch){
	return ( ch >= ' ' && ch != '"' && ch != '*' && ch != ':' && ch != '<' \
		&& ch != '>' && ch != '?' && ch != '|' && ch != 127) ; 
	
}
//
TFSNode::TFSNode(TFSNode* aParent, const char* aFileName, TUint8 aAttrs, const char* aPCSideName)  :
iParent(aParent),iFirstChild(0),iSibling(0),iAttrs(aAttrs), iPCSideName(0), iWideName(0){
	
  // According to the FAT specification, short name should be inited with empty string (' ' string)
	memset(iShortName,0x20,11);  
	iShortName[11] = 0 ; 
	if(aFileName) {
		const unsigned char* ptr = reinterpret_cast<const unsigned char*>(aFileName);
		bool allSpaces = true ;
		while(*ptr){
			if( !is_a_long_file_name_char(*ptr))
				throw "Illegal filename or dir name! \n";		
			if(*ptr != ' ')
				allSpaces = false ;		
			ptr++ ;
		}
		if(allSpaces)
			throw "Illegal filename or dir name(all spaces)!\n";
		iFileName = strdup(aFileName); 
		GenerateBasicName() ;	
	} 
	if(aPCSideName) {
		iPCSideName = strdup(aPCSideName);
	}
	iFATEntry = 0;
	iCrtTimeTenth  = 0;
	iCrtTime.iImageTime = 0 ;
	iCrtDate.iImageDate = 0 ;
	iLstAccDate.iImageDate = 0  ;
	iWrtTime.iImageTime = 0 ;
	iWrtDate.iImageDate = 0  ;
	iFileSize = 0;
	if(!iParent) return ;
	
	if(!iParent->iFirstChild)
	    iParent->iFirstChild = this ;
    else {
        TFSNode* sibling = iParent->iFirstChild;
        while(sibling->iSibling)
            sibling = sibling->iSibling ;
        sibling->iSibling = this ;
    } 

}
TFSNode::~TFSNode(){
	if(iFirstChild)
		delete iFirstChild ;
	if(iSibling)
		delete iSibling ;
	if(iFileName)
		free(iFileName) ;
	if(iWideName)
		delete iWideName;
	if(iPCSideName)
		free(iPCSideName);
}
 
TFSNode* TFSNode::CreateFromFolder(const char* aPath,TFSNode* aParent) { 
	 
	int len = strlen(aPath);  
#ifdef __LINUX__
	DIR* dir = opendir(aPath);
	if(dir == NULL) {
		cout << aPath << " does not contain any subfolder/file.\n";     
			return aParent;
	}
	if(!aParent)
		aParent = new TFSNode(NULL,"/",ATTR_DIRECTORY);
	dirent*  entry; 
	struct stat statbuf ;
	char* fileName = new(nothrow) char[len + 200];
	if(!fileName) return NULL ;
	memcpy(fileName,aPath,len); 
	fileName[len] = SPLIT_CHAR;
	while ((entry = readdir(dir)) != NULL)  {
		if(strcmp(entry->d_name,".") == 0 || strcmp(entry->d_name,"..") == 0)
			continue ; 
		strcpy(&fileName[len+1],entry->d_name);             
		stat(fileName , &statbuf);         
		TFSNode* pNewItem = new TFSNode(aParent,fileName,S_ISDIR(statbuf.st_mode) ? ATTR_DIRECTORY : 0);
		pNewItem->Init(statbuf.st_ctime,statbuf.st_atime,statbuf.st_mtime,statbuf.st_size);         
		if(S_ISDIR(statbuf.st_mode)){ 
			CreateFromFolder(fileName,pNewItem);
		} 
	}	
	delete []fileName ;
	closedir(dir);
#else
	struct _finddata_t data ;
	memset(&data, 0, sizeof(data)); 	
	char* fileName = new(nothrow) char[len + 200];
	if(!fileName) return NULL ;
	memcpy(fileName,aPath,len); 
    fileName[len] = SPLIT_CHAR;
	fileName[len+1] = '*';
	fileName[len+2] = 0;
	intptr_t hFind =  _findfirst(fileName,&data); 
 
	if(hFind == (intptr_t)-1 ) {
		cout << aPath << " does not contain any subfolder/file.\n";		
		delete []fileName;
		return aParent;
	}	
	if(!aParent)
	    aParent = new TFSNode(NULL,"/",ATTR_DIRECTORY);	
	
	do {        
        if(strcmp(data.name,".") == 0 || strcmp(data.name,"..") == 0)
            continue ; 
        
        strcpy(&fileName[len+1],data.name); 
        TUint8 attr = 0;
        if(data.attrib & _A_SUBDIR)  
            attr |= ATTR_DIRECTORY;
        if(data.attrib & _A_RDONLY)
            attr |= ATTR_READ_ONLY ;
        if(data.attrib &  _A_HIDDEN)
            attr |= ATTR_HIDDEN ;
        if(data.attrib & _A_SYSTEM)
            attr |= ATTR_SYSTEM ;
        if(data.attrib & _A_ARCH)
            attr |= ATTR_ARCHIVE;      
        TFSNode* pNewItem = new TFSNode(aParent,data.name,attr,fileName);        
        pNewItem->Init(data.time_create,data.time_access,data.time_write,data.size);            
        if(data.attrib & _A_SUBDIR){ 
            CreateFromFolder(fileName,pNewItem);
        }  
 
    } while(-1 != _findnext(hFind, &data));
	delete []fileName ;
    _findclose(hFind);
#endif
 
	return aParent;
}
 
/** GenerateBasicName : Generate the short name according to long name 
	* 
	* algorithm :
	* 
	* 1.	The UNICODE name passed to the file system is converted to upper case.
	* 2.	The upper cased UNICODE name is converted to OEM.
	*     if (the uppercased UNICODE glyph does not exist as an OEM glyph in the OEM code page)
	*				or	(the OEM glyph is invalid in an 8.3 name)
	*			{
	*				Replace the glyph to an OEM '_' (underscore) character.
	*				Set a "lossy conversion" flag.
	*			}
	* 3.	Strip all leading and embedded spaces from the long name.
	* 4.	Strip all leading periods from the long name.
	* 5.	While		(not at end of the long name)
	*					and	(char is not a period)
	*					and	(total chars copied < 8)
	*			{
	*				Copy characters into primary portion of the basis name
	*			}
	*	6.	Insert a dot at the end of the primary components of the basis-name 
	*     if the basis name has an extension after the last period in the name.
	*
	* 7.	Scan for the last embedded period in the long name.
	*     If	(the last embedded period was found)
	*     {
	*     	While		(not at end of the long name) and	(total chars copied < 3)
	*     	{
	*     		Copy characters into extension portion of the basis name
	*     	}
	*     }
  *
  */
void TFSNode::GenerateBasicName() { 
	const char* filename =  iFileName ;	 
	TUint length = strlen(filename);
	if(0 == length)
	    return ;
	if(0 == strcmp(filename,".")){
        iShortName[0] = '.' ;
        return ;
	}
	if(0 == strcmp(filename,"..")){
        iShortName[0] = '.' ;
        iShortName[1] = '.' ;
        return ;
	} 
	iWideName = new UTF16String(filename,length); // The unicode string
	char base[10];
	const char* ext = filename + length;
	
	//Strip all leading periods and spaces from the long name.
	while(*filename == '.' || *filename == ' ' || *filename == '\t') {
		filename ++ ;
		length -- ;
	}
	//find the extension
	while(ext > filename && *ext != '.')
		ext -- ;
	if(ext == filename){
		ext = "" ; 
	}
	else {
		length = ext - filename;
		ext ++ ;
	} 
	bool lossyConv = false ;
	TUint bl = 0;
	for(TUint i = 0 ; i < length ; i++) {
		if(filename[i] >= 'a' && filename[i] <= 'z')
			base[bl++] = filename[i] + 'A' - 'a';
		else if(filename[i] >= 'A' && filename[i] <= 'Z')
			base[bl++] = filename[i];
		else if(filename[i] == '$' || filename[i] == '%' ||
			filename[i] == '-' || filename[i] == '_' || filename[i] == '@' ||
			filename[i] == '~' || filename[i] == '`' || filename[i] == '!' ||
			filename[i] == '(' || filename[i] == ')' || filename[i] == '{' ||
			filename[i] == '}' || filename[i] == '^' || filename[i] == '#' ||
			filename[i] == '&' ||filename[i] == '\'')
			base[bl++] = filename[i];
		else if(filename[i] != ' ' && filename[i] != '.'){
			base[bl++] = '_';
			lossyConv = true ;
		}
		if(bl > 8){
			bl -- ;
			lossyConv = true ;
			break ;
		}		
	}
	if(lossyConv){
		if(bl > 6) bl = 6 ;		
		iShortName[bl] = '~';
		iShortName[bl+1] = '1';		
	}
	memcpy(iShortName,base,bl);

	//Copy the extension part.	
	TUint ei = 8;
	for(TUint e = 0; ei < 11 && ext[e] != 0 ; e++){
		if(ext[e] >= 'a' && ext[e] <= 'z')
			iShortName[ei++] = ext[e] + 'A' - 'a';
		else if(ext[e] >= 'A' && ext[e] <= 'Z')
			iShortName[ei++] = ext[e] ;
		else if(ext[e] == '$' || ext[e] == '%' || ext[e] == '-' || ext[e] == '_' || 
			ext[e] == '@' || ext[e] == '~' || ext[e] == '`' || ext[e] == '!' || 
			ext[e] == '(' || ext[e] == ')' || ext[e] == '{' || ext[e] == '}' || 
			ext[e] == '^' || ext[e] == '#' || ext[e] == '&' ||ext[e] == '\'')
			iShortName[ei++] = ext[e] ;
	}
 
	if(iParent) 
		iParent->MakeUniqueShortName(iShortName,bl); 
}

#ifdef _DEBUG
void TFSNode::PrintTree(int nTab) {
	for( int i = 0 ; i < nTab ; i++ )
		cout << " " ;
	cout << (iFileName ? iFileName : "") << " [" << hex << setw(2) << setfill('0') << (unsigned short)iAttrs << "] \n" ;
	if(iFirstChild)
		iFirstChild->PrintTree(nTab + 2);
	if(iSibling)
		iSibling->PrintTree(nTab);
}
#endif
bool TFSNode::IsDirectory() const {
	return (0 != (iAttrs & ATTR_DIRECTORY) || ATTR_VOLUME_ID == iAttrs) ;
}
int TFSNode::GetWideNameLength() const {
	if(!iWideName)
		return 0 ;
	return iWideName->length() ;
}
TUint TFSNode::GetSize() const {
	
	if( !IsDirectory())
		return iFileSize ;
	TUint retVal = sizeof(TShortDirEntry) ; // the tailed entry 
	if(iParent)
		retVal += sizeof(TShortDirEntry) * 2 ;
	TFSNode* child = iFirstChild ;
	while(child) {
		TUint longNameEntries =  (child->GetWideNameLength() + KBytesPerEntry) / KBytesPerEntry  ;
		retVal += longNameEntries * sizeof(TLongDirEntry) ;
		retVal += sizeof(TShortDirEntry);
		child = child->iSibling ;
	}
	return retVal ;
}
 
void TFSNode::Init(time_t aCreateTime, time_t aAccessTime, time_t aWriteTime, TUint aSize ) {
	
	struct tm* temp = localtime(&aCreateTime);
	iCrtDate.iCurrentDate.Day = temp->tm_mday;
	iCrtDate.iCurrentDate.Month = temp->tm_mon+1; //As per FAT spec
	iCrtDate.iCurrentDate.Year = temp->tm_year - 80;//As per FAT spec
	iCrtTime.iCurrentTime.Hour = temp->tm_hour;
	iCrtTime.iCurrentTime.Minute = temp->tm_min;
	iCrtTime.iCurrentTime.Seconds = temp->tm_sec / 2;//As per FAT spec
	iCrtTimeTenth = 0;
	
	temp = localtime(&aAccessTime);	
	iLstAccDate.iCurrentDate.Day = temp->tm_mday;
	iLstAccDate.iCurrentDate.Month = temp->tm_mon+1; //As per FAT spec
	iLstAccDate.iCurrentDate.Year = temp->tm_year - 80;//As per FAT spec
	
	temp = localtime(&aWriteTime);
	iWrtDate.iCurrentDate.Day = temp->tm_mday;
	iWrtDate.iCurrentDate.Month = temp->tm_mon+1; //As per FAT spec
	iWrtDate.iCurrentDate.Year = temp->tm_year - 80;//As per FAT spec
	iWrtTime.iCurrentTime.Hour = temp->tm_hour;
	iWrtTime.iCurrentTime.Minute = temp->tm_min;
	iWrtTime.iCurrentTime.Seconds = temp->tm_sec / 2;//As per FAT spec 
	
	iFileSize = aSize ; 
}
/** WriteDirEntries : Write FAT information for this node to a cluster buffer
	* aStartIndex : [in],the beginning index of the outputed cluster  
  * aClusterData : [in,out] the cluster buffer
  * 
  * notice, aClusterData is only required if node is a directory node.
  * for a file node, no data will be written out.
  * in this case, only corresponding cluster index information is updated.
  */ 
void TFSNode::WriteDirEntries(TUint aStartIndex,TUint8* aClusterData){
	if(iFATEntry){
		*((TUint16*)iFATEntry->DIR_FstClusHI) = (aStartIndex >> 16) ;
		*((TUint16*)iFATEntry->DIR_FstClusLO) = (aStartIndex & 0xFFFF) ;
	}
	 
	if(IsDirectory()) { // Directory , write dir entries ; 
		TShortDirEntry* entry = reinterpret_cast<TShortDirEntry*>(aClusterData);
		if(iParent != NULL) {
			//Make 
			GetShortEntry(entry); 
			//TODO: Add comments to avoid mistaken deleting.			
			memcpy(entry->DIR_Name,".            ",sizeof(entry->DIR_Name));
			entry ++ ;
			iParent->GetShortEntry(entry);
			memcpy(entry->DIR_Name,"..           ",sizeof(entry->DIR_Name));
			entry ++ ; 
		}		 
		TFSNode* child = iFirstChild ;
		while(child){			
			int items = child->GetLongEntries(reinterpret_cast<TLongDirEntry*>(entry));
			entry += items ;
			child->GetShortEntry(entry);
			child->iFATEntry = entry ;
			entry ++ ;
			child = child->iSibling ; 
			
		}

	}
}
/** GetShortEntry : Make a short directory entry (FAT16/32 conception)
  * aEntry : the entry buffer   
  */ 
void TFSNode::GetShortEntry(TShortDirEntry* aEntry) {
  if(!aEntry) return ;
	if(iFATEntry){
		if(iFATEntry != aEntry)
			memcpy(aEntry,iFATEntry,sizeof(TShortDirEntry));
		return ;
	}
	memcpy(aEntry->DIR_Name,iShortName,sizeof(aEntry->DIR_Name)); 
	aEntry->DIR_Attr = iAttrs;
	aEntry->DIR_NTRes = 0 ;
	aEntry->DIR_CrtTimeTenth = 0 ;        
	memcpy(aEntry->DIR_CrtTime,&iCrtTime,sizeof(aEntry->DIR_CrtTime)); 
	memcpy(aEntry->DIR_CrtDate,&iCrtDate,sizeof(aEntry->DIR_CrtDate));
	memcpy(aEntry->DIR_LstAccDate,&iLstAccDate,sizeof(aEntry->DIR_LstAccDate));
	memset(aEntry->DIR_FstClusHI,0,sizeof(aEntry->DIR_FstClusHI));
	memcpy(aEntry->DIR_WrtTime,&iWrtTime,sizeof(aEntry->DIR_WrtTime)); 
	memcpy(aEntry->DIR_WrtDate,&iWrtDate,sizeof(aEntry->DIR_WrtDate)); 
	memset(aEntry->DIR_FstClusLO,0,sizeof(aEntry->DIR_FstClusLO)); 
	memcpy(aEntry->DIR_FileSize,&iFileSize,sizeof(aEntry->DIR_FileSize));  
}
TUint8 FATChkSum(const char* pFcbName) {
    short fcbNameLen ;
    TUint8 sum = 0 ;
    for(fcbNameLen = 11 ; fcbNameLen != 0 ; fcbNameLen --) {
        sum = ((sum & 1) ? 0x80 : 0 ) + (sum >> 1 ) + *pFcbName++ ; 
    }
    return sum ;        
}
/** GetLongEntries : Make a series of long directory entries (FAT16/32 conception)
  * aEntries : the start addr of the long directory entries buffer
  *
  * return value : actual entris count.   
  */ 
int TFSNode::GetLongEntries(TLongDirEntry* aEntries) {
  
  if(!aEntries) return 0;
	int packs = (GetWideNameLength() + KBytesPerEntry) / KBytesPerEntry  ;
	
	TUint buflen = packs * KBytesPerEntry;
	TUint16* buffer = new(std::nothrow) TUint16[buflen];
	if(!buffer)
	return 0 ;
	memset(buffer,0xff,(buflen << 1));    
	if(iWideName) {
	    memcpy(buffer,iWideName->c_str(),iWideName->bytes()); 
	    buffer[iWideName->length()] = 0;
	}
	TUint8 chkSum = FATChkSum(iShortName);;
    
	TUint16* ptr = buffer ;
	TLongDirEntry* entry = aEntries +(packs - 1);
  for(int i = 1 ; i <= packs ; i++, entry--) {		
		entry->LDIR_Ord = i ;
		entry->LDIR_Chksum = chkSum ;
		entry->LDIR_Attr = (TUint8)ATTR_LONG_NAME;    
		*((TUint16*)(entry->LDIR_FstClusLO)) = 0;
		entry->LDIR_Type = 0;         
		memcpy(entry->LDIR_Name1,ptr,10); 
		memcpy(entry->LDIR_Name2,&ptr[5],12); 
		memcpy(entry->LDIR_Name3,&ptr[11],4);
		ptr += 13; 
  }
	aEntries->LDIR_Ord |= 0x40 ;
    
	delete []buffer ;
	return packs ; 
}
/** Make a unique name for a new child which has not been added.
  * to avoid same short names under a directory
  * rShortName : [in,out] , The new short name to be checked and changed.
  * baseNameLength: [in], the length of the base part of the short name 
  * not including the "~n"
  * for example, 
  *  "ABC.LOG" => baseNameLength == 3 ("ABC")
  *  "AB~1.TXT" => baseNameLength == 2 ("AB")
  *
  *
  *The Numeric-Tail Generation Algorithm

  * If (a "lossy conversion" was not flagged)
  * 		and	(the long name fits within the 8.3 naming conventions)
  * 		and	(the basis-name does not collide with any existing short name)
  * {
  * 	The short name is only the basis-name without the numeric tail.
  * }
  * else {
  * 	Insert a numeric-tail "~n" to the end of the primary name such that the value of 
  *		the "~n" is chosen so that the name thus formed does not collide with 
  *		any existing short name and that the primary name does not exceed eight
  *		characters in length.
  * }
  * The "~n" string can range from "~1" to "~999999". 
  *
  */

void TFSNode::MakeUniqueShortName(char rShortName[12],TUint baseNameLength) const { 
	bool dup ;
	char nstring[10];
	int n = 0 ;	
	do {
		TFSNode* child = iFirstChild ; 
		dup = false ;
		while(child){		 
			if(0 == memcmp(rShortName,child->iShortName,11)) {
				dup = true ;
				break ;
			}
			child = child->iSibling ;
		}
		if(dup){ //duplex , increase the index , make a new name 
			int nlen = sprintf(nstring,"~%u",++n);
			while((baseNameLength + nlen > 8) && baseNameLength > 1)
				baseNameLength -- ;
			memcpy(&rShortName[baseNameLength],nstring,nlen);
			
		}
	}while(dup) ;
		 
}

