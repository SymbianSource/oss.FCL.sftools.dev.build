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
#include "h_utl.h"
#include <string.h>
#include <stdlib.h>
#include "r_global.h"
#include "r_obey.h"
#include "r_rom.h"
#include "r_dir.h"

// Routines for optimising the ROM by improving the code
//
// NB. Largely untouched since ER5, so not likely to work without
// some significant effort. Doesn't know about ARMv4T or ARMv5 instructions.


TInt E32Rom::CollapseImportThunks(TRomBuilderEntry* aFile)
//
// Collapse 3-word import thunks into a single branch
//	
	{
	TRomImageHeader *pI=aFile->iRomImageHeader;
	TUint32 *pE=(TUint32*)RomToActualAddress(pI->iCodeAddress);	// address of code section
	TUint32 codeSize=pI->iCodeSize;
	TUint32 *pC=pE+(codeSize>>2)-3;
	TUint32 low=0;
	TUint32 high=0;
	TUint32 romLow=0;
	TUint32 romHigh=0;
	TBool block=EFalse;
	TInt blocknum=0;
	TRACE(TCOLLAPSE1,Print(ELog,"CollapseImportThunks() File %s[%08x]\n",aFile->iFileName,
						   pI->iHardwareVariant));
	while(pC>=pE)
		{
		if (pC[0]==0xe59fc000 && pC[1]==0xe59cf000 && (pC[2]&0xf0000000)==0x50000000)
			{
// assume this is an import thunk
			if (!block)
				{
				high=(TUint32)(pC+3);
				block=ETrue;
				}
			pC-=3;
			}
		else
			{
			if (block)
				{
				low=(TUint32)(pC+3);
				block=EFalse;
				TInt numImports=(high-low)/12;
				TRACE(TCOLLAPSE2,Print(ELog,"?Import thunk block %08x-%08x %d %d\n",ActualToRomAddress((TAny*)low),ActualToRomAddress((TAny*)high),numImports,aFile->iImportCount));
				if (numImports==aFile->iImportCount)
					{
					if (blocknum==0)
						{
						romLow=(TUint32)ActualToRomAddress((TAny*)low);
						romHigh=(TUint32)ActualToRomAddress((TAny*)high);
						}
					blocknum++;
					}
				}
			pC--;
			}
		}
	if (blocknum==0)
		{
		Print(EWarning,"Import thunk block for %s[%08x] not found\n",aFile->iFileName,
			  pI->iHardwareVariant);
		}
	else if (blocknum==1)
		{
		low=(TUint32)RomToActualAddress(romLow);
		high=(TUint32)RomToActualAddress(romHigh);
		TRACE(TCOLLAPSE1,Print(ELog,"Import thunk block %08x-%08x\n",romLow,romHigh));
		TUint32 *pX;
		for (pX=(TUint32*)low; pX<(TUint32*)high; pX+=3)
			{
			TUint32 *pA=(TUint32*)RomToActualAddress(pX[2]);
			TUint32 jumpAddr=*pA;
			jumpAddr=FindFinalJumpDestination(jumpAddr);
			TInt offset=(TInt)jumpAddr-(TInt)ActualToRomAddress(pX)-8;
			if (offset<33554432 && offset>-33554432)
				{
				pX[0]=0xea000000 | ((offset&0x03ffffff)>>2);
				iImportsFixedUp++;
				}
			}
		aFile->iImportBlockStartAddress=romLow;
		aFile->iImportBlockEndAddress=romHigh;
		}
	else
		Print(EWarning,"??Import thunk block ambiguous - not changed\n");
	return KErrNone;
	}

TInt E32Rom::CollapseBranches()
//
// Collapse chained branches
//	
	{

	Print(ELog, "\nCollapsing Chained Branches.\n");
	TInt i;
	for (i=0; i<iObey->iNumberOfPeFiles; i++)
		{
		TRomBuilderEntry* file=iPeFiles[i];
		if (file->iOrigHdr->iImportOffset && file->iImportBlockEndAddress!=0)
			{
			TInt r=CollapseBranches(file);
			if (r!=KErrNone)
				return r;
			}
		}
	return KErrNone;
	}

inline void SetBit(TUint32* aBitmap, TInt aOffset)
	{
	aOffset>>=2;
	aBitmap[aOffset>>5] |= (1<<(aOffset&0x1f));
	}

inline TInt BitTest(TUint32* aBitmap, TInt aOffset)
	{
	aOffset>>=2;
	return(aBitmap[aOffset>>5]&(1<<(aOffset&0x1f)));
	}

