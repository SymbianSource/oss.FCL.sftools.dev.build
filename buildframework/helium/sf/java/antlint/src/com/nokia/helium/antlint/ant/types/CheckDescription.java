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

import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.Element;
import org.dom4j.io.SAXReader;

import com.nokia.helium.antlint.ant.AntlintException;

/**
 * <code>CheckDescription</code> is used to check whether project description is
 * present or not.
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
 *       &lt;CheckDescription&quot; severity=&quot;error&quot; enabled=&quot;true&quot;/&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="CheckDescription" category="AntLint"
 */
public class CheckDescription extends AbstractCheck {

    private File antFile;

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        if (node.getName().equals("project")
                && node.element("description") == null) {
            this.getReporter().report(this.getSeverity(),
                    "Description not specified!", this.getAntFile(), 0);
        }
    }

    /*
     * (non-Javadoc)
     * 
     * @see com.nokia.helium.antlint.ant.types.Check#run(java.io.File)
     */
    public void run(File antFilename) throws AntlintException {
        this.antFile = antFilename;
        SAXReader saxReader = new SAXReader();
        Document doc;
        try {
            doc = saxReader.read(antFilename);
            run(doc.getRootElement());
        } catch (DocumentException e) {
            throw new AntlintException("Invalid XML file " + e.getMessage());
        }
    }

    /*
     * (non-Javadoc)
     * 
     * @see org.apache.tools.ant.types.DataType#toString()
     */
    public String toString() {
        return "CheckDescription";
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
