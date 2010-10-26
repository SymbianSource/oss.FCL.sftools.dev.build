/*
* Copyright (c) 2007-2010 Nokia Corporation and/or its subsidiary(-ies).
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
#include <string.h>
#include <stdlib.h>
#include <f32file.h>
#include "e32image.h"
#include "h_utl.h"
#include "h_ver.h"
#include "r_obey.h"
#include "r_driveimage.h"
#include "r_driveutl.h"
#include "r_coreimage.h"
#include "parameterfileprocessor.h"
#include "r_smrimage.h"
//cache headers
#include "cache/cacheexception.hpp"
#include "cache/cacheentry.hpp"
#include "cache/cache.hpp"
#include "cache/cachegenerator.hpp"
#include "cache/cachevalidator.hpp"
#include "cache/cacheablelist.hpp"
#include "cache/cachemanager.hpp"
#include "logging/loggingexception.hpp"
#include "logging/logparser.hpp"
#include <malloc.h>
 
#ifndef WIN32
#include <unistd.h>
#include <strings.h>
#include <fstream>
#define strnicmp strncasecmp
#define stricmp strcasecmp
#define _alloca alloca
#endif

static const TInt RofsbuildMajorVersion=2;
static const TInt RofsbuildMinorVersion=16;
static const TInt RofsbuildPatchVersion=1;
static TBool SizeSummary=EFalse;
static TPrintType SizeWhere=EAlways;

static TInt gHeaderType=1;			// EPOC header
static TInt MAXIMUM_THREADS = 128;
static TInt DEFAULT_THREADS = 8;
ECompression gCompress=ECompressionUnknown;
TUint  gCompressionMethod=0;
TInt gThreadNum = 0;
TInt gCPUNum = 0;
TBool gGenSymbols = EFalse;
TInt gCodePagingOverride = -1;
TInt gDataPagingOverride = -1;
TInt gLogLevel = 0;	// Information is logged based on logging level.
// The default is 0. So all the existing logs are generated as if gLogLevel = 0.
// If any extra information required, the log level must be appropriately supplied.
// Currrently, file details in ROM (like, file name in ROM & host, file size, whether
// the file is hidden etc) are logged when gLogLevel >= LOG_LEVEL_FILE_DETAILS.

TBool gUseCoreImage = EFalse; // command line option for using core image file
string gImageFilename = "";	// instead of obey file
TBool gEnableStdPathWarning = EFalse;// for in-correct destination path warning(executables).
TBool gLowMem = EFalse;
extern TBool gDriveImage;		// to Support data drive image.
string gDriveFilename = "";		// input drive oby filename.
string filename;				// to store oby filename passed to Rofsbuild.
TBool reallyHelp = EFalse;	
TBool gSmrImage = EFalse;
string gSmrFileName = "";
static string cmdlogfile = "";
static string loginput = "";

//Cache global variables
bool gCache = false;
bool gCleanCache = false;
bool gNoCache = false;
TBool gIsOBYUTF8 = EFalse;
TBool gKeepGoing = EFalse;
void PrintVersion() {
	printf("\nROFSBUILD - Rofs/Datadrive image builder");
	printf(" V%d.%d.%d\n", RofsbuildMajorVersion, RofsbuildMinorVersion, RofsbuildPatchVersion);
	printf("%s\n\n", "Copyright (c) 1996-2010 Nokia Corporation.");
}

char HelpText[] = 
	"Syntax: ROFSBUILD [options] obeyfilename(Rofs)\n"
	"Option: -v verbose,  -?,  -s[log|screen|both] size summary\n"
	"        -d<bitmask> set trace mask (DEB build only)\n"
	"        -compress   compress executable files where possible\n"
	"        -j<digit> do the main job with <digit> threads\n"
	"        -symbols generate symbol file\n"
	"        -compressionmethod none|inflate|bytepair to set the compression\n"
	"              none     uncompress the image.\n"
	"              inflate  compress the image.\n"
	"              bytepair compress the image.\n"
	"        -coreimage <core image file>\n"
	"        -cache allow the ROFSBUILD to reuse/generate cached executable files\n"
	"        -nocache force the ROFSBUILD not to reuse/generate cached executable files\n"
	"        -cleancache permanently remove all cached executable files\n"
	"        -datadrive=<drive obyfile1>,<drive obyfile2>,... for driveimage creation\n"
	"              user can also input rofs oby file if required to generate both.\n"
	"        -smr=<SMR obyfile1>,<SMR obyfile2>,... for SMR partition creation\n"
	"        -oby-charset=<charset> used character set in which OBY was written\n"
	"        -loglevel<level>  level of information to log (valid levels are 0,1,2).\n"//Tools like Visual ROM builder need the host/ROM filenames, size & if the file is hidden.
	"        -wstdpath   warn if destination path provided for a file is not the standard path\n"
	"        -argfile=<FileName>   specify argument-file name containing list of command-line arguments\n"
"        -lowmem     use memory-mapped file for image build to reduce physical memory consumption\n"
"        -k     to enable keepgoing when duplicate files exist in oby\n"
"        -logfile=<fileName>           specify log file\n"
"        -loginput=<log filename>      specify as input a log file and produce as output symbol file.\n";

char ReallyHelpText[] =
"Log Level:\n"
"        0  produce the default logs\n"
"        1  produce file detail logs in addition to the default logs\n"
"        2  logs e32 header attributes in addition to the level 1 details\n";
void processParamfile(const string& aFileName);
/**
Process the command line arguments and prints the helpful message if none are supplied.
@param argc    - No. of argument.
@param *argv[] - Arguments value.
*/ 
void processCommandLine(int argc, char *argv[], TBool paramFileFlag = EFalse) {
	// If "-argfile" option is passed to rofsbuild, then process the parameters
	// specified in parameter-file first and then the options passed from the command-line.
	
	string ParamFileArg("-ARGFILE=");	
	if(paramFileFlag == EFalse) {
		for (int count = 1; count<argc; count++) {
			string paramFile;
			//strupr(argv[count]);
			if(strnicmp(argv[count],ParamFileArg.c_str(),ParamFileArg.length()) == 0) {
				paramFile.assign(&argv[count][ParamFileArg.length()]);									
				processParamfile(paramFile);
			}
		}
	}	

	int i = 1;
	while (i<argc) {		 
#ifdef __LINUX__	
		if (argv[i][0] == '-') 
#else
		if ((argv[i][0] == '-') || (argv[i][0] == '/'))
#endif
		{ 
			// switch
			if ((argv[i][1] & 0x20) == 'v')
				H.iVerbose = ETrue;
			else if(strnicmp (argv[i], "-SMR=", 5) == 0) {
				if(argv[i][5]) {
					gSmrImage = ETrue;
					gSmrFileName.assign(&argv[i][5]);
				}
				else {
					Print (EError, "SMR obey file is missing\n");
				}
			} else if (stricmp(argv[i], "-K") == 0) {
				gKeepGoing = ETrue;
			}else if (stricmp(argv[i], "-SYMBOLS") == 0) {
				gGenSymbols = ETrue;
			}
			else if (((argv[i][1] | 0x20) == 's') &&  
				(((argv[i][2]| 0x20) == 'l')||((argv[i][2] | 0x20) == 's'))) {
					SizeSummary = ETrue;
					if ((argv[i][2]| 0x20) == 'l')
						SizeWhere = ELog;
					else
						SizeWhere = EScreen;
			}
			else if (strnicmp(argv[i],ParamFileArg.c_str(),ParamFileArg.length()) == 0) {
				if (paramFileFlag){
					string paramFile;
					paramFile.assign(&argv[i][ParamFileArg.length()]);		
					processParamfile(paramFile);
				}
				else {
					i++;
					continue;
				}
			}
			else if (stricmp(argv[i], "-COMPRESS") == 0) {
				gCompress = ECompressionCompress;
				gCompressionMethod = KUidCompressionDeflate;
			}
			else if(stricmp(argv[i], "-CACHE") == 0) {
				gCache = true;
				if(gCleanCache || gNoCache) {
					printf("Cache command line options are mutually exclusive, only one option can be used at a time\n");
					exit(1);
				}
			}
			else if(stricmp(argv[i], "-NOCACHE") == 0) {
				gNoCache = true;
				if(gCleanCache || gCache) {
					printf("Cache command line options are mutually exclusive, only one option can be used at a time\n");
					exit(1);
				}
			}
			else if(stricmp(argv[i], "-CLEANCACHE") == 0) {
				gCleanCache = true;
				if(gCache || gNoCache)
				{
					printf("Cache command line options are mutually exclusive, only one option can be used at a time\n");
					exit(1);
				}
			}
			else if (strnicmp(argv[i], "-J",2) == 0) {
				if(argv[i][2])
					gThreadNum = atoi(&argv[i][2]);
				else {
					printf("WARNING: The option should be like '-j4'.\n");
					gThreadNum = 0;
				}
				if(gThreadNum <= 0 || gThreadNum > MAXIMUM_THREADS) {
					printf("WARNING: The number of concurrent jobs set by -j should be between 1 and 128. ");
					if(gCPUNum > 0) {
						printf("WARNING: The number of processors %d is used as the number of concurrent jobs.\n", gCPUNum);
						gThreadNum = gCPUNum;
					}
					else {
						printf("WARNING: Can't automatically get the valid number of concurrent jobs and %d is used.\n", DEFAULT_THREADS);
						gThreadNum = DEFAULT_THREADS;
					}
				}
			}
			else if(strnicmp(argv[i], "-OBY-CHARSET=", 13) == 0)
			{
				if((stricmp(&argv[i][13], "UTF8")==0) || (stricmp(&argv[i][13], "UTF-8")==0))
					gIsOBYUTF8 = ETrue;
				else
					Print(EError, "Invalid encoding %s, default system internal encoding will be used.\n", &argv[i][13]);
			}
			else if (stricmp(argv[i], "-UNCOMPRESS") == 0) {
				gCompress = ECompressionUncompress;
			}
			else if( stricmp(argv[i], "-COMPRESSIONMETHOD") == 0 ) {
				// next argument should a be method
				if( (i+1) >= argc || argv[i+1][0] == '-') {
					Print (EError, "Missing compression method! Set it to default (no compression)!");
					gCompressionMethod = 0;
				}
				else {
					i++;					
					if( stricmp(argv[i], "NONE") == 0) {
						gCompress = ECompressionUncompress;
						gCompressionMethod = 0;	
					}
					else if( stricmp(argv[i], "INFLATE") == 0) {
						gCompress = ECompressionCompress;
						gCompressionMethod = KUidCompressionDeflate;	
					}	
					else if( stricmp(argv[i], "BYTEPAIR") == 0) {
						gCompress = ECompressionCompress;
						gCompressionMethod = KUidCompressionBytePair;	
					}
					else {
						Print (EError, "Unknown compression method! Set it to default (no compression)!");
						gCompress = ECompressionUnknown;
						gCompressionMethod = 0;		
					}
				}

			}
			else if (stricmp(argv[i], "-COREIMAGE") == 0) {
				
				gUseCoreImage = ETrue;
				// next argument should be image filename
				if ((i+1 >= argc) || argv[i+1][0] == '-')
					Print (EError, "Missing image file name");
				else {
					i++;
					gImageFilename.assign(argv[i]);
				}
			}
			else if (strnicmp(argv[i], "-DATADRIVE=",11) == 0){  
				if(argv[i][11])	{
					gDriveImage = ETrue; 
					gDriveFilename.assign(&argv[i][11]);	
				}
				else {
					Print (EError, "Drive obey file is missing\n"); 
				}
			}
			else if (argv[i][1] == '?') {
				reallyHelp = ETrue;
			}
			else if (stricmp(argv[i], "-WSTDPATH") == 0)	{	// Warn if destination path provided for a executables are incorrect as per platsec.		
				gEnableStdPathWarning = ETrue;						
			}
			else if( stricmp(argv[i], "-LOGLEVEL") == 0) {
				// next argument should a be loglevel
				if( (i+1) >= argc || argv[i+1][0] == '-') {
					Print (EError, "Missing loglevel!");
					gLogLevel = DEFAULT_LOG_LEVEL;
				}
				else {
					i++;
					if (strcmp(argv[i], "2") == 0)
						gLogLevel = (LOG_LEVEL_FILE_DETAILS | LOG_LEVEL_FILE_ATTRIBUTES);
					if (strcmp(argv[i], "1") == 0)
						gLogLevel = LOG_LEVEL_FILE_DETAILS;
					else if (strcmp(argv[i], "0") == 0)
						gLogLevel = DEFAULT_LOG_LEVEL;
					else
						Print(EError, "Only loglevel 0, 1 or 2 is allowed!");
				}
			}
			else if( stricmp(argv[i], "-LOGLEVEL2") == 0)
				gLogLevel = (LOG_LEVEL_FILE_DETAILS | LOG_LEVEL_FILE_ATTRIBUTES);
			else if( stricmp(argv[i], "-LOGLEVEL1") == 0)
				gLogLevel = LOG_LEVEL_FILE_DETAILS;
			else if( stricmp(argv[i], "-LOGLEVEL0") == 0)
				gLogLevel = DEFAULT_LOG_LEVEL;
			else if (stricmp(argv[i], "-LOWMEM") == 0)
				gLowMem = ETrue;
			else if (strnicmp(argv[i], "-logfile=",9) ==0) {
				cmdlogfile = argv[i] + 9;
			}
			else if (strnicmp(argv[i], "-loginput=", 10) == 0) {
				loginput = argv[i] + 10;
			}
			else {
#ifdef WIN32
				Print (EWarning, "Unrecognised option %s\n",argv[i]);
#else
				if(0 == access(argv[i],R_OK)){
					filename.assign(argv[i]);
				}
				else {
					Print (EWarning, "Unrecognised option %s\n",argv[i]);
				}
#endif				

			}
		}
		else // Must be the obey filename
			filename.assign(argv[i]);
		i++;
	}

	if (paramFileFlag)
		return;

	if((gDriveImage == EFalse) && (gSmrImage ==  EFalse) && 
		(filename.empty() || (gUseCoreImage && gImageFilename.length() == 0)) && (loginput.length() == 0)){
			Print (EAlways, HelpText);
			if (reallyHelp) {
				ObeyFileReader::KeywordHelp();
				Print (EAlways, ReallyHelpText);
			}
			else if (filename.empty()){
				Print(EAlways, "Obey filename is missing\n");
			}
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
		TBool paramFileFlag = ETrue;

		// Invoke function "processCommandLine" to process parameters read from parameter-file.
		processCommandLine(noOfParameters,parameters,paramFileFlag);
	}	
}

