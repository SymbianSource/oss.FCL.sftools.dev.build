/*
* Copyright (c) 2006-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* Directory class exports the functions required to construct either 
* single entry (constructor) or to construct directory structure.
* Also initializes the date and time attributes for all newly created
* entries.
* @internalComponent
* @released
*
*/


#include "errorhandler.h"
#include "directory.h"
#include "constants.h"
#include "utf16string.h"
/**
Constructor:
1. To Initialize the date and time variable
2. Also to initialize other variable's

@internalComponent
@released

@param aEntryName - the entry name
*/

FILESYSTEM_API CDirectory::CDirectory(const char* aEntryName,CDirectory* aParent):
						iEntryName(aEntryName),
						iAttribute(0),
						iNtReserved(KNTReserverdByte),
						iCreationTimeMsecs(KCreateTimeInMsecs),
						iClusterNumberHi(0),
						iClusterNumberLow(0),
						iFileSize (0), 
						iParent(aParent) 
{
	InitializeTime();
	
	memset(iShortName,0x20,11);
	iShortName[11] = 0 ; 
	size_t length = iEntryName.length();
	if(0 == length)
	    return ;
	if(0 == strcmp(aEntryName,".")){
        iShortName[0] = '.' ;
        return ;
	}
	if(0 == strcmp(aEntryName,"..")){
        iShortName[0] = '.' ;
        iShortName[1] = '.' ;
        return ;
    }
    size_t lenOfSuffix = 0 ;
    size_t dotPos = iEntryName.rfind('.',length);
    size_t lenOfPrefix ;
    if(dotPos != string::npos) {
        lenOfSuffix = length - dotPos - 1;
        lenOfPrefix = dotPos ;
    }
    else 
        lenOfPrefix = length ;
    size_t p  ;
    char c ;
    bool flag = false ;
    for( p = 0 ; p < lenOfPrefix ; p ++) {
        c = aEntryName[p];
        if(c == 0x22 || c == 0x2A || c == 0x2B || c == 0x2C || c == 0x2E || c == 0x2F || \
           c == 0x3A || c == 0x3B || c == 0x3C || c == 0x3D || c == 0x3E || c == 0x3 || \
           c == 0x5B || c == 0x5C || c == 0x5D || c == 0x7C )  { // illegal characters ;
            flag = true ;
            break ;
        }  
    }
    lenOfPrefix = p ;
    if(lenOfPrefix > 8){
        flag = true ;
    }    
    if(flag){
        size_t len =  (6 <= p) ? 6 : p;
        memcpy(iShortName,aEntryName,len);
        iShortName[len] = '~';
        iShortName[len + 1] = '1' ;
		if(lenOfSuffix > 0){
			memcpy(&iShortName[8],&aEntryName[dotPos + 1], ((3 <= lenOfSuffix) ? 3 : lenOfSuffix));
		}
		for(p = 0 ; p < 11 ; p++){
			if(iShortName[p] >= 'a' && iShortName[p] <= 'z')
				iShortName[p] = iShortName[p] + 'A' - 'a' ;
		}
		if(iParent)
			iParent->MakeUniqueShortName(iShortName,len);
    }
    else {
        memcpy(iShortName,aEntryName,lenOfPrefix);
		if(lenOfSuffix > 0){
			memcpy(&iShortName[8],&aEntryName[dotPos + 1], ((3 <= lenOfSuffix) ? 3 : lenOfSuffix));
		}
		for(p = 0 ; p < 11 ; p++){
			if(iShortName[p] >= 'a' && iShortName[p] <= 'z')
				iShortName[p] = iShortName[p] + 'A' - 'a' ;
		}
    }
    
	
}
void CDirectory::MakeUniqueShortName(unsigned char* rShortName,size_t aWavPos) const { 
	list<CDirectory*>::const_iterator i = iDirectoryList.begin();
	unsigned char nIndex = 1 ;
	while(i != iDirectoryList.end()){
		CDirectory* dir = (CDirectory*)(*i); 
		if(0 == memcmp(rShortName,dir->iShortName,aWavPos + 1) &&
			0 == memcmp(&rShortName[8],&(dir->iShortName[8]),3)) {
			nIndex ++ ;
		}
		i++ ;
	} 
	if(nIndex < 10)
		rShortName[aWavPos + 1] =  ('0' + nIndex) ;
	else if( nIndex < 36) 
		rShortName[aWavPos + 1] =  ('A' + nIndex - 10) ;
	else {
		nIndex = 10 ;
		rShortName[aWavPos-1] = '~';
		i = iDirectoryList.begin();
		while(i != iDirectoryList.end()){
			CDirectory* dir = (CDirectory*)(*i);
			if(0 == memcmp(rShortName,dir->iShortName,aWavPos) &&
				0 == memcmp(&rShortName[8],&(dir->iShortName[8]),3))
				nIndex ++ ;
			i++ ;
		}
		sprintf((char*)(&rShortName[aWavPos]),"%u",(unsigned int)(nIndex));
		rShortName[aWavPos + 2] = 0x20;
	}
}
/**
Destructor: 
1. To delete all the entries available in the form of directory structure
2. Also to delete the current entry

@internalComponent
@released 
*/

