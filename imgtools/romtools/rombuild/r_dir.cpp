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
* e32tools/rombuild/r_dir.cpp
*
*/


#include <stdlib.h>
#include <string.h>
#include "r_dir.h"
#include "r_obey.h"
#include "r_rom.h"
#include "r_global.h"

// Generalised set handling

// class SetMember
TInt SetMember::TotalInSystem=0;

SetMember::~SetMember()
	{
	TotalInSystem--;
	TRACE(TDIR,Print(EAlways,"SetMember %08x Destruct Remaining=%d\n",this,TotalInSystem));
	}

void SetMember::Close()
	{
	delete this;
	}

// class FiniteSet
FiniteSet::FiniteSet(TInt aMaxCount)
	: SetMember(EFiniteSetType), iMaxCount(aMaxCount), iCount(0), iMembers(NULL)
	{}

FiniteSet::FiniteSet(const FiniteSet& aSet)
	: SetMember(aSet), iMaxCount(aSet.iMaxCount), iCount(0), iMembers(NULL)
	{}

FiniteSet* FiniteSet::New(TInt aMaxCount)
	{
	FiniteSet* pS=new FiniteSet(aMaxCount);
	if (pS)
		pS=pS->Construct();
	return pS;
	}

FiniteSet* FiniteSet::Construct()
	{
	SetMember** pM=new SetMember*[iMaxCount];
	if (!pM)
		{
		delete this;
		return NULL;
		}
	iMembers=pM;
	TInt i;
	for(i=0; i<iMaxCount; i++)
		pM[i]=NULL;
	return this;
	}

FiniteSet* FiniteSet::Singleton(TInt aMaxCount, const SetMember& aMember)
	{
	FiniteSet* pS=New(aMaxCount);
	if (pS)
		{
		pS->iCount=1;
		pS->iMembers[0]=(SetMember*)&aMember;
		}
	return pS;
	}

FiniteSet::~FiniteSet()
	{
	TRACE(TDIR,Print(EAlways,"FiniteSet %08x Destruct, iCount=%d\n",this,iCount));
	TInt i;
	for (i=0; i<iCount; i++)
		iMembers[i]->Close();
	delete[] iMembers;
	}

TInt FiniteSet::Find(const SetMember& aMember, TInt& anIndex) const
	{
	if (iCount==0)
		{
		anIndex=0;
		return KErrNotFound;
		}
	TInt k=aMember.Compare(*iMembers[0]);
	if (k==0)
		{
		anIndex=0;
		return KErrNone;
		}
	if (k<0)
		{
		anIndex=0;
		return KErrNotFound;
		}
	if (iCount==1)
		{
		anIndex=1;
		return KErrNotFound;
		}
	TInt r=iCount-1;
	k=aMember.Compare(*iMembers[r]);
	if (k==0)
		{
		anIndex=r;
		return KErrNone;
		}
	if (k>0)
		{
		anIndex=iCount;
		return KErrNotFound;
		}
	if (iCount==2)
		{
		anIndex=1;
		return KErrNotFound;
		}
	TInt l=0;
	while(r-l>1)
		{
		TInt m=(l+r)>>1;
		k=aMember.Compare(*iMembers[m]);
		if (k==0)
			{
			anIndex=m;
			return KErrNone;
			}
		if (k>0)
			l=m;
		else
			r=m;
		}
	anIndex=r;
	return KErrNotFound;
	}

TInt FiniteSet::Compare(const SetMember& aSetMember) const
	{
	TInt k=Type()-aSetMember.Type();
	if (k!=0)
		return k;
	const FiniteSet& s=(const FiniteSet&)aSetMember;
	TInt c=Min(iCount,s.iCount);
	TInt i;
	for(i=0; i<c; i++)
		{
		k=iMembers[i]->Compare(s[i]);
		if (k!=0)
			return k;
		}
	return (iCount-s.iCount);
	}

SetMember* FiniteSet::Copy() const
	{
	FiniteSet* pS=new FiniteSet(*this);
	if (pS)
		{
		SetMember** pA=new SetMember*[iMaxCount];
		if (!pA)
			{
			delete pS;
			return NULL;
			}
		pS->iMembers=pA;
		TInt i;
		for(i=0; i<iCount; i++)
			{
			SetMember* pM=iMembers[i]->Copy();
			if (!pM)
				{
				delete pS;
				return NULL;
				}
			pA[i]=pM;
			pS->iCount++;
			}
		}
	return pS;
	}

TInt FiniteSet::Find(const SetMember& aMember) const
	{
	TInt i;
	TInt r=Find(aMember,i);
	if (r<0)
		return r;
	return i;
	}