/**
Main logic for data drive image creation. Called many types depending on no. of drive obey files.

@param aobeyFileName - Drive obey file.
@param alogfile      - log file name required for file system module.

@return - returns the status, after processing the drive obey file.
*/ 
TInt ProcessDataDriveMain(char* aobeyFileName, const char* alogfile) {

	ObeyFileReader *reader = new ObeyFileReader(aobeyFileName);

	if(!reader)
		return KErrNoMemory;

	if(!reader->Open())
		return KErrGeneral; 
		
	CObeyFile* mainObeyFile = new CObeyFile(*reader);    
	
	if(!mainObeyFile)
		return KErrNoMemory;

	// Process data drive image.
	// let's clear the TRomNode::sDefaultInitialAttr first, 'cause data drive is different from rom image
	TRomNode::sDefaultInitialAttr = 0; 
	TInt retstatus = mainObeyFile->ProcessDataDrive();
	if (retstatus == KErrNone) {
		// Build a Data drive image using the description compiled into the CObeyFile object
		CDriveImage* userImage = new CDriveImage(mainObeyFile);
		if(userImage) {	
			// Drive image creation.
			retstatus = userImage->CreateImage(alogfile);
			if(retstatus == KErrNone) {
				Print (EAlways, "\nSuccessfully generated the Drive image : %s \n",mainObeyFile->iDriveFileName);
			}
			else {
				Print (EError, "Failed to generate the Image : %s\n",mainObeyFile->iDriveFileName);
			}
			delete userImage; 
		}
		else {
			retstatus = KErrNoMemory;
		}
	}
	// restore
	TRomNode::sDefaultInitialAttr = (TUint8)KEntryAttReadOnly;
	cout << "\n-----------------------------------------------------------\n";

	delete mainObeyFile;
	delete reader;
	return retstatus;
}

