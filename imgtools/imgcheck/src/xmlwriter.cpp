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
	#include "/epoc32/gcc_mingw/include/windows.h"	
#endif //__LINUX__

/**
Constructor: XmlWriter class

@internalComponent
@released

@param aXmlfileName - Reference to xml filename.
@param iInputCommnd - Reference to the input options
*/
XmlWriter::XmlWriter(const String& aXmlFileName, const String& aInputCommand)
: iXmlFileName(aXmlFileName), iXmlBufPtr(0) , iXmlTextWriter(0) , iInputCommnd(aInputCommand), iRptType(KXml)
{
}


/**
Destructor : XmlWriter class
Closes the Xml output file.

@internalComponent
@released
*/
XmlWriter::~XmlWriter(void)
{
	if(iXmlFile.is_open())
	{
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
int XmlWriter::CreateXslFile(void)
{
	// Validate the user entered xml path.
	char* xslFileName = (char*)iXmlFileName.c_str();
	String xslSourcePath;

	while(*xslFileName)
	{
		if(*xslFileName++ == '\\')
			*(--xslFileName) = '/';
	}
	String xslDestPath(iXmlFileName);
	unsigned int position = xslDestPath.rfind('/');
	if(position != String::npos)
	{
		xslDestPath.erase(position+1);
		xslDestPath.append(KXslFileName);
	}
	else
	{
		xslDestPath.erase();
		xslDestPath.assign(KXslFileName);
	}

	if(!(GetXslSourcePath(xslSourcePath)))
	{
		return false;
	}
	xslSourcePath.append(KXslFileName.c_str());

	ifstream xslSourceHandle;
	xslSourceHandle.open(xslSourcePath.c_str(), Ios::binary);
	if(!xslSourceHandle)
	{
		return false;
	}
	xslSourceHandle.seekg(0, Ios::end);		
	int fileSize = xslSourceHandle.tellg();
	xslSourceHandle.seekg(0, Ios::beg);
	char* filetocopy = new char[fileSize];
	if (!filetocopy)
	{
		throw ExceptionReporter(NOMEMORY, __FILE__, __LINE__);
	}
	xslSourceHandle.read(filetocopy,fileSize);
	xslSourceHandle.close();

	ofstream xslDestHandle(xslDestPath.c_str(), Ios::binary | Ios::out);
	if(!xslDestHandle)
	{
		delete [] filetocopy;
		return false;
	}
	xslDestHandle.write(filetocopy,fileSize);			
	xslDestHandle.close();
	delete [] filetocopy;
	return true;
}
	

/**
Get Xsl file path (imagecheck.xsl).

@internalComponent
@released

@param aExePath - Reference to Xsl file Path.
@return - 'true' for success.
*/
bool XmlWriter::GetXslSourcePath(String& aExePath)
{
#ifdef __LINUX__
	aExePath.assign("/");
	return true;
#else

	char* size = new char[KXmlGenBuffer];
	if (!size)
	{
		throw ExceptionReporter(NOMEMORY, __FILE__, __LINE__);
	}
	if(!(GetModuleFileName(NULL, size, KXmlGenBuffer)))
	{
		delete [] size;
		return false;
	}
	String path(size);
	delete [] size;
	size_t last = path.rfind('\\');
	if(last != String::npos)
	{
		aExePath = path.substr(0, last+1);
		return true;
	}
#endif
	return true ; // to avoid warning
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
void XmlWriter::StartReport(void)
{
	iXmlFile.open(iXmlFileName.c_str());

	if(!(iXmlFile.is_open()))
	{
		throw ExceptionReporter(FILEOPENFAIL, __FILE__, __LINE__, (char*)iXmlFileName.c_str());
	}

	if(!(CreateXslFile()))
	{
		ExceptionReporter(XSLCREATIONFAILED, __FILE__, __LINE__, (char*)KXslFileName.c_str()).Report();
	}

	iXmlBufPtr = xmlBufferCreate();
	// xml writer pointer to buffer ( with no compression )
	iXmlTextWriter = xmlNewTextWriterMemory(iXmlBufPtr,0);

	if (!iXmlBufPtr || !iXmlTextWriter)
	{
		throw ExceptionReporter(NOMEMORY,__FILE__,__LINE__);
	}

	xmlTextWriterStartDocument(iXmlTextWriter, KXmlVersion.c_str(), KXmlEncoding.c_str(), KNull);
	xmlTextWriterWriteRaw(iXmlTextWriter,(unsigned char*)KDtdXslInfo.c_str());
	xmlTextWriterStartElement(iXmlTextWriter, BAD_CAST KXmlRootElement.c_str());
	xmlTextWriterStartElement(iXmlTextWriter,BAD_CAST KXmlcomment.c_str());
	xmlTextWriterWriteAttribute(iXmlTextWriter, BAD_CAST KXmlcomment.c_str(), BAD_CAST iInputCommnd.c_str());
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
void XmlWriter::EndReport(void)
{
	xmlTextWriterEndElement(iXmlTextWriter);
	xmlTextWriterEndElement(iXmlTextWriter);
	xmlTextWriterEndDocument(iXmlTextWriter);
	xmlFreeTextWriter(iXmlTextWriter);
	
	iXmlFile.clear(); 
	iXmlFile.write((const char *)iXmlBufPtr->content,iXmlBufPtr->use);
	 
	if(iXmlFile.fail()){
		xmlBufferFree(iXmlBufPtr);
		throw ExceptionReporter(NODISKSPACE, (char*)iXmlFileName.c_str()); 
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
void XmlWriter::StartExecutable(const unsigned int aSerNo, const String& aExeName)
{
	xmlTextWriterStartElement(iXmlTextWriter, BAD_CAST KXmlExeName.c_str());
	xmlTextWriterWriteFormatAttribute(iXmlTextWriter, BAD_CAST KXmlExeAtt1.c_str(),
									"%d",aSerNo);
	xmlTextWriterWriteAttribute(iXmlTextWriter, BAD_CAST KXmlExeAtt2.c_str(),
									BAD_CAST aExeName.c_str());
}


/**
Writes the executable end element

@internalComponent
@released
*/
void XmlWriter::EndExecutable(void)
{
	xmlTextWriterEndElement(iXmlTextWriter);
}


/**
Writes the note about unknown dependency.

@internalComponent
@released
*/
void XmlWriter::WriteNote(void)
{
	xmlTextWriterStartElement(iXmlTextWriter, BAD_CAST KNote.c_str());
	xmlTextWriterWriteAttribute(iXmlTextWriter, BAD_CAST KXmlExeAtt2.c_str(), BAD_CAST KUnknownDependency.c_str());
	xmlTextWriterWriteAttribute(iXmlTextWriter, BAD_CAST KNote.c_str(), BAD_CAST KNoteMesg.c_str());
	xmlTextWriterEndElement(iXmlTextWriter);
}


/**
Writes the attribute, their values and the status.

@internalComponent
@released

@param aOneSetExeAtt - Reference to the attributes, their value and status
*/
void XmlWriter::WriteExeAttribute(ExeAttribute& aOneSetExeAtt)
{
	xmlTextWriterStartElement(iXmlTextWriter, BAD_CAST aOneSetExeAtt.iAttName.c_str());
 	if (!(strcmp(KDepName.c_str(),aOneSetExeAtt.iAttName.c_str())) 
		|| !(strcmp(KXMLDbgFlag.c_str(),aOneSetExeAtt.iAttName.c_str())))
	{
		xmlTextWriterWriteAttribute(iXmlTextWriter, BAD_CAST KDepAtt1.c_str(),
								BAD_CAST aOneSetExeAtt.iAttValue.c_str());
	}
	else
	{
		xmlTextWriterWriteFormatAttribute(iXmlTextWriter, BAD_CAST KAtt2.c_str(),
			"0x%X",(Common::StringToInt(aOneSetExeAtt.iAttValue)));
	}
	
	xmlTextWriterWriteAttribute(iXmlTextWriter, BAD_CAST KAtt1.c_str(),
								BAD_CAST aOneSetExeAtt.iAttStatus.c_str());
	xmlTextWriterEndElement(iXmlTextWriter);
}


/**
Writes the image name element.

@internalComponent
@released

@param aImageName - Reference to the image name
*/
void XmlWriter::StartImage(const String& aImageName)
{
	xmlTextWriterStartElement(iXmlTextWriter, BAD_CAST KXmlImageName.c_str());
	xmlTextWriterWriteAttribute(iXmlTextWriter, BAD_CAST KXmlImageAtt1.c_str() ,
								BAD_CAST aImageName.c_str());
}

/**
Writes the image end element

@internalComponent
@released
*/
void XmlWriter::EndImage(void)
{
	xmlTextWriterEndElement(iXmlTextWriter);
}


/**
Returns the report type.

@internalComponent
@released
*/
const String& XmlWriter::ReportType(void)
{
	return iRptType;
}
