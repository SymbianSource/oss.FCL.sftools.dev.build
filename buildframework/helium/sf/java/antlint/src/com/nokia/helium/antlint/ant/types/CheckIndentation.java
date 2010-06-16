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

import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;
import javax.xml.parsers.ParserConfigurationException;
import org.xml.sax.SAXException;
import java.io.IOException;

import com.nokia.helium.antlint.AntLintHandler;
import com.nokia.helium.antlint.ant.AntlintException;

/**
 * <code>CheckIndentation</code> is used to check the indentations in the ant
 * files.
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
 *       &lt;CheckIndentation&quot; severity=&quot;error&quot; enabled=&quot;true&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="CheckIndentation" category="AntLint"
 * 
 */
public class CheckIndentation extends AbstractCheck {
    private File antFile;

    /*
     * (non-Javadoc)
     * 
     * @see com.nokia.helium.antlint.ant.types.Check#run(java.io.File)
     */
    public void run(File antFilename) throws AntlintException {
        try {
            this.antFile = antFilename;
            SAXParserFactory saxFactory = SAXParserFactory.newInstance();
            saxFactory.setNamespaceAware(true);
            saxFactory.setValidating(true);
            SAXParser parser = saxFactory.newSAXParser();
            AntLintHandler handler = new AntLintHandler(this);
            handler.setIndentationCheck(true);
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

    /*
     * (non-Javadoc)
     * 
     * @see org.apache.tools.ant.types.DataType#toString()
     */
    public String toString() {
        return "CheckIndentation";
    }

    /*
     * (non-Javadoc)
     * 
     * @see com.nokia.helium.antlint.ant.types.Check#getAntFile()
     */
    public File getAntFile() {
        return this.antFile;
    }
}
