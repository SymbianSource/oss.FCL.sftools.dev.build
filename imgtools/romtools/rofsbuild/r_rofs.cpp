/*
* Copyright (c) 1996-2009 Nokia Corporation and/or its subsidiary(-ies).
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


#include <e32std.h>
#include <e32std_private.h>
#include <e32uid.h>
#include <f32file.h>
#include "h_utl.h"
#include <string.h>
#include <stdlib.h>
#include "r_obey.h"
#include "r_rofs.h"
#include "r_coreimage.h"
#include "memmap.h"
#include "symbolgenerator.h"
extern TInt gLogLevel;
extern TBool gLowMem;
extern TInt gThreadNum;
extern TBool gGenSymbols;
////////////////////////////////////////////////////////////////////////



inline TUint32 AlignData(TUint32 anAddr) {
	return ((anAddr+0x0f)&~0x0f);
}


////////////////////////////////////////////////////////////////////////

E32Rofs::E32Rofs(CObeyFile *aObey)
//
// Constructor
//
	: iObey( aObey ), iOverhead(0)
	{
	if(gGenSymbols)
		iSymGen = SymbolGenerator::GetInstance();
	else
		iSymGen = NULL;

	iSize=aObey->iRomSize;
	if(gLowMem) {
		iImageMap = new Memmap();

		if(iImageMap == NULL) {
			iSize = 0;
			Print(EError, "Out of memory.\n");
		}
		else {
			iImageMap->SetMaxMapSize(iSize);
			if(iImageMap->CreateMemoryMap(0, 0xff) == EFalse) {
				iSize = 0;
				Print(EError, "Failed to create image map object");

				iImageMap->CloseMemoryMap(ETrue);
				delete iImageMap;
				iImageMap = NULL;
			}
			else {
				iData = iImageMap->GetMemoryMapPointer();
			}
		}
	}
	else {
		iData=new char [iSize];
		if (iData==NULL)
			iSize=0;
		HMem::Set(iData, 0xff, iSize);
	}

}

E32Rofs::~E32Rofs()  {

	if(gLowMem) {
		iImageMap->CloseMemoryMap(ETrue);
		delete iImageMap;
	}
	else if(iData)
		delete []iData;
}


TInt E32Rofs::CreateExtension(MRofsImage* aImage)  {

	TUint8* addr=(TUint8*)iData;

	TRomNode* pRootDir = aImage->RootDirectory();


	const TInt extensionRofsheaderSize = KExtensionRofsHeaderSize;

	// aImage->iSize contains the max size of the core image

	// Layout the directory structure. Does not actually write it
	// to the image. Returns the number of bytes used for the directory
	// structure within the image.
	TInt directoryOffset = extensionRofsheaderSize;
	const TInt directorySize = LayoutDirectory( pRootDir, aImage->Size()+directoryOffset );
	if( directorySize <= 0 ) {
		Print(EError, "Failed laying out directories - return code %d\n", directorySize);
		return KErrGeneral;
	}

	// get offset to start of file data, rounded up to next word boundary
	TInt offs = extensionRofsheaderSize + directorySize;
	const TInt fileDataStartOffset = offs + ( (4 - offs) & 3);

	// Now we traverse the list of entries placing each file
	// This updates the directory entries to point to the correct offset
	// to the start of the file
	const TInt fileDataSize = PlaceFiles( pRootDir, addr + fileDataStartOffset, fileDataStartOffset + aImage->Size(), aImage->Size());
	if( fileDataSize <= 0 ) {
		Print(EError, "Failed placing files - return code %d\n", fileDataSize);
		return KErrGeneral;
	}

	// and then put the directory into the image
	TInt err = PlaceDirectory( pRootDir, addr - aImage->Size() ); // offset pointer by size of core image
	if( err != KErrNone ) {
		Print(EError, "Failed placing directory - return code %d\n", err);
		return err;
	}

	directoryOffset+=aImage->Size(); // offset offset by size of core image
	// Now write the header
	TExtensionRofsHeader * pHeader = (TExtensionRofsHeader*)iData;
	pHeader->iIdentifier[0] = 'R';
	pHeader->iIdentifier[1] = 'O';
	pHeader->iIdentifier[2] = 'F';
	pHeader->iIdentifier[3] = 'x';
	pHeader->iHeaderSize = KExtensionRofsHeaderSize;
	pHeader->iDirTreeOffset = directoryOffset;
	pHeader->iDirTreeSize = iTotalDirectoryBlockSize;
	pHeader->iDirFileEntriesOffset = directoryOffset + iTotalDirectoryBlockSize;
	pHeader->iDirFileEntriesSize = iTotalFileBlockSize;
	pHeader->iRofsFormatVersion = KRofsFormatVersion;
	pHeader->iTime = iObey->iTime;
	iSizeUsed = fileDataSize + fileDataStartOffset;
	pHeader->iImageSize = iSizeUsed;
	if (iObey->AutoSize())
		MakeAutomaticSize(iObey->AutoPageSize()); // change iSize to nearest page size
	pHeader->iMaxImageSize = iSize;
	pHeader->iCheckSum = 0;		// not used yet

	return KErrNone;
}

void E32Rofs::MakeAutomaticSize(TUint32 aPageSize) {
	TUint32 size = iSizeUsed;
	if (iSizeUsed % aPageSize > 0) {
		//used size needs to be rounded up to nearest page size
		size = (iSizeUsed/aPageSize + 1)*aPageSize;
	}
	iSize = size;
}

//
// This is the main entry point to the ROFS image creation
//
TInt E32Rofs::Create() {
	TUint8* addr=(TUint8*)iData;

	TRomNode* pRootDir = iObey->iRootDirectory;
	const TInt headerSize = KRofsHeaderSize;
	// Layout the directory structure. Does not actually write it
	// to the image. Returns the number of bytes used for the directory
	// structure within the image.
	const TInt directoryOffset = headerSize;
	const TInt directorySize = LayoutDirectory( pRootDir, directoryOffset );
	if( directorySize <= 0 ) {
		Print(EError, "Failed laying out directories - return code %d\n", directorySize);
		return KErrGeneral;
	}

	// get offset to start of file data, rounded up to next word boundary
	TInt offs = headerSize + directorySize;
	const TInt fileDataStartOffset = offs + ( (4 - offs) & 3);

	// Now we traverse the list of entries placing each file
	// This updates the directory entries to point to the correct offset
	// to the start of the file
	const TInt fileDataSize = PlaceFiles( pRootDir, addr + fileDataStartOffset, fileDataStartOffset );
	if( fileDataSize < 0 ) {
		Print(EError, "Failed placing files - rofssize is too small\n", fileDataSize);
		return KErrGeneral;
	}

	// and then put the directory into the image
	TInt err = PlaceDirectory( pRootDir, addr );
	if( err != KErrNone ) {
		Print(EError, "Failed placing directory - return code %d\n", err);
		return err;
	}

	// Now write the header
	TRofsHeader* pHeader = (TRofsHeader*)iData;
	pHeader->iIdentifier[0] = 'R';
	pHeader->iIdentifier[1] = 'O';
	pHeader->iIdentifier[2] = 'F';
	pHeader->iIdentifier[3] = 'S';
	pHeader->iHeaderSize = KExtensionRofsHeaderSize;
	pHeader->iDirTreeOffset = directoryOffset;
	pHeader->iDirTreeSize = iTotalDirectoryBlockSize;
	pHeader->iDirFileEntriesOffset = directoryOffset + iTotalDirectoryBlockSize;
	pHeader->iDirFileEntriesSize = iTotalFileBlockSize;
	pHeader->iRofsFormatVersion = KRofsFormatVersion;
	pHeader->iTime = iObey->iTime;
	iSizeUsed = fileDataSize + fileDataStartOffset;
	pHeader->iImageSize = iSizeUsed;
	pHeader->iImageVersion = iObey->iVersion;
	if (iObey->AutoSize())
		MakeAutomaticSize(iObey->AutoPageSize()); // change iSize to nearest page size

	pHeader->iMaxImageSize = iSize;
	pHeader->iCheckSum = 0;		// not used yet

	return KErrNone;
}
void E32Rofs::DisplaySizes(TPrintType aWhere) {
	Print(aWhere, "Summary of file sizes in rofs:\n");
	TRomBuilderEntry *file=iObey->FirstFile();
	while(file) {
		file->DisplaySize(aWhere);
		file=iObey->NextFile();
	}
	Print( aWhere, "Directory block size: %d\n"
		"File block size:      %d\n"
		"Total directory size: %d\n"
		"Total image size:     %d\n",
		iTotalDirectoryBlockSize,
		iTotalFileBlockSize,
		iTotalDirectoryBlockSize + iTotalFileBlockSize,
		iSizeUsed );

}

void E32Rofs::LogExecutableAttributes(E32ImageHeaderV *aHdr) {
	Print(ELog, "Uids:                    %08x %08x %08x %08x\n", aHdr->iUid1, aHdr->iUid2, aHdr->iUid3, aHdr->iUidChecksum);
	Print(ELog, "Data size:               %08x\n", aHdr->iDataSize);
	Print(ELog, "Heap min:                %08x\n", aHdr->iHeapSizeMin);
	Print(ELog, "Heap max:                %08x\n", aHdr->iHeapSizeMax);
	Print(ELog, "Stack size:              %08x\n", aHdr->iStackSize);
	Print(ELog, "Secure ID:               %08x\n", aHdr->iS.iSecureId);
	Print(ELog, "Vendor ID:               %08x\n", aHdr->iS.iVendorId);
	Print(ELog, "Priority:                %d\n\n", aHdr->iProcessPriority);
}
class Worker : public boost::thread {
    public:
    static boost::mutex iOutputMutex;
    static void thrd_func(E32Rofs* rofs){
        CBytePair bpe;

        bool deferred = false;
        TPlacingSection* p = rofs->GetFileNode(deferred);
        while(p) {
            if(!deferred) {
                p->len = p->node->PlaceFile(p->buf, (TUint32)-1, 0, &bpe);
                //no symbol for hidden file
                if(rofs->iSymGen && !p->node->iEntry->iHidden)
                    rofs->iSymGen->AddFile(p->node->iEntry->iFileName,(p->node->iEntry->iCompressEnabled|| p->node->iEntry->iExecutable));
	        boost::mutex::scoped_lock lock(iOutputMutex);
		p->node->FlushLogMessages();
            }
            p = rofs->GetFileNode(deferred);
        }
        rofs->ArriveDeferPoint();
        p = rofs->GetDeferredJob();
        while(p) {
            p->len = p->node->PlaceFile(p->buf, (TUint32)-1, 0, &bpe);
	    iOutputMutex.lock();
	    p->node->FlushLogMessages();
	    iOutputMutex.unlock();
            p = rofs->GetDeferredJob();
        }
    }
    Worker(E32Rofs* rofs) : boost::thread(thrd_func,rofs) {
    }
};

boost::mutex Worker::iOutputMutex;

TPlacingSection* E32Rofs::GetFileNode(bool &aDeferred) {
	//get a node from the node list, the node list is protected by mutex iMuxTree.
	//The iMuxTree also helps to make sure the order in iVPS is consistent with the node list.
	//And this is the guarantee of same outputs regardless of how many threads being used.
	boost::mutex::scoped_lock lock(iMuxTree);
	aDeferred = false;
	TRomNode* node = iLastNode;
	while(node) {
		if( node->IsFile()) {
			if(!node->iHidden) {
				iLastNode = node->NextNode();
				break;
			}
		}
		node = node->NextNode();
	}

	if(node && node->IsFile() && !node->iHidden) {
		TPlacingSection* pps = new TPlacingSection(node);
		iVPS.push_back(pps);
		if(node->iAlias) {
			iQueueAliasNode.push(pps);
			aDeferred =  true;
		}
		return pps;
	}
	return NULL;
}
TPlacingSection* E32Rofs::GetDeferredJob() {
	// waiting all the normal node have been placed.
	while(iWorkerArrived < gThreadNum)
		boost::this_thread::sleep(boost::posix_time::milliseconds(10));

	// now we can safely handle the alias nodes.
	boost::mutex::scoped_lock lock(iMuxTree);
	TPlacingSection* p = NULL;
	if(!iQueueAliasNode.empty()) {
		p = iQueueAliasNode.front();
		iQueueAliasNode.pop();
	}
	return p;
}
void E32Rofs::ArriveDeferPoint() {
	boost::mutex::scoped_lock lock(iMuxTree);
	++iWorkerArrived;
}
TInt E32Rofs::PlaceFiles( TRomNode* /*aRootDir*/, TUint8* aDestBase, TUint aBaseOffset, TInt aCoreSize ) 
	//
	// Traverses all entries placing all files and updating directory entry pointers.
	// Returns number of bytes placed or -ve error code.
	//
	{
            if(iSymGen)
                iSymGen->SetSymbolFileName((const char *)iObey->iRomFileName);
            iLastNode = TRomNode::FirstNode();
            iWorkerArrived = 0;

            boost::thread_group thrds;
            Worker** workers = new Worker*[gThreadNum];
            int i;
            for (i = 0; i < gThreadNum; ++i) {
                workers[i] = new Worker(this);
                thrds.add_thread(workers[i]);
            }

            thrds.join_all();
            delete [] workers;
            if(iSymGen)
                iSymGen->SetFinished();

            TUint offset = aBaseOffset;
            TUint8* dest = aDestBase;
            TBool aIgnoreHiddenAttrib = ETrue;
            TInt len = iVPS.size();
            TInt maxSize;
            for(i=0;i<len;i++) {
                maxSize = aCoreSize + iSize - offset;
                if(maxSize <= 0) {
                    // Image size is too low to proceed.
                    return maxSize;
                }
                if(iVPS[i]->node->iFileStartOffset != (TUint)KFileHidden) {
                    if (iVPS[i]->len > maxSize) {
                       // Image size is too low to proceed.
                       return maxSize - iVPS[i]->len;
                    }
                    memcpy(dest,iVPS[i]->buf,iVPS[i]->len);
                    if(iVPS[i]->node->iEntry->iFileOffset == -1) {
                        iVPS[i]->node->iEntry->iFileOffset = offset;
                        iVPS[i]->node->iFileStartOffset = iVPS[i]->node->iEntry->iFileOffset;
                    }
                    else {
                        TRomBuilderEntry* aEntry = (TRomBuilderEntry*)(iVPS[i]->node->iFileStartOffset);
                        iVPS[i]->node->iFileStartOffset = aEntry->iFileOffset;
                    }
                }
                iVPS[i]->len += (4-iVPS[i]->len) & 3;// round up to next word boundary
                dest += iVPS[i]->len;
                offset += iVPS[i]->len;

                if(gLogLevel > DEFAULT_LOG_LEVEL )
                {
                    TRomNode* node = iVPS[i]->node;
                    TInt aLen = node->FullNameLength(aIgnoreHiddenAttrib);
                    char *aBuf = new char[aLen+1];
                    if(gLogLevel & LOG_LEVEL_FILE_DETAILS)
                    {
                        node->GetFullName(aBuf, aIgnoreHiddenAttrib);
                        if(node->iEntry->iFileName)
                            Print(ELog,"%s\t%d\t%s\t%s\n", node->iEntry->iFileName, node->iEntry->RealFileSize(), (node->iHidden || node->iEntry->iHidden)? "hidden":"", aBuf);
                        else
                            Print(ELog,"%s\t%s\n", (node->iHidden || node->iEntry->iHidden) ? "hidden":"", aBuf);
                    }

                    if(gLogLevel & LOG_LEVEL_FILE_ATTRIBUTES)
                    {
                        if(!node->iHidden && !node->iEntry->iHidden)
                            Print(ELog, "Device file name:        %s\n", aBuf);
                        if(node->iEntry->iExecutable)
                            LogExecutableAttributes((E32ImageHeaderV*)(dest-len));
                    }
                    delete[] aBuf;
                }
            }
	return offset - aBaseOffset;	// number of bytes used
	}






