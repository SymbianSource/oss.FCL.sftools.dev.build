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
* Writes XML elements into output stream to generate a XML file
*
*/


/**
@file
@internalComponent
@released
*/

#include "xmlwriter.h"

#ifndef __LINUX__		
#include <windows.h>	
#endif //__LINUX__

/**
Constructor: XmlWriter class

@internalComponent
@released

@param aXmlfileName - Reference to xml filename.
@param iInputCommnd - Reference to the input options
*/
XmlWriter::XmlWriter(const string& aXmlFileName, const string& aInputCommand)
: iXmlFileName(aXmlFileName), iXmlBufPtr(0) , iXmlTextWriter(0) , iInputCommnd(aInputCommand), iRptType(KXml) {
}


/**
Destructor : XmlWriter class
Closes the Xml output file.

@internalComponent
@released
*/
XmlWriter::~XmlWriter(void) {
	if(iXmlFile.is_open()) {
		iXmlFile.close();
	}
}


/**
Create the XSL file, OverWrites if exist.
Get the Xsl Source Path.

@internalComponent
@released

@returns : 'True' for Success or 'False'.
*/		   
int XmlWriter::CreateXslFile(void) {
	// Validate the user entered xml path.
	char* xslFileName = (char*)iXmlFileName.c_str(); 
	string xslSourcePath("");

	while(*xslFileName) {
		if(*xslFileName == '\\') {
			*xslFileName = '/';
		}
		xslFileName++ ;
	}
	string xslDestPath(iXmlFileName);
	unsigned int position = xslDestPath.rfind('/');
	if(position != string::npos) {
		xslDestPath.erase(position+1);
		xslDestPath.append(KXslFileName);
	}
	else { 
		xslDestPath.assign(KXslFileName);
	}

	if(!(GetXslSourcePath(xslSourcePath))) { 
		return false;
	}
	xslSourcePath.append(KXslFileName);

	ifstream xslSourceHandle;
	xslSourceHandle.open(xslSourcePath.c_str(), ios_base::binary | ios_base::in);
	if(!xslSourceHandle) { 
		return false;
	}
	xslSourceHandle.seekg(0, ios_base::end);		
	int fileSize = xslSourceHandle.tellg();
	xslSourceHandle.seekg(0, ios_base::beg);
	char* buffer = new char[fileSize];
	if (!buffer) {
		throw ExceptionReporter(NOMEMORY, __FILE__, __LINE__);
	}
	xslSourceHandle.read(buffer,fileSize);
	xslSourceHandle.close();

	ofstream xslDestHandle(xslDestPath.c_str(), ios_base::binary | ios_base::out);
	if(!xslDestHandle) {
		delete [] buffer; 
		return false;
	}
	xslDestHandle.write(buffer,fileSize);			
	xslDestHandle.close();
	delete [] buffer;
	return true;
}


/**
Get Xsl file path (imagecheck.xsl).

@internalComponent
@released

@param aExePath - Reference to Xsl file Path.
@return - 'true' for success.
*/
bool XmlWriter::GetXslSourcePath(string& aExePath) { 

#ifdef __LINUX__
	char* temp = getenv("_");
	if(NULL == temp) return false ;		
	string path(temp);
#else
	char buffer[MAX_PATH];
	if(!(GetModuleFileName(NULL, buffer, MAX_PATH))) return false; 
	string path(buffer);
#endif  
	size_t last = path.rfind(SLASH_CHAR1);
	if(last != string::npos) {
		aExePath = path.substr(0, last+1);
		return true;
	} 
	
	return false ;  
}


/**
Writes report header to xml file..

Opens the xml file for output.
Allocate the memory for xml report.
Write the Dtd/Xslt info.
Write the root element.

@internalComponent
@released
*/
void XmlWriter::StartReport(void) {
	iXmlFile.open(iXmlFileName.c_str(),ios_base::out | ios_base::binary | ios_base::trunc);

	if(!(iXmlFile.is_open())) { 
		throw ExceptionReporter(FILEOPENFAIL, __FILE__, __LINE__,iXmlFileName.c_str());
	}


	if(!(CreateXslFile())) {
		ExceptionReporter(XSLCREATIONFAILED, __FILE__, __LINE__, KXslFileName).Report();
	}

	iXmlBufPtr = xmlBufferCreate();
	// xml writer pointer to buffer ( with no compression )
	iXmlTextWriter = xmlNewTextWriterMemory(iXmlBufPtr,0);

	if (!iXmlBufPtr || !iXmlTextWriter) {
		throw ExceptionReporter(NOMEMORY,__FILE__,__LINE__);
	}

	xmlTextWriterStartDocument(iXmlTextWriter, KXmlVersion, KXmlEncoding, KNull);
	xmlTextWriterWriteRaw(iXmlTextWriter,(unsigned char*)KDtdXslInfo);
	xmlTextWriterStartElement(iXmlTextWriter, BAD_CAST KXmlRootElement);
	xmlTextWriterStartElement(iXmlTextWriter,BAD_CAST KXmlcomment);
	xmlTextWriterWriteAttribute(iXmlTextWriter, BAD_CAST KXmlcomment, BAD_CAST iInputCommnd.c_str()); 
}


