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
* @internalComponent * @released
*
*/


#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <e32std.h>
#include <e32std_private.h>
#include <e32rom.h>
#include <u32std.h>
#include <e32uid.h>
#include <f32file.h>

#if defined(__MSVCDOTNET__) || defined(__TOOLS2__)
	#include <iomanip>
	#include <strstream>
#else //!__MSVCDOTNET__
	#include <iomanip.h>
#endif //__MSVCDOTNET__

#ifdef _L
#undef _L
#endif

#include "h_utl.h"
#include "r_obey.h"
#include "rofs.h"
#include "e32image.h"
#include "patchdataprocessor.h"

extern TUint checkSum(const void* aPtr);

extern ECompression gCompress;
extern TUint gCompressionMethod;
extern TInt  gCodePagingOverride;
extern TInt  gDataPagingOverride;
extern TInt  gLogLevel;
TBool gDriveImage=EFalse;	// for drive image support.


TInt TRomNode::Count=0;
TRomNode* TRomNode::TheFirstNode = NULL;
TRomNode* TRomNode::TheLastNode = NULL;

// introduced for data drive files' attribute
TUint8 TRomNode::sDefaultInitialAttr = (TUint8)KEntryAttReadOnly;

struct SortableEntry
	{
	TRofsEntry* iEntry;
	TBool iIsDir;
	TUint16 iOffset;
	};

int compare(const void* l, const void* r)
	{
	const SortableEntry* left  = (const SortableEntry*)l;
	const SortableEntry* right = (const SortableEntry*)r;
	if (left->iIsDir)
		{
		if (!right->iIsDir)
			return -1;	// dir < file
		}
	else
		{
		if (right->iIsDir)
			return +1;	// file > dir
		}

	// both the same type of entry, sort by name
	// must first convert to an 8 bit string
	// array and NULL terminate it.
	char temp1[500];
	char temp2[500];


TInt i=0;
	for (i = 0; i < left->iEntry->iNameLength; i++)
		{
		temp1[i]=(char) left->iEntry->iName[i];
		}
	temp1[i]=0;

	for (i = 0; i < right->iEntry->iNameLength; i++)
		{
		temp2[i]=(char) right->iEntry->iName[i];
		}
	temp2[i]=0;

	return stricmp((const char*)&temp1[0], (const char*)&temp2[0]);
	}

TRomNode::TRomNode(TText* aName, TRomBuilderEntry* aEntry)
//
// Constructor
//
	:
	iNextNode(NULL),
	iParent(NULL), iSibling(0), iChild(0), iNextNodeForSameFile(0), 
	iTotalDirectoryBlockSize(0),
	iTotalFileBlockSize(0),
	iImagePosition(0),
	iFileBlockPosition(0),
	iAtt(sDefaultInitialAttr),
	iAttExtra(0xFF),
	iHidden(EFalse),
	iEntry(aEntry),
	iFileStartOffset(0), 
	iSize(0), 
	iOverride(0),
	iFileUpdate(EFalse),
    iAlias(false)
	{
	iName = (TText*)NormaliseFileName((const char*)aName);
	iIdentifier=TRomNode::Count++;

	// Add this node to the flat linked list
	if( !TheFirstNode )
		{
		TheFirstNode = this;
		}
	else
		{
		TheLastNode->iNextNode = this;
		}
	TheLastNode = this;

	if (iEntry)
		{
		iEntry->SetRomNode(this);
		}
	else
		{
		iAtt = (TUint8)KEntryAttDir;
		}
	}

TRomNode::~TRomNode()
	{
	if (iEntry && !iAlias)
        {
		delete iEntry;
        }
    iEntry = 0;
	if(iName)
		free(iName);
    iName = 0;
	}

TRomNode *TRomNode::FindInDirectory(TText *aName)
//
// Check if the TRomNode for aName exists in aDir, and if so, return it.
//
	{

	TRomNode *entry=iChild; // first subdirectory or file
	while (entry)
		{
		if ((stricmp((const char *)aName, (const char *)entry->iName))==0) 
			return entry;
		else
			entry=entry->iSibling;
		}
	return 0;
	}



TInt indend = 0;

void indendStructure(TInt i)
       {
	while(i > 0)
	   {
	     cout << "    ";
	     i--;
	   }
       };  

// displays the directory structure
void TRomNode::DisplayStructure(ostream* aOut)
	{
	  indendStructure(indend);
      *aOut  << iName << "\n";
	  if (iChild)
	    {
	      indend++; 
	      iChild->DisplayStructure(aOut);
	      indend--;
	    }
	  if (iSibling)
	    iSibling->DisplayStructure(aOut);
	}


void TRomNode::deleteTheFirstNode()
{

	TheFirstNode = NULL;
}


void TRomNode::InitializeCount()
{
	Count = 0;
}
void TRomNode::displayFlatList()
{
	TRomNode* current =	TheFirstNode;
	TInt i = 0;
	while(current)
	{
		i++;
		cout <<  "\n" << i <<": " << current->iName << endl;
		current = current->NextNode();
	}

	}



void TRomNode::AddFile(TRomNode* aChild)
	{
	if (iEntry)
		{
		Print(EError, "Adding subdirectory to a file!!!\n");
		return;
		}
	Add(aChild);
	}

TRomNode* TRomNode::NewSubDir(TText *aName)
	{
	if (iEntry)
		{
		Print(EError, "Adding subdirectory to a file!!!\n");
		return 0;
		}

	TRomNode* node = new TRomNode(aName );
	if (node==0)
		{
		Print(EError, "TRomNode::NewNode: Out of memory\n");
		return 0;
		}
	node->iParent = this;
	Add(node);
	return node;
	}