//
// Creates the directory layout but does not write it to the image.
// All directories are given a location in the image.
// Returns the total number of bytes used for the directory (rounded
// up to the nearest word) or a -ve error code.
//
TInt E32Rofs::LayoutDirectory( TRomNode* /*aRootDir*/, TUint aBaseOffset )  {
	TRomNode* node = TRomNode::FirstNode();

	TUint offset = aBaseOffset;
	while( node ) {
		if( node->IsDirectory()) {
			// it is a directory block so we have to give it a location
			node->SetImagePosition( offset );

			// work out how much space it requires for the directory block
			TInt dirLen;
			TInt fileLen;
			TInt err = node->CalculateDirectoryEntrySize( dirLen, fileLen );
			if( err != KErrNone ) {
				return err;
			}
			Print( ELog, "Directory '%s' @offs=0x%x, size=%d\n", node->iName, offset, dirLen );
			dirLen += (4-dirLen) & 3;	// round up to next word boundary
			offset += dirLen;
		}

		node = node->NextNode();
	}

	TInt totalDirectoryBlockSize = offset - aBaseOffset;	// number of bytes used
	totalDirectoryBlockSize += (4 - totalDirectoryBlockSize) & 3;		// round up

	// Now go round again placing the file blocks
	offset = aBaseOffset + totalDirectoryBlockSize;
	const TUint fileBlockStartOffset = offset;
	node = TRomNode::FirstNode();
	while( node ) {
		if( node->IsDirectory() ) {
			// work out how much space it requires for the file block
			TInt dummy;
			TInt fileLen;
			TInt err = node->CalculateDirectoryEntrySize( dummy, fileLen );

			if( err != KErrNone ) {
				return fileLen;
			}
			if( fileLen ) {
				node->SetFileBlockPosition( offset );
				Print( ELog, "File block for dir '%s' @offs=0x%x, size=%d\n", node->iName, offset, fileLen );
			}

			fileLen += (4-fileLen) & 3;	// round up to next word boundary
			offset += fileLen;
		}

		node = node->NextNode();
	}

	TInt totalFileBlockSize = offset - fileBlockStartOffset;	// number of bytes used
	totalFileBlockSize += (4 - totalFileBlockSize) & 3;		// round up

	iTotalDirectoryBlockSize = totalDirectoryBlockSize;
	iTotalFileBlockSize = totalFileBlockSize;

	return totalDirectoryBlockSize + totalFileBlockSize;
}
//
// Writes the directory into the image. 
// Returns KErrNone on success, or error code
//

