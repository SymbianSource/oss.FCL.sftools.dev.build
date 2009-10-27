// Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
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

const TInt KRomLoaderHeaderNone=0;
const TInt KRomLoaderHeaderEPOC=1;
const TInt KRomLoaderHeaderCOFF=2;

static const TInt RombuildMajorVersion=2;
static const TInt RombuildMinorVersion=14;
static const TInt RombuildPatchVersion=0;
static TBool SizeSummary=EFalse;
static TPrintType SizeWhere=EAlways;
static char *CompareRom=NULL;
static TInt MAXIMUM_THREADS = 128;
static TInt DEFAULT_THREADS = 8;

string filename;			// to store oby filename passed to Rombuild.
TBool reallyHelp=EFalse;
TInt gCPUNum = 0;
TInt gThreadNum = 0;
char* g_pCharCPUNum = NULL;
TBool gGenDepGraph = EFalse;
char* gDepInfoFile = NULL;

void PrintVersion()
	{
	Print(EAlways,"\nROMBUILD - Rom builder");
  	Print(EAlways, " V%d.%d.%d\n", RombuildMajorVersion, RombuildMinorVersion, RombuildPatchVersion);
  	Print(EAlways,Copyright);
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
	"									   without any argumentum compress both sections\n"
	"									   paged 	compress paged section only\n"
	"									   unpaged 	compress unpaged section only\n"	
	"        -fastcompress  compress files with faster bytepair and tradeoff of compress ratio\n"
	"        -j<digit> do the main job with <digit> threads\n"
	"        -compressionmethod <method>   method one of none|inflate|bytepair to set the compression\n"
	"        -no-sorted-romfs              do not add sorted entries arrays (6.1 compatible)\n"
	"        -geninc                       to generate include file for licensee tools to use\n"			// DEF095619
	"        -loglevel<level>              level of information to log (valid levels are 0,1,2,3,4).\n" //Tools like Visual ROM builder need the host/ROM filenames, size & if the file is hidden.
	"        -wstdpath                     warn if destination path provided for a file is not a standard path\n"
	"        -argfile=<fileName>           specify argument-file name containing list of command-line arguments to rombuild\n"
	"        -lowmem                       use memory-mapped file for image build to reduce physical memory consumption\n"
	"        -coreimage=<core image file>  to pass the core image as input for extension ROM image generation\n";


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

void processParamfile(string aFileName);

void processCommandLine(int argc, char *argv[], TBool paramFileFlag=EFalse)
//
// Process the command line arguments, printing a helpful message if none are supplied
//
	{

	// If "-argfile" option is passed to Rombuild, then process the parameters
	// specified in parameter-file first and then the options passed from the 
	// command-line.
	string ParamFileArg("-ARGFILE=");	
	if(paramFileFlag == EFalse)
	{	
		for (int count=1; count<argc; count++)
		{
			string paramFile;
			strupr(argv[count]);
			if(strncmp(argv[count],ParamFileArg.c_str(),ParamFileArg.length())==0)
			{
				paramFile.assign(&argv[count][ParamFileArg.length()]);					
				processParamfile(paramFile);
			}
		}
	}	
	
	for (int i=1; i<argc; i++)
		{
		strupr(argv[i]);
		if ((argv[i][0] == '-') || (argv[i][0] == '/'))
			{ // switch
			if (argv[i][1] == 'V')
				H.iVerbose = ETrue;
			else if (argv[i][1] == 'S')
				{
				SizeSummary=ETrue;
				if (argv[i][2] == 'L')
					SizeWhere=ELog;
				if (argv[i][2] == 'S')
					SizeWhere=EScreen;
				}
			else if (strcmp(argv[i], "-FASTCOMPRESS")==0)
				gFastCompress = ETrue;
			else if (strcmp(argv[i], "-GENDEP")==0)
				gGenDepGraph = ETrue;
			else if (strncmp(argv[i], "-J", 2)==0)
				{
					if(argv[i][2])
						gThreadNum = atoi(&argv[i][2]);
					else
						{
						Print(EWarning, "The option should be like '-j4'.\n");
						gThreadNum = 0;
						}
					if(gThreadNum <= 0 || gThreadNum > MAXIMUM_THREADS)
						{
						if(gCPUNum > 0 && gCPUNum <= MAXIMUM_THREADS)
							{
							Print(EWarning, "The number of concurrent jobs set by -j should be between 1 and 128. And the number of processors %d will be used as the number of concurrent jobs.\n", gCPUNum);
							gThreadNum = gCPUNum;
							}
						else if(g_pCharCPUNum)
							{
							Print(EWarning, "The number of concurrent jobs set by -j should be between 1 and 128. And the NUMBER_OF_PROCESSORS is invalid, so the default value %d will be used.\n", DEFAULT_THREADS);
							gThreadNum = DEFAULT_THREADS;
							}
						else
							{
							Print(EWarning, "The number of concurrent jobs set by -j should be between 1 and 128. And the NUMBER_OF_PROCESSORS is not available, so the default value %d will be used.\n", DEFAULT_THREADS);
							gThreadNum = DEFAULT_THREADS;
							}
						}	
				}
			else if (strncmp(argv[i],ParamFileArg.c_str(),ParamFileArg.length())==0)
			{
				// If "-argfile" option is specified within parameter-file then process it 
				// otherwise ignore the option.
				if (paramFileFlag)
				{
					String paramFile;
					paramFile.assign(&argv[i][ParamFileArg.length()]);		
					processParamfile(paramFile);
				}
				else
				{
					continue;
				}
			}
			else if (argv[i][1] == 'T')
				TypeSafeLink=ETrue;
			else if (argv[i][1] == '?')
				reallyHelp=ETrue;
			else if (argv[i][1] == 'R')
				CompareRom=strdup(&argv[i][2]);
			else if (strcmp(argv[i], "-NO-HEADER")==0)
				gHeaderType=KRomLoaderHeaderNone;
			else if (strcmp(argv[i], "-EPOC-HEADER")==0)
				gHeaderType=KRomLoaderHeaderEPOC;
			else if (strcmp(argv[i], "-COFF-HEADER")==0)
				gHeaderType=KRomLoaderHeaderCOFF;
			else if (strcmp(argv[i], "-COMPRESS")==0)
				{				
				if( (i+1) >= argc || argv[i+1][0] == '-')
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
					// An argument exists
					i++;
					strupr(argv[i]);
					if( strcmp(argv[i], "PAGED") == 0)
						{
						gEnableCompress=ETrue;
						gCompressionMethod = KUidCompressionBytePair;	
						}	
					else if( strcmp(argv[i], "UNPAGED") == 0)
						{
						gCompressUnpaged=ETrue;
						gCompressUnpagedMethod = KUidCompressionDeflate;	
						}	
					else
						{
 						Print (EError, "Unknown -compression argument! Set it to default (no compression)!");
 						gEnableCompress=EFalse;
						gCompressionMethod = 0;
						gCompressUnpaged = EFalse;
						gCompressUnpagedMethod = 0;					
						}
					}
				}	
			else if( strcmp(argv[i], "-COMPRESSIONMETHOD") == 0 )
				{
				// next argument should be a method
				if( (i+1) >= argc || argv[i+1][0] == '-')
					{
					Print (EError, "Missing compression method! Set it to default (no compression)!");
					gEnableCompress=EFalse;
					gCompressionMethod = 0;
					}
				else 
					{
					i++;
					strupr(argv[i]);
					if( strcmp(argv[i], "INFLATE") == 0)
						{
						gEnableCompress=ETrue;
						gCompressionMethod = KUidCompressionDeflate;	
						}	
					else if( strcmp(argv[i], "BYTEPAIR") == 0)
						{
						gEnableCompress=ETrue;
						gCompressionMethod = KUidCompressionBytePair;	
						}	
					else
						{
 						if( strcmp(argv[i], "NONE") != 0)
 							{
 							Print (EError, "Unknown compression method! Set it to default (no compression)!");
 							}
 						gEnableCompress=EFalse;
						gCompressionMethod = 0;
						}
					}
					
				}
			else if (strcmp(argv[i], "-NO-SORTED-ROMFS")==0)
				gSortedRomFs=EFalse;
			else if (strcmp(argv[i], "-GENINC")==0)				// DEF095619
				gGenInc=ETrue;
 			else if (strcmp(argv[i], "-WSTDPATH")==0)			// Warn if destination path provided for a file		
 				gEnableStdPathWarning=ETrue;					// is not a standard path as per platsec
			else if( strcmp(argv[i], "-LOGLEVEL") == 0)
				{
				// next argument should a be loglevel
				if( (i+1) >= argc || argv[i+1][0] == '-')
					{
					Print (EError, "Missing loglevel!");
					gLogLevel = DEFAULT_LOG_LEVEL;
					}
				else
					{
					i++;
					if (strcmp(argv[i], "4") == 0)
						gLogLevel = (LOG_LEVEL_FILE_DETAILS | LOG_LEVEL_FILE_ATTRIBUTES | LOG_LEVEL_COMPRESSION_INFO | LOG_LEVEL_SMP_INFO);
					else if (strcmp(argv[i], "3") == 0)
						gLogLevel = (LOG_LEVEL_FILE_DETAILS | LOG_LEVEL_FILE_ATTRIBUTES | LOG_LEVEL_COMPRESSION_INFO);
					else if (strcmp(argv[i], "2") == 0)
						gLogLevel = (LOG_LEVEL_FILE_DETAILS | LOG_LEVEL_FILE_ATTRIBUTES);
					else if (strcmp(argv[i], "1") == 0)
						gLogLevel = LOG_LEVEL_FILE_DETAILS;
					else if (strcmp(argv[i], "0") == 0)
						gLogLevel = DEFAULT_LOG_LEVEL;
					else
						Print(EError, "Only loglevel 0, 1, 2, 3 or 4 is allowed!");
					}
				}
			else if( strcmp(argv[i], "-LOGLEVEL4") == 0)
				gLogLevel = (LOG_LEVEL_FILE_DETAILS | LOG_LEVEL_FILE_ATTRIBUTES | LOG_LEVEL_COMPRESSION_INFO | LOG_LEVEL_SMP_INFO);
			else if( strcmp(argv[i], "-LOGLEVEL3") == 0)
				gLogLevel = (LOG_LEVEL_FILE_DETAILS | LOG_LEVEL_FILE_ATTRIBUTES | LOG_LEVEL_COMPRESSION_INFO);
			else if( strcmp(argv[i], "-LOGLEVEL2") == 0)
				gLogLevel = (LOG_LEVEL_FILE_DETAILS | LOG_LEVEL_FILE_ATTRIBUTES);
			else if( strcmp(argv[i], "-LOGLEVEL1") == 0)
				gLogLevel = LOG_LEVEL_FILE_DETAILS;
			else if( strcmp(argv[i], "-LOGLEVEL0") == 0)
				gLogLevel = DEFAULT_LOG_LEVEL;
			else if (argv[i][1] == 'D')
				{
				TraceMask=strtoul(argv[i]+2, 0, 0);
				}
			else if (strcmp(argv[i], "-LOWMEM") == 0)
				gLowMem = ETrue;
			else if (strncmp(argv[i], "-COREIMAGE=",11) ==0)
			{  
				if(argv[i][11])	
				{
					gUseCoreImage = ETrue; 
					gImageFilename = (TText*)strdup(&argv[i][11]);	
				}
				else
				{
					Print (EError, "Core ROM image file is missing\n"); 
				}
			}
			else 
				cout << "Unrecognised option " << argv[i] << "\n";
			}	
		else // Must be the obey filename
			filename=argv[i];
		}
	if (paramFileFlag)
		return;
	if (filename.empty())
		{
		PrintVersion();
		cout << HelpText;
		if (reallyHelp)
			{
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
void processParamfile(string aFileName)
{
	CParameterFileProcessor parameterFile(aFileName);
	
	// Invoke fuction "ParameterFileProcessor" to process parameter-file.
	if(parameterFile.ParameterFileProcessor())
	{		
		TUint noOfParameters = parameterFile.GetNoOfArguments();
		char** parameters = parameterFile.GetParameters();
		TBool paramFileFlag=ETrue;
		
		// Invoke function "processCommandLine" to process parameters read from parameter-file.
		processCommandLine(noOfParameters, parameters, paramFileFlag);
	}	
}

void GenerateIncludeFile(char* aRomName, TInt aUnpagedSize, TInt aPagedSize )
	{
	
	const char * incFileNameExt = ".inc";
	
	TText* incFileName;
	incFileName=new TText[strlen(aRomName) + strlen(incFileNameExt) + 1];  // Place for include file name and ".inc" extension and '\0'
	strcpy((char *)incFileName, aRomName);
	
	char *p = (char*)strrchr((const char *)incFileName, '.');
	if( NULL != p)
		{
		strncpy(p, incFileNameExt, strlen(incFileNameExt) + 1);				// copy extension and the '\0'
		}
	else
		{
		strcat((char *)incFileName, incFileNameExt);		//Doesn't cotains extension, add to it.
		}
		
	Print(EAlways," (%s)\n", (const char *)incFileName);
	
	ofstream incFile((const char*)incFileName, ios::out);
	if(!incFile)
		{
		Print(EError,"Cannot open include file %s for output\n",(const char *)incFileName);		
		}
	else
		{
		const char * incContent = 
					"/** Size of the unpaged part of ROM.\n"
	    			"This part is at the start of the ROM image. */\n"
					"#define SYMBIAN_ROM_UNPAGED_SIZE 0x%08x\n"
					"\n"
					"/** Size of the demand paged part of ROM.\n"
	    			"This part is stored immediately after the unpaged part in the ROM image. */\n"
					"#define SYMBIAN_ROM_PAGED_SIZE 0x%08x\n";
		
		TText* temp = new TText[strlen(incContent)+ 2 * 8 + 1]; 	// for place of two hex representated values and '\0'
		
		sprintf((char *)temp,incContent, aUnpagedSize, aPagedSize);
		incFile.write((const char *)temp, strlen((const char *)temp));
		
		incFile.close();
		delete[]  temp;
		}
	delete[]  incFileName;
		
	}

int main(int argc, char *argv[]) 
{
	H.SetLogFile((unsigned char *)"ROMBUILD.LOG");
	TInt r = 0;
	g_pCharCPUNum = getenv("NUMBER_OF_PROCESSORS");
	if(g_pCharCPUNum != NULL)
		gCPUNum = atoi(g_pCharCPUNum);
		
	// initialise set of all capabilities
	ParseCapabilitiesArg(gPlatSecAllCaps, "all");

 	processCommandLine(argc, argv);
 	if(filename.empty())
   		return KErrGeneral;
		
    if(gThreadNum == 0)
	{
		if(gCPUNum > 0 && gCPUNum <= MAXIMUM_THREADS)
		{
			Print(EAlways, "The number of processors (%d) is used as the number of concurrent jobs.\n", gCPUNum);
			gThreadNum = gCPUNum;
		}
		else if(g_pCharCPUNum)
		{
			Print(EWarning, "The NUMBER_OF_PROCESSORS is invalid, and the default value %d will be used.\n", DEFAULT_THREADS);
			gThreadNum = DEFAULT_THREADS;
		}
		else
		{
			Print(EWarning, "The NUMBER_OF_PROCESSORS is not available, and the default value %d will be used.\n", DEFAULT_THREADS);
			gThreadNum = DEFAULT_THREADS;
		}
	}
 	TText *obeyFileName= (TText*)filename.c_str();	
 
	PrintVersion();
	
	ObeyFileReader *reader=new ObeyFileReader(obeyFileName);
	if (!reader->Open())
	{
		delete reader;
		return KErrGeneral;
	}
	
	E32Rom* kernelRom=0;		// for image from obey file
	CoreRomImage *core= 0;		// for image from core image file
	MRomImage* imageInfo=0;
	CObeyFile *mainObeyFile=new CObeyFile(*reader);

	// need check if obey file has coreimage keyword
	TText *file = mainObeyFile->ProcessCoreImage();
	if (file)
	{
		// hase coreimage keyword but only use if command line option
		// for coreimage not already selected
		if (!gUseCoreImage)
		{
			gUseCoreImage = ETrue;
			gImageFilename = file;
		}
	}

	if (!gUseCoreImage)
	{
		r=mainObeyFile->ProcessKernelRom();
		if (r==KErrNone)
		{
				// Build a kernel ROM using the description compiled into the
				// CObeyFile object
				
				kernelRom = new E32Rom(mainObeyFile);
				if (kernelRom == 0 || kernelRom->iData == 0)
					return KErrNoMemory;
				
				r=kernelRom->Create();
				if (r!=KErrNone)
				{
					delete kernelRom;
					delete mainObeyFile;
					return r;
				}
				if (SizeSummary)
					kernelRom->DisplaySizes(SizeWhere);
				
				r=kernelRom->WriteImages(gHeaderType);
				if (r!=KErrNone)
				{
					delete kernelRom;
					delete mainObeyFile;
					return r;
				}
				
				if (CompareRom)
				{
					r=kernelRom->Compare(CompareRom, gHeaderType);
					if (r!=KErrNone)
					{
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
	else
	{
		// need to use core image
		core = new CoreRomImage((char*)gImageFilename);
		if (!core)
		{
			return KErrNoMemory;
		}
		if (!core->ProcessImage(gLowMem))
		{
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
		if(gCompressionMethod)
		{
			gEnableCompress = ETrue;
		}
		
		imageInfo = core;
		if(!mainObeyFile->SkipToExtension())
		{
			delete core;
			delete mainObeyFile;
			return KErrGeneral;
		}
	}
	
	if(gGenInc)
	{
		Print(EAlways,"Generating include file for ROM image post-processors ");
		if( gPagedRom )
		{
			Print(EAlways,"Paged ROM");
			GenerateIncludeFile((char*)mainObeyFile->iRomFileName, kernelRom->iHeader->iPageableRomStart, kernelRom->iHeader->iPageableRomSize);
		}
		else
		{
			Print(EAlways,"Unpaged ROM");
			int headersize=(kernelRom->iExtensionRomHeader ? sizeof(TExtensionRomHeader) : sizeof(TRomHeader)) - sizeof(TRomLoaderHeader);
			GenerateIncludeFile((char*)mainObeyFile->iRomFileName, kernelRom->iHeader->iCompressedSize + headersize, kernelRom->iHeader->iPageableRomSize);
		}
	}
	
	do
	{
		CObeyFile* extensionObeyFile = 0;
		E32Rom* extensionRom = 0;

		extensionObeyFile = new CObeyFile(*reader);
		r = extensionObeyFile->ProcessExtensionRom(imageInfo);
		if (r==KErrEof)
		{
			delete imageInfo;
			delete mainObeyFile;
			delete extensionObeyFile;
			return KErrNone;
		}
		if (r!=KErrNone)
		{
			delete extensionObeyFile;
			break;
		}
		
		extensionRom = new E32Rom(extensionObeyFile);
		r=extensionRom->CreateExtension(imageInfo);
		if (r!=KErrNone)
		{
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
	free(gDepInfoFile); 
	return r;
}