void TRomNode::Add(TRomNode* aChild)
	{
	if (iChild) // this node is a non-empty directory
		{
		TRomNode* dir = iChild; // find where to link in the new node
		while (dir->iSibling)
			dir = dir->iSibling;
		dir->iSibling = aChild;
		}
	else
		iChild = aChild; // else just set it up as the child of the dir
	aChild->iSibling = 0;
	aChild->iParent = this;
	}

TInt TRomNode::SetAttExtra(TText *anAttWord, TRomBuilderEntry* aFile, enum EKeyword aKeyword)
//
// Set the file extra attribute byte from the letters passed
// Note: The iAttExtra bits are inverted. '0' represent enabled
//
	{
	iAttExtra=0xFF;
	if (anAttWord==0 || anAttWord[0]=='\0')
		return Print(EError, "Missing argument for keyword 'exattrib'.\n");
	for (TText *letter=anAttWord;*letter!=0;letter++)
		{
		switch (*letter)
			{
		case 'u':
			iAttExtra |= (KEntryAttUnique >> 23);	// '1' represents disabled in iAttExtra
			break;
		case 'U':
			iAttExtra &= ~(KEntryAttUnique >> 23);	// '0' represent enabled in iAttExtra
			break;
		default:
			return Print(EError, "Unrecognised exattrib - '%c'.\n", *letter);
			break;
			}
		}

	if((~iAttExtra & (KEntryAttUnique >> 23))!=0)	// If the unique file attribute is set
		{
		if(aKeyword==EKeywordFile || aKeyword==EKeywordData)	// If the Keyword is File or Data
			{
				if(strlen(aFile->iFileName) > (KMaxFileName-KRofsMangleNameLength)) // check whether we have enough space to add the mangle tage
					return Print(EError, "Lengthy filename with unique attribute to name mangle.\n");
			}
		else	// for all other keywords
			return Print(EError, "exattrib field not allowed for entries except data and file.\n");
		}
	return KErrNone;
	}


TInt TRomNode::SetAtt(TText *anAttWord)
//
// Set the file attribute byte from the letters passed
//
	{
	iAtt=0;
	if (anAttWord==0 || anAttWord[0]=='\0')
		return Print(EError, "Missing argument for keyword 'attrib'.\n");
	for (TText *letter=anAttWord;*letter!=0;letter++)
		{
		switch (*letter)
			{
		case 'R':
		case 'w':
			iAtt |= KEntryAttReadOnly;
			break;
		case 'r':
		case 'W':
			iAtt &= ~KEntryAttReadOnly;
			break;
		case 'H':
			iAtt |= KEntryAttHidden;
			break;
		case 'h':
			iAtt &= ~KEntryAttHidden;
			break;
		case 'S':
			iAtt |= KEntryAttSystem;
			break;
		case 's':
			iAtt &= ~KEntryAttSystem;
			break;
		default:
			return Print(EError, "Unrecognised attrib - '%c'.\n", *letter);
			break;
			}
		}
	return KErrNone;
	}



TInt TRomNode::CalculateEntrySize() const
	// Calculates the amount of ROM space required to hold
	// this entry. The return is the actual size of the TRofsEntry
	// structure, not rounded up
	{
	TInt requiredSizeBytes = KRofsEntryHeaderSize +	NameLengthUnicode();
	return requiredSizeBytes;
	}

TInt TRomNode::CalculateDirectoryEntrySize( TInt& aDirectoryBlockSize,
										    TInt& aFileBlockSize )
	// Calculates the total size of the TRofsDir structure required
	// for this directory and the size of the files block. Traverses all the
	// children adding their entry sizes. The result is not rounded up.
	//
	// On return aDirectoryBlockSize is the number of bytes required for the
	//	main directory structure. aFileBlockSize is the number of bytes
	//	required to hold the list of files.
	//
	// Returns KErrNone on success
	{

	TInt offsetBytes=0;
	TInt padBytes=0;
	if( 0 == iTotalDirectoryBlockSize )
		{
		// need to calculate by walking children	
		if( !iChild )
			{
			return Print(EError, "TRomNode structure corrupt\n");
			}

		TInt dirBlockSize = KRofsDirHeaderSize;
		TInt fileBlockSize = 0;
		TInt fileCount=0;
		TInt dirCount=0;

		TRomNode* node = iChild;
		while (node)
			{
			TInt entrySize = node->CalculateEntrySize();
			if( node->IsDirectory() )
				{
				dirBlockSize += (4 - dirBlockSize) & 3;	// pad to next word boundary
				dirBlockSize += entrySize;
				dirCount++;
				}
			else
				{
				fileBlockSize += (4 - fileBlockSize) & 3;	// pad to next word boundary
				fileBlockSize += entrySize;
				fileCount++;
				}
			node = node->iSibling;
			}
		
		offsetBytes = ((fileCount + dirCount) * 2) + 4; //the +4 are the two offset counts,
		padBytes = offsetBytes % 4;

		iTotalDirectoryBlockSize = dirBlockSize;
		iTotalFileBlockSize = fileBlockSize;
		}

	aDirectoryBlockSize = iTotalDirectoryBlockSize + offsetBytes + padBytes;
	aFileBlockSize = iTotalFileBlockSize;
	return KErrNone;
	}