/**
Writes the report footer to Xml file..

Write the xml end doc info..
Release the writer pointer from the buffer.
Writes the buffer content to xml file.
Frees the xml buffer.

@internalComponent
@released
*/
void XmlWriter::EndReport(void) {
	xmlTextWriterEndElement(iXmlTextWriter);
	xmlTextWriterEndElement(iXmlTextWriter);
	xmlTextWriterEndDocument(iXmlTextWriter);
	xmlFreeTextWriter(iXmlTextWriter);

	iXmlFile.clear(); 
	iXmlFile.write((const char *)iXmlBufPtr->content,iXmlBufPtr->use);

	if(iXmlFile.fail()){
		xmlBufferFree(iXmlBufPtr);
		throw ExceptionReporter(NODISKSPACE, iXmlFileName.c_str()); 
	}
	xmlBufferFree(iXmlBufPtr);
}


/**
Writes the executable name element.

@internalComponent
@released

@param aSerNo	  - Serial numebr of the executable specific to the image.
@param aExeName	  - Reference to executable name.
*/
void XmlWriter::StartExecutable(const unsigned int aSerNo, const string& aExeName) {
	xmlTextWriterStartElement(iXmlTextWriter, BAD_CAST KXmlExeName);
	xmlTextWriterWriteFormatAttribute(iXmlTextWriter, BAD_CAST KXmlExeAtt1,
		"%d",aSerNo);
	xmlTextWriterWriteAttribute(iXmlTextWriter, BAD_CAST KXmlExeAtt2,
		BAD_CAST aExeName.c_str());
}


/**
Writes the executable end element

@internalComponent
@released
*/
void XmlWriter::EndExecutable(void) {
	xmlTextWriterEndElement(iXmlTextWriter);
}


/**
Writes the note about unknown dependency.

@internalComponent
@released
*/
void XmlWriter::WriteNote(void) {
	xmlTextWriterStartElement(iXmlTextWriter, BAD_CAST KNote);
	xmlTextWriterWriteAttribute(iXmlTextWriter, BAD_CAST KXmlExeAtt2, BAD_CAST KUnknownDependency);
	xmlTextWriterWriteAttribute(iXmlTextWriter, BAD_CAST KNote, BAD_CAST KNoteMesg);
	xmlTextWriterEndElement(iXmlTextWriter);
}


/**
Writes the attribute, their values and the status.

@internalComponent
@released

@param aOneSetExeAtt - Reference to the attributes, their value and status
*/
void XmlWriter::WriteExeAttribute(ExeAttribute& aOneSetExeAtt) {
	xmlTextWriterStartElement(iXmlTextWriter, BAD_CAST aOneSetExeAtt.iAttName.c_str());
	if (!(strcmp(KDepName,aOneSetExeAtt.iAttName.c_str())) 
		|| !(strcmp(KXMLDbgFlag,aOneSetExeAtt.iAttName.c_str()))) {
			xmlTextWriterWriteAttribute(iXmlTextWriter, BAD_CAST KDepAtt1,
				BAD_CAST aOneSetExeAtt.iAttValue.c_str());
	}
	else {
		xmlTextWriterWriteFormatAttribute(iXmlTextWriter, BAD_CAST KAtt2,
			"0x%X",(Common::StringToInt(aOneSetExeAtt.iAttValue)));
	}

	xmlTextWriterWriteAttribute(iXmlTextWriter, BAD_CAST KAtt1,
		BAD_CAST aOneSetExeAtt.iAttStatus.c_str());
	xmlTextWriterEndElement(iXmlTextWriter);
}


/**
Writes the image name element.

@internalComponent
@released

@param aImageName - Reference to the image name
*/
void XmlWriter::StartImage(const string& aImageName) {
	xmlTextWriterStartElement(iXmlTextWriter, BAD_CAST KXmlImageName);
	xmlTextWriterWriteAttribute(iXmlTextWriter, BAD_CAST KXmlImageAtt1 ,
		BAD_CAST aImageName.c_str());
}

/**
Writes the image end element

@internalComponent
@released
*/
void XmlWriter::EndImage(void) {
	xmlTextWriterEndElement(iXmlTextWriter);
}


/**
Returns the report type.

@internalComponent
@released
*/
const string& XmlWriter::ReportType(void) {
	return iRptType;
}
