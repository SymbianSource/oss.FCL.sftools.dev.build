// Copyright (c) 2007-2010 Nokia Corporation and/or its subsidiary(-ies).
// All rights reserved.
// This component and the accompanying materials are made available
// under the terms of the License "Eclipse Public License v1.0"
// which accompanies this distribution, and is available
// at the URL "http://www.eclipse.org/legal/epl-v10.html".
//
// Initial Contributors:
// Nokia Corporation - initial contribution.
// 
// Contributors:
//
// Description:
//

#include <string.h>
#include <stdlib.h>

#include "h_utl.h"
#include "h_ver.h"

#include "r_global.h"
#include "r_rom.h"
#include "r_obey.h"
#include "parameterfileprocessor.h"

#include "r_dir.h"
#include "r_coreimage.h"
#include "logparser.h"

const TInt KRomLoaderHeaderNone=0;
const TInt KRomLoaderHeaderEPOC=1;
const TInt KRomLoaderHeaderCOFF=2;

static const TInt RombuildMajorVersion=2;
static const TInt RombuildMinorVersion=19;
static const TInt RombuildPatchVersion=1;
static TBool SizeSummary=EFalse;
static TPrintType SizeWhere=EAlways;
static string compareROMName = "";
static TInt MAXIMUM_THREADS = 128;
static TInt DEFAULT_THREADS = 8;
static string romlogfile = "ROMBUILD.LOG";

string filename;			// to store oby filename passed to Rombuild.
TBool reallyHelp=EFalse;
TInt gCPUNum = 0;
TInt gThreadNum = 0;
char* g_pCharCPUNum = NULL;
TBool gGenDepGraph = EFalse;
string gDepInfoFile = "";
TBool gGenSymbols = EFalse ;
TBool gGenBsymbols = EFalse ;
TBool gIsOBYUTF8 = EFalse;
static string loginput = "";
void PrintVersion() {
 	printf("\nROMBUILD - Rom builder");
  	printf(" V%d.%d.%d\n", RombuildMajorVersion, RombuildMinorVersion, RombuildPatchVersion);
  	printf(Copyright);
	}

char HelpText[] = 
	"Syntax: ROMBUILD [options] obeyfilename\n"
	"Option: -v verbose,  -?  \n"
	"        -type-safe-link  \n"
	"        -s[log|screen|both]           size summary\n"
	"        -r<FileName>                  compare a sectioned Rom image\n"
	"        -no-header                    suppress the image loader header\n"
	"        -gendep                       generate the dependence graph for paged part\n"
	"        -coff-header                  use a PE-COFF header rather than an EPOC header\n"
	"        -d<bitmask>                   set trace mask (DEB build only)\n"
	"        -compress[[=]paged|unpaged]   compress the ROM Image\n"
	"                                      without any argumentum compress both sections\n"
	"                                      paged 	compress paged section only\n"
	"                                      unpaged 	compress unpaged section only\n\n"	
	"        -j<digit>                     do the main job with <digit> threads\n"
	"        -symbols                      generate symbol file\n"
	"        -compressionmethod <method>   method one of none|inflate|bytepair to set the compression\n"
	"        -no-sorted-romfs              do not add sorted entries arrays (6.1 compatible)\n"
	"        -oby-charset=<charset> used character set in which OBY was written\n"
	"        -geninc                       to generate include file for licensee tools to use\n"			
	"        -loglevel<level>              level of information to log (valid levels are 0,1,2,3,4).\n" //Tools like Visual ROM builder need the host/ROM filenames, size & if the file is hidden.
	"        -wstdpath                     warn if destination path provided for a file is not a standard path\n"
	"        -argfile=<fileName>           specify argument-file name containing list of command-line arguments to rombuild\n"
	"        -lowmem                       use memory-mapped file for image build to reduce physical memory consumption\n"
	"        -coreimage=<core image file>  to pass the core image as input for extension ROM image generation\n"
	"        -k                            to enable keepgoing when duplicate files exist in oby\n"
	"        -logfile=<fileName>           specify log file\n"
    "        -loginput=<log filename>      specify as input a log file and produce as output symbol file.\n";