TBool FiniteSet::SubsetOf(const FiniteSet& aSet) const
	{
	if (iCount>aSet.iCount)
		return EFalse;
	TInt i;
	for(i=0; i<iCount; i++)
		{
		TInt j;
		if (aSet.Find(*iMembers[i],j)!=KErrNone)
			return EFalse;
		}
	return ETrue;
	}

TInt FiniteSet::Intersection(const FiniteSet& aSet)
	{
	if (iCount==0)
		return KErrNotFound;
	TInt i;
	for(i=0; i<iCount; i++)
		{
		TInt j;
		if (aSet.Find(*iMembers[i],j)!=KErrNone)
			Detach(i)->Close();
		}
	return iCount ? KErrNone : KErrNotFound;
	}

TInt FiniteSet::Union(const FiniteSet& aSet)
	{
	TInt i;
	for(i=0; i<aSet.iCount; i++)
		{
		const SetMember& m=*aSet.iMembers[i];
		TInt j;
		if (Find(m,j)!=KErrNone)
			{
			const SetMember* pC=m.Copy();
			if (!pC)
				return KErrNoMemory;
			TInt r=Insert(*pC,j);
			if (r!=KErrNone)
				return r;
			}
		}
	return iCount ? KErrNone : KErrNotFound;
	}

TInt FiniteSet::Difference(const FiniteSet& aSet)
	{
	if (iCount==0)
		return KErrNotFound;
	TInt i;
	for(i=0; i<iCount; i++)
		{
		TInt j;
		if (aSet.Find(*iMembers[i],j)==KErrNone)
			Detach(i)->Close();
		}
	return iCount ? KErrNone : KErrNotFound;
	}

TInt FiniteSet::Add(const SetMember& aMember)
	{
	TInt i;
	TInt r=Find(aMember,i);
	if (r==KErrNotFound && Insert(aMember,i)==KErrOverflow)
		return KErrOverflow;
	return r;
	}

TInt FiniteSet::Remove(const SetMember& aMember)
	{
	TInt i;
	TInt r=Find(aMember,i);
	if (r==KErrNone)
		Detach(i)->Close();
	return r;
	}

SetMember* FiniteSet::Detach(TInt anIndex)
	{
	TInt i;
	SetMember* pM=iMembers[anIndex];
	for(i=anIndex; i<iCount-1; i++)
		iMembers[i]=iMembers[i+1];
	iCount--;
	return pM;
	}

TInt FiniteSet::Insert(const SetMember& aMember, TInt anIndex)
	{
	if (iCount==iMaxCount)
		return KErrOverflow;
	TInt i;
	for(i=iCount-1; i>=anIndex; i--)
		iMembers[i+1]=iMembers[i];
	iMembers[anIndex]=(SetMember*)&aMember;
	iCount++;
	return KErrNone;
	}

// ROMBUILD-specific stuff

inline TLinAddr ActualToRomAddress(TAny* anAddr)
	{ return TLinAddr(anAddr)-TheRomMem+TheRomLinearAddress; }

// class TVariantList
TInt TVariantList::NumVariants;
THardwareVariant TVariantList::Variants[TVariantList::EMaxVariants];
void TVariantList::Setup(CObeyFile* aObey)
	{
	NumVariants=aObey->iNumberOfVariants;
	if (NumVariants>EMaxVariants)
		Print(EError,"Too many variants");
	TInt i;
	for(i=0; i<NumVariants; i++)
		{
		Variants[i]=aObey->iVariants[i]->iHardwareVariant;
		}
	}

TVariantList::TVariantList(THardwareVariant a)
	{
	iList=0;
	TInt i;
	for (i=0; i<NumVariants; i++)
		{
		if (Variants[i]<=a)
			iList|=TUint(1<<i);
		}
	}

THardwareVariant TVariantList::Lookup() const
	{
	TInt i;
	for (i=0; i<NumVariants; i++)
		{
		if (iList & TUint(1<<i))
			return Variants[i];
		}
	return THardwareVariant(0);
	}

void TVariantList::SetNumVariants(TInt aNumVariants)
{
	NumVariants = aNumVariants;
	if (NumVariants>EMaxVariants)
		Print(EError,"Too many variants");
}

void TVariantList::SetVariants(THardwareVariant* aVariants)
{
	TInt Index = NumVariants;
	while(Index--)
	{
		Variants[Index] = aVariants[Index];
	}
}