/**
Place the files and it's attributes (incase of executables)
Called for both rofs and datadrive creation.
 
@param aDest   - Destination buffer.
@param aOffset - offset value, used for rofs only.
@param aMaxSize- Maximum size required for rofs.
  
@return - Returns the number of bytes placed or a -ve error code.
*/ 
TInt TRomNode::PlaceFile( TUint8* &aDest, TUint aOffset, TUint aMaxSize, CBytePair *aBPE )
	//
	// Place the file into the ROM image, making any necessary conversions
	// along the way.
	//
	// Returns the number of bytes placed or a -ve error code.
	{

	TInt size=0;
	
	// file hasn't been placed for drive image. 
	if(gDriveImage)
	{
		size = iEntry->PlaceFile(aDest,aMaxSize,aBPE);
		iSize = size;
	}
	else
	{
		if (iEntry->iHidden)
			iFileStartOffset = KFileHidden;
		else
		{
                    if (iEntry->iFileOffset==0)
                    {
                        // file hasn't been placed
                        size = iEntry->PlaceFile( aDest, aMaxSize, aBPE );
                        if (size>=0)
                            iEntry->iFileOffset = aOffset;
                    }
                    else {
                        iFileStartOffset = (TInt)iEntry;
                    }
		}
	}

	// Deal with any override attributes
	// (omit paging overrides as these are dealt with in TRomBuilderEntry::PlaceFile
	//  and may also be legitimately specified for non-executable files in ROM)
	if( iOverride&~(KOverrideCodeUnpaged|KOverrideCodePaged|KOverrideDataUnpaged|KOverrideDataPaged) )
		{
		E32ImageHeaderV* hdr = (E32ImageHeaderV*)aDest;

		TUint hdrfmt = hdr->HeaderFormat();
		if (hdrfmt != KImageHdrFmt_V)
			{
			Print(EError,"%s: Can't load old format binary\n", iEntry->iFileName);
			return KErrNotSupported;
			}
		
		// First need to check that it's a real image header
		if( (TUint)size > sizeof(E32ImageHeader) )
			{
			if( ((TInt)hdr->iSignature == 0x434f5045u) && ((TInt)hdr->iUid1 == KExecutableImageUidValue || (TInt)hdr->iUid1 == KDynamicLibraryUidValue) )
				{
				// Should check the CRC as well here...
				// Something for later

				// Ok, it looks like an image header
				if( iOverride & KOverrideStack )
					{
					hdr->iStackSize = iStackSize;
					}
				if( iOverride & KOverrideHeapMin )
					{
					hdr->iHeapSizeMin = iHeapSizeMin;
					}
				if( iOverride & KOverrideHeapMax )
					{
					hdr->iHeapSizeMax = iHeapSizeMax;
					}
				if( iOverride & KOverrideFixed )
					{
					if( hdr->iFlags & KImageDll )
						{
						Print(EError,"%s: Can't used FIXED keyword on a DLL\n", iEntry->iFileName);
						return KErrNotSupported;
						}
					hdr->iFlags |= KImageFixedAddressExe;
					}
				if( iOverride & (KOverrideUid1|KOverrideUid2|KOverrideUid3))
					{
					if (iOverride & KOverrideUid1)
						{
						hdr->iUid1 = iUid1;
						}
					if (iOverride & KOverrideUid2)
						{
						hdr->iUid2 = iUid2;
						}
					if (iOverride & KOverrideUid3)
						{
						hdr->iUid3 = iUid3;
						}
					// Need to re-checksum the UIDs
					TUidType ut(TUidType(TUid::Uid(hdr->iUid1), TUid::Uid(hdr->iUid2), TUid::Uid(hdr->iUid3)));
					hdr->iUidChecksum =  (checkSum(((TUint8*)&ut)+1)<<16)|checkSum(&ut);
					}
				if( iOverride & KOverridePriority )
					{
					hdr->iProcessPriority = (TUint16)iPriority;
					}
				if( iOverride & KOverrideCapability )
					{
					hdr->iS.iCaps = iCapability;
					}

				// Need to re-CRC the header
				hdr->iHeaderCrc = KImageCrcInitialiser;
				TUint32 crc = 0;
				TInt hdrsz = hdr->TotalSize();
				HMem::Crc32(crc, hdr, hdrsz);
				hdr->iHeaderCrc = crc;
				}
			}
		}

	return size;
	}

TInt TRomNode::CountFileAndDir(TInt& aFileCount, TInt& aDirCount)
	{
	//
	// Count the number of file and directory entries for this node
	//
	TRomNode* node = iChild;

	aFileCount=0;
	aDirCount=0;
	while( node )
		{
		if( node->IsFile() )
			{
			aFileCount++;
			}
		else
			{
			aDirCount++;
			}

		node = node->iSibling;
		}
	return KErrNone;
	}

