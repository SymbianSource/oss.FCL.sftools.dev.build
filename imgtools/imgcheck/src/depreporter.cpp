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
* Reports Executable Dependency
*
*/


/**
 @file
 @internalComponent
 @released
*/
#include "depreporter.h"

/**
Constructor: DepReporter class
Initilize the parameters to data members.

@internalComponent
@released

@param aMap		   - Reference to map data
@param aReportType - Reference to report type.
@param aXmlFile	   - Pointer to xml file name.
*/
DepReporter::DepReporter(const StringVsMapOfExeVsDep& aMap, const unsigned int& aReportType, const char* aXmlFile)
: Reporter(aReportType,aXmlFile), iReportData(aMap)
{
}


/**
Destructor: DepReporter class

@internalComponent
@released
*/
DepReporter::~DepReporter()
{
}


/**
Generates the Report of mentioned type.

Checks the validty of input data.
Construct the report objects(Based on options).
Traverse the Map and generate the report.

@internalComponent
@released

@return Status - returns the status of the depreporter.
				 'true' - for sucessful completion of the report.
*/
bool DepReporter::CreateReport()
{
	try
	{
		// Check for the empty map.
		if (iReportData.empty() != 0)
		{
			throw ExceptionReporter(NODATATOREPORT);
		}
	 	// Check for valid Xml filename for report generation.
		if (iReportType & XML_REPORT)
		{
			if (iXmlFileName.size() <= 0)
			{
				throw ExceptionReporter(XMLNAMENOTVALID);
			}
		}
		ConstructReportObjects();
		ProcessMapData();
	}
	catch (ExceptionReporter& aErrorReport)
	{
		throw aErrorReport;
	}
	return true;
}


/**
Traverse the map and Creates the report.
Both rom and rofs image is supported.

@internalComponent
@released
*/
void DepReporter::ProcessMapData(void)
{
	StringVsMapOfExeVsDep::const_iterator aIterMapBegin = iReportData.begin();
	StringVsMapOfExeVsDep::const_iterator aIterMapEnd = iReportData.end();
	const ExeNamesVsDepMapData* exeNamesVsDepMapDataAddress = 0;
	ExeNamesVsDepMapData::const_iterator aIterExeNameBegin;
	ExeNamesVsDepMapData::const_iterator aIterExeNameEnd;
	const NameVsDepStatusData* nameVsDepStatusDataAddress = 0;
	NameVsDepStatusData::const_iterator aIterNameVsDepBegin;
	NameVsDepStatusData::const_iterator aIterNameVsDepEnd;

	ConstructReport(KReportStart);
	
	for (; aIterMapBegin != aIterMapEnd ; ++aIterMapBegin)
	{
		//If no dependency data found don't display the empty report
		if(((*aIterMapBegin).second).size() == 0)
		{
			ExceptionReporter(NOMISSINGDEPS, (char*)(*aIterMapBegin).first.c_str()).Report();
			continue;
		}
		ConstructReport(KReportStartElementHeader,aIterMapBegin->first);
		exeNamesVsDepMapDataAddress = &aIterMapBegin->second;
		if(exeNamesVsDepMapDataAddress->empty() != 0)
		{
			ConstructReport(KReportEndElementHeader);
			continue; 
		}
		aIterExeNameBegin = exeNamesVsDepMapDataAddress->begin();
		aIterExeNameEnd = exeNamesVsDepMapDataAddress->end();

		// Traverse the executable.
		for( ; aIterExeNameBegin != aIterExeNameEnd ; ++aIterExeNameBegin)
		{
		
			ConstructReport(KReportStartExecutable,"",aIterExeNameBegin->first);
			nameVsDepStatusDataAddress = &aIterExeNameBegin->second;
			if(nameVsDepStatusDataAddress->empty() != 0)
			{
			ConstructReport(KReportEndExecutable);
			continue; 
			}
			aIterNameVsDepBegin = nameVsDepStatusDataAddress->begin();
			aIterNameVsDepEnd = nameVsDepStatusDataAddress->end();

			// Traverse the dependencies.
			for(; aIterNameVsDepBegin != aIterNameVsDepEnd ; ++aIterNameVsDepBegin)
			{
				ConstructReport(KReportWriteDependency,"",
						"", aIterNameVsDepBegin->first,
						aIterNameVsDepBegin->second);
			}
			ConstructReport(KReportEndExecutable);
		}
		ConstructReport(KReportEndElementHeader);
		ConstructReport(KReportWriteNote);
	}
	ConstructReport(KReportEnd);
}


/**
Writes the Report sections to the report objects.

@internalComponent
@released

@param aReportSection - Reference to Report section
@param aImageName	  - Reference to Image Name string.
@param aExeName	      - Reference to Executable string.
@param aDepName		  - Reference to Dependency Name string.
@param aDepStatus	  - Reference to Dependency Status string.
*/
void DepReporter::ConstructReport(EReportSection aReportSection, const String& aImageName,
								  const String& aExeName, const String& aDepName,
								  const String& aDepStatus)
{
	ReportWriter* iReportBasePointer = 0;
	int count = iReportObjectList.size();
	while(count)
	{
		iReportBasePointer = (ReportWriter*)iReportObjectList[count-1];
		switch(aReportSection)
		{
			// Start Report document.
			case KReportStart	:
				iReportBasePointer->StartReport();
				break;

			// End Report document.
			case KReportEnd	:
				iReportBasePointer->EndReport();
				break;

			// Start element header info.
			case KReportStartElementHeader	:
				iReportBasePointer->StartElementHeader(aImageName);
				iReportBasePointer->WriteImageHeader(KCmdDependencyHeader);
				break;

			// End element header info.
			case KReportEndElementHeader :	
				iReportBasePointer->EndElementHeader();
				break;

			// Start Executable info.
			case KReportStartExecutable :	
				iReportBasePointer->StartExecutable(aExeName);
				break;

			// End Executable info.
			case KReportEndExecutable :	
				iReportBasePointer->EndExecutable();
				break;

			// Write element details
			case KReportWriteDependency	:	
				iReportBasePointer->WriteElementDependencies(aDepName, aDepStatus);
				break;

			// Write a note about unknown dependency
			case KReportWriteNote :
				iReportBasePointer->WriteNote();
				break;

			// Do nothing..
			default	:	
				break;
		}
	--count;
	}
}
