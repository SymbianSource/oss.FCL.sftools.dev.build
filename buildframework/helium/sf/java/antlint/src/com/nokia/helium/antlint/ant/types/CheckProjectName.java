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
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.Element;
import org.dom4j.io.SAXReader;

import com.nokia.helium.antlint.ant.AntlintException;

/**
 * <code>CheckProjectName</code> is used to check the naming convention of
 * project names.
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
 *       &lt;CheckProjectName&quot; severity=&quot;error&quot; enabled=&quot;true&quot; regexp=&quot;([a-z0-9[\\d\\-]]*)&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="CheckProjectName" category="AntLint"
 * 
 */
public class CheckProjectName extends AbstractCheck {
    private String regExp;
    private File antFile;

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        if (node.getName().equals("project")) {
            String text = node.attributeValue("name");
            if (text != null && !text.isEmpty()) {
                checkProjectName(text);
            } else {
                this.getReporter().report(this.getSeverity(),
                        "Project name not specified!", this.getAntFile(), 0);
            }

        }
    }

    /**
     * Check the given the project name.
     * 
     * @param text
     *            is the text to check.
     */
    private void checkProjectName(String text) {
        Pattern p1 = Pattern.compile(getRegExp());
        Matcher m1 = p1.matcher(text);
        if (!m1.matches()) {
            this.getReporter().report(this.getSeverity(),
                    "INVALID Project Name: " + text, this.getAntFile(), 0);
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

    /**
     * @param regExp
     *            the regExp to set
     */
    public void setRegExp(String regExp) {
        this.regExp = regExp;
    }

    /**
     * @return the regExp
     */
    public String getRegExp() {
        return regExp;
    }

    /*
     * (non-Javadoc)
     * 
     * @see org.apache.tools.ant.types.DataType#toString()
     */
    public String toString() {
        return "CheckProjectName";
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