TInt TRomNode::Place( TUint8* aDestBase )
	//
	// Writes this directory entry out to the image.
	// The image starts at aDestBase.
	// The position in the image must already have been set with SetImagePosition()
	// and SetFileBlockPosition().
	// Returns KErrNone on success
	//
	{
	TUint8* dirBlockBase = aDestBase + iImagePosition;
	TUint8* fileBlockBase = aDestBase + iFileBlockPosition;

	TRofsDir* pDir = (TRofsDir*)dirBlockBase;
	pDir->iFirstEntryOffset = KRofsDirFirstEntryOffset;
	pDir->iFileBlockAddress = iFileBlockPosition;
	pDir->iFileBlockSize = iTotalFileBlockSize;
	pDir->iStructSize = (TUint16)iTotalDirectoryBlockSize;

	TRofsEntry* pDirEntry = &(pDir->iSubDir);
	TRofsEntry* pFileEntry = (TRofsEntry*)fileBlockBase;

	TInt dirCount;
	TInt fileCount;
	TInt index = 0;
	CountFileAndDir(fileCount, dirCount);

	SortableEntry* array = new SortableEntry[fileCount + dirCount];
	TRomNode* node = iChild;

	while( node )
		{
		TRofsEntry* entry;

		if( node->IsFile() )
			{
			entry = pFileEntry;

			//Offset in 32bit words from start of file block
			array[index].iOffset = (TUint16) ((((TUint8*) entry) - fileBlockBase) >> 2);
			array[index].iIsDir = EFalse;
			}
		else
			{
			entry = pDirEntry;

			//Offset in 32bit words from start of directory block
			array[index].iOffset = (TUint16) ((((TUint8*) entry) - dirBlockBase) >> 2);
			array[index].iIsDir = ETrue;
			}
		array[index].iEntry = entry;
		index++;

		entry->iNameOffset = KRofsEntryNameOffset;
		entry->iAtt = node->iAtt;
		entry->iAttExtra = node->iAttExtra;

		TInt entryLen = KRofsEntryHeaderSize;
		entryLen += node->NameCpy( (char*)&entry->iName, entry->iNameLength );
		entryLen += (4 - entryLen) & 3;	// round up to nearest word
		entry->iStructSize = (TUint16)entryLen;


		if( node->IsFile() )
			{
			// node is a file, entry points to the file
			// write an entry out into the file block
			pFileEntry->iFileAddress = node->iFileStartOffset;
			node->iAtt &= ~KEntryAttDir;
			pFileEntry->iFileSize = node->iEntry->RealFileSize();
			memcpy(&pFileEntry->iUids[0], &node->iEntry->iUids[0], sizeof(pFileEntry->iUids));
			pFileEntry = (TRofsEntry*)( (TUint8*)pFileEntry + entryLen );
			}
		else
			{
			// node is a subdirectory, entry points to directory
			pDirEntry->iFileAddress = node->iImagePosition;
			node->iAtt |= KEntryAttDir;
			
			// the size is just the size of the directory block
			pDirEntry->iFileSize = node->iTotalDirectoryBlockSize;
			pDirEntry = (TRofsEntry*)( (TUint8*)pDirEntry + entryLen );
			}

		node = node->iSibling;
		}

	qsort(array,fileCount + dirCount,sizeof(SortableEntry),&compare);

	//Now copy the contents of sorted array to the image
	TUint16* currentPtr = (TUint16*) (dirBlockBase + iTotalDirectoryBlockSize);

	*currentPtr=(TUint16)dirCount;
	currentPtr++;
	*currentPtr=(TUint16)fileCount;
	currentPtr++;

	for (index = 0; index < (fileCount + dirCount); index++)
		{
		*currentPtr = array[index].iOffset;
		currentPtr++;
		}
	delete[] array;
	return KErrNone;
	}



void TRomNode::Remove(TRomNode* aChild)
	{
	if (iChild==0)
		{
		Print(EError, "Removing file from a file!!!\n");
		return;
		}
	if (iChild==aChild) // first child in this directory
		{
		iChild = aChild->iSibling;
		aChild->iSibling = 0;
		if(iChild==0)
			{
				iParent->Remove(this);
				TRomNode * current = TheFirstNode;
				TRomNode * prev = current;
				while(current != this)
					{
						prev = current;
						current = current->NextNode();
					}
				prev->SetNextNode(current->NextNode());
				delete this;
			}
		return;
		}
	TRomNode* prev = iChild;
	while (prev->iSibling && prev->iSibling != aChild)
		prev = prev->iSibling;
	if (prev==0)
		{
		Print(EError, "Attempting to remove file not in this directory!!!\n");
		return;
		}
	prev->iSibling = aChild->iSibling;
	aChild->iSibling = 0;
	}

void TRomNode::CountDirectory(TInt& aFileCount, TInt& aDirCount)
	{
	TRomNode *current=iChild;
	while(current)
		{
		if (current->iChild)
			aDirCount++;
		else
 			aFileCount++;
	current=current->iSibling;
		}
	}

 void TRomNode::Destroy()
//
// Follow the TRomNode tree, destroying it
//
	{

 	TRomNode *current = this; // root has no siblings
	while (current)
		{
		if (current->iChild)
			current->iChild->Destroy();
		TRomNode* prev=current;
		current=current->iSibling;
		delete prev;
        prev = 0;
		}
 	}