char ReallyHelpText[] =
	"Priorities:\n"
	"        low background foreground high windowserver\n"
	"        fileserver realtimeserver supervisor\n"
	"Languages:\n"
	"        Test English French German Spanish Italian Swedish Danish\n"
	"        Norwegian Finnish American SwissFrench SwissGerman Portuguese\n"
	"        Turkish Icelandic Russian Hungarian Dutch BelgianFlemish\n"
	"        Australian BelgianFrench\n"
	"Compression methods:\n"
	"        none     no compression on the individual executable image.\n"
	"        inflate  compress the individual executable image.\n"
	"        bytepair compress the individual executable image.\n"
	"Log Level:\n"
	"        0  produce the default logs\n"
	"        1  produce file detail logs in addition to the default logs\n"
	"        2  logs e32 header attributes(same as default log) in addition to the level 1 details\n";

void processParamfile(const string& aFileName);
//
// Process the command line arguments, printing a helpful message if none are supplied
//
void processCommandLine(int argc, char *argv[], TBool paramFileFlag=EFalse) {
 
	// If "-argfile" option is passed to Rombuild, then process the parameters
	// specified in parameter-file first and then the options passed from the 
	// command-line.
	string ParamFileArg("-argfile=");	
	if(paramFileFlag == EFalse) {
 		for (int count=1; count<argc; count++) {
 			string paramFile;
			if(strnicmp(argv[count],ParamFileArg.c_str(),ParamFileArg.length())==0) {
 				paramFile.assign(&argv[count][ParamFileArg.length()]);					
				processParamfile(paramFile);
			}
		}
	}	
	
	for (int i=1; i<argc; i++) { 	
#ifdef __LINUX__	
		if (argv[i][0] == '-') 
#else
		if ((argv[i][0] == '-') || (argv[i][0] == '/'))
#endif
		{ // switch
			char* arg = argv[i] + 1;
			if (stricmp(arg, "symbols") == 0)  
				gGenSymbols = ETrue; 
			else if (stricmp(arg, "v") == 0)
				H.iVerbose = ETrue;
			else if (stricmp(arg, "sl") == 0 || stricmp(arg, "slog") == 0) {
 				SizeSummary = ETrue;
				SizeWhere = ELog;
			}
			else if (stricmp(arg, "ss") == 0 || stricmp(arg, "sscreen") == 0) {
				SizeSummary = ETrue;
				SizeWhere = EScreen; 					
			}
			else if(stricmp(arg, "sb") == 0 || stricmp(arg, "sboth") == 0) {
				SizeSummary = ETrue;
				SizeWhere = EAlways; 					
			}
			else if (stricmp(arg, "gendep")==0)
				gGenDepGraph = ETrue;
			else if (stricmp(arg, "k")==0)
				gKeepGoing = ETrue;
			else if ('j' == *arg || 'J' == *arg) {
				if(arg[1])
					gThreadNum = atoi(arg + 1);
				else {
					Print(EWarning, "The option should be like '-j4'.\n");
					gThreadNum = 0;
				}
				if(gThreadNum <= 0 || gThreadNum > MAXIMUM_THREADS) {
					if(gCPUNum > 0 && gCPUNum <= MAXIMUM_THREADS) {
						Print(EWarning, "The number of concurrent jobs set by -j should be between 1 and 128. And the number of processors %d will be used as the number of concurrent jobs.\n", gCPUNum);
						gThreadNum = gCPUNum;
					}
					else if(g_pCharCPUNum) {
						Print(EWarning, "The number of concurrent jobs set by -j should be between 1 and 128. And the NUMBER_OF_PROCESSORS is invalid, so the default value %d will be used.\n", DEFAULT_THREADS);
						gThreadNum = DEFAULT_THREADS;
					}
					else {
						Print(EWarning, "The number of concurrent jobs set by -j should be between 1 and 128. And the NUMBER_OF_PROCESSORS is not available, so the default value %d will be used.\n", DEFAULT_THREADS);
						gThreadNum = DEFAULT_THREADS;
					}
				}	
			} 
			else if (strnicmp(argv[i],ParamFileArg.c_str(),ParamFileArg.length())==0) {
 				// If "-argfile" option is specified within parameter-file then process it 
				// otherwise ignore the option.
				if (paramFileFlag) {
 					string paramFile;
					paramFile.assign(&argv[i][ParamFileArg.length()]);		
					processParamfile(paramFile);
				}
				else {
 					continue;
				}
			}
			else if ('t' == *arg || 'T' == *arg)
				TypeSafeLink=ETrue;
			else if (*arg == '?')
				reallyHelp=ETrue;
			else if ('r' == *arg || 'R' == *arg)
				compareROMName.assign(arg + 1);
			else if (stricmp(arg, "no-header")==0)
				gHeaderType=KRomLoaderHeaderNone;
			else if (stricmp(arg, "epoc-header")==0)
				gHeaderType=KRomLoaderHeaderEPOC;
			else if (stricmp(arg, "coff-header")==0)
				gHeaderType=KRomLoaderHeaderCOFF;
			else if ((stricmp(arg, "compress")==0) || (strnicmp(arg, "compress=", 9)==0))
				{				
				if((stricmp(arg, "compress")==0) && ((i+1) >= argc || argv[i+1][0] == '-'))
					{
					// No argument, compress both parts with default compression method
					// un-paged part compressed by Deflate
					gCompressUnpaged = ETrue;
					gCompressUnpagedMethod = KUidCompressionDeflate;					
					// paged part compressed by the Bytepiar
					gEnableCompress=ETrue;
					gCompressionMethod = KUidCompressionBytePair;
					}
				else 
					{
					const int paraMaxLen = 20;
					char* parameter = new char[paraMaxLen];
					memset(parameter, 0, paraMaxLen);
					
					if(strncmp(arg, "compress=", 9)==0)
						{
						int paraLen = strlen(arg + 9);
						if (paraLen > paraMaxLen - 1)
							{
							delete[] parameter;
							parameter = new char[paraLen + 1];
							memset(parameter, 0, paraLen + 1);
							}
							
						memcpy(parameter, arg + 9, paraLen);
						}
					else
						{
						int paraLen = strlen(argv[++i]);
						if (paraLen > paraMaxLen - 1)
							{
							delete[] parameter;
							parameter = new char[paraLen + 1];
							memset(parameter, 0, paraLen + 1);
							}
						memcpy(parameter, argv[i], paraLen);
						}
					// An argument exists 
					if( stricmp(parameter, "paged") == 0)
						{
						gEnableCompress=ETrue;
						gCompressionMethod = KUidCompressionBytePair;	
						}	
					else if( stricmp(parameter, "unpaged") == 0)
						{
						gCompressUnpaged=ETrue;
						gCompressUnpagedMethod = KUidCompressionDeflate;	
						}	
					else {
  						Print (EError, "Unknown -compression argument! Set it to default (no compression)!");
 						gEnableCompress=EFalse;
						gCompressionMethod = 0;
						gCompressUnpaged = EFalse;
						gCompressUnpagedMethod = 0;					
						}
						
					delete[] parameter;
					}
				}	
			else if(strnicmp(argv[i], "-OBY-CHARSET=", 13) == 0)
			{
				if((stricmp(&argv[i][13], "UTF8")==0) || (stricmp(&argv[i][13], "UTF-8")==0))
					gIsOBYUTF8 = ETrue;
				else
					Print(EError, "Invalid encoding %s, default system internal encoding will be used.\n", &argv[i][13]);
			}
			else if( stricmp(arg, "compressionmethod") == 0 ) {
 				// next argument should be a method
				if( (i+1) >= argc || argv[i+1][0] == '-') {
 					Print (EError, "Missing compression method! Set it to default (no compression)!");
					gEnableCompress=EFalse;
					gCompressionMethod = 0;
					}
				else  {
 					i++; 
					if( stricmp(argv[i], "inflate") == 0) {
 						gEnableCompress=ETrue;
						gCompressionMethod = KUidCompressionDeflate;	
						}	
					else if( stricmp(argv[i], "bytepair") == 0) {
 						gEnableCompress=ETrue;
						gCompressionMethod = KUidCompressionBytePair;	
						}	
					else {
  						if( stricmp(argv[i], "none") != 0) {
  							Print (EError, "Unknown compression method! Set it to default (no compression)!");
 							}
 						gEnableCompress=EFalse;
						gCompressionMethod = 0;
						}
					}
					
				}
			else if (stricmp(arg, "no-sorted-romfs")==0)
				gSortedRomFs=EFalse;
			else if (stricmp(arg, "geninc")==0)				
				gGenInc=ETrue;
 			else if (stricmp(arg, "wstdpath")==0)			// Warn if destination path provided for a file		
 				gEnableStdPathWarning=ETrue;					// is not a standard path as per platsec
			else if( stricmp(arg, "loglevel") == 0) {
 				// next argument should a be loglevel
				if( (i+1) >= argc || argv[i+1][0] == '-') {
 					Print (EError, "Missing loglevel!");
					gLogLevel = DEFAULT_LOG_LEVEL;
					}
				else {
 					i++;
					if (stricmp(argv[i], "4") == 0)
						gLogLevel = (LOG_LEVEL_FILE_DETAILS | LOG_LEVEL_FILE_ATTRIBUTES | LOG_LEVEL_COMPRESSION_INFO | LOG_LEVEL_SMP_INFO);
					else if (stricmp(argv[i], "3") == 0)
						gLogLevel = (LOG_LEVEL_FILE_DETAILS | LOG_LEVEL_FILE_ATTRIBUTES | LOG_LEVEL_COMPRESSION_INFO);
					else if (stricmp(argv[i], "2") == 0)
						gLogLevel = (LOG_LEVEL_FILE_DETAILS | LOG_LEVEL_FILE_ATTRIBUTES);
					else if (stricmp(argv[i], "1") == 0)
						gLogLevel = LOG_LEVEL_FILE_DETAILS;
					else if (stricmp(argv[i], "0") == 0)
						gLogLevel = DEFAULT_LOG_LEVEL;
					else
						Print(EError, "Only loglevel 0, 1, 2, 3 or 4 is allowed!");
					}
				}
			else if( stricmp(arg, "loglevel4") == 0)
				gLogLevel = (LOG_LEVEL_FILE_DETAILS | LOG_LEVEL_FILE_ATTRIBUTES | LOG_LEVEL_COMPRESSION_INFO | LOG_LEVEL_SMP_INFO);
			else if( stricmp(arg, "loglevel3") == 0)
				gLogLevel = (LOG_LEVEL_FILE_DETAILS | LOG_LEVEL_FILE_ATTRIBUTES | LOG_LEVEL_COMPRESSION_INFO);
			else if( stricmp(arg, "loglevel2") == 0)
				gLogLevel = (LOG_LEVEL_FILE_DETAILS | LOG_LEVEL_FILE_ATTRIBUTES);
			else if( stricmp(arg, "loglevel1") == 0)
				gLogLevel = LOG_LEVEL_FILE_DETAILS;
			else if( stricmp(arg, "loglevel0") == 0)
				gLogLevel = DEFAULT_LOG_LEVEL;
			else if ('d' == *arg || 'D' == *arg) {
 				TraceMask=strtoul(arg+1, 0, 0);
				}
			else if (stricmp(arg, "lowmem") == 0)
				gLowMem = ETrue;
			else if (strnicmp(arg, "coreimage=",10) ==0) {
 				if(argv[i][11])	 {
 					gUseCoreImage = ETrue; 
					gImageFilename.assign(arg + 10);	
				}
				else {
 					Print (EError, "Core ROM image file is missing\n"); 
				}
			}
			else if (strnicmp(arg, "logfile=",8) ==0) {
				romlogfile = arg + 8;
			}
			else if (strnicmp(arg, "loginput=",9) ==0) {
				loginput = arg + 9;
			}
			else 
#ifdef WIN32
				cout << "Unrecognised option " << argv[i] << "\n";
#else
				if(0 == access(argv[i],R_OK)){
					filename.assign(argv[i]);
				}
				else {
					cout << "Unrecognised option " << argv[i] << "\n";
				}
#endif		
			}	
		else // Must be the obey filename
			filename.assign(argv[i]);
		}
	if (paramFileFlag)
		return;
	if (filename.empty() && loginput.empty()) {
 		PrintVersion();
		cout << HelpText;
		if (reallyHelp) {
 			ObeyFileReader::KeywordHelp();
			cout << ReallyHelpText;
			}
		else
			Print(EError, "Obey filename is missing\n");
		}	
	}

