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
* @internalComponent * @released
* Rofsbuild mainfile to generate both rofs and data drive image.
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

static const TInt RofsbuildMajorVersion=2;
static const TInt RofsbuildMinorVersion=6;
static const TInt RofsbuildPatchVersion=5;
static TBool SizeSummary=EFalse;
static TPrintType SizeWhere=EAlways;

static TInt gHeaderType=1;			// EPOC header
static TInt MAXIMUM_THREADS = 128;
static TInt DEFAULT_THREADS = 8;
ECompression gCompress=ECompressionUnknown;
TUint  gCompressionMethod=0;
TBool gFastCompress = EFalse;
TInt gThreadNum = 0;
TInt gCPUNum = 0;
char* g_pCharCPUNum = NULL;
TInt gCodePagingOverride = -1;
TInt gDataPagingOverride = -1;
TInt gLogLevel = 0;	// Information is logged based on logging level.
					// The default is 0. So all the existing logs are generated as if gLogLevel = 0.
					// If any extra information required, the log level must be appropriately supplied.
					// Currrently, file details in ROM (like, file name in ROM & host, file size, whether 
					// the file is hidden etc) are logged when gLogLevel >= LOG_LEVEL_FILE_DETAILS.

TBool gUseCoreImage=EFalse; // command line option for using core image file
char* gImageFilename=NULL;	// instead of obey file
TBool gEnableStdPathWarning=EFalse;// for in-correct destination path warning(executables).
TBool gLowMem=EFalse;

extern TBool gDriveImage;		// to Support data drive image.
TText* gDriveFilename=NULL;		// input drive oby filename.

string filename;				// to store oby filename passed to Rofsbuild.
TBool reallyHelp=EFalse;	

TBool gSmrImage = EFalse;
TText* gSmrFileName = NULL;

void PrintVersion()
	{
		Print(EAlways,"\nROFSBUILD - Rofs/Datadrive image builder");
		Print(EAlways, " V%d.%d.%d\n", RofsbuildMajorVersion, RofsbuildMinorVersion, RofsbuildPatchVersion);
		Print(EAlways,Copyright);
	}

char HelpText[] = 
	"Syntax: ROFSBUILD [options] obeyfilename(Rofs)\n"
	"Option: -v verbose,  -?,  -s[log|screen|both] size summary\n"
	"        -d<bitmask> set trace mask (DEB build only)\n"
	"        -compress   compress executable files where possible\n"
	"        -fastcompress  compress files with faster bytepair and tradeoff of compress ratio\n"
	"        -j<digit> do the main job with <digit> threads\n"
	"        -compressionmethod none|inflate|bytepair to set the compression\n"
	"              none     uncompress the image.\n"
	"              inflate  compress the image.\n"
	"              bytepair compress the image.\n"
	"        -coreimage <core image file>\n"
	"        -datadrive=<drive obyfile1>,<drive obyfile2>,... for driveimage creation\n"
	"              user can also input rofs oby file if required to generate both.\n"
	"        -smr=<SMR obyfile1>,<SMR obyfile2>,... for SMR partition creation\n"
	"        -loglevel<level>  level of information to log (valid levels are 0,1,2).\n"//Tools like Visual ROM builder need the host/ROM filenames, size & if the file is hidden.
	"        -wstdpath   warn if destination path provided for a file is not the standard path\n"
	"        -argfile=<FileName>   specify argument-file name containing list of command-line arguments\n"
	"        -lowmem     use memory-mapped file for image build to reduce physical memory consumption\n";

char ReallyHelpText[] =
	"Log Level:\n"
	"        0  produce the default logs\n"
	"        1  produce file detail logs in addition to the default logs\n"
	"        2  logs e32 header attributes in addition to the level 1 details\n";

void processParamfile(string aFileName);