TInt TRomNode::NameCpy(char* aDest, TUint8& aUnicodeLength )
//
// Safely copy a file name in the rom entry
// Returns the number of bytes used. Write the length in unicode characters
// into aUnicodeLength.
//
	{

	if ((aDest==NULL) || (iName==NULL))
		return 0;
	const unsigned char* pSourceByte = (const unsigned char*)iName;
	unsigned char* pTargetByte=(unsigned char*)aDest;
	for (;;)
		{
		const TUint sourceByte=*pSourceByte;
		if (sourceByte==0)
			{
			break;
			}
		if ((sourceByte&0x80)==0)
			{
			*pTargetByte=(unsigned char)sourceByte;
			++pTargetByte;
			*pTargetByte=0;
			++pTargetByte;
			++pSourceByte;
			}
		else if ((sourceByte&0xe0)==0xc0)
			{
			++pSourceByte;
			const TUint secondSourceByte=*pSourceByte;
			if ((secondSourceByte&0xc0)!=0x80)
				{
				Print(EError, "Bad UTF-8 '%s'", iName);
				exit(671);
				}
			*pTargetByte=(unsigned char)((secondSourceByte&0x3f)|((sourceByte&0x03)<<6));
			++pTargetByte;
			*pTargetByte=(unsigned char)((sourceByte>>2)&0x07);
			++pTargetByte;
			++pSourceByte;
			}
		else if ((sourceByte&0xf0)==0xe0)
			{
			++pSourceByte;
			const TUint secondSourceByte=*pSourceByte;
			if ((secondSourceByte&0xc0)!=0x80)
				{
				Print(EError, "Bad UTF-8 '%s'", iName);
				exit(672);
				}
			++pSourceByte;
			const TUint thirdSourceByte=*pSourceByte;
			if ((thirdSourceByte&0xc0)!=0x80)
				{
				Print(EError, "Bad UTF-8 '%s'", iName);
				exit(673);
				}
			*pTargetByte=(unsigned char)((thirdSourceByte&0x3f)|((secondSourceByte&0x03)<<6));
			++pTargetByte;
			*pTargetByte=(unsigned char)(((secondSourceByte>>2)&0x0f)|((sourceByte&0x0f)<<4));
			++pTargetByte;
			++pSourceByte;
			}
		else
			{
			Print(EError, "Bad UTF-8 '%s'", iName);
			exit(674);
			}
		}
	const TInt numberOfBytesInTarget=(pTargetByte-(unsigned char*)aDest); // this number excludes the trailing null-terminator
	if (numberOfBytesInTarget%2!=0)
		{
		Print(EError, "Internal error");
		exit(675);
		}
	aUnicodeLength = (TUint8)(numberOfBytesInTarget/2); // returns the length of aDest (in UTF-16 characters for Unicode, not bytes)
	return numberOfBytesInTarget;
	}


TInt TRomNode::NameLengthUnicode() const
//
// Find the unicode lenght of the name
//
	{

	if (iName==NULL)
		return 0;

	const unsigned char* pSourceByte = (const unsigned char*)iName;
	TInt len = 0;
	for (;;)
		{
		const TUint sourceByte=*pSourceByte;
		if (sourceByte==0)
			{
			break;
			}
		if ((sourceByte&0x80)==0)
			{
			len += 2;
			++pSourceByte;
			}
		else if ((sourceByte&0xe0)==0xc0)
			{
			++pSourceByte;
			const TUint secondSourceByte=*pSourceByte;
			if ((secondSourceByte&0xc0)!=0x80)
				{
				Print(EError, "Bad UTF-8 '%s'", iName);
				exit(671);
				}
			len += 2;
			++pSourceByte;
			}
		else if ((sourceByte&0xf0)==0xe0)
			{
			++pSourceByte;
			const TUint secondSourceByte=*pSourceByte;
			if ((secondSourceByte&0xc0)!=0x80)
				{
				Print(EError, "Bad UTF-8 '%s'", iName);
				exit(672);
				}
			++pSourceByte;
			const TUint thirdSourceByte=*pSourceByte;
			if ((thirdSourceByte&0xc0)!=0x80)
				{
				Print(EError, "Bad UTF-8 '%s'", iName);
				exit(673);
				}
			len += 2;
			++pSourceByte;
			}
		else
			{
			Print(EError, "Bad UTF-8 '%s'", iName);
			exit(674);
			}
		}
	return len;
	}


void TRomNode::AddNodeForSameFile(TRomNode* aPreviousNode, TRomBuilderEntry* aFile)
	{
	// sanity checking
	if (iNextNodeForSameFile != 0 || iEntry != aFile || (aPreviousNode && aPreviousNode->iEntry != iEntry))
		{
		Print(EError, "Adding Node for same file: TRomNode structure corrupted\n");
		exit(666);
		}
	iNextNodeForSameFile = aPreviousNode;
	}





//**************************************
// TRomBuilderEntry
//**************************************



TRomBuilderEntry::TRomBuilderEntry(const char *aFileName,TText *aName)
//
// Constructor
//
:iFirstDllDataEntry(0),	iName(0),iFileName(0),iNext(0), iNextInArea(0),
iExecutable(EFalse), iFileOffset(EFalse), iCompressEnabled(0),
iHidden(0), iRomNode(0), iRealFileSize(0)		 
{
	if (aFileName)
   		iFileName = NormaliseFileName(aFileName);
	if (aName)
		iName = (TText*)NormaliseFileName((const char*)aName);
	memset(iUids,0 ,sizeof(TCheckedUid));
}
	
TRomBuilderEntry::~TRomBuilderEntry()
//
// Destructor
//
	{
	if(iFileName)
	{
	free(iFileName);
	}
	iFileName = 0;
	if(iName)
	{
	free(iName);
	}
	}

void TRomBuilderEntry::SetRomNode(TRomNode* aNode)
	{
	aNode->AddNodeForSameFile(iRomNode, this);
	iRomNode = aNode;
	}


TInt isNumber(TText *aString)
	{
	if (aString==NULL)
		return 0;
	if (strlen((char *)aString)==0)
		return 0;
	return isdigit(aString[0]);
	}

TInt getNumber(TText *aStr)
	{
	TUint a;
	#ifdef __TOOLS2__
	istringstream val((char *)aStr);
	#else
	istrstream val((char *)aStr,strlen((char *)aStr));
	#endif

#if defined(__MSVCDOTNET__) || defined(__TOOLS2__)
	val >> setbase(0);
#endif //__MSVCDOTNET__

	val >> a;
	return a;
	}


