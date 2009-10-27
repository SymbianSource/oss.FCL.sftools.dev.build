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


#define __REFERENCE_CAPABILITY_NAMES__

#include "e32image.h"
#include <e32std.h>
#include <e32std_private.h>
#include <e32ver.h>
#include <e32rom.h>
#include <stdlib.h>
#include <u32std.h>

#include "r_rom.h"
#include "r_global.h"
#include "r_obey.h"
#include "h_utl.h"

inline char* RomToActualAddress(TLinAddr aRomAddr)
	{ return (char*)(aRomAddr+TheRomMem-TheRomLinearAddress); }

//
void TRomLoaderHeader::SetUp(CObeyFile *aObey)
//
// Fill in the TRomLoaderHeader - this is used by the ROM loader / programmer.
//
 	{

	if (CPU==ECpuX86)
		_snprintf((char *)r.name,24,"%-16.16s%2x%2x%4x","EPOC486 ROM",aObey->iVersion.iMajor,aObey->iVersion.iMinor,aObey->iVersion.iBuild);
	else if (CPU==ECpuArmV4)
		_snprintf((char *)r.name,24,"%-16.16s%2x%2x%4x","EPOCARM4ROM",aObey->iVersion.iMajor,aObey->iVersion.iMinor,aObey->iVersion.iBuild);
	else if (CPU==ECpuArmV5)
		_snprintf((char *)r.name,24,"%-16.16s%2x%2x%4x","EPOCARM5ROM",aObey->iVersion.iMajor,aObey->iVersion.iMinor,aObey->iVersion.iBuild);
	else if (CPU==ECpuMCore)
		_snprintf((char *)r.name,24,"%-16.16s%2x%2x%4x","EPOCMCORROM",aObey->iVersion.iMajor,aObey->iVersion.iMinor,aObey->iVersion.iBuild);
	else
		_snprintf((char *)r.name,24,"%-16.16s%2x%2x%4x","EPOCUNKNOWN",aObey->iVersion.iMajor,aObey->iVersion.iMinor,aObey->iVersion.iBuild);
	r.romSize = aObey->iRomSize;
	r.wrapSize = KRomWrapperSize;
	for (TUint i=0; i<KFillSize; i++)
		filler[i] = 0;
 	}
//  
void ImpTRomHeader::SetUp(CObeyFile *aObey)
//
// Fill in the TRomHeader - this is used by the bootstrap and kernel.
//
	{

	iVersion = aObey->iVersion;
	iTime = aObey->iTime;
	iTimeHi = (TUint32)(aObey->iTime>>32);
	iRomBase = aObey->iRomLinearBase;
	iRomSize = aObey->iRomSize;

	iKernDataAddress = aObey->iKernDataRunAddress;
	iKernelLimit = aObey->iKernelLimit;
	iPrimaryFile = TheRomHeader->iPrimaryFile;
	iSecondaryFile = TheRomHeader->iSecondaryFile;
	iLanguage=aObey->iLanguage;
	iHardware=aObey->iHardware;
	iRomHeaderSize=KRomHeaderSize;
	iRomSectionHeader=aObey->iSectionStart;
	TUint j; 
	for (j=0; j<(TUint)KNumTraceMaskWords; j++)
		iTraceMask[j]=aObey->iTraceMask[j];
	for (j=0; j<sizeof(iInitialBTraceFilter)/sizeof(TUint32); j++)
		iInitialBTraceFilter[j]=aObey->iInitialBTraceFilter[j];
	iInitialBTraceMode = aObey->iInitialBTraceMode;
	iInitialBTraceBuffer = aObey->iInitialBTraceBuffer;
	iDebugPort=aObey->iDebugPort;
	iKernelConfigFlags=aObey->iKernelConfigFlags;
	for(TInt i=0; i<SCapabilitySet::ENCapW; i++)
		iDisabledCapabilities[i]=aObey->iPlatSecDisabledCaps[i];
	}

void ImpTRomHeader::CheckSum(TUint32 aTargetValue)
	{
	iCheckSum=0;
	iCheckSum=aTargetValue-(HMem::CheckSum((TUint *)(TRomHeader *)this, iRomSize));
	}