/**
Function to process parameter-file. 

@param aFileName parameter-file name.
*/
void processParamfile(const string& aFileName) {
 	CParameterFileProcessor parameterFile(aFileName);
	
	// Invoke fuction "ParameterFileProcessor" to process parameter-file.
	if(parameterFile.ParameterFileProcessor()) {
 		TUint noOfParameters = parameterFile.GetNoOfArguments();
		char** parameters = parameterFile.GetParameters();
		TBool paramFileFlag=ETrue;
		
		// Invoke function "processCommandLine" to process parameters read from parameter-file.
		processCommandLine(noOfParameters, parameters, paramFileFlag);
	}	
}

void GenerateIncludeFile(const char* aRomName, TInt aUnpagedSize, TInt aPagedSize ) {
 	
 
	string incFileName(aRomName);
	int pos = -1 ;
	for(int i = incFileName.length() - 1 ; i >= 0 ; i--){
		char ch = incFileName[i];
		if(ch == '/' || ch == '\\') 
			break ;
		else if(ch == '.'){
			pos = i ;
			break ;
		}		
	}	
	if(pos > 0)
		incFileName.erase(pos,incFileName.length() - pos);
	incFileName += ".inc"; 
	
	ofstream incFile(incFileName.c_str(),ios_base::trunc + ios_base::out);
	if(!incFile.is_open()) {
 		Print(EError,"Cannot open include file %s for output\n", incFileName.c_str());		
	}
	else {
 		const char incContent[] = 
					"/** Size of the unpaged part of ROM.\n"
	    			"This part is at the start of the ROM image. */\n"
					"#define SYMBIAN_ROM_UNPAGED_SIZE 0x%08x\n"
					"\n"
					"/** Size of the demand paged part of ROM.\n"
	    			"This part is stored immediately after the unpaged part in the ROM image. */\n"
					"#define SYMBIAN_ROM_PAGED_SIZE 0x%08x\n";
		// for place of two hex representated values and '\0'
		char* temp = new char[sizeof(incContent)+ 20]; 		
		size_t len = sprintf(temp,incContent, aUnpagedSize, aPagedSize);
		incFile.write(temp, len);		
		incFile.close();
		delete[]  temp;
	} 		
}

