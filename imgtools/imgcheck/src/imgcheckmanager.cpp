/*
* Copyright (c) 2008-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* ImgCheckManager controller class Controls the instantiation and 
* operations of ImageReader, Checker, Reporter and ReportWriter.
*
*/


/**
 @file
 @internalComponent
 @released
*/

#include "imgcheckmanager.h"
#include "romreader.h"
#include "rofsreader.h"
#include "dirreader.h"
#include "depchecker.h"
#include "sidchecker.h"
#include "vidchecker.h"
#include "dbgflagchecker.h"

/**
Constructor initializes command line handler pointer.
Which can be used by any tool which is derived from this class.

@internalComponent
@released

@param aCmdPtr - command line handler pointer
*/
ImgCheckManager::ImgCheckManager(CmdLineHandler* aCmdPtr)
:iCmdLine(aCmdPtr)
{
	iReporter = Reporter::Instance(iCmdLine->ReportFlag());
	iNoRomImage = true; 
}

/**
Destructor traverses through the imagereader list and delets the same

@internalComponent
@released
*/
ImgCheckManager::~ImgCheckManager()
{
	while(iImageReaderList.size() > 0)
	{
		DELETE(iImageReaderList.back());
		iImageReaderList.pop_back();
	}
	while(iCheckerList.size() > 0)
	{
		DELETE(iCheckerList.back());
		iCheckerList.pop_back();
	}
	while(iWriterList.size() > 0)
	{
		DELETE(iWriterList.back())
		iWriterList.pop_back();
	}
	Reporter::DeleteInstance();
	iCmdLine = 0;
}

/**
Function responsible to read the header and directory section.

@internalComponent
@released

@param aImageName - image name
@param aImageType - image type
*/
void ImgCheckManager::Process(ImageReader* aImageReader)
{
	ExceptionReporter(READINGIMAGE,(char*)aImageReader->ImageName().c_str()).Log();
	aImageReader->ReadImage();
	aImageReader->ProcessImage();
	if(!aImageReader->ExecutableAvailable())
	{
		throw ExceptionReporter(NOEXEPRESENT);
	}
}

/**
Function responsible to 
1. get the image names one by one. 
2. Identify the image type and Create respective Reader objects.
3. Identify the required validations and create respective Instances.
4. Identify the required Writers and create respective instances.

@internalComponent
@released
*/
void ImgCheckManager::CreateObjects(void)
{
	unsigned int imgCnt = iCmdLine->NoOfImages();
	String imgName;
	
	while(imgCnt > 0)
	{	
		imgName = iCmdLine->NextImageName();
		--imgCnt;
		HandleImage(imgName);
	}

	Checker* checkerPtr = KNull;
	unsigned int checks = iCmdLine->EnabledValidations();
	unsigned short int bitPos = 1;
	while(bitPos)
	{
		if(bitPos & checks)
		{
			switch(bitPos)
			{
			case EDep:
				checkerPtr = new DepChecker(iCmdLine, iImageReaderList,iNoRomImage);
				break;
			case ESid:
				checkerPtr = new SidChecker(iCmdLine, iImageReaderList);
				break;
			case EVid:
				checkerPtr = new VidChecker(iCmdLine, iImageReaderList);
				break;
			case EDbg:
				checkerPtr = new DbgFlagChecker(iCmdLine, iImageReaderList);
				break;
			}
			if(checkerPtr == KNull)
			{
				throw ExceptionReporter(NOMEMORY, __FILE__, __LINE__);
			}
			iCheckerList.push_back(checkerPtr);
		}
		bitPos <<= 1; //Shift one bit left
	}

	unsigned int rptFlag = iCmdLine->ReportFlag();
	ReportWriter* rptWriter = KNull;
	if(!( rptFlag & QuietMode))
	{
		rptWriter = new CmdLineWriter(rptFlag);
		InsertWriter(rptWriter);
	}
	if(iCmdLine->ReportFlag() & KXmlReport)
	{
		rptWriter = new XmlWriter(iCmdLine->XmlReportName(), iCmdLine->Command());
		InsertWriter(rptWriter);
	}
}

