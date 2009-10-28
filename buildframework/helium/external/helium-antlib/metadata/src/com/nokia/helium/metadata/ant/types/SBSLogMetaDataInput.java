/*
 * Copyright (c) 2007-2008 Nokia Corporation and/or its subsidiary(-ies).
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

package com.nokia.helium.metadata.ant.types;

import java.io.*;
import java.util.*;
//import javax.xml.parsers.SAXParser;
//import javax.xml.parsers.SAXParserFactory;
import org.apache.log4j.Logger;
import javax.xml.stream.XMLStreamReader;


/**
 * This Type is to specify and use the sbs logparsertype to 
 * parse and store the data based on xmlstreamreader.
 * <pre>
 * &lt;hlm:metadatafilterset id="sbs.metadata.filter"&gt;
 *    &lt;metadatafilterset filterfile="common.csv" /&gt;
 * &lt;/hlm:metadatafilterset&gt;
 * 
 * &lt;hlm:sbsmetadatainput&gt;
 *    &lt;fileset dir="${project.dir}/../data/"&gt;
 *        &lt;include name="*compile.log"/&gt;
 *    &lt;/fileset&gt;
 *    &lt;metadatafilterset refid="sbs.metadata.filter" /&gt;
 * &lt;/hlm:sbsmetadatainput&gt;
 * </pre>
 * @ant.task name="sbsmetadatainput" category="Metadata"
 */
public class SBSLogMetaDataInput extends XMLLogMetaDataInput {

    private Logger log = Logger.getLogger(SBSLogMetaDataInput.class);

    private String currentComponent;
    
    private String logTextInfo = "";
    
    private int lineNumber;

    private boolean recordText;
    
    
    public SBSLogMetaDataInput() {
    }
    
    private String getComponent(XMLStreamReader streamReader) {
        int count = streamReader.getAttributeCount() ;
        for (int i = 0 ; i < count ; i++) {
            if ( streamReader.getAttributeLocalName(i).equals("bldinf") ) {
                return streamReader.getAttributeValue(i);
            }
        }
        return null;
    }

    public boolean characters (XMLStreamReader streamReader) {
        if (recordText) {
            logTextInfo += streamReader.getText();
        }
        return false;
    }
    
    public boolean startElement (XMLStreamReader streamReader) throws Exception {
        try {
            String tagName = streamReader.getLocalName();
            if (tagName.equalsIgnoreCase("buildlog")) {
                log.debug("starting with buildlog");
            }
            if (tagName.equalsIgnoreCase("recipe") ) {
                lineNumber = streamReader.getLocation().getLineNumber();
                //log.debug(" startElement: receipe tag");
                recordText = true;
                //currentComponent = attributes.getValue("bldinf");
                currentComponent = getComponent(streamReader);
            } else if (tagName.equalsIgnoreCase("error")
                    || tagName.equalsIgnoreCase("warning")) {
                lineNumber = streamReader.getLocation().getLineNumber();
                recordText = true;
            } else if (tagName.equalsIgnoreCase("whatlog") ) {
                currentComponent = getComponent(streamReader);
            }
        } catch (Exception ex) {
            log.debug("exception in startelement",ex);
            throw ex;
        }
        return false;
    }


    public boolean endElement(XMLStreamReader streamReader) throws Exception {
        try {
            String tagName = streamReader.getLocalName();
            if (tagName.equalsIgnoreCase("recipe")) {
                recordText = false;
                if (logTextInfo != null) {
                    //log.debug("endElement: lineNumber: " + lineNumber);
                    boolean entryCreated = findAndAddEntries(logTextInfo, currentComponent,
                            getCurrentFile().toString(), lineNumber);
                    logTextInfo = "";
                    if ( entryCreated) {
                        //log.debug("Entry creating end element");
                        return true;
                    }
                }
            } else if (tagName.equalsIgnoreCase("error")
                    || tagName.equalsIgnoreCase("warning")) {
                recordText = false;
                addEntry(tagName, "general", getCurrentFile().toString(), lineNumber, 
                        logTextInfo);
                logTextInfo = "";
                return true;
            } else if (tagName.equalsIgnoreCase("whatlog") ) {
                addEntry("default", currentComponent, getCurrentFile().toString(), -1, 
                        "");
            }
        } catch (Exception ex) {
            log.debug("Exception while processing for sbs metadata input", ex);
            throw ex;
        }
        return false;
    }
}