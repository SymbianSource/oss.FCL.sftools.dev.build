/*
* Copyright (c) 1995-2009 Nokia Corporation and/or its subsidiary(-ies).
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


#ifndef __R_ROMNODE_H__
#define __R_ROMNODE_H__

#if defined(__MSVCDOTNET__) || defined(__TOOLS2__)
#include <fstream>
#else //!__MSVCDOTNET__
#include <fstream.h>
#endif //__MSVCDOTNET__

#include <e32std.h>
#include "rofs.h"
#include "e32image.h"
#include "h_utl.h"

const TUint KOverrideStack = 0x01;
const TUint KOverrideHeapMin = 0x02;
const TUint KOverrideHeapMax = 0x04;
const TUint KOverrideRelocationAddress = 0x08;
const TUint KOverrideUid1 = 0x10;
const TUint KOverrideUid2 = 0x20;
const TUint KOverrideUid3 = 0x40;
const TUint KOverrideCallEntryPoint = 0x80;
const TUint KOverrideNoCallEntryPoint = 0x100;
const TUint KOverridePriority = 0x200;
const TUint KOverrideStackReserve = 0x400;
const TUint KOverrideKeepIAT = 0x800;
const TUint KOverrideCapability = 0x1000;
const TUint KOverrideFixed = 0x2000;
const TUint KOverrideDllData  = 0x4000;
const TUint KOverrideCodeUnpaged = 0x8000;
const TUint KOverrideCodePaged = 0x10000;
const TUint KOverrideDataUnpaged = 0x20000;
const TUint KOverrideDataPaged = 0x40000;

enum ECompression{
	ECompressionUnknown=0,
	ECompressionCompress=1,
	ECompressionUncompress=2
};

const TInt KFileHidden = 0xFFFFFFFF;



class TRomBuilderEntry;
class RomFileStructure;
class TRomNode
	{
public:
	TRomNode(TText* aName, TRomBuilderEntry* aEntry=0);
	~TRomNode();
	void Destroy();

	static inline TRomNode* FirstNode() { return TheFirstNode; };
	inline TRomNode* NextNode() { return iNextNode; };
	inline void SetNextNode(TRomNode* aNode) { iNextNode = aNode; };
	inline TRomNode* Currentchild() const { return iChild; };
	inline TRomNode* Currentsibling() const { return iSibling; };

	void DisplayStructure(ostream* aOut);
	TRomNode* FindInDirectory(TText *aName);
	void AddFile(TRomNode *aChild);
	TRomNode* NewSubDir(TText *aName);
	TInt SetAtt(TText *anAttWord);
	TInt SetAttExtra(TText *anAttWord, TRomBuilderEntry* aFile, enum EKeyword aKeyword);
	inline void SetStackSize(TInt aValue);
	inline void SetHeapSizeMin(TInt aValue);
	inline void SetHeapSizeMax(TInt aValue);
	inline void SetCapability(SCapabilitySet& aCapability);
	inline void SetUid1(TInt aValue);
	inline void SetUid2(TInt aValue);
	inline void SetUid3(TInt aValue);
	inline void SetPriority(TProcessPriority aValue);
	inline void SetFixed();
	inline void SetDllData();


	TBool IsDirectory() const { return 0==iEntry; };
	TBool IsFile() const { return 0!=iEntry; };

	TInt CalculateDirectoryEntrySize( TInt& aDirectoryBlockSize,
										    TInt& aFileBlockSize );

	TInt CountFileAndDir(TInt& aFileCount, TInt& aDirCount);

	TInt PlaceFile( TUint8* &aDest, TUint aOffset, TUint aMaxSize, CBytePair *aBPE );
	TInt Place( TUint8* aDestBase );

	TInt NameCpy(char* aDest, TUint8& aUnicodeLength );
	TInt NameLengthUnicode() const;

	void Rename(TRomNode *aOldParent, TRomNode* aNewParent, TText* aNewName);

	TRofsEntry* RofsEntry() const { return iRofsEntry; };
	void SetRofsEntry(TRofsEntry* aEntry);
	inline void SetImagePosition( TInt aPosition ) { iImagePosition = aPosition; };
	inline void SetFileBlockPosition( TInt aPosition ) { iFileBlockPosition = aPosition; };
	
	void AddNodeForSameFile(TRomNode* aPreviousNode, TRomBuilderEntry* aFile);

	void CountDirectory(TInt& aFileCount, TInt& aDirCount);
	TInt ProcessDirectory(RomFileStructure* aRFS);

	TRomNode* CopyDirectory(TRomNode*& aLastExecutable);
	void Alias(TRomNode* aNode);
	
	static void deleteTheFirstNode();
	static void displayFlatList();
	TInt FullNameLength(TBool aIgnoreHiddenAttrib = EFalse) const;
	TInt GetFullName(char* aBuf, TBool aIgnoreHiddenAttrib = EFalse) const;
	static void InitializeCount();
	// Accessor Function.
    inline TRomNode* GetParent() const { return iParent; }

private:
	void Remove(TRomNode* aChild);
	void Add(TRomNode* aChild);
	void Clone(TRomNode* aOriginal);

	TInt CalculateEntrySize() const;

private:	
	static TInt Count;			// seed for unique identifiers

	// Flat linked list of TRomNode structures
	static TRomNode*	TheFirstNode;
	static TRomNode*	TheLastNode;
	TRomNode* iNextNode;

	TRomNode* iParent;
	TRomNode* iSibling;
	TRomNode* iChild;
	TRomNode* iNextNodeForSameFile;

protected:
	TInt iIdentifier;
	TRofsEntry* iRofsEntry;		// in ROM image buffer

	TInt	iTotalDirectoryBlockSize;	// calculated size of directory block
	TInt	iTotalFileBlockSize;		// calculated size of file block


	TInt iImagePosition;		// position of directory entry in image
	TInt iFileBlockPosition;	// position of directory file block in image

	friend class FileEntry;

public:
	TText* iName;
	TUint8 iAtt;
	TUint8 iAttExtra;
	TBool iHidden;
	TRomBuilderEntry* iEntry;		// represents file data
	TUint	iFileStartOffset;		// position in image of start of file
	TInt iSize;			        // size of associated file

	// Override values
	TInt iStackSize;
	TInt iHeapSizeMin;
	TInt iHeapSizeMax;
	SCapabilitySet iCapability;
	TInt iUid1;
	TInt iUid2;
	TInt iUid3;
	TProcessPriority iPriority;

	TInt iOverride;
	TBool iFileUpdate;
  bool iAlias;
  // for a ROM image, all the files have a default read-only attribute, but in data drive, files's default attribute should be 0 
	static TUint8 sDefaultInitialAttr ;
	};



class DllDataEntry;
class TRomBuilderEntry
	{
public:
	TRomBuilderEntry(const char *aFileName, TText *aName);
	~TRomBuilderEntry();
	void SetRomNode(TRomNode* aNode);
	TRofsEntry* RofsEntry() const {return iRomNode->RofsEntry(); };
	TInt PlaceFile( TUint8* &aDest, TUint aMaxSize, CBytePair *aBPE );

	inline TInt RealFileSize() const { return iRealFileSize; };
	inline void SetRealFileSize(TInt aFileSize) { iRealFileSize=aFileSize;};
	void DisplaySize(TPrintType aWhere);
	
private:
	TRomBuilderEntry();
	TRomBuilderEntry(const TRomBuilderEntry&);
	const TRomBuilderEntry& operator==(const TRomBuilderEntry &);
	DllDataEntry* iFirstDllDataEntry;

public:
	TText *iName;
	char *iFileName;

	TRomBuilderEntry* iNext;
	TRomBuilderEntry* iNextInArea;
	TBool iExecutable;
	TBool iFileOffset; // offset of the file in ROM
	TUint iCompressEnabled;
	TUint8 iUids[sizeof(TCheckedUid)];
	TBool iHidden;
  	DllDataEntry* GetFirstDllDataEntry() const;
	void SetFirstDllDataEntry(DllDataEntry *aDllDataEntry);

private:
	TRomNode *iRomNode;
	TInt	iRealFileSize;	
	};


inline void TRomNode::SetStackSize(TInt aValue)
	{
	iStackSize = aValue;
	iOverride |= KOverrideStack;
	}

inline void TRomNode::SetHeapSizeMin(TInt aValue)
	{
	iHeapSizeMin = aValue;
	iOverride |= KOverrideHeapMin;
	}

inline void TRomNode::SetHeapSizeMax(TInt aValue)
	{
	iHeapSizeMax = aValue;
	iOverride |= KOverrideHeapMax;
	}

inline void TRomNode::SetCapability(SCapabilitySet& aCapability)
	{
	iCapability = aCapability;
	iOverride |= KOverrideCapability;
	}

inline void TRomNode::SetUid1(TInt aValue)
	{
	iUid1 = aValue;
	iOverride |= KOverrideUid1;
	}

inline void TRomNode::SetUid2(TInt aValue)
	{
	iUid2 = aValue;
	iOverride |= KOverrideUid2;
	}

inline void TRomNode::SetUid3(TInt aValue)
	{
	iUid3 = aValue;
	iOverride |= KOverrideUid3;
	}

inline void TRomNode::SetPriority(TProcessPriority aValue)
	{
	iPriority = aValue;
	iOverride |= KOverridePriority;
	}

inline void TRomNode::SetFixed()
	{
	iOverride |= KOverrideFixed;
	}
inline void TRomNode::SetDllData()
{
	iOverride |= KOverrideDllData;
}

#endif
