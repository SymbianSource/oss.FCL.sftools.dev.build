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
* XmlWriter class implementation.
* @internalComponent
* @released
*
*/



#ifndef XMLWRITER_H
#define XMLWRITER_H

#include "reportwriter.h"
#include "libxml/xmlwriter.h"
#include "common.h"

/**
Constants for XML report generation.
xml tags (headers,elements and attribute names).
*/
const String KXmlEncoding("ISO-8859-1");
const String KXslFileName("imgcheck.xsl");
const String KXmlVersion("1.0");
const String KDtdXslInfo("<!DOCTYPE imgcheck_report [ \
							<!ELEMENT comment (imgcheck_report+) > \
							<!ELEMENT imgcheck_report (Image*)> \
							<!ELEMENT Image (Exe_Name*)> \
							<!ELEMENT Executable (Dependency*,SID*,VID*,DBG*)> \
							<!ELEMENT Dependency ANY> \
							<!ATTLIST comment comment CDATA #REQUIRED>\
							<!ATTLIST Image name CDATA #REQUIRED> \
							<!ATTLIST Executable \
							SNo CDATA #REQUIRED  \
							name CDATA #REQUIRED> \
							<!ATTLIST Dependency \
							name CDATA #REQUIRED \
							status (Nill | Hidden | Available | Missing) \"Nill\"> \
							<!ATTLIST SID \
							val CDATA #IMPLIED \
							status CDATA #IMPLIED> \
							<!ATTLIST VID \
							val CDATA #IMPLIED \
							status CDATA #IMPLIED> \
							<!ATTLIST DBG \
							val CDATA #IMPLIED \
							status CDATA #IMPLIED> \
							]> \
							<?xml-stylesheet type=\"text/xsl\" href=\"imgcheck.xsl\"?>");

const String KXmlRootElement("imgcheck_report");
const String KXmlcomment("comment");
const String KXmlinputcmd("Inputcmd");

const String KXmlImageName("Image");
const String KXmlImageAtt1("name");

const String KXmlExeName("Executable");
const String KXmlExeAtt1("SNo");
const String KXmlExeAtt2("name");

const String KDepName("Dependency");
const String KDepAtt1("name");
const String KAtt1("status");
const String KAtt2("val");
const String KDepAvaStatus("Available");
const String KXml("XML");
const String KXMLDbgFlag("DBG");
const unsigned int KXmlGenBuffer=1024;

/** 
Xml writer derived class.

@internalComponent
@released
*/
class XmlWriter: public ReportWriter
{
public:

	XmlWriter(const String& aXmlFileName, const String& aInputCommand);
	~XmlWriter(void);

	int CreateXslFile(void);
	bool GetXslSourcePath(String& aExePath);
	void StartReport(void);
	void EndReport(void);
	void StartImage(const String& aImageName);
    void EndImage(void);
	void WriteExeAttribute(ExeAttribute& aOneSetExeAtt);
	void StartExecutable(const unsigned int aSerNo, const String& aExeName);
	void EndExecutable(void);
	void WriteNote(void);
	const String& ReportType(void);

private:
	// File stream for xml output.
	ofstream iXmlFile;
	// Xml file name for output.
	const String iXmlFileName;
	// Xml Buffer pointer.
	xmlBufferPtr iXmlBufPtr;
	// Xml write pointer to buffer.
	xmlTextWriterPtr iXmlTextWriter;
	//Hold the input command string
	String iInputCommnd;
	//Hold the report type
	String iRptType;
};

#endif // XMLWRITER_H