FILESYSTEM_API CDirectory::~CDirectory()
{
	while(iDirectoryList.size() > 0)
	{
		delete iDirectoryList.front();
		iDirectoryList.pop_front();
	}
}

/**
Function to initialize the time attributes of an entry

@internalComponent
@released 
*/

void CDirectory::InitializeTime()
{
	time_t rawtime;
	time ( &rawtime );
	iDateAndTime = localtime ( &rawtime );
	iDate.iCurrentDate.Day = iDateAndTime->tm_mday;
	iDate.iCurrentDate.Month = iDateAndTime->tm_mon+1; //As per FAT spec
	iDate.iCurrentDate.Year = iDateAndTime->tm_year - 80;//As per FAT spec
	iTime.iCurrentTime.Hour = iDateAndTime->tm_hour;
	iTime.iCurrentTime.Minute = iDateAndTime->tm_min;
	iTime.iCurrentTime.Seconds = iDateAndTime->tm_sec / 2;//As per FAT spec

	iCreationDate = iDate.iImageDate;
	iCreatedTime = iTime.iImageTime;
	iLastAccessDate = iDate.iImageDate;
	iLastWriteDate = iDate.iImageDate;
	iLastWriteTime = iTime.iImageTime;
}

/**
Function to initialize the entry name

@internalComponent
@released

@param aEntryName - entry name need to be initialized
*/
FILESYSTEM_API void CDirectory::SetEntryName(string aEntryName)
{
	iEntryName = aEntryName;
}

/**
Function to return the entry name

@internalComponent
@released

@return iEntryName - the entry name
*/

FILESYSTEM_API string CDirectory::GetEntryName() const
{
	return iEntryName;
}

/**
Function to initialize the file path

@internalComponent
@released

@param aFilePath - where the current entry contents actually stored
*/
FILESYSTEM_API void CDirectory::SetFilePath(char* aFilePath)
{
	iFilePath.assign(aFilePath);
}

/**
Function to return the file path

@internalComponent
@released

@return iFilePath - the file path
*/
FILESYSTEM_API string CDirectory::GetFilePath() const
{
	return iFilePath;
}

/**
Function to set the entry attribute

@internalComponent
@released

@param aAttribute - entry attribute
*/
FILESYSTEM_API void CDirectory::SetEntryAttribute(char aAttribute)
{
	iAttribute = aAttribute;
}

/**
Function to return the entry attribute

@internalComponent
@released

@return iAttribute - the entry attribute
*/
FILESYSTEM_API char CDirectory::GetEntryAttribute() const
{
	return iAttribute;
}