int main(int argc, char *argv[])  {
	TInt r = 0;
#ifdef __LINUX__
	gCPUNum = sysconf(_SC_NPROCESSORS_CONF);
#else
	g_pCharCPUNum = getenv("NUMBER_OF_PROCESSORS");
	if(g_pCharCPUNum != NULL)
		gCPUNum = atoi(g_pCharCPUNum);
#endif		
	// initialise set of all capabilities
	ParseCapabilitiesArg(gPlatSecAllCaps, "all");

 	processCommandLine(argc, argv);
 	if(filename.empty() && loginput.empty())
   		return KErrGeneral;
		

    if(gThreadNum == 0) {
 		if(gCPUNum > 0 && gCPUNum <= MAXIMUM_THREADS) {
 			printf("The double number of processors (%d) is used as the number of concurrent jobs.\n", gCPUNum * 2);
			gThreadNum = gCPUNum * 2;
		}
		else if(g_pCharCPUNum) {
 			printf("The NUMBER_OF_PROCESSORS is invalid, and the default value %d will be used.\n", DEFAULT_THREADS);
			gThreadNum = DEFAULT_THREADS;
		}
		else {
 			printf("The NUMBER_OF_PROCESSORS is not available, and the default value %d will be used.\n", DEFAULT_THREADS);
			gThreadNum = DEFAULT_THREADS;
		}
	} 
	PrintVersion();
	
	if(loginput.length() >= 1)
	{
		try
		{
			LogParser::GetInstance(ERomImage)->ParseSymbol(loginput.c_str());
		}
		catch(LoggingException le)
		{
			printf("ERROR: %s\r\n", le.GetErrorMessage());
			return 1;
		}
		return 0;
	}
	if (romlogfile[romlogfile.size()-1] == '\\' || romlogfile[romlogfile.size()-1] == '/')
		romlogfile += "ROMBUILD.LOG";
 	H.SetLogFile(romlogfile.c_str());
	ObeyFileReader *reader=new ObeyFileReader(filename.c_str());
	if (!reader->Open()) {
 		delete reader;
		return KErrGeneral;
	}
	
	E32Rom* kernelRom=0;		// for image from obey file
	CoreRomImage *core= 0;		// for image from core image file
	MRomImage* imageInfo=0;
	CObeyFile *mainObeyFile=new CObeyFile(*reader);

	// need check if obey file has coreimage keyword
	char* file = mainObeyFile->ProcessCoreImage();
	if (file) {
 		// hase coreimage keyword but only use if command line option
		// for coreimage not already selected
		if (!gUseCoreImage) {
 			gUseCoreImage = ETrue;
			gImageFilename = file;
		}	 
		delete []file ;
	}

	if (!gUseCoreImage) {
 		r=mainObeyFile->ProcessKernelRom();
		if (r==KErrNone) {
 				// Build a kernel ROM using the description compiled into the
				// CObeyFile object
				
				kernelRom = new E32Rom(mainObeyFile);
				if (kernelRom == 0 || kernelRom->iData == 0)
					return KErrNoMemory;
				
				r=kernelRom->Create();
				if (r!=KErrNone) {
 					delete kernelRom;
					delete mainObeyFile;
					return r;
				}
				if (SizeSummary)
					kernelRom->DisplaySizes(SizeWhere);
				
				r=kernelRom->WriteImages(gHeaderType);
				if (r!=KErrNone) {
 					delete kernelRom;
					delete mainObeyFile;
					return r;
				}
				
				if (compareROMName.length() > 0 ) {
 					r=kernelRom->Compare(compareROMName.c_str(), gHeaderType);
					if (r!=KErrNone) {
 						delete kernelRom;
						delete mainObeyFile;
						return r;
					}
				}
				imageInfo = kernelRom;
				mainObeyFile->Release();
		}
		else if (r!=KErrNotFound)
			return r;
	}
	else {
 		// need to use core image
		core = new CoreRomImage(gImageFilename.c_str());
		if (!core) {
 			return KErrNoMemory;
		}
		if (!core->ProcessImage(gLowMem)) {
 			delete core;
			delete mainObeyFile;
			return KErrGeneral;
		}
		
		NumberOfVariants = core->VariantCount();
		TVariantList::SetNumVariants(NumberOfVariants);
		TVariantList::SetVariants(core->VariantList());
		
		core->SetRomAlign(mainObeyFile->iRomAlign);
		core->SetDataRunAddress(mainObeyFile->iDataRunAddress);

		gCompressionMethod = core->CompressionType();
		if(gCompressionMethod) {
 			gEnableCompress = ETrue;
		}
		
		imageInfo = core;
		if(!mainObeyFile->SkipToExtension()) {
 			delete core;
			delete mainObeyFile;
			return KErrGeneral;
		}
	}
	
	if(gGenInc) {
 		
		if(kernelRom != NULL) {
			Print(EAlways,"Generating include file for ROM image post-processors ");
			if( gPagedRom ) {
 				Print(EAlways,"Paged ROM");
				GenerateIncludeFile((char*)mainObeyFile->iRomFileName, kernelRom->iHeader->iPageableRomStart, kernelRom->iHeader->iPageableRomSize);
			}
			else {
 				Print(EAlways,"Unpaged ROM");
				int headersize=(kernelRom->iExtensionRomHeader ? sizeof(TExtensionRomHeader) : sizeof(TRomHeader)) - sizeof(TRomLoaderHeader);
				GenerateIncludeFile((char*)mainObeyFile->iRomFileName, kernelRom->iHeader->iCompressedSize + headersize, kernelRom->iHeader->iPageableRomSize);
			}
		}
		else {
			Print(EWarning,"Generating include file for ROM image igored because no Core ROM image generated.\n");
		}
	}
	
	do {
 		CObeyFile* extensionObeyFile = 0;
		E32Rom* extensionRom = 0;

		extensionObeyFile = new CObeyFile(*reader);
		r = extensionObeyFile->ProcessExtensionRom(imageInfo);
		if (r==KErrEof) {
 			delete imageInfo;
			delete mainObeyFile;
			delete extensionObeyFile;
			return KErrNone;
		}
		if (r!=KErrNone) {
 			delete extensionObeyFile;
			break;
		}
		
		extensionRom = new E32Rom(extensionObeyFile);
		r=extensionRom->CreateExtension(imageInfo);
		if (r!=KErrNone) {
 			delete extensionRom;
			delete extensionObeyFile;
			break;
		}
		if (SizeSummary)
			extensionRom->DisplaySizes(SizeWhere);
		
		r=extensionRom->WriteImages(0);		// always a raw image
		
		delete extensionRom;
		delete extensionObeyFile;
	}
	while (r==KErrNone);

	delete imageInfo;
	delete mainObeyFile;
 
	return r;
}