TUint32 E32Rom::FindFinalJumpDestination(TUint32 ja)
	{
// follow a chain of branches to final destination
	TUint32 initja=ja;
	TUint8* aja=(TUint8*)RomToActualAddress(ja);
	FOREVER
			{
			if ((*(TUint32*)aja &0xff000000)==0xea000000)
				{
// branch to an unconditional branch
				TInt off=(*(TUint32*)aja & 0x00ffffff)<<8;
				off>>=6;
				if (off==-8)
					{
// branch to same address
					break;
					}
				ja+=(off+8);
				aja+=(off+8);
				TRACE(TCOLLAPSE2,Print(ELog,"Chain branch %08x to %08x\n",initja,ja));
				}
			else
				break;
			}
	return ja;
	}


TInt E32Rom::CollapseBranches(TRomBuilderEntry* aFile)
	{
// Main code section is between pI->iCodeAddress and aImportThunkStart. This contains
// all the explicit code and interspersed literals.
// aImportThunkStart-aImportThunkEnd contains import thunks (already collapsed)
// aImportThunkEnd-iat contains template instantiations and virtual destructors
// iat-rdata contains import addresses - no need to touch these
// rdata-expdir contains constant data and vtables
// expdir-end contains exported addresses - no need to touch these
	TUint32 impStart=aFile->iImportBlockStartAddress;
	TUint32 impEnd=aFile->iImportBlockEndAddress;
	TRomImageHeader *pI=aFile->iRomImageHeader;
	TRACE(TCOLLAPSE1,Print(ELog,"CollapseBranches() File %s[%08x]\n",aFile->iFileName,
						   pI->iHardwareVariant));
	TUint32 codeStart=pI->iCodeAddress;
	TUint32 codeSize=pI->iCodeSize;
	TUint32 codeEnd=codeStart+codeSize;
	TUint32 *pC=(TUint32*)RomToActualAddress(codeStart);	// address of code section
	TUint32 *pE=(TUint32*)RomToActualAddress(codeEnd);
	TUint32 romIat=codeStart+aFile->iHdr->iTextSize;
	TUint32 romRdata=romIat+aFile->iImportCount*4;
	TUint32 exportDir=pI->iExportDir;
	if (exportDir==0)
		exportDir=codeEnd;
	TRACE(TCOLLAPSE1,Print(ELog,"iat=%08x, rdata=%08x, expdir=%08x, end=%08x\n",romIat,romRdata,exportDir,codeEnd));
	TUint32 *pD=new TUint32[(codeSize+127)>>7];
	if (!pD)
		return KErrNoMemory;
	TInt rdataSize=TInt(exportDir)-TInt(romRdata);
	TUint32 *pR=new TUint32[(rdataSize+127)>>7];
	if (!pR)
		return KErrNoMemory;
	TInt i;
	for (i=0; i<TInt((codeSize+127)>>7); i++)
		pD[i]=0;
	for (i=0; i<TInt((rdataSize+127)>>7); i++)
		pR[i]=0;
	TUint32 *pX;
// go through code looking for data references
	for (pX=pC; pX<pE; pX++)
		{
		if ((*pX&0x0f3f0000)==0x051f0000)
			{
// opcode is LDRcc Rn, [PC, #d]
			TInt offset=*pX & 0xfff;
			if ((*pX&0x00800000)==0)
				offset=-offset;
			TUint32 eff=(ActualToRomAddress(pX)+8+offset)&~3;
			if (eff>=codeStart && eff<codeEnd)
				{
				SetBit(pD,eff-codeStart);
				if (eff<codeEnd-4)
					SetBit(pD,eff-codeStart+4);
				TUint32 data=*(TUint32*)((TUint8*)pX+(offset&~3)+8);	// fetch data word
				if (data>=romRdata && data<exportDir)
					{
// it's an address of something in .rdata, possibly a vtable
					SetBit(pR,data-romRdata);
					}
				}
			}
		}

	TUint32 *importStart=(TUint32*)RomToActualAddress(impStart);
	TUint32 *iatStart=(TUint32*)RomToActualAddress(romIat);
	if (iObey->iCollapseMode==ECollapseImportThunksAndVtables)
		goto vtablesonly;

	// go through .text looking for Bcc and BLcc intstructions
	for (pX=pC; pX<importStart; pX++)
		{
		if ((*pX&0xfe000000)==0xea000000 && BitTest(pD,TInt(pX)-TInt(pC))==0 )
			{
			TInt off=(*pX & 0x00ffffff)<<8;
			off>>=6;
			TUint32 pc=ActualToRomAddress(pX)+8;
			TUint32 ja=pc+off;
			TUint32 initja=ja;
			if (ja<codeStart || ja>=codeEnd)
				{
				TRACE(TCOLLAPSE2,Print(ELog,"??Branch at %08x to %08x??\n",pc-8,ja));
				goto notthismodule;
				}
			TRACE(TCOLLAPSE4,Print(ELog,"Branch at %08x opcode %08x ja=%08x\n",pc-8,*pX,ja));
			ja=FindFinalJumpDestination(ja);
			if (ja!=initja)
				{
				off=(TInt(ja)-TInt(pc))>>2;
				if (off>-33554432 && off<33554432)
					{
					TUint32 oldOpc=*pX;
					*pX=(*pX & 0xff000000)|(off&0x00ffffff); // fix up branch
					TRACE(TCOLLAPSE2,Print(ELog,"Opcode at %08x fixed up from %08x to %08x\n",pc-8,oldOpc,*pX));
					iBranchesFixedUp++;
					}
				}
		notthismodule: ;
			}
		}
// go through template instantiations and virtual destructors
// looking for Bcc and BLcc intstructions to import thunks
	pX=(TUint32*)RomToActualAddress(impEnd);
	for (; pX<iatStart; pX++)
		{
		if ((*pX&0xfe000000)==0xea000000 && BitTest(pD,TInt(pX)-TInt(pC))==0 )
			{
			TInt off=(*pX & 0x00ffffff)<<8;
			off>>=6;
			TUint32 pc=ActualToRomAddress(pX)+8;
			TUint32 ja=pc+off;
			TUint32 initja=ja;
			TRACE(TCOLLAPSE4,Print(ELog,"Branch at %08x opcode %08x ja=%08x\n",pc-8,*pX,ja));
			if (ja<codeStart || ja>=codeEnd)
				{
				TRACE(TCOLLAPSE2,Print(ELog,"??Branch at %08x to %08x??\n",pc-8,ja));
				goto notthismodule2;
				}
			ja=FindFinalJumpDestination(ja);
			if (ja!=initja)
				{
				off=(TInt(ja)-TInt(pc))>>2;
				if (off>-33554432 && off<33554432)
					{
					TUint32 oldOpc=*pX;
					*pX=(*pX & 0xff000000)|(off&0x00ffffff); // fix up branch
					TRACE(TCOLLAPSE2,Print(ELog,"Opcode at %08x fixed up from %08x to %08x\n",pc-8,oldOpc,*pX));
					iBranchesFixedUp++;
					}
				}
		notthismodule2: ;
			}
		}
vtablesonly:
// go through rdata section looking for vtables with references to import thunks
	TUint32 *expStart=(TUint32*)RomToActualAddress(exportDir);
	TUint32* pW=(TUint32*)RomToActualAddress(romRdata);
	pX=pW;
	while(pX<expStart-1)
		{
// first look for reference to start of vtable
// there are always two 0 words at the start of a vtable
		if (BitTest(pR,TInt(pX)-TInt(pW)) && pX[0]==0 && pX[1]==0)
			{
			TRACE(TCOLLAPSE3,Print(ELog,"?vtable at %08x\n",ActualToRomAddress(pX)));
// look for next reference - there are no references to
// intermediate entries of vtable
			TUint32* pY;
			for (pY=pX+1; pY<expStart && BitTest(pR,TInt(pY)-TInt(pW))==0; pY++);

// pY should now point to the end of the vtable
// check all entries except the first two are valid ROM addresses in this module
			TRACE(TCOLLAPSE3,Print(ELog,"?vtable at %08x to %08x\n",ActualToRomAddress(pX),ActualToRomAddress(pY)));
			TUint32 *pZ;
			for (pZ=pX+2; pZ<pY; pZ++)
				{
				if (*pZ<codeStart || *pZ>=codeEnd)
					break;
				}
			if (pZ==pY)
				{
// this is a vtable
// check each address to see if it is an import thunk and if so fix it up
				TRACE(TCOLLAPSE3,Print(ELog,"!vtable at %08x to %08x\n",ActualToRomAddress(pX),ActualToRomAddress(pY)));
				for (pZ=pX+2; pZ<pY; pZ++)
					{
					TUint32 ja=*pZ;
					TUint32 initja=ja;
					ja=FindFinalJumpDestination(ja);
					if (ja!=initja)
						{
						*pZ=ja;
						TRACE(TCOLLAPSE2,Print(ELog,"Vtable entry at %08x fixed up from %08x to %08x\n",ActualToRomAddress(pZ),initja,ja));
						iVtableEntriesFixedUp++;
						}
					}
				pX=pY;
				}
			else
				pX++;
			}
		else
			pX++;
		}
	delete[] pR;
	delete[] pD;
	return KErrNone;
	}

