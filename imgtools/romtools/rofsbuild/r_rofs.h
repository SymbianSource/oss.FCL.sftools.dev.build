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


#ifndef __R_ROFS_H__
#define __R_ROFS_H__

#include <e32rom.h>

#if defined(__MSVCDOTNET__) || defined(__TOOLS2__)
#include <fstream>
#else //!__MSVCDOTNET__
#include <fstream.h>
#endif //__MSVCDOTNET__

#include "h_utl.h"
#include "r_coreimage.h"
#include <boost/thread/thread.hpp>
#include <boost/thread/condition.hpp>
#include <queue>

#define DEFAULT_LOG_LEVEL 0x0
#define LOG_LEVEL_FILE_DETAILS	0x00000001       // Destination file name (loglevel1)
#define LOG_LEVEL_FILE_ATTRIBUTES 0x00000002     // File attributes (loglevel2)


class CObeyFile;
class MRofsImage;
class Memmap;

struct TPlacingSection {
    TUint8* buf;
    TInt len;
    TRomNode* node;
    TPlacingSection(TRomNode* anode){
        node = anode;
        buf = NULL;
        len = 0;
    }
};
class E32Rofs : public MRofsImage
	{
public:
	E32Rofs(CObeyFile *aObey);
	virtual ~E32Rofs();
	TInt Create();

	TInt CreateExtension(MRofsImage* info);
	TInt WriteImage( TInt aHeaderType );

	TRomNode* CopyDirectory(TRomNode*& aLastExecutable);
	TRomNode* RootDirectory();
	void SetRootDirectory(TRomNode* aDir);
	TText* RomFileName();
	TInt Size();
	void MakeAutomaticSize(TUint32 aSize);

        //Get a node to handle, if there is no more, NULL returns.
        //For alias node, it will be deferred to later phase to handle.
	TPlacingSection* GetFileNode(bool &aDeferred);
        TPlacingSection* GetDeferredJob();
        void ArriveDeferPoint();
	void DisplaySizes(TPrintType aWhere);
private:
	TInt PlaceFiles( TRomNode* aRootDir, TUint8* aDestBase, TUint aBaseOffset, TInt aCoreSize = 0 );
	TInt LayoutDirectory( TRomNode* aRootDir, TUint aBaseOffset );
	TInt PlaceDirectory( TRomNode* aRootDir, TUint8* aDest );
	void LogExecutableAttributes(E32ImageHeaderV *aHdr);


	void Write(ofstream &of, TInt aHeaderType);		// main ROM image
	Memmap* iImageMap;

public:
	char *iData;
	TInt iSize;

	TRofsHeader *iHeader;
	TExtensionRofsHeader *iExtensionRofsHeader;	
	//
	CObeyFile *iObey;

	//
	TInt iSizeUsed;
	TInt iOverhead;
	TInt iDirectorySize;

	TInt iTotalDirectoryBlockSize;
	TInt iTotalFileBlockSize;
	//

private:
	TRomNode *iLastNode;
        int iWorkerArrived;
        boost::mutex iMuxTree;
        std::vector<TPlacingSection*> iVPS;
        std::queue<TPlacingSection*> iQueueAliasNode;
};


class TRofsDirStructure
	{
	public:
		TRofsDirStructure( TRomEntry* aRootDirectory );

		TInt CalculateDirectorySize();

	private:
		TRomEntry* iRootDirectory;
	};
#endif