/**
Process the command line arguments and prints the helpful message if none are supplied.
@param argc    - No. of argument.
@param *argv[] - Arguments value.
*/ 
void processCommandLine(int argc, char *argv[], TBool paramFileFlag=EFalse)
{
	// If "-argfile" option is passed to rofsbuild, then process the parameters
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

	int i=1;
	while (i<argc)
		{
		strupr(argv[i]);
		if ((argv[i][0] == '-') || (argv[i][0] == '/'))
			{ // switch
			if (argv[i][1] == 'V')
				H.iVerbose = ETrue;
			else if(strncmp (argv[i], "-SMR=", 5) == 0)
			{
				if(argv[i][5])
				{
					gSmrImage = ETrue;
					gSmrFileName = (TText*)strdup(&argv[i][5]);
				}
				else
				{
					Print (EError, "SMR obey file is missing\n");
				}
			}
			else if (argv[i][1] == 'S')
				{
				SizeSummary=ETrue;
				if (argv[i][2] == 'L')
					SizeWhere=ELog;
				if (argv[i][2] == 'S')
					SizeWhere=EScreen;
				}
			else if (strncmp(argv[i],ParamFileArg.c_str(),ParamFileArg.length())==0)
				{
					if (paramFileFlag)
					{
						String paramFile;
						paramFile.assign(&argv[i][ParamFileArg.length()]);		
						processParamfile(paramFile);
					}
					else
					{
						i++;
						continue;
					}
				}
			else if (strcmp(argv[i], "-COMPRESS")==0)
				{
				gCompress=ECompressionCompress;
				gCompressionMethod = KUidCompressionDeflate;
				}
			else if (strcmp(argv[i], "-FASTCOMPRESS")==0)
				{
				gFastCompress=ETrue;
				}
			else if (strncmp(argv[i], "-J",2)==0)
				{
					if(argv[i][2])
						gThreadNum = atoi(&argv[i][2]);
					else
						{
						printf("WARNING: The option should be like '-j4'.\n");
						gThreadNum = 0;
						}
					if(gThreadNum <= 0 || gThreadNum > MAXIMUM_THREADS)
						{
						if(gCPUNum > 0 && gCPUNum <= MAXIMUM_THREADS)
							{
							printf("WARNING: The number of concurrent jobs set by -j should be between 1 and 128. And the number of processors %d will be used as the number of concurrent jobs.\n", gCPUNum);
							gThreadNum = gCPUNum;
							}
						else if(g_pCharCPUNum)
							{
							printf("WARNING: The number of concurrent jobs set by -j should be between 1 and 128. And the NUMBER_OF_PROCESSORS is invalid, so the default value %d will be used.\n", DEFAULT_THREADS);
							gThreadNum = DEFAULT_THREADS;
							}
						else
							{
							printf("WARNING: The number of concurrent jobs set by -j should be between 1 and 128. And the NUMBER_OF_PROCESSORS is not available, so the default value %d will be used.\n", DEFAULT_THREADS);
							gThreadNum = DEFAULT_THREADS;
							}
						}
				}
			else if (strcmp(argv[i], "-UNCOMPRESS")==0)
				{
				gCompress=ECompressionUncompress;
				}
			else if( strcmp(argv[i], "-COMPRESSIONMETHOD") == 0 )
				{
					// next argument should a be method
					if( (i+1) >= argc || argv[i+1][0] == '-') 
					{
					Print (EError, "Missing compression method! Set it to default (no compression)!");
					gCompressionMethod = 0;
					}
					else 
					{
					i++;
					strupr(argv[i]);
					if( strcmp(argv[i], "NONE") == 0)	
						{
						gCompress=ECompressionUncompress;
						gCompressionMethod = 0;	
						}
					else if( strcmp(argv[i], "INFLATE") == 0)
						{
						gCompress=ECompressionCompress;
						gCompressionMethod = KUidCompressionDeflate;	
						}	
					else if( strcmp(argv[i], "BYTEPAIR") == 0)
						{
						gCompress=ECompressionCompress;
						gCompressionMethod = KUidCompressionBytePair;	
						}
					else
						{
						Print (EError, "Unknown compression method! Set it to default (no compression)!");
						gCompress=ECompressionUnknown;
						gCompressionMethod = 0;		
						}
					}
					
				}
			else if (strcmp(argv[i], "-COREIMAGE") ==0)
				{
					gUseCoreImage = ETrue;

					// next argument should be image filename
					if ((i+1 >= argc) || argv[i+1][0] == '-')
						Print (EError, "Missing image file name");
					else
					{
						i++;
						gImageFilename = strdup(argv[i]);
					}
				}
			else if (strncmp(argv[i], "-DATADRIVE=",11) ==0)
				{  
				   	if(argv[i][11])	
						{
						gDriveImage = ETrue; 
						gDriveFilename = (TText*)strdup(&argv[i][11]);	
						}
					else
						{
						Print (EError, "Drive obey file is missing\n"); 
						}
				}
			else if (argv[i][1] == '?')
				{
				reallyHelp=ETrue;
				}
 			else if (strcmp(argv[i], "-WSTDPATH") ==0)		// Warn if destination path provided for a executables are incorrect as per platsec.		
 				{
 				gEnableStdPathWarning=ETrue;						
 				}
			
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
			else if( strcmp(argv[i], "-LOGLEVEL2") == 0)
				gLogLevel = (LOG_LEVEL_FILE_DETAILS | LOG_LEVEL_FILE_ATTRIBUTES);
			else if( strcmp(argv[i], "-LOGLEVEL1") == 0)
				gLogLevel = LOG_LEVEL_FILE_DETAILS;
			else if( strcmp(argv[i], "-LOGLEVEL0") == 0)
				gLogLevel = DEFAULT_LOG_LEVEL;
			else if (strcmp(argv[i], "-LOWMEM") == 0)
				gLowMem = ETrue;
			else 
				cout << "Unrecognised option " << argv[i] << "\n";
			}
		else // Must be the obey filename
			filename=argv[i];
		i++;
		}
	
		if (paramFileFlag)
		return;

		if((gDriveImage == EFalse) && (gSmrImage ==  EFalse) && (filename.empty() || (gUseCoreImage && gImageFilename == NULL)))
		{
		PrintVersion();
		cout << HelpText;
		if (reallyHelp)
			{
			ObeyFileReader::KeywordHelp();
			cout << ReallyHelpText;
			}
		else if (filename.empty())
			{
			Print(EError, "Obey filename is missing\n");
			}
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
		processCommandLine(noOfParameters,parameters,paramFileFlag);
	}	
}

