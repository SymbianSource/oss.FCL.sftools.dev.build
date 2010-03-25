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
import org.apache.log4j.Logger;
import javax.xml.stream.XMLInputFactory;
import javax.xml.stream.XMLStreamReader;
import javax.xml.stream.events.XMLEvent;


/**
 * This Type abstract base class for all the types based on
 * XML processing.
 */
abstract class XMLLogMetaDataInput extends LogMetaDataInput {

    private Logger log = Logger.getLogger(XMLLogMetaDataInput.class);

    private XMLInputFactory xmlInputFactory;

    private XMLStreamReader xmlStreamReader;
    
    private boolean inParsing;
    

    /**
     * Constructor
     */
    public XMLLogMetaDataInput() {
        try {
            inParsing = true;
            xmlInputFactory = XMLInputFactory.newInstance();
            xmlInputFactory.setProperty(XMLInputFactory.IS_REPLACING_ENTITY_REFERENCES,Boolean.TRUE);
            xmlInputFactory.setProperty(XMLInputFactory.IS_SUPPORTING_EXTERNAL_ENTITIES,Boolean.FALSE);
            xmlInputFactory.setProperty(XMLInputFactory.IS_COALESCING , Boolean.TRUE);
        } catch (Exception ex) {
         // We are Ignoring the errors as no need to fail the build.
            log.debug("Exception while initializing stax processing",ex);
        }
    }
    
    /**
     * Closes the xml stream
     */
    private void close() {
        try {
            if (xmlStreamReader != null) {
                xmlStreamReader.close();
                xmlStreamReader = null;
            }
        } catch (Exception ex) {
         // We are Ignoring the errors as no need to fail the build.
            log.debug("Exception while closing xml stream", ex);
        }
        
    }

    /**
     * Function to check from the input stream if is there any entries available.
     * @param file for which the contents needs to be parsed for errors
     * @return true if there are any entry available otherwise false.
     */
    boolean isEntryCreated(File currentFile) throws Exception {
        boolean entryCreated = false;
        if (inParsing ) {
            if (xmlStreamReader == null) {
                log.debug("Processing file: " + currentFile);
                xmlStreamReader = xmlInputFactory.createXMLStreamReader(
                        currentFile.toString(), new BufferedInputStream(new FileInputStream(currentFile)));
            }
            int eventType = xmlStreamReader.getEventType();
            while (xmlStreamReader.hasNext()) {
                eventType = xmlStreamReader.next();
                switch (eventType) {
                case XMLEvent.START_ELEMENT:
                    entryCreated = startElement(xmlStreamReader);
                    break;
                case XMLEvent.END_ELEMENT:
                    entryCreated = endElement(xmlStreamReader);
                    break;
                case XMLEvent.CHARACTERS:
                    entryCreated = characters(xmlStreamReader);
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
            inParsing = false;
        }
        return false;
    }


    /**
     * Function implemented by the subclasses to process the start event of xml stream callback.
     * @param streamReader: the input stream reader which contains the xml data to be parsed for recording data.
     * @return true if there are any element to be added to the database.
     */
    abstract boolean startElement (XMLStreamReader streamReader) throws Exception ;

    /**
     * Function implemented by the subclasses to process the end event of xml stream callback.
     * @param streamReader: the input stream reader which contains the xml data to be parsed for recording data.
     * @return true if there are any element to be added to the database.
     */
    abstract boolean endElement(XMLStreamReader streamReader) throws Exception;

    /**
     * Function implemented by the subclasses to process the characters event of xml stream callback.
     * @param streamReader: the input stream reader which contains the xml data to be parsed for recording data.
     * @return true if there are any element to be added to the database.
     */
    abstract boolean characters (XMLStreamReader streamReader) throws Exception;
}
