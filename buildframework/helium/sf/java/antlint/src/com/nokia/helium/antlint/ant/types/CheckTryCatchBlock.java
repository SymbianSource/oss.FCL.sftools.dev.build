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

import java.io.File;
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
 * <code>CheckTryCatchBlock</code> is used to check for empty and more than one
 * catch elements in a given try-catch block.
 * 
 * <pre>
 * Usage:
 * 
 *  &lt;antlint&gt;
 *       &lt;fileset id=&quot;antlint.files&quot; dir=&quot;${antlint.test.dir}/data&quot;&gt;
 *               &lt;include name=&quot;*.ant.xml&quot;/&gt;
 *               &lt;include name=&quot;*build.xml&quot;/&gt;
 *               &lt;include name=&quot;*.antlib.xml&quot;/&gt;
 *       &lt;/fileset&gt;
 *       &lt;checkTryCatchBlock&quot; severity=&quot;error&quot; enabled=&quot;true&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="checkTryCatchBlock" category="AntLint"
 * 
 */
public class CheckTryCatchBlock extends AbstractCheck {

    private File antFile;

    /**
     * {@inheritDoc}
     */
    public File getAntFile() {
        return antFile;
    }

    /**
     * {@inheritDoc}
     */
    public void run(File antFilename) throws AntlintException {
        try {
            this.antFile = antFilename;
            SAXParserFactory saxFactory = SAXParserFactory.newInstance();
            saxFactory.setNamespaceAware(true);
            saxFactory.setValidating(true);
            SAXParser parser = saxFactory.newSAXParser();
            TryCatchBlockHandler handler = new TryCatchBlockHandler();
            parser.parse(antFilename, handler);
        } catch (ParserConfigurationException e) {
            throw new AntlintException("Not able to parse XML file "
                    + e.getMessage());
        } catch (SAXException e) {
            throw new AntlintException("Not able to parse XML file "
                    + e.getMessage());
        } catch (IOException e) {
            throw new AntlintException("Not able to find XML file "
                    + e.getMessage());
        }
    }

    public String toString() {
        return "CheckTryCatchBlock";
    }

    private class TryCatchBlockHandler extends DefaultHandler {

        private Locator locator;
        private int catchCounter;

        /**
         * {@inheritDoc}
         */
        public void setDocumentLocator(Locator locator) {
            this.locator = locator;
        }

        /**
         * {@inheritDoc}
         */
        public void startElement(String uri, String localName, String qName,
                Attributes attributes) throws SAXException {
            if (localName.equals("trycatch")) {
                catchCounter = 0;
            } else if (localName.equals("catch")) {
                catchCounter++;
            }
        }

        /**
         * {@inheritDoc}
         */
        public void endElement(String uri, String localName, String qName)
            throws SAXException {
            if (localName.equals("trycatch") && catchCounter == 0) {
                getReporter().report(getSeverity(),
                        "<trycatch> block found without <catch> element",
                        getAntFile(), locator.getLineNumber());
            } else if (localName.equals("trycatch") && catchCounter > 1) {
                getReporter().report(
                        getSeverity(),
                        "<trycatch> block found with " + catchCounter
                                + " <catch> elements.", getAntFile(),
                        locator.getLineNumber());
            }
        }
    }
}