/**
Main logic for data drive image creation. Called many types depending on no. of drive obey files.

@param aobeyFileName - Drive obey file.
@param alogfile      - log file name required for file system module.
 
@return - returns the status, after processing the drive obey file.
*/ 
TInt ProcessDataDriveMain(TText* aobeyFileName,TText* alogfile)
	{

	ObeyFileReader *reader=new ObeyFileReader(aobeyFileName);

	if(!reader)
		return KErrNoMemory;

	if(!reader->Open())
    {
        if (reader)
        {
            delete reader;
        }
		return KErrGeneral;
    }

	TInt retstatus =0;		
	CObeyFile* mainObeyFile=new CObeyFile(*reader);   
	CDriveImage* userImage = 0; 

	if(!mainObeyFile)
    {
        if (reader)
        {
            delete reader;
        }
		return KErrNoMemory;
    }

	// Process data drive image.
	// let's clear the TRomNode::sDefaultInitialAttr first, 'cause data drive is different from rom image
	TRomNode::sDefaultInitialAttr = 0; 
	retstatus = mainObeyFile->ProcessDataDrive();
	if (retstatus == KErrNone)
		{
		// Build a Data drive image using the description compiled into the CObeyFile object
		userImage = new CDriveImage(mainObeyFile);
		if(userImage)
			{	
			// Drive image creation.
			retstatus = userImage->CreateImage(alogfile);
			if(retstatus == KErrNone)
				{
				cout << "\nSuccessfully generated the Drive image : " << mainObeyFile->iDriveFileName << "\n";
				}
			else
				{
				cout << "\nFailed to generate the Image : " << mainObeyFile->iDriveFileName << "\n";
				}

			delete userImage;
			userImage = 0;
			}
		else
			{
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

TInt ProcessSmrImageMain(TText* aObeyFileName, TText* /* alogfile */)
{
	ObeyFileReader *reader = new ObeyFileReader(aObeyFileName);
	if(!reader)
		return KErrNoMemory;
	if(!reader->Open())
    {
        if (reader)
        {
            delete reader;
        }
		return KErrGeneral;
    }
	TInt retstatus = 0;
	CObeyFile* mainObeyFile = new CObeyFile(*reader);
	CSmrImage* smrImage = 0;
	if(!mainObeyFile)
    {
        if (reader)
        {
            delete reader;
        }
		return KErrNoMemory;
    }

	if(mainObeyFile->Process())
	{
		smrImage = new CSmrImage(mainObeyFile);
		if(smrImage)
		{
			if((retstatus=smrImage->Initialise()) == KErrNone)
			{
				retstatus = smrImage->CreateImage();
			}
			if(retstatus == KErrNone)
			{
				cout << "\nSuccessfully generated the SMR image : " << smrImage->GetImageName().c_str() << "\n";
			}
			else
			{
				cout << "\nFailed to generate the Image : " << smrImage->GetImageName().c_str() << "\n";
			}
			delete smrImage;
		}
		else
		{
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
TInt main(int argc, char *argv[])
{
	TInt r =0;	

	g_pCharCPUNum = getenv("NUMBER_OF_PROCESSORS");
	if(g_pCharCPUNum != NULL)
		gCPUNum = atoi(g_pCharCPUNum);

 	processCommandLine(argc, argv);

 	TText *obeyFileName = NULL;	
 	if(!filename.empty())
 		obeyFileName=(TText*)filename.c_str();	

	if ((obeyFileName==NULL) && (gDriveFilename==NULL) && (gSmrFileName == NULL))                   
		return KErrGeneral;
	
	if(gThreadNum == 0)
	{
		if(gCPUNum > 0 && gCPUNum <= MAXIMUM_THREADS)
		{
			printf("The number of processors (%d) is used as the number of concurrent jobs.\n", gCPUNum);
			gThreadNum = gCPUNum;
		}
		else if(g_pCharCPUNum)
		{
			printf("WARNING: The NUMBER_OF_PROCESSORS is invalid, and the default value %d will be used.\n", DEFAULT_THREADS);
			gThreadNum = DEFAULT_THREADS;
		}
		else
		{
			printf("WARNING: The NUMBER_OF_PROCESSORS is not available, and the default value %d will be used.\n", DEFAULT_THREADS);
			gThreadNum = DEFAULT_THREADS;
		}
	}

	// Process drive obey files.
	if(gDriveImage)
	{  
		TText temp = 0;
		TText *driveobeyFileName = gDriveFilename;
		
		do
		{
			while(((temp = *gDriveFilename++) != ',') && (temp != 0));
			*(--gDriveFilename)++ = 0;
			
			if(*driveobeyFileName)
			{	
				TText* logfile = 0;
				if(Getlogfile(driveobeyFileName,logfile)== KErrNone)
				{
					H.SetLogFile(logfile);	
					PrintVersion();
					GetLocalTime();
					r = ProcessDataDriveMain(driveobeyFileName,logfile);   
					H.CloseLogFile();
					delete[] logfile;
					if(r == KErrNoMemory)
						return KErrNoMemory;
				}
				else
				{
					cout << "Error : Invalid obey file name : " << driveobeyFileName << "\n" ;   
				}
			}
			driveobeyFileName = gDriveFilename;
		}
		while(temp != 0);   
		
		gDriveImage=EFalse;
	} 
	if(gSmrImage)
	{
		TText temp = 0;
		TText *smrImageObeyFileName = gSmrFileName;
		do
		{
			while(((temp = *gSmrFileName++) != ',') && (temp != 0));
			*(--gSmrFileName)++ = 0;
			if(*smrImageObeyFileName)
			{	
				TText * logfile = 0;
				if(Getlogfile(smrImageObeyFileName,logfile) == KErrNone)
				{
					H.SetLogFile(logfile);
					PrintVersion();
					GetLocalTime();
					r = ProcessSmrImageMain(smrImageObeyFileName, logfile);
					H.CloseLogFile();
					delete[] logfile;
					if(r == KErrNoMemory)
						return KErrNoMemory;
				}
				else
				{
					cout << "Error: Invalid obey file name: " << smrImageObeyFileName << "\n";
				}
			}
			smrImageObeyFileName = gSmrFileName;
		}
		while(temp != 0);
		gSmrImage = EFalse;
	}
	// Process Rofs Obey files.
	if(obeyFileName)
	{
		
		H.SetLogFile((unsigned char *)"ROFSBUILD.LOG");	
		PrintVersion();
		
		ObeyFileReader *reader=new ObeyFileReader(obeyFileName);
		if (!reader->Open())
			return KErrGeneral;
		
		E32Rofs* RofsImage = 0;		// for image from obey file
		CCoreImage *core= 0;		// for image from core image file
		MRofsImage* imageInfo=0;
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
				gImageFilename = (char *)file;
			}
		}
		
		if (!gUseCoreImage)
		{
			
			r=mainObeyFile->ProcessRofs();
			if (r==KErrNone)
			{
				// Build a ROFS image using the description compiled into the
				// CObeyFile object
				
				RofsImage = new E32Rofs( mainObeyFile );
				if( !RofsImage )
				{
					return KErrNoMemory;
				}
				
				r = RofsImage->Create();
				if( KErrNone == r )
				{
					if(SizeSummary)
						RofsImage->DisplaySizes(SizeWhere);
					RofsImage->WriteImage( gHeaderType );
				}
				imageInfo = RofsImage;
				mainObeyFile->Release();
			}
			else if (r!=KErrNotFound)
				return r;
		}
		else
		{
			
			// need to use core image
			RCoreImageReader *reader = new RCoreImageReader(gImageFilename);
			if (!reader)
			{
				return KErrNoMemory;
			}
			core= new CCoreImage(reader);
			if (!core)
			{
				return KErrNoMemory;
			}
			r = core->ProcessImage();
			if (r != KErrNone)
				return r;
			imageInfo = core;
			mainObeyFile->SkipToExtension();
			
		}
		
		do 
		{
			CObeyFile* extensionObeyFile = 0;
			E32Rofs* extensionRofs = 0;
			
			extensionObeyFile = new CObeyFile(*reader);
			r = extensionObeyFile->ProcessExtensionRofs(imageInfo);
			if (r==KErrEof)
			{
				if(RofsImage)
					delete RofsImage;
				if(core)
					delete core;
				delete extensionObeyFile;
				return KErrNone;
			}
			if (r!=KErrNone)
				break;
			
			extensionRofs = new E32Rofs(extensionObeyFile);
			r=extensionRofs->CreateExtension(imageInfo);
			if (r!=KErrNone)
			{
				delete extensionRofs;
				delete extensionObeyFile;
				break;
			}
			if(SizeSummary)
				RofsImage->DisplaySizes(SizeWhere);
			r=extensionRofs->WriteImage(0);		
			delete extensionRofs;
			delete extensionObeyFile;
			extensionRofs = 0;
			extensionObeyFile = 0;
			
		}
		while (r==KErrNone);
		
		if(RofsImage) 
			delete RofsImage;									
		if(core)
			delete core;
		delete mainObeyFile;
		
	}
	return r;
}//end of main.
