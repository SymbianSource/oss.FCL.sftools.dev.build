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
* Directory operations for FileSystem component
* @internalComponent
* @released
*
*/


#ifndef DIRECTORY_H
#define DIRECTORY_H

#include "utils.h"

/* If the macro _FILESYSTEM_DLL is defined, then the macro FILESYSTEM_API is used to 
 * export the functions. Hence while building the DLL this macro should be used.
 * Else if the macro _USE_FILESYSTEM_DLL is defined, then the macro FILESYSTEM_API is 
 * used to import the functions. Hence while linking this macro should be used.
 * If none of the above macros defined, then the macro FILESYSTEM_API is defined empty 
 * and it is used for creating static library.
 * The purpose of using multiple macros is to deliver both the static and dynamic 
 * libraries from the same set of source files.
 */
#ifdef _FILESYSTEM_DLL
	#define FILESYSTEM_API __declspec(dllexport)
#elif _USE_FILESYSTEM_DLL
	#define FILESYSTEM_API __declspec(dllimport)
#else
	#define FILESYSTEM_API
#endif

#include <list>
#include <stack>
#include <time.h>

class CDirectory;
class CLongEntry;

typedef list<CDirectory*> EntryList;

//Directory, file and volume Attributes
enum KAttributes
{
	EAttrReadOnly = 0x01,
	EAttrHidden = 0x02,
	EAttrSystem = 0x04,
	EAttrVolumeId = 0x08,
	EAttrDirectory = 0x10,
	EAttrArchive = 0x20,
	EAttrLongName = EAttrReadOnly | EAttrHidden | EAttrSystem | EAttrVolumeId,
	EAttrLongNameMask = EAttrReadOnly | EAttrHidden | EAttrSystem | EAttrVolumeId \
						| EAttrDirectory | EAttrArchive,
	ELastLongEntry = 0x40
};

//Time format, should be written as a integer in FAT image
typedef struct 
{
	unsigned short int Seconds:5;
	unsigned short int Minute:6;
	unsigned short int Hour:5;
}FatTime;

//Date format, should be written as a integer in FAT image
typedef struct 
{
	unsigned short int Day:5;
	unsigned short int Month:4;
	unsigned short int Year:7;
}FatDate;

//This union convention used to convert bit fields into integer
union TDateInteger
{
	FatDate iCurrentDate;
	unsigned short int iImageDate;
};

//This union convention used to convert bit fields into integer
union TTimeInteger
{	
	FatTime iCurrentTime;
	unsigned short int iImageTime;
};

struct TShortDirEntry {
    unsigned char DIR_Name [11];
    unsigned char DIR_Attr ;
    unsigned char DIR_NTRes ;
    unsigned char DIR_CrtTimeTenth ;
    unsigned char DIR_CrtTime[2] ;
    unsigned char DIR_CrtDate[2] ;
    unsigned char DIR_LstAccDate[2] ;
    unsigned char DIR_FstClusHI[2] ;
    unsigned char DIR_WrtTime[2] ;
    unsigned char DIR_WrtDate[2];
    unsigned char DIR_FstClusLO[2];
    unsigned char DIR_FileSize[4] ;    
};

struct TLongDirEntry {
    unsigned char LDIR_Ord ;
    unsigned char LDIR_Name1[10] ;
    unsigned char LDIR_Attr ;
    unsigned char LDIR_Type ;
    unsigned char LDIR_Chksum ;
    unsigned char LDIR_Name2[12] ;
    unsigned char LDIR_FstClusLO[2] ; 
    unsigned char LDIR_Name3[4] ;
};
/* This class describes the attributes of a single directory/file/volume entry.
 *
 * @internalComponent
 * @released
 */
class CDirectory
{

public:
	FILESYSTEM_API CDirectory(const char* aEntryName,CDirectory* aParent);
	FILESYSTEM_API ~CDirectory();
	FILESYSTEM_API EntryList* GetEntryList();
	FILESYSTEM_API void InsertIntoEntryList(CDirectory* aEntry);
	FILESYSTEM_API void SetFilePath(char* aFilePath);
	FILESYSTEM_API string GetFilePath() const;
	FILESYSTEM_API void SetEntryName(string aEntryName);
	FILESYSTEM_API string GetEntryName() const;
	FILESYSTEM_API void SetEntryAttribute(char aAttribute);
	FILESYSTEM_API char GetEntryAttribute() const;
	char GetNtReservedByte() const;
	char GetCreationTimeMsecs() const;
	unsigned short int GetCreatedTime() const;
	unsigned short int GetCreationDate() const;
	unsigned short int GetLastAccessDate() const;
	unsigned short int GetClusterNumberHi() const;
	void SetClusterNumberHi(unsigned short int aHiClusterNumber);
	unsigned short int GetClusterNumberLow() const;
	void SetClusterNumberLow(unsigned short int aLowClusterNumber);
	unsigned short int GetLastWriteDate() const;
	unsigned short int GetLastWriteTime() const;
	FILESYSTEM_API void SetFileSize(unsigned int aFileSize);
	FILESYSTEM_API unsigned int GetFileSize() const;
	bool IsFile() const ; 
	FILESYSTEM_API CDirectory* GetParent()const {
	    return iParent ;
	}
	FILESYSTEM_API bool GetShortEntry(TShortDirEntry& rEntry) ;
	FILESYSTEM_API bool GetLongEntries(list<TLongDirEntry>& rEntries) ;
private:
	void InitializeTime();
	void MakeUniqueShortName(unsigned char* rShortName,size_t aWavPos) const ;
private:
	string iEntryName;					//Directory or file name
    unsigned char iShortName[12] ; 
	char iAttribute;					//To mention file or directory or Volume
	char iNtReserved;					//Reserved for use by windows NT, this value always zero
	char iCreationTimeMsecs;			/**Millisecond stamp at file creation time, Since this is not 
	so important, always initialized to zero*/
	unsigned short int iCreatedTime;	//Time file was created
	unsigned short int iCreationDate;	//Date file was created
	unsigned short int iLastAccessDate;	//Date file was last accessed
	unsigned short int iClusterNumberHi;//High word of this entry's first cluster number
	unsigned short int iClusterNumberLow;//Low word of this entry's first cluster number
	unsigned short int iLastWriteDate;	//Date file was written
	unsigned short int iLastWriteTime;	//Time file was written
	unsigned int iFileSize;				//file size
	EntryList iDirectoryList;			//List Template used to hold subdirectories
	
	string iFilePath; //Holds file path only if the entry is of type "file"

	struct tm* iDateAndTime;
	union TTimeInteger iTime;
	union TDateInteger iDate; 
	CDirectory* iParent ;
};

#endif //DIRECTORY_H