TInt TRomBuilderEntry::PlaceFile( TUint8* &aDest,TUint aMaxSize, CBytePair *aBPE )
	//
	// Place the file in ROM. Since we don't support compression yet all
	// we have to do is read the file into memory
	// compress it, if it isn't already compressed.
	//
	// Returns the number of bytes used, or -ve error code
	{
	TUint compression = 0;
	TBool executable = iExecutable;
	Print(ELog,"Reading file %s to image\n", iFileName );
	TUint32 size=HFile::GetLength((TText*)iFileName);
	if (size==0)
		Print(EWarning, "File %s does not exist or is 0 bytes in length.\n",iFileName);
        if (aDest == NULL) {
            aMaxSize = size*2;
            aMaxSize = (aMaxSize>0) ? aMaxSize : 2;
            aDest = new TUint8[aMaxSize];
        }

	if (executable)
		{
		// indicate if the image will overflow without compression
	TBool overflow;
			if(size>aMaxSize)
			overflow = ETrue;
		else
			overflow = EFalse;

		// try to compress this executable
		E32ImageFile f(aBPE);
		TInt r = f.Open(iFileName);
		// is it really a valid E32ImageFile?
		if (r != KErrNone)
			{
			Print(EWarning, "File '%s' is not a valid executable.  Placing file as data.\n", iFileName);
			executable = EFalse;
			}
		else
			{

			if(iRomNode->iOverride & KOverrideDllData)
			{
				DllDataEntry *aDllEntry = iRomNode->iEntry->GetFirstDllDataEntry();
				TLinAddr* aExportTbl;
				void *aLocation;
				TUint aDataAddr;
				char *aCodeSeg, *aDataSeg;

				aExportTbl = (TLinAddr*)((char*)f.iData + f.iOrigHdr->iExportDirOffset);

				// const data symbol may belong in the Code section. If the address lies within the Code or data section limits, 
				// get the corresponding location and update it.While considering the Data section limits
				// don't include the Bss section, as it doesn't exist as yet in the image.
				while( aDllEntry ){
					if(aDllEntry->iOrdinal != (TUint32)-1){
						if(aDllEntry->iOrdinal < 1 || aDllEntry->iOrdinal > (TUint)f.iOrigHdr->iExportDirCount){
							Print(EWarning, "Invalid ordinal %d specified for DLL %s\n", aDllEntry->iOrdinal, iRomNode->iName);
							aDllEntry = aDllEntry->NextDllDataEntry();
							continue;
						}
					
				//	Get the address of the data field via the export table.
					aDataAddr = (TInt32)(aExportTbl[aDllEntry->iOrdinal - 1] + aDllEntry->iOffset);
					if( aDataAddr >= f.iOrigHdr->iCodeBase && aDataAddr <= (f.iOrigHdr->iCodeBase + f.iOrigHdr->iCodeSize)){
						aCodeSeg = (char*)(f.iData + f.iOrigHdr->iCodeOffset);
						aLocation = (void*)(aCodeSeg + aDataAddr - f.iOrigHdr->iCodeBase );
						memcpy(aLocation, &aDllEntry->iNewValue, aDllEntry->iSize);
					}
					else if(aDataAddr >= f.iOrigHdr->iDataBase && aDataAddr <= (f.iOrigHdr->iDataBase + f.iOrigHdr->iDataSize)){
						aDataSeg = (char*)(f.iData + f.iOrigHdr->iDataOffset);
						aLocation = (void*)(aDataSeg + aDataAddr - f.iOrigHdr->iDataBase );
						memcpy(aLocation, &aDllEntry->iNewValue, aDllEntry->iSize);
					}
					else
					{
						Print(EWarning, "Patchdata failed as address pointed by ordinal %d of DLL %s doesn't lie within Code or Data section limits\n", aDllEntry->iOrdinal, iRomNode->iName);
					}
					}
					else if(aDllEntry->iDataAddress != (TLinAddr)-1){
						aDataAddr = aDllEntry->iDataAddress + aDllEntry->iOffset;
					if( aDataAddr >= f.iOrigHdr->iCodeBase && aDataAddr <= (f.iOrigHdr->iCodeBase + f.iOrigHdr->iCodeSize)){
						aCodeSeg = (char*)(f.iData + f.iOrigHdr->iCodeOffset);
						aLocation = (void*)(aCodeSeg + aDataAddr - f.iOrigHdr->iCodeBase );
						memcpy(aLocation, &aDllEntry->iNewValue, aDllEntry->iSize);
					}
					else if(aDataAddr >= f.iOrigHdr->iDataBase && aDataAddr <= (f.iOrigHdr->iDataBase + f.iOrigHdr->iDataSize)){
						aDataSeg = (char*)(f.iData + f.iOrigHdr->iDataOffset);
						aLocation = (void*)(aDataSeg + aDataAddr - f.iOrigHdr->iDataBase );
						memcpy(aLocation, &aDllEntry->iNewValue, aDllEntry->iSize);
					}
					else
					{
						Print(EWarning, "Patchdata failed as address 0x%x of DLL %s doesn't lie within Code or Data section limits\n", aDllEntry->iOrdinal, iRomNode->iName);
					}
					}
					aDllEntry = aDllEntry->NextDllDataEntry();
					}
			}

			compression = f.iHdr->CompressionType();
			Print(ELog,"Original file:'%s' is compressed by method:%08x\n", iFileName, compression);


			TUint32 oldFileComp;
			TUint32 newFileComp;

			if(compression)
			{
				// The E32 image in release directory is compressed
				oldFileComp = compression;
			}
			else
			{
				// The E32 image in release directory is uncompressed
				oldFileComp = 0;
			}

			if( iCompressEnabled != ECompressionUnknown)
			{
				// The new state would be as stated in obey file, i.e. 
				// filecompress or fileuncompress
				newFileComp = gCompressionMethod;
			}
			else if (gCompress != ECompressionUnknown)
			{
				// The new state would be as stated set globally
				newFileComp = gCompressionMethod;
			}
			else
			{
				// When not known if compression is to be applied or not,
				// set it same as that of the E32 image in release directory
				newFileComp = oldFileComp;
			}

			if(!gDriveImage)
			{
				// overide paging flags...
				E32ImageHeaderV* h=f.iHdr;
				if (iRomNode->iOverride & KOverrideCodePaged)
					{
					h->iFlags &= ~KImageCodeUnpaged;
					h->iFlags |= KImageCodePaged;
					}
				if (iRomNode->iOverride & KOverrideCodeUnpaged)
					{
					h->iFlags |= KImageCodeUnpaged;
					h->iFlags &= ~KImageCodePaged;
					}
				if (iRomNode->iOverride & KOverrideDataPaged)
					{
					h->iFlags &= ~KImageDataUnpaged;
					h->iFlags |= KImageDataPaged;
					}
				if (iRomNode->iOverride & KOverrideDataUnpaged)
					{
					h->iFlags |= KImageDataUnpaged;
					h->iFlags &= ~KImageDataPaged;
					}

				// apply global paging override...
				switch(gCodePagingOverride)
					{
				case EKernelConfigPagingPolicyNoPaging:
					h->iFlags |= KImageCodeUnpaged;
					h->iFlags &= ~KImageCodePaged;
					break;
				case EKernelConfigPagingPolicyAlwaysPage:
					h->iFlags |= KImageCodePaged;
					h->iFlags &= ~KImageCodeUnpaged;
					break;
				case EKernelConfigPagingPolicyDefaultUnpaged:
					if(!(h->iFlags&(KImageCodeUnpaged|KImageCodePaged)))
						h->iFlags |= KImageCodeUnpaged;
					break;
				case EKernelConfigPagingPolicyDefaultPaged:
					if(!(h->iFlags&(KImageCodeUnpaged|KImageCodePaged)))
						h->iFlags |= KImageCodePaged;
					break;
					}
				switch(gDataPagingOverride)
					{
				case EKernelConfigPagingPolicyNoPaging:
					h->iFlags |= KImageDataUnpaged;
					h->iFlags &= ~KImageDataPaged;
					break;
				case EKernelConfigPagingPolicyAlwaysPage:
					h->iFlags |= KImageDataPaged;
					h->iFlags &= ~KImageDataUnpaged;
					break;
				case EKernelConfigPagingPolicyDefaultUnpaged:
					if(!(h->iFlags&(KImageDataUnpaged|KImageDataPaged)))
						h->iFlags |= KImageDataUnpaged;
					break;
				case EKernelConfigPagingPolicyDefaultPaged:
					if(!(h->iFlags&(KImageDataUnpaged|KImageDataPaged)))
						h->iFlags |= KImageDataPaged;
					break;
					}
				f.UpdateHeaderCrc();

				// make sure paged code has correct compression type...
				if(h->iFlags&KImageCodePaged)
					{
					if(newFileComp!=0)
						newFileComp = KUidCompressionBytePair;
					}
			}

			if ( oldFileComp != newFileComp )
				{
				
				if( newFileComp == 0)
					{
					Print(ELog,"Decompressing executable '%s'\n", iFileName);
					f.iHdr->iCompressionType = 0;
					}
				else
					{
					Print(ELog,"Compressing executable '%s' with method:%08x\n", iFileName, newFileComp);
					f.iHdr->iCompressionType = newFileComp;
					}
				f.UpdateHeaderCrc();
				if (overflow)
					{
					char * buffer = new char [size];
					// need to check if the compressed file will fit in the image
   					#if defined(__LINUX__)
 					ostrstream os((char*)aDest, aMaxSize, (ios::openmode)(ios::out+ios::binary));
					#elif defined(__TOOLS2__) && defined (_STLP_THREADS)
  					ostrstream os((char*)buffer, size,(ios::out+ios::binary));
  					#elif defined( __TOOLS2__)
   					ostrstream os((char*)buffer, size,(ios::out+ios::binary));
					#else
					ostrstream os( (char*)buffer, size, (ios::out+ios::binary));
					#endif
					os << f;
					TUint compressedSize = os.pcount();
					if (compressedSize <= aMaxSize)
						overflow = EFalse;	
					delete[] buffer;
					}
				}
			if (overflow)
				{
				Print(EError, "Can't fit '%s' in image\n", iFileName);
				Print(EError, "Overflowed by approximately 0x%x bytes.\n", size - aMaxSize);
				exit(667);
				}
  			#if defined(__TOOLS2__) && defined (_STLP_THREADS)
  			ostrstream os((char*)aDest, aMaxSize,(ios::out+ios::binary));
  			#elif __TOOLS2__
			ostrstream os((char*)aDest, aMaxSize, (std::_Ios_Openmode)(ios::out+ios::binary));
			#else
			ostrstream os((char*)aDest, aMaxSize, (ios::out+ios::binary));
			#endif
			os << f;
			size = os.pcount();
			compression = f.iHdr->CompressionType();
			memcpy(&iUids[0], aDest, sizeof(iUids));
			}
		}
	if (!executable)
		{
		if ( size > aMaxSize )
			{
			Print(EError, "Can't fit '%s' in image\n", iFileName);
			Print(EError, "Overflowed by approximately 0x%x bytes.\n", size - aMaxSize);
			exit(667);
			}
		size = HFile::Read((TText*)iFileName, (TAny *)aDest);
                TUint32 Uidslen = (size > sizeof(iUids)) ? sizeof(iUids) : size;
                memcpy(&iUids[0], aDest, Uidslen);
		}

	if (compression)
		Print(ELog,"Compressed executable File '%s' size: %08x, mode:%08x\n", iFileName, size, compression);
	else if (iExecutable)
		Print(ELog,"Executable File '%s' size: %08x\n", iFileName, size);
	else
		Print(ELog,"File '%s' size: %08x\n", iFileName, size);
	iRealFileSize = size;	// required later when directory is written
	
	return size;
	}