void DumpRomEntry(const TRomEntry& e)
	{
	char name[256];
	char* d = name;
	const wchar_t* s = (const wchar_t*)e.iName;
	const wchar_t* sE = s + e.iNameLength;
	for (; s<sE; *d++ = (char)*s++) {}
	*d++ = 0;
	Print(ELog, "RomEntry @ %08x: SZ=%08x A=%08x att=%02x name %s\n", &e, e.iSize, e.iAddressLin, e.iAtt, name);
	}

// class Entry
TRomEntry* Entry::CreateRomEntry(char*& anAddr) const
	{

	TRomEntry *pE=(TRomEntry*)anAddr;
	pE->iAtt=iRomNode->iAtt;
	pE->iSize=iRomNode->iRomFile->iAddresses.iSize;
	pE->iAddressLin=iRomNode->iRomFile->iAddresses.iRunAddr;
	if (IsFile())
		iRomNode->iRomFile->SetRomEntry(pE);
	pE->iName[0]=0;
	pE->iName[1]=0;
	TInt nl=iRomNode->NameCpy((char*)pE->iName);
	pE->iNameLength=(TUint8)nl;
	if (Unicode)
		nl<<=1;
	anAddr+=Align4(KRomEntrySize+nl);
	TRACE(TDIR,DumpRomEntry(*pE));
	return pE;
	}

const TText* Entry::Name() const
	{
	return iRomNode->iName;
	}

// class FileEntry
FileEntry::FileEntry(const FileEntry& aFileEntry)
	: Entry(aFileEntry)
	{
	iVariants=aFileEntry.iVariants;
	iRomNode=aFileEntry.iRomNode;
	}

FileEntry* FileEntry::New(TRomNode* aFile)
	{
	FileEntry* pE=new FileEntry();
	if (pE)
		{
		pE->iRomNode=aFile;
		pE->iVariants=TVariantList(aFile->HardwareVariant());
		}
	return pE;
	}

TInt FileEntry::Compare(const SetMember& aMember) const
	{
	TInt k=Type()-aMember.Type();
	if (k!=0)
		return k;
	FileEntry *entry=(FileEntry *)&aMember;
	return (iRomNode->iIdentifier-entry->iRomNode->iIdentifier);
	}

SetMember* FileEntry::Copy() const
	{
	return new FileEntry(*this);
	}

FileEntry::~FileEntry()
	{
	}

// class DirEntry
DirEntry::DirEntry(const DirEntry& aDirEntry)
	: Entry(aDirEntry)
	{
	iVariants=aDirEntry.iVariants;
	iRomNode=aDirEntry.iRomNode;
	iDir=aDirEntry.iDir;
	}

DirEntry* DirEntry::New(TRomNode* aFile, Directory* aDir)
	{
	DirEntry* pE=new DirEntry();
	if (pE)
		{
		pE->iRomNode=aFile;
		pE->iVariants=aDir->iVariants;
		pE->iDir=aDir;
		if (aDir)
			aDir->Open();
		}
	return pE;
	}

TInt DirEntry::Compare(const SetMember& aMember) const
	{
	TInt k=Type()-aMember.Type();
	if (k!=0)
		return k;
	DirEntry *entry=(DirEntry *)&aMember;
	return (iDir->iIdentifier - entry->iDir->iIdentifier);
	}

SetMember* DirEntry::Copy() const
	{
	DirEntry* pE=new DirEntry(*this);
	if (pE && pE->iDir)
		pE->iDir->Open();
	return pE;
	}

DirEntry::~DirEntry()
	{
	if (iDir)
		iDir->Close();
	}

// data structure and function for qsort
struct SortableEntry 
	{
	unsigned int iOffset;
	Entry* iEntry;
	};

int compare(const void* left, const void* right)
	{
	const SortableEntry* le  = (const SortableEntry*)left;
	const SortableEntry* re = (const SortableEntry*)right;
	if (le->iEntry->IsDir())
		{
		if (!re->iEntry->IsDir())
			return -1;	// dir < file
		}
	else
		{
		if (re->iEntry->IsDir())
			return +1;	// file > dir
		}
	// Both the same type of entry, sort by name.
	// Sorting the 8-bit data using ASCII folding matches the sort order in terms of 16 bit
	// characters provided that 8-bit data is actually CESU-8 rather than UTF-8. The two
	// formats differ only when using surrogates (ie unicode values >= 0x10000). UTF-8 encodes
	// an entire 32 bit value as a sequence of up to 6 bytes whereas CESU-8 encodes UTF-16
	// values independently.
	const char* l = (const char*)le->iEntry->Name();
	const char* r = (const char*)re->iEntry->Name();
	int result, lc, rc;
	do	{
		lc = *l++;
		rc = *r++;
		if (lc >= 'A' && lc <= 'Z')
			lc += ('a' - 'A');
		if (rc >= 'A' && rc <= 'Z')
			rc += ('a' - 'A');
		result = lc - rc;
		} while (lc && result==0);
	return result;
	}


