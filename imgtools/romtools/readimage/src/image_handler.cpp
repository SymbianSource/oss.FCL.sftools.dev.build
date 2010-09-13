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


#include "image_handler.h"
#include "r_obey.h"
#include "r_romnode.h"
#include "r_coreimage.h"
#include "rofs_image_reader.h"
#include "rom_image_reader.h"
#include "e32_image_reader.h"
#include "e32rom.h"
#include "h_ver.h"
#include "sis2iby.h"
#include <time.h>

ECompression gCompress=ECompressionUnknown;
ostream *out = &cout;
string ImageReader::iE32ImgFileName = "";
string ImageReader::iZdrivePath = "";
string ImageReader::iLogFileName = "";
string ImageReader::iPattern = "";

string SisUtils::iOutputPath = ".";
string SisUtils::iExtractPath = ".";

TBool gIsOBYUTF8 = EFalse;
ImageHandler::ImageHandler() : iReader(NULL) ,iOptions(0), iSisUtils(NULL) {
}

ImageHandler::~ImageHandler() {
	if(iReader)
		delete iReader;

	if(iSisUtils)
		delete iSisUtils;
}


void ImageHandler::ProcessArgs(int argc, char*argv[]) {
	if( argc < 2) {
		throw ImageReaderUsageException("", "");
	}

	bool aOutFileGiven = false;
	int index = 1; 
	
	while( argc > index ) {
		char* arg = argv[index]; 
		if(arg[0] == '-') {
			switch(0x20 | arg[1]) {
			case 'd': 
				//dump header info
				iOptions |= DUMP_HDR_FLAG;
				break;
			case 'e': 
				iOptions |= DUMP_E32_IMG_FLAG; 
				++index ;
				if(index < argc) {
					arg = argv[index];
					ImageReader::iE32ImgFileName = string(arg);
				}
				else 
					throw ImageReaderUsageException("Usage error", arg);
				
				break;
			case 'h': 
				PrintUsage();
				exit(EXIT_SUCCESS);
			case 'o':  
				if(arg[2]) {
					if((stricmp(arg,"-OUTDIR")==0)) {
						++index;
						if(index < argc) {
							arg = argv[index];
							SisUtils::iOutputPath = string(arg);
						}
						else
							throw ImageReaderUsageException("Usage Error", arg); 
					}
					else
						throw ImageReaderUsageException("Usage Error", arg);
				}
				else {
					aOutFileGiven = true;
					++index;				
					if( index < argc ) {
						// unless using iOutFile.c_str() immediately after 
						// iOutFile = argv[index+1];
						// iOutFile will not be assign correctly,
						// is it a defect of gcc 3.4.5 ? 
						arg = argv[index];
						iOutFile = string(arg); 
					}
					else
						throw ImageReaderUsageException("Usage Error", arg); 
				}
				 
				break;
			case 'r': 				 
				if(arg[2])
					throw ImageReaderUsageException("Usage Error", arg);
				iOptions |= RECURSIVE_FLAG;				 
				break;
			case 's': 				
				if(arg[2]) {
					if(stricmp(arg,"-SIS2IBY")==0) {
						iOptions |= MODE_SIS2IBY;
					}
					else
						throw ImageReaderUsageException("Usage Error", arg);
				}
				else
					iOptions |= DUMP_DIR_ENTRIES_FLAG;
				
				break;
			case 't': 				 
				if((stricmp(argv[index],"-TMPDIR")==0)) {
					++index;
					if( index < argc ) {  
						arg = argv[index];
						SisUtils::iExtractPath = string(arg);
					}
					else
						throw ImageReaderUsageException("Usage Error", arg); 
				}
				else
					throw ImageReaderUsageException("Usage Error", arg);
				 
				break;
			case 'v':  
				if(arg[2])
					throw ImageReaderUsageException("Usage Error", arg);
				iOptions |= DUMP_VERBOSE_FLAG; 
				break;
			case 'l': 
				++index;
				if(index < argc) {
					arg = argv[index];
					ImageReader::iLogFileName = string(arg);
				}
				else
					throw ImageReaderUsageException("Usage error", arg);
				iOptions |= LOG_IMAGE_CONTENTS_FLAG;
				 
				break;
			case 'x': 
				++index;
				if(index < argc && 0 == arg[2]) {
					arg = argv[index];
					ImageReader::iPattern = string(arg);
				}
				else
					throw ImageReaderUsageException("Usage error", arg);

				iOptions |= EXTRACT_FILE_SET_FLAG; 
				 
				break;
			case 'z': 
				++index;
				if(index < argc ){
					arg = argv[index];
					ImageReader::iZdrivePath = string(arg);
				}
				else
					throw ImageReaderUsageException("Usage error", arg);					
				iOptions |= EXTRACT_FILES_FLAG; 
				
				break;
			default:
				throw ImageReaderUsageException("Invalid command", arg);
				break;
			}
		}
		else {
			if(!iInputFileName.empty()) {
				throw ImageReaderUsageException("Invalid command", "Multiple input file not supported");
			}

			SetInputFile(string(arg));
		}
		index++;
	}

	if( aOutFileGiven && !(iOptions & MODE_SIS2IBY) ) {
		ofstream* rdout = new ofstream(iOutFile.c_str(), ios_base::out | ios_base::trunc);
		if( !rdout->is_open()){
			delete rdout ;
			rdout = NULL ;
			throw ImageReaderException(iOutFile.c_str(), "Unable to open File");
		}
		out = rdout ;
	}

	// Disable -z option if -x option is passed
	if( (iOptions & EXTRACT_FILE_SET_FLAG) && (iOptions & EXTRACT_FILES_FLAG) ) {
		iOptions &= ~(EXTRACT_FILES_FLAG);
	}

	// -r option should be used along with -x option
	if( (iOptions & RECURSIVE_FLAG) && !(iOptions & EXTRACT_FILE_SET_FLAG) ) {
		throw ImageReaderUsageException("Usage error", "-r should be used with -x");
	}
}