TRomNode* TRomNode::CopyDirectory(TRomNode*& aLastExecutable)
	{

	if (iHidden && iChild==0)
		{
		// Hidden file - do not copy (as it wouldn't be visible in the ROM filestructure)
		if (iSibling)
			return iSibling->CopyDirectory(aLastExecutable);
		else
			return 0;
		}

	TRomNode* copy = new TRomNode(iName);
	if(aLastExecutable==0)
		aLastExecutable = copy;		// this must be the root of the structure
	// recursively copy the sub-structures
	if (iChild)
		copy->iChild = iChild->CopyDirectory(aLastExecutable);
	if (iSibling)
		copy->iSibling = iSibling->CopyDirectory(aLastExecutable);
	copy->Clone(this);
	return copy;
	}




void TRomNode::Clone(TRomNode* aOriginal)
	{
	iAtt = aOriginal->iAtt;
	iAttExtra = aOriginal->iAttExtra;
	iEntry = aOriginal->iEntry;
	iHidden = aOriginal->iHidden;
	iFileStartOffset = aOriginal->iFileStartOffset;
	iSize = aOriginal->iSize;
	iParent = aOriginal->iParent;
    iAlias = aOriginal->iAlias;
	}


void TRomNode::Alias(TRomNode* aNode)
	{
	  // sanity checking
	if (aNode->iEntry == 0) 
	{
		Print(EError, "Aliasing: TRomNode structure corrupted\n");
		exit(666);
	}
	Clone(aNode);
	iEntry = aNode->iEntry;
	if (iEntry)
		{
		iEntry->SetRomNode(this);
		}
    iAlias = true;
	}