TRomDir* DirEntry::CreateRomEntries(char*& anAddr) const
	{
	TInt i;
	TInt count=iDir->Count();
	TInt subdircount=0;
	for(i=0; i<count; i++)
		{
		Entry* pE=(Entry*)&(*iDir)[i];
		if (pE->IsDir())
			{
			subdircount++;
			// Recursively build & place the subdirectories
			DirEntry *pD=(DirEntry*)pE;
			TRomDir *pR=pD->iDir->iRomDir;
			if (!pR)
				{
				pR=pD->CreateRomEntries(anAddr);
				pD->iDir->iRomDir=pR;
				}
			}
		}
	// Now place & build the TRomDir for this directory
	TInt *pS=(TInt*)anAddr;
	iDir->iRomDir=(TRomDir*)anAddr;
	*pS=0;
	anAddr+=sizeof(TInt);

	char* offsetbase=anAddr;
	SortableEntry* array=new SortableEntry [count];
	if (array==0)
		{
		Print(EError,"Failed to allocate array of SortableEntry\n");
		exit(-1);
		}

	for(i=0; i<count; i++)
		{
		Entry* pE=(Entry*)&(*iDir)[i];
		array[i].iOffset=anAddr-offsetbase;
		array[i].iEntry=pE;
		TRomEntry *pR=pE->CreateRomEntry(anAddr);
		if (pE->IsDir())
			{
			TRomDir *pD=((DirEntry*)pE)->iDir->iRomDir;
			if (pD)
				pR->iAddressLin=ActualToRomAddress(pD);
			else
				Print(EError,"Failed to fix up subdirectory address\n");
			}
		}
	*pS=TInt(anAddr-(char*)pS-sizeof(TInt));

	// Emit table of offsets for the subdirs and files in sorted order
	if (gSortedRomFs)
		{
	TInt filecount=count-subdircount;
	if (filecount>65535 || subdircount>65535)
		{
		Print(EError,"Too many files or subdirectories\n");
		exit(-1);
		}
	TUint16* ptr=(TUint16*)anAddr;
	*ptr++=(TUint16)subdircount;
	*ptr++=(TUint16)filecount;
	qsort(array,count,sizeof(SortableEntry),&compare);
	for (i=0; i<count; i++)
		{
		unsigned int scaledOffset = array[i].iOffset>>2;
		if ((array[i].iOffset & 3) != 0 || scaledOffset > 65535)
			Print(EError, "Bad offset into directory\n");
		*ptr++ = (TUint16)scaledOffset;
		}
	anAddr=(char*)ALIGN4((int)ptr);
		}
	delete [] array;
	return (TRomDir*)pS;
	}

// class Directory
TInt Directory::DirectoryCount=0;
Directory::Directory(TInt aMaxCount)
	: FiniteSet(aMaxCount), iRomDir(NULL), iAccessCount(1)
	{
	iIdentifier=Directory::DirectoryCount++;
	}

Directory* Directory::New(TInt aMaxCount, TVariantList aList)
	{
	Directory *pD=new Directory(aMaxCount);
	if (pD)
		{
		pD->iVariants=aList;
		pD=(Directory*)pD->Construct();
		}
	return pD;
	}

Directory::~Directory()
	{
	TRACE(TDIR,Print(EAlways,"Directory %08x Destruct\n",this));
	}

void Directory::Open()
	{
	iAccessCount++;
	TRACE(TDIR,Print(EAlways,"Directory %08x Open() access count=%d\n",this,iAccessCount));
	}

void Directory::Close()
	{
	TRACE(TDIR,Print(EAlways,"Directory %08x Close() access count=%d\n",this,iAccessCount));
	if (--iAccessCount==0)
		delete this;
	}

TInt Directory::Compile(const FiniteSet& aSet)
	{
	TInt i;
	TInt count=aSet.Count();
	for(i=0; i<count; i++)
		{
		Entry *pE=(Entry*)&aSet[i];
		if (iVariants<=pE->Variants())
			{
			Entry *pN=(Entry*)pE->Copy();
			if (!pN)
				return KErrNoMemory;
			pN->Restrict(iVariants);
			TInt r=Add(*pN);
			if (r==KErrOverflow)
				return r;
			}
		}
	return KErrNone;
	}

