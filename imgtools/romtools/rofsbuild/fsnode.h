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
#ifndef __FILE_SYSTEM_ITEM_HEADER__
#define __FILE_SYSTEM_ITEM_HEADER__ 
#include "fatdefines.h"
#include <time.h>
class UTF16String; 
class TFSNode {
public :
   TFSNode(TFSNode* aParent = 0 ,const char* aFileName = 0, TUint8 aAttrs = 0, const char* aPCSideName = 0);
	~TFSNode() ;
#ifdef _DEBUG
	void PrintTree(int nTab = 0);
#endif
	inline TUint8 GetAttrs() const { return iAttrs ;}
	inline const char* GetFileName() const { return (iFileName != 0) ? iFileName : "" ;}
	inline const char* GetPCSideName() const { return (iPCSideName != 0) ? iPCSideName : "" ;}
	inline TFSNode* GetParent() const { return iParent;}
	inline TFSNode* GetFirstChild() const {return iFirstChild;}
	inline TFSNode* GetSibling() const { return iSibling ;}
	
	// return the size of memory needed to store this entry in a FAT system
	// for a file entry, it's size of file
	// for a directory entry, it's sumup of memory for subdir and files entry storage
	TUint GetSize() const ; 
	
	bool IsDirectory() const ;
	
	//Except for "." and "..", every direcoty/file entry in FAT filesystem are treated as with
	//"long name", for the purpose of reserving case sensitive file name.
	// This function is for GetLongEntries() to know length of long name .
	int GetWideNameLength() const ;
	
	// To init the entry,
	// For a file entry, aSize is the known file size,
	// For a directory entry, aSize is not cared.	
	void Init(time_t aCreateTime, time_t aAccessTime, time_t aWriteTime, TUint aSize );
	
	//This function is used by TFatImgGenerator::PrepareClusters, to prepare the clusters 
	// aClusterData should points to a buffer which is at least the size returns by 
	// GetSize() 
	void WriteDirEntries(TUint aStartIndex, TUint8* aClusterData ); 
	

	
protected:
	void GenerateBasicName();
	void MakeUniqueShortName(char rShortName[12],TUint baseNameLength) const;
	void GetShortEntry(TShortDirEntry* aEntry);
	int GetLongEntries(TLongDirEntry* aEntries) ; 
	TFSNode* iParent ;
	TFSNode* iFirstChild ;
	TFSNode* iSibling ;
	TUint8 iAttrs ;
	char* iPCSideName;
	char* iFileName;
	char iShortName[12];
	UTF16String* iWideName ;	
	TTimeInteger iCrtTime ;
	TDateInteger iCrtDate ;
	TUint8 iCrtTimeTenth ;
	TDateInteger iLstAccDate ;
	TTimeInteger iWrtTime ;
	TDateInteger iWrtDate ;
	TUint iFileSize ;
	TShortDirEntry* iFATEntry ;
};
 
#endif