EImageType ImageHandler::ReadMagicWord() {
	ifstream file(iInputFileName.c_str(), ios_base::in | ios_base::binary );
	
	EImageType retVal = EUNKNOWN_IMAGE;

	if( !file.is_open() ) {
		throw ImageReaderException(iInputFileName.c_str(), "Cannot open file ");
	}

	TUint8 magicWords[16];
	file.read(reinterpret_cast<char*>(magicWords),16);

	if(0 == memcmp(magicWords,"ROFS",4)) {		 
		retVal = EROFS_IMAGE; 			
	}else if(0 == memcmp(magicWords,"ROFx",4)) {
		retVal = EROFX_IMAGE;
	}
	else if(0 == memcmp(magicWords,"EPOC",4) && 0 == memcmp(&magicWords[8],"ROM",3) ) {		 
		retVal = EROM_IMAGE; 
	}
	else {
		E32ImageFile	aE32;
		TUint32			aSz;
		file.seekg(0,ios_base::end);
		aSz = file.tellg();
		file.seekg(0,ios_base::beg);			 
		aE32.Adjust(aSz);
		aE32.iFileSize = aSz;
		file  >> aE32;
	
		if(aE32.iError == KErrNone){
			retVal = EE32_IMAGE;
		}
		else {
			TExtensionRomHeader exRomHeader;
			file.seekg(0, ios_base::beg);
			file.read(reinterpret_cast<char*>(&exRomHeader), sizeof(TExtensionRomHeader));
			TUint zeroTime = time(0);
			// aExtensionRomHeader.iTime and aExtensionRomHeader.iKernelTime are 
			// in microseconds. So convert them to seconds and see if these are 
			// valid times e.g. a time(in seconds) after midnight Jan 1st, 1970
			TUint imgTime = exRomHeader.iTime / 1000000;
			TUint kernImgTime = exRomHeader.iKernelTime / 1000000;
			if( imgTime >= zeroTime && kernImgTime >= zeroTime) {
				//Check if the padding in the header has value 0xff
				retVal = EROMX_IMAGE;
				for(int i = sizeof(exRomHeader.iPad) - 1 ; i >= 0 ; i--){
					if(0xff != exRomHeader.iPad[i]){
						retVal = EUNKNOWN_IMAGE;
						break ;
					}
				}  
			}
		}		 
	}   
	
	if(retVal == EUNKNOWN_IMAGE){
		file.seekg(0,ios_base::beg);
        retVal = ReadBareImage(file);
	}

	file.close();

	return retVal;
}


/**
 * @fn ImageHandler::ReadBareImage
 * @brief this function processes image type under the condition of that if an image is given without header which means the image is not self-described
 * @return type of the image.
 * @note this function is introduced for handling issues raised by DEF129908
 */
EImageType ImageHandler::ReadBareImage(ifstream& aIfs) {
    TRomHeader romHdr ; 
    aIfs.read(reinterpret_cast<char*>(&romHdr),sizeof(TRomHeader)); 

    return ((romHdr.iRomBase >= KRomBase ) && 
		(romHdr.iRomRootDirectoryList > KRomBase ) &&
       (romHdr.iRomBase < KRomBaseMaxLimit ) && 
	   (romHdr.iRomRootDirectoryList < KRomBaseMaxLimit)) ? EBAREROM_IMAGE : EUNKNOWN_IMAGE;
     
}