TInt ProcessSmrImageMain(char* aObeyFileName, const char* /* alogfile */) {
	ObeyFileReader *reader = new ObeyFileReader(aObeyFileName);
	if(!reader)
		return KErrNoMemory;
	if(!reader->Open())
		return KErrGeneral;
	TInt retstatus = 0;
	CObeyFile* mainObeyFile = new CObeyFile(*reader);
	CSmrImage* smrImage = 0;
	if(!mainObeyFile)
		return KErrNoMemory;
	if(mainObeyFile->Process()) {
		smrImage = new CSmrImage(mainObeyFile);
		if(smrImage) {
			if((retstatus = smrImage->Initialise()) == KErrNone) {
				retstatus = smrImage->CreateImage();
			}
			if(retstatus == KErrNone) {
				Print (EAlways,  "\nSuccessfully generated the SMR image : %s\n" ,smrImage->GetImageName().c_str());
			}
			else {
				Print (EError, "\nFailed to generate the Image : %s\n" ,smrImage->GetImageName().c_str());
			}
			delete smrImage;
		}
		else {
			retstatus = KErrNoMemory;
		}
	}
	delete mainObeyFile;
	delete reader;
	return retstatus;
}

/**
Rofsbuild Main function, which creates both Rofs and Data drive image.

@param argc    - No. of argument.
@param *argv[] - Arguments value.

@return - returns the status to caller.
*/ 
TInt main(int argc, char *argv[]){
	TInt r =0;
#ifdef __LINUX__
	gCPUNum = sysconf(_SC_NPROCESSORS_CONF);
#else	
	char* pCPUNum = getenv ("NUMBER_OF_PROCESSORS");
	if (pCPUNum != NULL)
		gCPUNum = atoi(pCPUNum);
#endif		
	if(gCPUNum > MAXIMUM_THREADS)
		gCPUNum = MAXIMUM_THREADS;
	PrintVersion();
	processCommandLine(argc, argv);
	if(gThreadNum == 0) {
		if(gCPUNum > 0) {
			printf("WARNING: The number of processors (%d) is used as the number of concurrent jobs.\n", gCPUNum);
			gThreadNum = gCPUNum;
		}
		else {
			printf("WARNING: Can't automatically get the valid number of concurrent jobs and %d is used.\n", DEFAULT_THREADS);
			gThreadNum = DEFAULT_THREADS;
		}
	}
	if(loginput.length() >= 1)
	{
		try
		{
			LogParser::GetInstance()->ParseSymbol(loginput.c_str());
		}
		catch(LoggingException le)
		{
			printf("ERROR: %s\r\n", le.GetErrorMessage());
			return 1;
		}
		return 0;
	}
	//if the user wants to clean up the cache, do it only.
	if(gCleanCache){
		try {
			CacheManager::GetInstance()->CleanCache();
			Print (EAlways, "Cache has been deleted successfully.\n");
		}
		catch(CacheException& ce){
			Print (EError, "%s\n", ce.GetErrorMessage());
			return (TInt)1;
		}
		return r;
	}
	//initialize cache if the user switches on.
	if(gCache) {
		try {
			CacheManager::GetInstance();
		}
		catch(CacheException ce){
			Print (EError, "%s\n", ce.GetErrorMessage());
			return (TInt)1;
		}
	}
	const char *obeyFileName = 0;	
	if(!filename.empty())
		obeyFileName = filename.c_str(); 
	if ((!obeyFileName) && (!gDriveFilename.empty()) && (!gSmrFileName.empty())){
		return KErrGeneral;
	}
	// Process drive obey files.
	if(gDriveImage) {  
		char temp = 0;
		char *driveobeyFileName = (char*)_alloca(gDriveFilename.length() + 1);
		memcpy(driveobeyFileName,gDriveFilename.c_str(),gDriveFilename.length() + 1);
		char* ptr = driveobeyFileName;
		do {
			while(((temp = *ptr++) != ',') && (temp != 0));
			*(--ptr)++ = 0; 

			if(*driveobeyFileName) {
				string logfile = Getlogfile(driveobeyFileName, cmdlogfile);
				if(logfile.size() > 0) {
					H.SetLogFile(logfile.c_str());
					GetLocalTime();
					r = ProcessDataDriveMain(driveobeyFileName,logfile.c_str());   
					H.CloseLogFile();
					if(r == KErrNoMemory)
						return KErrNoMemory;
				}
				else {
					Print(EError,"Invalid obey file name : %s\n", driveobeyFileName);   
				}
			}
			driveobeyFileName = ptr;
		} while(temp != 0); 
		gDriveImage = EFalse;
	} 
	if(gSmrImage){
		char temp = 0;
		char *smrImageObeyFileName = (char*)_alloca(gSmrFileName.length() + 1);
		memcpy(smrImageObeyFileName,gSmrFileName.c_str(),gSmrFileName.length() + 1);
		char* ptr = smrImageObeyFileName;
		do {
			while(((temp = *ptr++) != ',') && (temp != 0));
			*(--ptr)++ = 0;

			if(*smrImageObeyFileName){	
				string logfile = Getlogfile(smrImageObeyFileName, cmdlogfile);
				if(logfile.size() > 0) {
					H.SetLogFile(logfile.c_str());
					GetLocalTime();
					r = ProcessSmrImageMain(smrImageObeyFileName, logfile.c_str());
					H.CloseLogFile();
					if(r == KErrNoMemory)
						return KErrNoMemory;
				}
				else {
					Print(EError,"Invalid obey file name: %s", smrImageObeyFileName);
				}
			}
			smrImageObeyFileName = ptr;
		} while(temp != 0);
		gSmrImage = EFalse;
	}
	// Process Rofs Obey files.
	if(obeyFileName) {
		if (cmdlogfile.empty() || cmdlogfile[cmdlogfile.size()-1] == '\\' || cmdlogfile[cmdlogfile.size()-1] == '/')
			cmdlogfile += "ROFSBUILD.LOG" ;
			
	 	H.SetLogFile(cmdlogfile.c_str());
		ObeyFileReader *reader = new ObeyFileReader(obeyFileName); 
		if (!reader->Open())
			return KErrGeneral;

		E32Rofs* RofsImage = 0;		// for image from obey file
		CCoreImage *core = 0;		// for image from core image file
		MRofsImage* imageInfo = 0;
		CObeyFile *mainObeyFile = new CObeyFile(*reader);
		// need check if obey file has coreimage keyword
		char *file = mainObeyFile->ProcessCoreImage();
		if (file) {
			// hase coreimage keyword but only use if command line option
			// for coreimage not already selected
			if (!gUseCoreImage){
				gUseCoreImage = ETrue;
				gImageFilename = file;
			}
			delete []file ;
		}
		if (!gUseCoreImage) {
			r = mainObeyFile->ProcessRofs();
			if (r == KErrNone) {
				// Build a ROFS image using the description compiled into the CObeyFile object
				RofsImage = new E32Rofs( mainObeyFile );
				if( !RofsImage ) {
					if(gCache || gCleanCache)
						delete CacheManager::GetInstance();
					return KErrNoMemory;
				}
				r = RofsImage->Create();

				if( KErrNone == r )	{
					RofsImage->WriteImage( gHeaderType );
				}
				imageInfo = RofsImage;
				mainObeyFile->Release();
				if(gCache || gCleanCache)
					delete CacheManager::GetInstance();
			}
			else if (r != KErrNotFound){
				return r;
			}
		}
		else {
			// need to use core image
			RCoreImageReader *reader = new RCoreImageReader(gImageFilename.c_str());
			if (!reader) {
				return KErrNoMemory;
			}
			core = new CCoreImage(reader);
			if (!core) {
				return KErrNoMemory;
			}
			r = core->ProcessImage();
			if (r != KErrNone) {
				return r;
			}
			imageInfo = core;
			mainObeyFile->SkipToExtension();
		}

		do {
			CObeyFile* extensionObeyFile = new CObeyFile(*reader);
			r = extensionObeyFile->ProcessExtensionRofs(imageInfo);
			if (r == KErrEof){
				if(RofsImage){
					delete RofsImage;
				}
				if(core){
					delete core;
				}
				delete extensionObeyFile;
				return KErrNone;
			}
			if (r != KErrNone){
				break;
			}
			E32Rofs* extensionRofs = new E32Rofs(extensionObeyFile);
			r = extensionRofs->CreateExtension(imageInfo);
			if (r!= KErrNone){
				delete extensionRofs;
				delete extensionObeyFile;
				break;
			}
			r = extensionRofs->WriteImage(0);	

			delete extensionRofs;
			extensionRofs = 0;
		} while (r == KErrNone);
		if(RofsImage) {
			delete RofsImage;									
		}
		if(core){
			delete core;
		}
		delete mainObeyFile;
	}
	return r;
}//end of main.