void DisplayExceptionTable(TLinAddr aRomExcTab)
	{
	Print(ELog,"Rom Exception Search Table Address: %08x\n",aRomExcTab);
	TRomExceptionSearchTable* pT=(TRomExceptionSearchTable*)RomToActualAddress(aRomExcTab);
	Print(ELog,"Rom Exception Search Table contains %d entries:\n",pT->iNumEntries);

	Print(ELog,"CodeAddr\tCd + Data\tidx size\tNum Ents\t Shorts \n");
	Print(ELog,"========\t=========\t========\t========\t========\n");
	TInt i;
	for (i=0; i<pT->iNumEntries; i++)
		{
		TRomImageHeader* pE = (TRomImageHeader *)RomToActualAddress(pT->iEntries[i]);
		TRomImageHeader* pH = pE - 1;
		const TExceptionDescriptor* pX = (const TExceptionDescriptor*)RomToActualAddress(pH->iExceptionDescriptor);
		if (!pX)
			continue;
		TUint32 indexTableSize = (char *)pX->iExIdxLimit - (char *)pX->iExIdxBase;
		struct IndexTableEntry { TUint32 aPc; TInt aVal; };
		struct IndexTableEntry* aExIdxBase = (struct IndexTableEntry *)RomToActualAddress(pX->iExIdxBase);
		struct IndexTableEntry* aExIdxLimit = (struct IndexTableEntry *)RomToActualAddress(pX->iExIdxLimit);
		TUint32 numIndexTableEntries = aExIdxLimit - aExIdxBase;
		TUint32 numShortEntries = 0;
		// Short entries have top bit set.
		for(; aExIdxBase < aExIdxLimit; aExIdxBase++) 
		  if (aExIdxBase->aVal == 1 || aExIdxBase->aVal < 0) 
			numShortEntries++;
		
		Print(ELog,"%08x\t%08d\t%08d\t%08d\t%08d\n", 
				pT->iEntries[i], 
				pH->iCodeSize+pH->iDataSize, 
				indexTableSize, 
				numIndexTableEntries, 
				numShortEntries);
		}
	Print(ELog,"\nROM EST fencepost = %08x\n", pT->iEntries[pT->iNumEntries]);	
	}


