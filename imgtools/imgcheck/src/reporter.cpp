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
:iInputOptions(aCmdOptions) {
}


/**
Destructor: Reporter class 
Release the objects. 

@internalComponent
@released
*/
Reporter::~Reporter() {
	for(ImgVsExeStatus::iterator it = iImgVsExeStatus.begin() ; it != iImgVsExeStatus.end(); it++)
		delete it->second; 
	iImgVsExeStatus.clear();
}

/**
Function responsible to return the reference of iImgVsExeStatus

@internalComponent
@released

@return - returns the reference of iImgVsExeStatus
*/
ImgVsExeStatus& Reporter::GetContainerReference() {
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
Reporter* Reporter::Instance(unsigned int aCmdOptions) {
	if(iInstance == KNull) {
		iInstance = new Reporter(aCmdOptions);
		if(!iInstance) {
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
void Reporter::DeleteInstance() {
	if(NULL != iInstance) {
	  delete iInstance;
	  iInstance = 0 ;
	}
}


/**
Function responsible to create the report which is common for both the XML and command line output.

@internalComponent
@released

@param aWriterList - Container which stores the report objects
*/
void Reporter::CreateReport(const WriterPtrList& aWriterList) {
	int maxIndex = aWriterList.size() - 1;  
	int serNo = 0; 
	// fetches the begin and end of the image and the related data from the integrated container 
	if(IsAttributeAvailable()) {
		for(int i = 0 ; i <= maxIndex ; i++) { 
			ReportWriter* writer = aWriterList.at(i) ;
			ExceptionReporter(GENERATINGREPORT, writer->ReportType().c_str()).Log(); 
			// starts the report			
			writer->StartReport();			
			for(ImgVsExeStatus::iterator j = iImgVsExeStatus.begin();
			j != iImgVsExeStatus.end(); j++) {
				// starts the image
				writer->StartImage(j->first);

				// fetches the begin and end of the executable container
				ExeVsMetaData* exeAttStatus = j->second; 
				serNo = 1;
				for(ExeVsMetaData::iterator k = exeAttStatus->begin(); 
				k != exeAttStatus->end(); k++ ) {
					ExeAttList exeAttList = k->second.iExeAttList;
					int attrCnt = exeAttList.size();
					for(int ii = 0 ; ii < attrCnt ; ii++) {
						// starts the executable	
						if(ii == 0)
							writer->StartExecutable(serNo, k->first);					
						 
						// writes the attributes
						ExeAttribute* attr = exeAttList.front();											
						if(attr) { 
							writer->WriteExeAttribute(*attr);
							//If no more reports to be generated, delete it
							if(maxIndex == i ) delete attr; 
							
						}
						exeAttList.pop_front(); 
						if(ii == attrCnt - 1){
						// ends the executable
							writer->EndExecutable();	
							++serNo;
						}
					} 
				} 
				// ends the image
				writer->EndImage();
			}
			writer->WriteNote();
			// ends the report
			writer->EndReport();  
		}
		ExceptionReporter(REPORTGENERATION,"Success").Log();
	}
	else {
		if(iInputOptions & KE32Input) {
			ExceptionReporter(VALIDE32INPUT).Report();
		}
		else {
			ExceptionReporter(VALIDIMAGE).Report();
		}
	}
}

/**
Function checks if the attributes are valid and are not blank.

@internalComponent
@released

*/
bool Reporter::IsAttributeAvailable() { 
	for(ImgVsExeStatus::iterator i = iImgVsExeStatus.begin(); 
		i != iImgVsExeStatus.end(); i++) {
		ExeVsMetaData* d = i->second; 
		for(ExeVsMetaData::iterator j = d->begin() ; j != d->end() ; j++) {
			if(j->second.iExeAttList.size() > 0)
				return true ;
		}
	}
	return false;
}
