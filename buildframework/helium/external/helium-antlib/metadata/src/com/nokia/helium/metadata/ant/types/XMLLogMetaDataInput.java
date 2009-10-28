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
import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLStreamReader;
//import javax.xml.stream.XMLStreamException;
import javax.xml.stream.events.XMLEvent;


/**
 * This Type abstract base class for all the types based on
 * XML processing.
 */
abstract class XMLLogMetaDataInput extends LogMetaDataInput {

    private Logger log = Logger.getLogger(XMLLogMetaDataInput.class);

    private XMLInputFactory xmlInputFactory;

    private XMLStreamReader xmlStreamReader;
    
    private int currentFileIndex;
    
    public XMLLogMetaDataInput() {
        try {
            xmlInputFactory = XMLInputFactory.newInstance();
            xmlInputFactory.setProperty(XMLInputFactory.IS_REPLACING_ENTITY_REFERENCES,Boolean.TRUE);
            xmlInputFactory.setProperty(XMLInputFactory.IS_SUPPORTING_EXTERNAL_ENTITIES,Boolean.FALSE);
            xmlInputFactory.setProperty(XMLInputFactory.IS_COALESCING , Boolean.TRUE);
        } catch (Exception ex) {
            ex.printStackTrace();
        }
    }
    

    private void close() {
        try {
            if (xmlStreamReader != null) {
                xmlStreamReader.close();
                xmlStreamReader = null;
            }
        } catch (Exception ex) {
            log.info("Exception whil closing xml stream" + ex.getMessage());
            log.debug("exception while closing xml stream",ex);
        }
        
    }
   
    protected File getCurrentFile() {
        List<File> fileList = getFileList();
        return fileList.get(currentFileIndex); 
    }
    
    boolean isEntryAvailable() throws Exception {
        //log.debug("Getting next set of log entries for xml Input");
        //log.debug("currentFileIndex" + currentFileIndex);
        int fileListSize = getFileList().size();
        //log.debug("fileList.size" + fileListSize);

        //if ( isEntryCreatedForRemainingText() ) {
        //    log.debug("Entry creating from remaining text");
        //    return true;
        //}
        try {
            while (currentFileIndex < fileListSize) {
                boolean entryCreated = false;
                File currentFile = getCurrentFile();
                    if (xmlStreamReader == null) {
                        log.info("Processing file: " + currentFile);
                        xmlStreamReader = xmlInputFactory.createXMLStreamReader(
                                currentFile.toString(), new BufferedInputStream(new FileInputStream(currentFile)));
                    //First the START_DOCUMENT is the first event directly pointed to.
                    }
                int eventType = xmlStreamReader.getEventType();
                while (xmlStreamReader.hasNext()) {
                    eventType = xmlStreamReader.next();
                    switch (eventType) {
                    case XMLEvent.START_ELEMENT:
                        //log.debug("XMLEvent:START_ELEMENT");
                        entryCreated = startElement(xmlStreamReader);
                        break;
                    case XMLEvent.END_ELEMENT:
                        //log.debug("XMLEvent:END_ELEMENT");
                        entryCreated = endElement(xmlStreamReader);
                        //log.debug("XMLEvent:END_ELEMENT: entryCreated: " +entryCreated);
                        break;
                    case XMLEvent.PROCESSING_INSTRUCTION:
                        //log.debug("XMLEvent:PI_DATA");
                        //printPIData(xmlr);
                        break;
                    case XMLEvent.CHARACTERS:
                        //log.debug("XMLEvent:chacacters");
                        entryCreated = characters(xmlStreamReader);
                        break;
                    case XMLEvent.COMMENT:
                        log.debug("XMLEvent:COMMENT");
                        break;
                    case XMLEvent.START_DOCUMENT:
                        log.debug("XMLEvent:START_DOCUMENT");
                        break;
                    case XMLEvent.END_DOCUMENT:
                        log.debug("XMLEvent:END_DOCUMENT");
                        break;
                    case XMLEvent.ENTITY_REFERENCE:
                        log.debug("XMLEvent:ENTITY_REFERENCE");
                        break;
                    case XMLEvent.ATTRIBUTE:
                        log.debug("XMLEvent:ATTRIBUTE");
                        break;
                    case XMLEvent.DTD:
                        log.debug("XMLEvent:DTD");
                        break;
                    case XMLEvent.CDATA:
                        log.debug("XMLEvent:CDATA");
                        break;
                    case XMLEvent.SPACE:
                        log.debug("XMLEvent:chacacters");
                        break;
                    default:
                        break;
                    }
                    if ( entryCreated) {
                        return true; 
                    }
                }
                if (xmlStreamReader != null) {
                    close();
                }
                currentFileIndex ++;
            }
        } catch (Exception ex1 ) {
            log.info("Exception processing xml stream: " + ex1.getMessage());
            log.debug("exception while parsing the stream", ex1);
            close();
        }
        return false;
    }

    
    abstract boolean startElement (XMLStreamReader streamReader) throws Exception ;

    abstract boolean endElement(XMLStreamReader streamReader) throws Exception;
    
    abstract boolean characters (XMLStreamReader streamReader);
}