//
void ImpTRomHeader::Display()
// 
// Display info from ROM header
//
	{
	TInt i;

	Print(ELog,"\n\nDevelopment configuration settings:\n");
	TUint j; 
	for (j=0; j<(TUint)KNumTraceMaskWords; j++) 
		Print(ELog,"TraceMask[%d]:            %08x\n",j, iTraceMask[j]);
	for (j=0; j<sizeof(iInitialBTraceFilter)/sizeof(TUint32); j++)
		Print(ELog,"BTrace[%d]:            %08x\n",j, iInitialBTraceFilter[j]);
	Print(ELog,"BTraceMode:           %08x\n",iInitialBTraceMode);
	Print(ELog,"BTraceBuffer:         %08x\n",iInitialBTraceBuffer);
	Print(ELog,"DebugPort:               %08x\n",iDebugPort);
	Print(ELog,"KernelConfigFlags:       %08x\n",iKernelConfigFlags);
	Print(ELog,"PlatSecDiagnostics:      %s\n",iKernelConfigFlags&EKernelConfigPlatSecDiagnostics ? "ON":"OFF");
	Print(ELog,"PlatSecEnforcement:      %s\n",iKernelConfigFlags&EKernelConfigPlatSecEnforcement ? "ON":"OFF");
	Print(ELog,"PlatSecProcessIsolation: %s\n",iKernelConfigFlags&EKernelConfigPlatSecProcessIsolation ? "ON":"OFF");
	Print(ELog,"PlatSecEnforceSysBin:    %s\n",iKernelConfigFlags&EKernelConfigPlatSecEnforceSysBin ? "ON":"OFF");
	const char* pagingPolicy =0;
	switch(iKernelConfigFlags&EKernelConfigCodePagingPolicyMask)
		{
	case EKernelConfigCodePagingPolicyNoPaging:
		pagingPolicy = "NoPaging";
		break;
	case EKernelConfigCodePagingPolicyAlwaysPage:
		pagingPolicy = "AlwaysPage";
		break;
	case EKernelConfigCodePagingPolicyDefaultUnpaged:
		pagingPolicy = "DefaultUnpaged";
		break;
	case EKernelConfigCodePagingPolicyDefaultPaged:
		pagingPolicy = "DefaultPaged";
		break;
		}
	Print(ELog,"CodePagingPolicy:            %s\n",pagingPolicy);
	switch(iKernelConfigFlags&EKernelConfigDataPagingPolicyMask)
		{
	case EKernelConfigDataPagingPolicyNoPaging:
		pagingPolicy = "NoPaging";
		break;
	case EKernelConfigDataPagingPolicyAlwaysPage:
		pagingPolicy = "AlwaysPage";
		break;
	case EKernelConfigDataPagingPolicyDefaultUnpaged:
		pagingPolicy = "DefaultUnpaged";
		break;
	case EKernelConfigDataPagingPolicyDefaultPaged:
		pagingPolicy = "DefaultPaged";
		break;
		}
	Print(ELog,"DataPagingPolicy:            %s\n",pagingPolicy);
	Print(ELog,"PlatSecDisabledCaps:     ");
	TBool all=ETrue;
	TBool none=ETrue;
	for(i=0; i<ECapability_Limit; i++)
		if(CapabilityNames[i])
			{
			if(iDisabledCapabilities[i>>5] & (1<<(i&31)))
				none = EFalse;
			else
				all = EFalse;
			}
	if(none)
		Print(ELog,"NONE");
	else if(all)
		Print(ELog,"ALL");
	else
		for(i=0; i<ECapability_Limit; i++)
			if(iDisabledCapabilities[i>>5] & (1<<(i&31)))
				Print(ELog,"%s ",CapabilityNames[i]);	
	Print(ELog,"\n");

	Print(ELog,"\n\nRom details:\n");
	Print(ELog,"Version %d.%02d(%03d)\n", iVersion.iMajor, iVersion.iMinor, iVersion.iBuild);
	Print(ELog,"Hardware version:        %08x\n",iHardware);
	Print(ELog,"Language Support:        %08x%08x\n",TUint32(iLanguage>>32),TUint32(iLanguage));
	Print(ELog,"Linear base address:     %08x\n",iRomBase); 
	Print(ELog,"Size:                    %08x\n",iRomSize); 
	Print(ELog,"Root directory list:     %08x\n",iRomRootDirectoryList);
	Print(ELog,"Kernel data address:     %08x\n",iKernDataAddress); 
 	Print(ELog,"Kernel limit:            %08x\n",iKernelLimit); 
 	Print(ELog,"Primary file address:    %08x\n",iPrimaryFile); 
 	Print(ELog,"Secondary file address:  %08x\n",iSecondaryFile);
 	Print(ELog,"First variant address:   %08x\n",iVariantFile);
 	Print(ELog,"First extension address: %08x\n",iExtensionFile);
 	Print(ELog,"Pageable ROM offset:     %08x\n",iPageableRomStart);
 	Print(ELog,"Pageable ROM size:       %08x\n",iPageableRomSize);
 	Print(ELog,"ROM page index offset:   %08x\n",iRomPageIndex);
 	Print(ELog,"Demand Paging Config:    minPages=%d maxPages=%d ageRatio=%d spare[0..2]=%d,%d,%d \n",iDemandPagingConfig.iMinPages,iDemandPagingConfig.iMaxPages,iDemandPagingConfig.iYoungOldRatio,iDemandPagingConfig.iSpare[0],iDemandPagingConfig.iSpare[1],iDemandPagingConfig.iSpare[2]);
	Print(ELog,"Checksum word:           %08x\n",iCheckSum);
	Print(ELog,"TotalSvDataSize:         %08x\n",iTotalSvDataSize);
	Print(ELog,"User data address:       %08x\n",iUserDataAddress); 
	Print(ELog,"TotalUserDataSize:       %08x\n",iTotalUserDataSize);
	Print(ELog,"Relocation Info Address: %08x\n",iRelocInfo);
	if(iRelocInfo)
		{
		TReloc* reloc=(TReloc*)RomToActualAddress(iRelocInfo);
		while(reloc->iLength)
			{
			Print(ELog,"  Src %08x  Dest %08x  Length %08x\n",
				  reloc->iSrc, reloc->iDest, reloc->iLength);
			reloc++;
			}
		}
				  
	TRomRootDirectoryList* pR=(TRomRootDirectoryList*)RomToActualAddress(iRomRootDirectoryList);
	Print(ELog,"\nRoot directories:\n");
	for (i=0; i<pR->iNumRootDirs; i++)
		{
		Print(ELog,"Directory %2d %08x %08x\n",i,pR->iRootDir[i].iHardwareVariant,pR->iRootDir[i].iAddressLin);
		}
	if (iRomExceptionSearchTable)
		{
		if(!iPageableRomSize) // Don't do this for Paged ROMs because of page compression
			DisplayExceptionTable(iRomExceptionSearchTable);
		}
	}