TInt Directory::Merge(const Directory& aDir)
	{
	TInt i;
	TInt r=Find(aDir,i);
	if (r==KErrNone)
		{
		((Directory*)iMembers[i])->iVariants.Union(aDir.iVariants);
		return KErrAlreadyExists;
		}
	else if (Insert(aDir,i)==KErrOverflow)
		return KErrOverflow;
	return KErrNone;
	}

// class RomFileStructure
RomFileStructure::RomFileStructure(TInt aMaxCount)
	: FiniteSet(aMaxCount)
	{}

RomFileStructure::~RomFileStructure()
	{
	}

RomFileStructure* RomFileStructure::New(TInt aMaxCount)
	{
	RomFileStructure* pS=new RomFileStructure(aMaxCount);
	if (pS)
		pS=(RomFileStructure*)pS->Construct();
	return pS;
	}

void RomFileStructure::Destroy()
	{
	}

TInt RomFileStructure::ProcessDirectory(TRomNode* aDir)
	{
	TRACE(TSCRATCH, Print(EAlways, "ProcessDirectory (%08x) %s\n",aDir,aDir->iName));
	TRACE(TDIR,Print(EAlways,"ProcessDirectory %s\nInitial:\n",aDir->iName));
	TRACE(TDIR,DebugPrint());
	TInt dirs=0;
	TInt files=0;
	aDir->CountDirectory(files,dirs);
	TInt maxSize=files+dirs*TVariantList::NumVariants;
	TRACE(TDIR,Print(EAlways,"files=%d dirs=%d maxSize=%d\n",files,dirs,maxSize));
	RomFileStructure* pS=New(maxSize);
	if (!pS)
		return KErrNoMemory;
	TInt r=aDir->ProcessDirectory(pS);
	TRACE(TDIR,Print(EAlways,"FileList:\n"));
	TRACE(TDIR,pS->DebugPrint());
	Directory* dir[TVariantList::EMaxVariants];
	TInt v;
	for(v=0; v<TVariantList::NumVariants; v++)
		{
		TVariantList vList(v);
		Directory *pD=Directory::New(files+dirs,vList);
		if (!pD)
			return KErrNoMemory;
		dir[v]=pD;
		r=pD->Compile(*pS);
		if (r!=KErrNone)
			return r;
		TRACE(TDIR,Print(EAlways,"Variant %d Directory:\n",v));
		TRACE(TDIR,pD->DebugPrint());
		}
	pS->Close();
	Directory *pX=Directory::New(TVariantList::NumVariants,TVariantList());
	if (!pX)
		return KErrNoMemory;
	for(v=0; v<TVariantList::NumVariants; v++)
		{
		if (dir[v]->Empty())
			r=KErrAlreadyExists;
		else
			r=pX->Merge(*dir[v]);
		if (r==KErrAlreadyExists)
			{
			dir[v]->Close();
			dir[v]=NULL;
			}
		else if (r!=KErrNone)
			return r;
		}
	TRACE(TDIR,Print(EAlways,"Final Directories:\n",v));
	TRACE(TDIR,pX->DebugPrint());
	TInt count=pX->Count();
	TInt i;
	for(i=0; i<count; i++)
		{
		Directory* pD=(Directory*)&(*pX)[i];
		DirEntry* pE=DirEntry::New(aDir,pD);
		if (!pE)
			return KErrNoMemory;
		r=Add(*pE);	// accumulate into the caller
		if (r==KErrOverflow)
			return r;
		}
	pX->Close();
	return KErrNone;
	}


// DEBUG

void FileEntry::DebugPrint() const
	{
	Print(EAlways,"FileEntry %08x %08x %s\n",iRomNode,iVariants.Mask(),iRomNode->iName);
	}

void DirEntry::DebugPrint() const
	{
	Print(EAlways,"DirEntry %08x %08x %08x %s\n",iRomNode,iVariants.Mask(),iDir,iRomNode->iName);
	}

void FiniteSet::DebugPrint() const
	{
	if (Count()==0)
		Print(EAlways,"FiniteSet 0\n");
	else
		{
		Print(EAlways,"FiniteSet %d {\n",Count());
		TInt i;
		for (i=0; i<Count(); i++)
			{
			iMembers[i]->DebugPrint();
			}
		Print(EAlways,"}\n");
		}
	}

void Directory::DebugPrint() const
	{
	Print(EAlways,"Directory %08x %08x\n",iVariants.Mask(),iRomDir);
	FiniteSet::DebugPrint();
	}





