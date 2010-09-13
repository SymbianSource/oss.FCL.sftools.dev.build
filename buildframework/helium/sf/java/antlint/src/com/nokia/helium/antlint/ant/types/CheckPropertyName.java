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
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.Element;
import org.dom4j.io.SAXReader;

import com.nokia.helium.antlint.ant.AntlintException;

/**
 * <code>CheckPropertyName</code> is used to check the naming convention of
 * property names.
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
 *       &lt;CheckPropertyName&quot; severity=&quot;error&quot; enabled=&quot;true&quot; regexp=&quot;([a-z0-9[\\d\\-]]*)&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="CheckPropertyName" category="AntLint"
 * 
 */
public class CheckPropertyName extends AbstractCheck {

    private ArrayList<String> propertiesVisited = new ArrayList<String>();
    private String regExp;
    private File antFile;

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        if (node.getName().equals("property")) {
            String text = node.attributeValue("name");
            if (text != null && !text.isEmpty()) {
                checkPropertyName(text);
            }
        }
    }

    /**
     * Check the given property name.
     * 
     * @param propertyName
     *            is the property name to check.
     */
    private void checkPropertyName(String propertyName) {
        Pattern p1 = Pattern.compile(getRegExp());
        Matcher m1 = p1.matcher(propertyName);
        if (!m1.matches() && !isPropertyAlreadyVisited(propertyName)) {
            this.getReporter().report(this.getSeverity(),
                    "INVALID Property Name: " + propertyName,
                    this.getAntFile(), 0);
            markPropertyAsVisited(propertyName);
        }
    }

    /*
     * (non-Javadoc)
     * 
     * @see com.nokia.helium.antlint.ant.types.Check#run(java.io.File)
     */
    public void run(File antFilename) throws AntlintException {
        List<Element> propertyNodes = new ArrayList<Element>();

        this.antFile = antFilename;
        SAXReader saxReader = new SAXReader();
        Document doc;
        try {
            doc = saxReader.read(antFilename);
            elementTreeWalk(doc.getRootElement(), "property", propertyNodes);
        } catch (DocumentException e) {
            throw new AntlintException("Invalid XML file " + e.getMessage());
        }
        for (Element propertyNode : propertyNodes) {
            run(propertyNode);
        }
    }

    /**
     * Check whether the property is already visited or not.
     * 
     * @param propertyName
     *            is the property to be checked.
     * @return true, if already been visited; otherwise false
     */
    private boolean isPropertyAlreadyVisited(String propertyName) {
        return propertiesVisited.contains(propertyName);
    }

    /**
     * Mark the given property as visited.
     * 
     * @param propertyName
     *            is the property to be marked.
     */
    private void markPropertyAsVisited(String propertyName) {
        propertiesVisited.add(propertyName);
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
        return "CheckPropertyName";
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
