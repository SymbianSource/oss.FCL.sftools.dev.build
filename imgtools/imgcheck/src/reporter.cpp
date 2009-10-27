/*
* Copyright (c) 2007-2009 Nokia Corporation and/or its subsidiary(-ies).
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
* Base for commandline or xml report generation.
*
*/


/**
 @file
 @internalComponent
 @released
*/

#include "reporter.h"

/**
Static variable as instance pointer

@internalComponent
@released
*/
Reporter* Reporter::iInstance = KNull;

/**
Constructor: Reporter class
Initilize the parameters to data members.

@internalComponent
@released
*/
Reporter::Reporter(unsigned int aCmdOptions)
:iInputOptions(aCmdOptions)
{
}


/**
Destructor: Reporter class 
Release the objects. 

@internalComponent
@released
*/
Reporter::~Reporter()
{
	iImgVsExeStatus.clear();
}

/**
Function responsible to return the reference of iImgVsExeStatus

@internalComponent
@released

@return - returns the reference of iImgVsExeStatus
*/
ImgVsExeStatus& Reporter::GetContainerReference()
{
	return iImgVsExeStatus;
}


/**
Function responsible to create the report instances.

@internalComponent
@released

@param aReportType - report type either commandline or XML
@param aXmlFile - if XML then pass the xml filename

@return - return the new report instance created
*/
Reporter* Reporter::Instance(unsigned int aCmdOptions)
{
	if(iInstance == KNull)
	{
		iInstance = new Reporter(aCmdOptions);
		if(!iInstance)
		{
			throw ExceptionReporter(NOMEMORY, __FILE__, __LINE__);
		}
	}
	return iInstance;
}

/**
Function to delete the instance.

@internalComponent
@released
*/
void Reporter::DeleteInstance()
{
	DELETE(iInstance);
}


/**
Function responsible to create the report which is common for both the XML and command line output.

@internalComponent
@released

@param aWriterList - Container which stores the report objects
*/
void Reporter::CreateReport(const WriterPtrList& aWriterList)
{
	int wtrPtrLstCnt = aWriterList.size();
	int attrCnt=0;
	int serNo = 0;
	ReportWriter* rptWriter = KNull;

	// fetches the begin and end of the image and the related data from the integrated container
	ImgVsExeStatus::iterator imgBegin;
	ImgVsExeStatus::iterator imgEnd;

	ExeVsMetaData::iterator exeBegin;
	ExeVsMetaData::iterator exeEnd;
	
	if(IsAttributeAvailable())
	{
		while(wtrPtrLstCnt)
		{
			imgBegin = iImgVsExeStatus.begin();
			imgEnd = iImgVsExeStatus.end();

			rptWriter = aWriterList[wtrPtrLstCnt-1];
			ExceptionReporter(GENERATINGREPORT, (char*)rptWriter->ReportType().c_str()).Log();
			// starts the report
			rptWriter->StartReport();
			
			while(imgBegin != imgEnd)
			{
				// starts the image
				rptWriter->StartImage(imgBegin->first);

				// fetches the begin and end of the executable container
				ExeVsMetaData& exeAttStatus = imgBegin->second;
				exeBegin = exeAttStatus.begin();
				exeEnd = exeAttStatus.end();
				serNo = 1;
				while(exeBegin != exeEnd)
				{
					ExeAttList exeAttList = exeBegin->second.iExeAttList;
					attrCnt = exeAttList.size();
					if(attrCnt)
					{
						// starts the executable	
						rptWriter->StartExecutable(serNo, exeBegin->first);
					
						while(attrCnt)
						{
							// writes the attributes
							rptWriter->WriteExeAttribute(*exeAttList.front());
							if(wtrPtrLstCnt == 1)
							{
								DELETE(exeAttList.front()); //If no more reports to be generated, delete it
							}
							exeAttList.pop_front();
							--attrCnt;
						}
						// ends the executable
						rptWriter->EndExecutable();	
						++serNo;
					}
					++exeBegin;
				}
				++imgBegin;
				// ends the image
				rptWriter->EndImage();
			}
			rptWriter->WriteNote();
			// ends the report
			rptWriter->EndReport();
			--wtrPtrLstCnt;
		}
		ExceptionReporter(REPORTGENERATION,"Success").Log();
	}
	else
	{
		if(iInputOptions & KE32Input)
		{
			ExceptionReporter(VALIDE32INPUT).Report();
		}
		else
		{
			ExceptionReporter(VALIDIMAGE).Report();
		}
	}
}

/**
Function checks if the attributes are valid and are not blank.

@internalComponent
@released

*/
bool Reporter::IsAttributeAvailable()
{
	ImgVsExeStatus::iterator imgBegin = iImgVsExeStatus.begin();
	ImgVsExeStatus::iterator imgEnd = iImgVsExeStatus.end();

	ExeVsMetaData::iterator exeBegin;
	ExeVsMetaData::iterator exeEnd;

	while(imgBegin != imgEnd)
	{
		ExeVsMetaData& exeVsMetaData = imgBegin->second;

		exeBegin = exeVsMetaData.begin();
		exeEnd = exeVsMetaData.end();
		while(exeBegin != exeEnd)
		{
			if((exeBegin->second).iExeAttList.size() == 0)
			{
				++exeBegin;
				continue;
			}
			else
			{
				return true;
			}
			++exeBegin;
		}
		++imgBegin;
	}
	return false;
}