/**
Function responsible to insert the ReprtWriter into iWriterList

@internalComponent
@released
*/
void ImgCheckManager::InsertWriter(ReportWriter* aWriter)
{
	if(aWriter == KNull)
	{
		throw ExceptionReporter(NOMEMORY, __FILE__, __LINE__);
	}
	iWriterList.push_back(aWriter);
}

/**
Function responsible to initiate the enabled validations

@internalComponent
@released
*/
void ImgCheckManager::Execute(void)
{
	unsigned int cnt = 0;
	ImgVsExeStatus& imgVsExeStatus = iReporter->GetContainerReference();
	while(cnt < iCheckerList.size())
	{
		iCheckerList[cnt++]->Check(imgVsExeStatus);
	}
}

/**
Function responsible to write the validated data into Reporter.

@internalComponent
@released
*/
void ImgCheckManager::FillReporterData(void)
{
	
	ImgVsExeStatus& imgVsExeStatus = iReporter->GetContainerReference();
	ImgVsExeStatus::iterator imgBegin = imgVsExeStatus.begin();
	ImgVsExeStatus::iterator imgEnd = imgVsExeStatus.end();
	
	ExeVsMetaData::iterator exeBegin;
	ExeVsMetaData::iterator exeEnd;


	while(imgBegin != imgEnd)
	{
		ExeVsMetaData& exeVsMetaData = imgBegin->second;
		exeBegin = exeVsMetaData.begin();
		exeEnd = exeVsMetaData.end();
		while(exeBegin != exeEnd)
		{
			ExeContainer& exeContainer = (*exeBegin).second;

			unsigned int cnt = 0;
			while(cnt < iCheckerList.size())
			{
				iCheckerList[cnt++]->PrepareAndWriteData(&exeContainer);
			}
			++exeBegin;
		}
		++imgBegin;
	}
}

/**
Function responsible to start report generation. This function invokes the Reporter's
CreateReport function by passing iWriterList as argument.

@internalComponent
@released

@return - returns the return value of Reporter::CreateReport function.
*/
void ImgCheckManager::GenerateReport(void)
{
	iReporter->CreateReport(iWriterList);
}

/** 
Function to identify the image type and read the header and file and/or directory entries.

@internalComponent
@released

@param aImageName - image name received as part of command line
@param EImageType - type of the input image
*/
void ImgCheckManager::HandleImage(const String& aImageName, EImageType aImageType)
{
	unsigned int rptFlag = iCmdLine->ReportFlag();
	if(rptFlag & KE32Input)
	{
		aImageType = DirReader::EntryType((char*)aImageName.c_str());
	}
	else if(aImageType == EUnknownImage)
	{
		aImageType = ImageReader::ReadImageType(aImageName);
	}
	ImageReader* imgReader = KNull;

	switch(aImageType)
	{
	case ERomImage:
		iNoRomImage = false;
	case ERomExImage:
		imgReader = new RomReader((char*)aImageName.c_str(), aImageType);
		break;

	case ERofsImage:
	case ERofsExImage:
		imgReader = new RofsReader((char*)aImageName.c_str(), aImageType);
		break;

	case EE32Directoy:
		imgReader = new DirReader((char*)aImageName.c_str());
		break;
	
	case EE32File:
		imgReader = new E32Reader((char*)aImageName.c_str());
		break;

	case EUnknownImage:
		throw ExceptionReporter(UNKNOWNIMAGETYPE, (char*)aImageName.c_str());
		break;

	case EE32InputNotExist:
		throw ExceptionReporter(E32INPUTNOTEXIST, (char*)aImageName.c_str());
		break;
	}
	if(imgReader == KNull)
	{
		throw ExceptionReporter(NOMEMORY, __FILE__, __LINE__);
	}
	Process(imgReader);
	iImageReaderList.push_back(imgReader);
}
