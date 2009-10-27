/*
* Copyright (c) 1998-2009 Nokia Corporation and/or its subsidiary(-ies).
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


#ifndef __R_DIR_H__
#define __R_DIR_H__

#include <e32std.h>

// Generalised set handling
class SetMember
	{
public:
	TBool operator==(const SetMember& aMember) {return(Compare(aMember)==0);}
	virtual SetMember* Copy() const =0;
	virtual void Close();
public:
	TInt Type() const {return iType;}
	virtual TInt Compare(const SetMember& aMember) const =0;
	virtual void DebugPrint() const =0;
protected:
	virtual ~SetMember();
	SetMember(TInt aType) : iType(aType) {TotalInSystem++;}
	SetMember(const SetMember& aMember) : iType(aMember.iType) {TotalInSystem++;}
	TBool operator<(const SetMember& aMember) {return(Compare(aMember)<0);}
	TBool operator>(const SetMember& aMember) {return(Compare(aMember)>0);}
private:
	TInt iType;
	static TInt TotalInSystem;
	};

class FiniteSet : public SetMember
	{
protected:
	enum TFiniteSetType {EFiniteSetType=100};
public:
	static FiniteSet* New(TInt aMaxCount);
	static FiniteSet* Singleton(TInt aMaxCount, const SetMember& aMember);
	virtual ~FiniteSet();
	virtual SetMember* Copy() const;
	TInt Find(const SetMember& aMember) const;
	TBool SubsetOf(const FiniteSet& aSet) const;
	TInt Intersection(const FiniteSet& aSet);
	TInt Union(const FiniteSet& aSet);
	TInt Difference(const FiniteSet& aSet);
	TInt Add(const SetMember& aMember);
	TInt Remove(const SetMember& aMember);
	SetMember* Detach(TInt anIndex);
	TInt Count() const {return iCount;}
	TBool Empty() const {return !iCount;}
	SetMember& operator[](TInt anIndex) const {return *iMembers[anIndex];}
	virtual void DebugPrint() const;
protected:
	FiniteSet(TInt aMaxCount);
	FiniteSet(const FiniteSet& aSet);
	FiniteSet* Construct();
	virtual TInt Compare(const SetMember& aMember) const;
	TInt Find(const SetMember& aMember, TInt& anIndex) const;
	TInt Insert(const SetMember& aMember, TInt anIndex);
protected:
	TInt iMaxCount;
	TInt iCount;
	SetMember** iMembers;
	};

// ROMBUILD-specific stuff
#include <e32rom.h>

class CObeyFile;
class TRomNode;
class THardwareVariant;

class RomFileStructure;
class TVariantList
	{
public:
	enum {EMaxVariants=32};
	static void Setup(CObeyFile* aObey);
	TVariantList() : iList(0)
		{}
	TVariantList(TInt aVariant)
		{iList=TUint(1<<aVariant);}
	TVariantList(THardwareVariant a);
	void Add(TInt aVariant)
		{iList|=TUint(1<<aVariant);}
	TVariantList& Union(const TVariantList aList)
		{iList|=aList.iList; return *this;}
	TVariantList& Intersection(const TVariantList aList)
		{iList&=aList.iList; return *this;}
	TBool operator==(const TVariantList aList) const
		{return(iList==aList.iList);}
	TBool operator!=(const TVariantList aList) const
		{return(iList!=aList.iList);}
	TBool operator<=(const TVariantList aList) const
		{return(iList==(iList&aList.iList));}
	TBool operator>=(const TVariantList aList) const
		{return(iList==(iList|aList.iList));}
	TBool operator[](TInt aVariant) const
		{return(iList&TUint(1<<aVariant));}
	TBool Empty() const
		{return !iList;}
	TUint Mask() const
		{return iList;}
	THardwareVariant Lookup() const;
	static void SetNumVariants(TInt aNumVariants);
	static void SetVariants(THardwareVariant* aVariants);
private:
	friend class RomFileStructure;
	TUint iList;
	static TInt NumVariants;
	static THardwareVariant Variants[EMaxVariants];
	};

class Entry : public SetMember
	{
public:
	Entry(TInt aType) : SetMember(aType), iRomNode(NULL) {}
	Entry(const Entry& anEntry) : SetMember(anEntry), iRomNode(NULL) {}
	TBool IsFile() const {return (Type()==EFile);}
	TBool IsDir() const {return (Type()==EDir);}
	TVariantList Variants() const {return iVariants;}
	TRomEntry* CreateRomEntry(char*& anAddr) const;
	void Restrict(TVariantList aList) {iVariants.Intersection(aList);}
	const TText* Name() const;
protected:
	enum {EFile=0, EDir=1};
	TVariantList iVariants;
	TRomNode* iRomNode;
	};

class FileEntry : public Entry
	{
public:
	static FileEntry* New(TRomNode* aFile);
	virtual SetMember* Copy() const;
	virtual ~FileEntry();
	virtual void DebugPrint() const;
protected:
	FileEntry() : Entry(EFile) {}
	FileEntry(const FileEntry& aFileEntry);
	virtual TInt Compare(const SetMember& aMember) const;
	};

class Directory;
class DirEntry : public Entry
	{
public:
	static DirEntry* New(TRomNode* aFile, Directory* aDir);
	virtual SetMember* Copy() const;
	virtual ~DirEntry();
	Directory* Dir() const {return iDir;}
	TRomDir* CreateRomEntries(char*& anAddr) const;
	virtual void DebugPrint() const;
protected:
	DirEntry() : Entry(EDir) {}
	DirEntry(const DirEntry& aDirEntry);
	virtual TInt Compare(const SetMember& aMember) const;
protected:
	Directory* iDir;
	};

class Directory : public FiniteSet
	{
public:
	static Directory* New(TInt aMaxCount, TVariantList aList);
	TInt Compile(const FiniteSet& aSet);
	TInt Merge(const Directory& aDir);
	TVariantList Variants() const {return iVariants;}
	virtual void DebugPrint() const;
	void Open();
	virtual void Close();
protected:
	Directory(TInt aMaxCount);
private:
	Directory(const Directory &);
	~Directory();
protected:
	friend class DirEntry;
	TVariantList iVariants;
	TRomDir* iRomDir;
private:
	static TInt DirectoryCount;
private:
	TInt iAccessCount;
	TInt iIdentifier;
	};

class RomFileStructure : public FiniteSet
	{
public:
	static RomFileStructure* New(TInt aMaxCount);
	~RomFileStructure();
	void Destroy();
	TInt ProcessDirectory(TRomNode* aDir);
protected:
	RomFileStructure(TInt aMaxCount);
	};


#endif