void ImageHandler::HandleInputFiles() {
	if(!(iOptions & MODE_SIS2IBY)) {
		EImageType imgType = ReadMagicWord();
		
		switch(imgType)
		{
		case EROFS_IMAGE:
		case EROFX_IMAGE:
			iReader = new RofsImageReader(iInputFileName.c_str());
			break;
		case EROM_IMAGE:
			iReader = new RomImageReader(iInputFileName.c_str());
			break;
        case EBAREROM_IMAGE:
            iReader = new RomImageReader(iInputFileName.c_str(), EBAREROM_IMAGE);
            break;
		case EROMX_IMAGE:
			iReader = new RomImageReader(iInputFileName.c_str(), EROMX_IMAGE);
			break;
		case EE32_IMAGE:
			iReader = new E32ImageReader(iInputFileName.c_str());
			break;
		default:
			{
            throw ImageReaderException(iInputFileName.c_str(), "Unknown Type of Image file");
			}
			break;
		}

		if(iReader) {
			iReader->ReadImage();
			iReader->ProcessImage();
			iReader->Validate();
			iReader->SetDisplayOptions( iOptions );
			iReader->ExtractImageContents();
			iReader->Dump();
		}
	}
	else {
		if(iInputFileName.empty()) {
			throw SisUtilsException("Usage Error", "No SIS file passed");
		}

		iSisUtils = new Sis2Iby(iInputFileName.c_str());

		if(iSisUtils) {
			if(iOptions & DUMP_VERBOSE_FLAG) {
				iSisUtils->SetVerboseMode();
			}

			iSisUtils->ProcessSisFile();
			iSisUtils->GenerateOutput();
		}
		else {
			throw SisUtilsException("Error:", "Cannot create Sis2Iby object");
		}
	}
}

void ImageHandler::PrintVersion() {
	*out << "\nReadimage - reader for Rom, Rofs and E32 images V";
	out->width(1);
	*out << MajorVersion << ".";
	out->width(2);
	out->fill('0');
	*out << MinorVersion << " (";
	out->width(3);
	*out << Build  << ") " << endl;
	*out << Copyright;
}

void ImageHandler::PrintUsage() {
	PrintVersion();
	const char aUsage[] = 
		"Usage: readImage [options] [<-sis2iby> [sis-options]] <filename>\n\n"
		"Options: With no options, it prints the files and directories in image\n"
		"       -o      output file name\n"
		"       -d      dump header information(default)\n"
		"       -s      dump the directory structure\n"
		"       -v      dump image headers and directory structure\n"
		"       -e xxx  dump the xxx e32 image within the entire image when used along with -v or -s option\n"
		"       -h      this message\n"
		"       -z xxx  extract all the file(s) from the given image to xxx location\n"
		"       -l xxx  log the image contents on to xxx file\n"
		"       -x xxx  extract single or set of files as given in xxx from the given image\n"
		"       -r      recursively extract files from the sub-directories when used along with -x option\n\n"
		"SIS-options: Option -sis2iby changes the mode to generate IBY from SIS file\n"
		"       -sis2iby      generates iby file for the given SIS file\n"
		"       -tmpdir xxx   extract all sis file contents to xxx location\n"
		"       -outdir xxx   generates the iby file(s) to xxx location\n"
		"       -v            verbose output\n";
	*out << aUsage << endl;
}

int main(int argc, char* argv[]) {
	ImageHandler aIh;
	int retVal = EXIT_SUCCESS;
	try {
		aIh.ProcessArgs(argc, argv);
		aIh.HandleInputFiles();
	}
	catch(ImageReaderUsageException& aIre) {
		if(argc >= 2) {
			//This is a usage error and has to be reported
			//Otherwise, it is called just to display the usage
			aIre.Report();
		}
		aIh.PrintUsage();
		retVal = EXIT_FAILURE;
	}
	catch(ImageReaderException& aIre) {
		aIre.Report();
		retVal = EXIT_FAILURE;
	}
	catch(SisUtilsException& aSUe) {
		aSUe.Report();
		retVal = EXIT_FAILURE;
	}
	
	if(out != &cout){
		ofstream* rdout = static_cast<ofstream*>(out) ;
		rdout->close() ;
		delete rdout ; 
	}

	return retVal;
}