//

void E32Rom::FinaliseSectionHeader()
//
// Fill in the section header
//
	{

	if (iHeader->iRomSectionHeader)
		{
		// Set up the section header
		TRomSectionHeader *header=(TRomSectionHeader *)RomToActualAddress(iHeader->iRomSectionHeader);
		header->iVersion=iHeader->iVersion;
		header->iTime=iHeader->iTime;
		header->iLanguage=iHeader->iLanguage;
		header->iCheckSum=0;
		header->iCheckSum=0-HMem::CheckSum((TUint *)header, iHeader->iRomSize-(iHeader->iRomSectionHeader-iHeader->iRomBase));
		}
	}

//
void E32Rom::FinaliseExtensionHeader(MRomImage* aKernelRom)
	{
	TExtensionRomHeader* header = (TExtensionRomHeader*)iHeader;
	
	header->iVersion = iObey->iVersion;
	header->iTime = iObey->iTime;
	header->iRomBase = iObey->iRomLinearBase;
	header->iRomSize = iObey->iRomSize;

	header->iKernelVersion = aKernelRom->Version();
	header->iKernelTime = aKernelRom->Time();
	header->iKernelCheckSum = aKernelRom->CheckSum();

	header->iCheckSum=0;
	header->iCheckSum=0-HMem::CheckSum((TUint *)header, iObey->iRomSize);
	}

void E32Rom::DisplayExtensionHeader()
// 
// Display info from extension ROM header
//
	{

	TExtensionRomHeader* header = (TExtensionRomHeader*)iHeader;

	TVersion version = header->iVersion;
	Print(ELog,"\n\nExtension Rom details:\n");
	Print(ELog,"Version %d.%02d(%03d)  ", version.iMajor, version.iMinor, version.iBuild);
	version = header->iKernelVersion;
	Print(ELog,"(Kernel %d.%02d(%03d))\n", version.iMajor, version.iMinor, version.iBuild);
	Print(ELog,"Linear base address:     %08x\n",header->iRomBase); 
	Print(ELog,"Size:                    %08x\n",header->iRomSize); 
	Print(ELog,"Root directory list:     %08x\n",header->iRomRootDirectoryList);
	Print(ELog,"Checksum word:           %08x  (Kernel %08x)\n",header->iCheckSum, header->iKernelCheckSum);
	Print(ELog,"Exception Search Table:  %08x\n", header->iRomExceptionSearchTable);
	  
	if (header->iRomExceptionSearchTable)
		{
		DisplayExceptionTable(header->iRomExceptionSearchTable);
		}

	TRomRootDirectoryList* pR=(TRomRootDirectoryList*)RomToActualAddress(header->iRomRootDirectoryList);
	Print(ELog,"\nRoot directories:\n");
	TInt i;
	for (i=0; i<pR->iNumRootDirs; i++)
		{
		Print(ELog,"Directory %2d %08x %08x\n",i,pR->iRootDir[i].iHardwareVariant,pR->iRootDir[i].iAddressLin);
		}
	Print(ELog, "\n");
	}