void TRomNode::Rename(TRomNode *aOldParent, TRomNode* aNewParent, TText* aNewName)
	{
	aOldParent->Remove(this);
	aNewParent->Add(this);
	delete [] iName;
	iName = new TText[strlen((const char *)aNewName)+1];
	strcpy ((char *)iName, (const char *)aNewName);
	}

TInt TRomNode::FullNameLength(TBool aIgnoreHiddenAttrib) const
	{
	TInt l = 0;
	// aIgnoreHiddenAttrib is used to find the complete file name length as 
	// in ROM of a hidden file.
	if (iParent && ( !iHidden || aIgnoreHiddenAttrib))
		l = iParent->FullNameLength() + 1;
	l += strlen((const char*)iName);
	return l;
	}

TInt TRomNode::GetFullName(char* aBuf, TBool aIgnoreHiddenAttrib) const
	{
	TInt l = 0;
	TInt nl = strlen((const char*)iName);
	// aIgnoreHiddenAttrib is used to find the complete file name as in ROM of a hidden file.
	if (iParent && ( !iHidden || aIgnoreHiddenAttrib))
		l = iParent->GetFullName(aBuf);
	char* b = aBuf + l;
	if (l)
		*b++ = '\\', ++l;
	memcpy(b, iName, nl);
	b += nl;
	*b = 0;
	l += nl;
	return l;
	}

// Fuction to return first node in the patchdata linked list
DllDataEntry *TRomBuilderEntry::GetFirstDllDataEntry() const
{
	if (iFirstDllDataEntry)
	{
		return iFirstDllDataEntry;
	}
	else
	{
		return NULL;
	}
}

// Fuction to set first node in the patchdata linked list
void TRomBuilderEntry::SetFirstDllDataEntry(DllDataEntry *aDllDataEntry)
{
	iFirstDllDataEntry = aDllDataEntry;	
}
void TRomBuilderEntry::DisplaySize(TPrintType aWhere)
{
	TBool aIgnoreHiddenAttrib = ETrue;
	TInt aLen = iRomNode->FullNameLength(aIgnoreHiddenAttrib);
	char *aBuf = new char[aLen+1];
	if(gLogLevel & LOG_LEVEL_FILE_DETAILS)
		{
		iRomNode->GetFullName(aBuf, aIgnoreHiddenAttrib);
		if(iFileName)
			Print(aWhere, "%s\t%d\t%s\t%s\n", iFileName, RealFileSize(), (iRomNode->iHidden || iHidden)?"hidden":"", aBuf);
		else
			Print(aWhere, "%s\t%s\n", (iRomNode->iHidden || iHidden)?"hidden":"", aBuf);
		}
	else
		{
		if(iFileName)
			Print(aWhere, "%s\t%d\n", iFileName, RealFileSize());
		}

}