TInt E32Rofs::PlaceDirectory( TRomNode* /*aRootDir*/, TUint8* aDestBase )  {
	TRomNode* node = TRomNode::FirstNode();

	while( node ) {
		if( node->IsDirectory() ) {
			TInt err = node->Place( aDestBase );
			if( err != KErrNone ) {
				return err;
			}
		}
		node = node->NextNode();
	}
	return KErrNone;
}

TInt E32Rofs::WriteImage( TInt aHeaderType ) {
	ofstream romFile((const char *)iObey->iRomFileName,ios_base::binary);
	if (!romFile)
		return Print(EError,"Cannot open ROM file %s for output\n",iObey->iRomFileName);
	Write(romFile, aHeaderType);
	romFile.close();
        if(iSymGen)
            SymbolGenerator::Release();

	return KErrNone;
}

TRomNode* E32Rofs::CopyDirectory(TRomNode*& aLastExecutable) {
	return iObey->iRootDirectory->CopyDirectory(aLastExecutable);
}


// Output a rom image
void E32Rofs::Write(ofstream &os, TInt aHeaderType) {

	switch (aHeaderType) {
	default:
	case 0:
		Print(EAlways, "\nWriting Rom image without");
		break;
	case 2:
		Print(EAlways, "\nWriting Rom image with PE-COFF"); {
			unsigned char coffhead[0x58] = {0};  // zero all the elements

			// fill in the constant bits
			// this is supposed to be simple, remember
			coffhead[1] = 0x0a;
			coffhead[2] = 0x01;
			coffhead[0x10] = 0x1c;
			coffhead[0x12] = 0x0f;
			coffhead[0x13] = 0xa1;
			coffhead[0x14] = 0x0b;
			coffhead[0x15] = 0x01;
			coffhead[0x26] = 0x40;
			coffhead[0x2a] = 0x40;
			coffhead[0x30] = 0x2e;
			coffhead[0x31] = 0x74;
			coffhead[0x32] = 0x65;
			coffhead[0x33] = 0x78;
			coffhead[0x34] = 0x74;
			coffhead[0x3a] = 0x40;
			coffhead[0x3e] = 0x40;
			coffhead[0x44] = 0x58;
			coffhead[0x54] = 0x20;

			// now fill in the text segment size
			*(TUint32 *) (&coffhead[0x18]) = ALIGN4K(iSizeUsed);
			*(TUint32 *) (&coffhead[0x40]) = ALIGN4K(iSizeUsed);

			os.write(reinterpret_cast<char *>(coffhead), sizeof(coffhead));
		}
		break;
	}
	Print(EAlways, " header to file %s\n", iObey->iRomFileName);
	os.write( iData, iSizeUsed );
}


TRomNode* E32Rofs::RootDirectory() {
	return iObey->iRootDirectory;
}
void E32Rofs::SetRootDirectory(TRomNode* aDir) {
	iObey->iRootDirectory = aDir;
}
const char* E32Rofs::RomFileName() const  {
	return iObey->iRomFileName;
}
TInt E32Rofs::Size() const  {
	return iSize;
}

///////////////////

