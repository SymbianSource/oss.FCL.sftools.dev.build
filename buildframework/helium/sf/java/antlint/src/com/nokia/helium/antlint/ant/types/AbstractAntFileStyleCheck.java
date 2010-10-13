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
package com.nokia.helium.antlint.ant.types;

import java.io.IOException;

import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.xml.sax.Attributes;
import org.xml.sax.Locator;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

import com.nokia.helium.antlint.ant.AntlintException;

/**
 * <code>AbstractAntFileStyleCheck</code> is an abstract check class used to
 * parse an Ant file. The class uses an internal handler to receive
 * notifications of XML parsing.
 * 
 */
public abstract class AbstractAntFileStyleCheck extends AbstractCheck {

    private Locator locator;
    private StringBuffer buffer = new StringBuffer();
    
    /**
     * {@inheritDoc}
     */
    public void run() throws AntlintException {
        try {
            SAXParserFactory saxFactory = SAXParserFactory.newInstance();
            saxFactory.setNamespaceAware(true);
            saxFactory.setValidating(true);
            SAXParser parser = saxFactory.newSAXParser();
            AntlintHandler handler = new AntlintHandler();
            parser.parse(getAntFile().getFile(), handler);
        } catch (ParserConfigurationException e) {
            throw new AntlintException("Not able to parse XML file " + e.getMessage());
        } catch (SAXException e) {
            throw new AntlintException("Not able to parse XML file " + e.getMessage());
        } catch (IOException e) {
            throw new AntlintException("Not able to find XML file " + e.getMessage());
        }
    }

    /**
     * Set the locator.
     * 
     * @param locator is the locator to set
     */
    private void setLocator(Locator locator) {
        this.locator = locator;
    }

    /**
     * Return the locator.
     * 
     * @return the locator
     */
    public Locator getLocator() {
        return locator;
    }

    protected void clearBuffer() {
        buffer.delete(0, buffer.length());
    }
    
    /**
     * Method to handle the element start notification.
     * 
     * @param text is the text read at element start notification.
     * @param lineNum is the current line number where the parser is reading.
     */
    protected abstract void handleStartElement(String text);

    /**
     * Method to handle the element end notification.
     * 
     * @param text is the text read at element end notification.
     * @param lineNum is the current line number where the parser is reading.
     */
    protected abstract void handleEndElement(String text);

    /**
     * Method to handle the document start notification.
     */
    protected abstract void handleStartDocument();

    /**
     * Method to handle the document end notification.
     */
    protected abstract void handleEndDocument();

    /**
     * A private class used to receive xml parsing notifications.
     * 
     */
    private class AntlintHandler extends DefaultHandler {
        
        /**
         * {@inheritDoc}
         */
        public void setDocumentLocator(Locator locator) {
            setLocator(locator);
        }

        public void startDocument() throws SAXException {
            handleStartDocument();
        }
        
        @Override
        public void endDocument() throws SAXException {
            handleEndDocument();
        }
        
        /**
         * {@inheritDoc}
         */
        public void startElement(String uri, String name, String qName, Attributes atts) {
            handleStartElement(buffer.toString());
        }

        /**
         * {@inheritDoc}
         */
        public void endElement(String uri, String name, String qName) {
            handleEndElement(buffer.toString());
        }

        /**
         * {@inheritDoc}
         */
        public void characters(char[] ch, int start, int length) {
            for (int i = start; i < start + length; i++) {
                buffer.append(ch[i]);
            }
        }
    }

}
