/*
* Copyright (c) 2005-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* @internalComponent 
* @released
*
*/


#include "e32_image_reader.h"

E32ImageReader::E32ImageReader(const char* aFile):ImageReader(aFile)
{
}

E32ImageReader::E32ImageReader():ImageReader("")
{
}


E32ImageReader::~E32ImageReader()
{
	delete iE32Image;
}

void E32ImageReader::ReadImage()
{
	ifstream aIf(iImgFileName.c_str(), ios_base::binary | ios_base::in);
	if( !aIf.is_open() )
	{
		throw ImageReaderException(iImgFileName.c_str(), "Cannot open file ");
	}

	iE32Image = new E32ImageFile();

	TUint32			aSz;

	aIf.seekg(0,ios_base::end);
	aSz = aIf.tellg();

	iE32Image->Adjust(aSz);
	iE32Image->iFileSize = aSz;

	aIf.seekg(0,ios_base::beg);
	aIf >> *iE32Image;
}

void E32ImageReader::Validate()
{
}

void E32ImageReader::ProcessImage()
{
}

void E32ImageReader::Dump()
{
	*out << "Image Name................." << iImgFileName.c_str() << endl;
	DumpE32Attributes(*iE32Image);
}

void E32ImageReader::DumpE32Attributes(E32ImageFile& aE32Image)
{
	bool aContinue = true;

	DumpInHex("Size", aE32Image.iSize ) << endl;
	DumpInHex("Uids",aE32Image.iOrigHdr->iUid1);
	DumpInHex(" ",aE32Image.iOrigHdr->iUid2, aContinue);
	DumpInHex(" ",aE32Image.iOrigHdr->iUid3, aContinue);
	DumpInHex(" ",aE32Image.iOrigHdr->iUidChecksum, aContinue) << endl;

	
	DumpInHex("Entry point", aE32Image.iOrigHdr->iEntryPoint ) << endl;
	DumpInHex("Code start addr" ,aE32Image.iOrigHdr->iCodeBase)<< endl;
	DumpInHex("Data start addr" ,aE32Image.iOrigHdr->iDataBase) << endl;
	DumpInHex("Text size" ,aE32Image.iOrigHdr->iTextSize) << endl;
	DumpInHex("Code size" ,aE32Image.iOrigHdr->iCodeSize) << endl;
	DumpInHex("Data size" ,aE32Image.iOrigHdr->iDataSize) << endl;
	DumpInHex("Bss size" ,aE32Image.iOrigHdr->iBssSize) << endl;
	DumpInHex("Total data size" ,(aE32Image.iOrigHdr->iBssSize + aE32Image.iOrigHdr->iDataSize)) << endl;
	DumpInHex("Heap min" ,aE32Image.iOrigHdr->iHeapSizeMin) << endl;
	DumpInHex("Heap max" ,aE32Image.iOrigHdr->iHeapSizeMax) << endl;
	DumpInHex("Stack size" ,aE32Image.iOrigHdr->iStackSize) << endl;
	DumpInHex("Export directory" ,aE32Image.iOrigHdr->iExportDirOffset) << endl;
	DumpInHex("Export dir count" ,aE32Image.iOrigHdr->iExportDirCount) << endl;
	DumpInHex("Flags" ,aE32Image.iOrigHdr->iFlags) << endl;

	TUint aHeaderFmt = E32ImageHeader::HdrFmtFromFlags(aE32Image.iOrigHdr->iFlags);

	if (aHeaderFmt >= KImageHdrFmt_V)
	{
		//
		// Important. Don't change output format of following security info
		// because this is relied on by used by "Symbian Signed".
		//
		E32ImageHeaderV* v = aE32Image.iHdr;
		DumpInHex("Secure ID", v->iS.iSecureId) << endl;
		DumpInHex("Vendor ID", v->iS.iVendorId) << endl;
		DumpInHex("Capability", v->iS.iCaps[1]);
		DumpInHex(" ", v->iS.iCaps[0], aContinue) << endl;

	}

	*out << "Tools Version..............." << dec << (TUint)aE32Image.iOrigHdr->iToolsVersion.iMajor;
	*out << ".";
	out->width (2);
	*out << dec << (TUint)aE32Image.iOrigHdr->iToolsVersion.iMinor ;
	*out << "(" << dec << aE32Image.iOrigHdr->iToolsVersion.iBuild << ")" << endl;

	*out << "Module Version.............." << dec << (aE32Image.iOrigHdr->iModuleVersion >> 16) << endl;
	DumpInHex("Compression", aE32Image.iOrigHdr->iCompressionType) << endl;

	if( aHeaderFmt >= KImageHdrFmt_V )
	{
		E32ImageHeaderV* v = aE32Image.iHdr;
		DumpInHex("Exception Descriptor", v->iExceptionDescriptor) << endl;
		DumpInHex("Code offset", v->iCodeOffset) << endl;
	}

	*out << "Priority...................." << dec << aE32Image.iOrigHdr->iProcessPriority << endl;
	DumpInHex("Dll ref table size", aE32Image.iOrigHdr->iDllRefTableCount) << endl << endl << endl;
}