/**
Function to initialize the file size, this function is called only if the entry is of
type File.

@internalComponent
@released

@param aFileSize - the current entry file size
*/
FILESYSTEM_API void CDirectory::SetFileSize(unsigned int aFileSize)
{
	iFileSize = aFileSize;
}

/**
Function to return the entry file size, this function is called only if the entry is of
type File.

@internalComponent
@released

@return iFileSize - the file size
*/
FILESYSTEM_API unsigned int CDirectory::GetFileSize() const
{
	return iFileSize;
}

/**
Function to check whether this is a file 

@internalComponent
@released 

@return iFileFlag - the File Flag
*/
bool CDirectory::IsFile() const 
{
	return (iAttribute & EAttrDirectory) == 0  ;
}

/**
Function to return the entries Nt Reserved byte

@internalComponent
@released 

@return iNtReserverd - the Nt Reserved byte
*/
char CDirectory::GetNtReservedByte() const
{
	return iNtReserved;
}

/**
Function to return the entry Creation time in milli-seconds.

@internalComponent
@released

@return iCreatedTimeMsecs - created time in Milli-seconds
*/
char CDirectory::GetCreationTimeMsecs() const
{
	return iCreationTimeMsecs;
}

/**
Function to return the entry Created time

@internalComponent
@released

@retun iCreatedTime - created time
*/
unsigned short int CDirectory::GetCreatedTime() const
{
	return iCreatedTime;
}

/**
Function to return the entry Created date

@internalComponent
@released

@return iCreationDate - created date
*/
unsigned short int CDirectory::GetCreationDate() const
{
	return iCreationDate;
}

/**
Function to return the entry last accessed date

@internalComponent
@released

@return iLastAccessDate - last access date
*/
unsigned short int CDirectory::GetLastAccessDate() const
{
	return iLastAccessDate;
}

/**
Function to set high word cluster number

@internalComponent
@released

@param aHiClusterNumber - high word of current cluster number
*/
void CDirectory::SetClusterNumberHi(unsigned short int aHiClusterNumber)
{
	iClusterNumberHi = aHiClusterNumber;
}

/**
Function to return high word cluster number

@internalComponent
@released

@return iClusterNumberHi - high word of cluster number
*/
unsigned short int CDirectory::GetClusterNumberHi() const
{
	return iClusterNumberHi;
}

/**
Function to set low word cluster number

@internalComponent
@released 

@param aLowClusterNumber - low word of current cluster number
*/
void CDirectory::SetClusterNumberLow(unsigned short int aLowClusterNumber)
{
	iClusterNumberLow = aLowClusterNumber;
}

/**
Function to return low word cluster number

@internalComponent
@released 

@return iClusterNumberLow - low word of cluster number
*/
unsigned short int CDirectory::GetClusterNumberLow() const
{
	return iClusterNumberLow;
}

/**
Function to return last write date

@internalComponent
@released 

@return iLastWriteDate - last write date
*/
unsigned short int CDirectory::GetLastWriteDate() const
{
	return iLastWriteDate;
}

/**
Function to return last write time

@internalComponent
@released

@return iLastWriteTime - last write time
*/
unsigned short int CDirectory::GetLastWriteTime() const
{
	return iLastWriteTime;
}

/**
Function to return sub directory/file list

@internalComponent
@released

@return iDirectoryList -  entry list
*/
FILESYSTEM_API EntryList* CDirectory::GetEntryList()
{
	return &iDirectoryList;
}

/**
Function to insert a entry into Directory list. Also this function can be used 
extensively to construct tree form of directory structure.

@internalComponent
@released

@param aEntry - the entry to be inserted
*/
FILESYSTEM_API void CDirectory::InsertIntoEntryList(CDirectory* aEntry)
{
    aEntry->iParent = this ;
	iDirectoryList.push_back(aEntry);
}
 
FILESYSTEM_API bool CDirectory::GetShortEntry(TShortDirEntry& rEntry) {
  
    memcpy(rEntry.DIR_Name,iShortName,sizeof(rEntry.DIR_Name)); 
    rEntry.DIR_Attr = iAttribute;
    rEntry.DIR_NTRes = 0 ;
    rEntry.DIR_CrtTimeTenth = 0 ;        
    memcpy(rEntry.DIR_CrtTime,&iCreatedTime,sizeof(rEntry.DIR_CrtTime)); 
    memcpy(rEntry.DIR_CrtDate,&iCreationDate,sizeof(rEntry.DIR_CrtDate));
    memcpy(rEntry.DIR_LstAccDate,&iLastAccessDate,sizeof(rEntry.DIR_LstAccDate));
    memcpy(rEntry.DIR_FstClusHI,&iClusterNumberHi,sizeof(rEntry.DIR_FstClusHI)); 
    memcpy(rEntry.DIR_WrtTime,&iLastWriteTime,sizeof(rEntry.DIR_WrtTime)); 
    memcpy(rEntry.DIR_WrtDate,&iLastWriteDate,sizeof(rEntry.DIR_WrtDate)); 
    memcpy(rEntry.DIR_FstClusLO,&iClusterNumberLow,sizeof(rEntry.DIR_FstClusLO)); 
    memcpy(rEntry.DIR_FileSize,&iFileSize,sizeof(rEntry.DIR_FileSize)); 
    return true ;
}
static unsigned char ChkSum(const unsigned char* pFcbName) {
    short fcbNameLen ;
    unsigned char sum = 0 ;
    for(fcbNameLen = 11 ; fcbNameLen != 0 ; fcbNameLen --) {
        sum = ((sum & 1) ? 0x80 : 0 ) + (sum >> 1 ) + *pFcbName++ ; 
    }
    return sum ;        
}
 
FILESYSTEM_API bool CDirectory::GetLongEntries(list<TLongDirEntry>& rEntries) {
    if(0 == iEntryName.compare(".") || 0 == iEntryName.compare("..")){
        return false ;
    }
    rEntries.clear();
    TLongDirEntry entry ; 
	UTF16String uniStr(iEntryName.c_str() , iEntryName.length());
    size_t length = uniStr.length() ;
    const size_t KBytesPerEntry = (sizeof(entry.LDIR_Name1) + sizeof(entry.LDIR_Name2) +  \
		sizeof(entry.LDIR_Name3)) / 2 ;  
    size_t packs =  (length + KBytesPerEntry) / KBytesPerEntry  ;
    size_t buflen = packs * KBytesPerEntry;
    TUint16* buffer = new TUint16[buflen];
    if(!buffer)
        return false ;
    memset(buffer,0xff,(buflen << 1));    
    memcpy(buffer,uniStr.c_str(),(length << 1)); 
	buffer[length] = 0;
    entry.LDIR_Attr = (unsigned char)EAttrLongName;
    entry.LDIR_Chksum = ChkSum(iShortName);
    entry.LDIR_FstClusLO[0] = 0;
	entry.LDIR_FstClusLO[1] = 0;
    entry.LDIR_Type = 0;
    TUint16* ptr = buffer ;
    for(size_t n = 1 ; n <= packs ; n++ ) {
        entry.LDIR_Ord = n ;
        if(n == packs ){
            entry.LDIR_Ord |= 0x40 ;
        }
        memcpy(entry.LDIR_Name1,ptr,sizeof(entry.LDIR_Name1));
        ptr += (sizeof(entry.LDIR_Name1) / 2) ;
        memcpy(entry.LDIR_Name2,ptr,sizeof(entry.LDIR_Name2));
        ptr += (sizeof(entry.LDIR_Name2) / 2);
        memcpy(entry.LDIR_Name3,ptr,sizeof(entry.LDIR_Name3));
        ptr += (sizeof(entry.LDIR_Name3) / 2);
        rEntries.push_front(entry);
    }
    
    delete []buffer ;
    return true ; 
}
