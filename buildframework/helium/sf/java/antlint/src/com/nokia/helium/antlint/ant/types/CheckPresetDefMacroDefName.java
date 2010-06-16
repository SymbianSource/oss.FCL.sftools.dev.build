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
 * <code>CheckPresetDefMacroDefName</code> is used to check the naming
 * convention of presetdef and macrodef
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
 *       &lt;CheckPresetDefMacroDefName&quot; severity=&quot;error&quot; enabled=&quot;true&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="CheckPresetDefMacroDefName" category="AntLint"
 * 
 */
public class CheckPresetDefMacroDefName extends AbstractCheck {

    private String regExp;
    private File antFile;

    /**
     * {@inheritDoc}
     */
    @SuppressWarnings("unchecked")
    public void run(Element node) {
        if (node.getName().equals("presetdef")
                || node.getName().equals("macrodef")) {
            String text = node.attributeValue("name");
            if (text != null && !text.isEmpty()) {
                checkDefName(text);

            }

            List<Element> attributeList = node.elements("attribute");
            for (Element attributeElement : attributeList) {
                String attributeName = attributeElement.attributeValue("name");
                checkDefName(attributeName);
            }
        }
    }

    /**
     * Check the given text.
     * 
     * @param text
     *            is the text to check.
     */
    private void checkDefName(String text) {
        Pattern p1 = Pattern.compile(getRegExp());
        Matcher m1 = p1.matcher(text);
        if (!m1.matches()) {
            this.getReporter().report(this.getSeverity(),
                    "INVALID PRESETDEF/MACRODEF Name: " + text,
                    this.getAntFile(), 0);
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
        List<Element> presetDefNodes = new ArrayList<Element>();
        try {
            doc = saxReader.read(antFilename);
            elementTreeWalk(doc.getRootElement(), "presetdef", presetDefNodes);
            elementTreeWalk(doc.getRootElement(), "macrodef", presetDefNodes);
        } catch (DocumentException e) {
            throw new AntlintException("Invalid XML file " + e.getMessage());
        }
        for (Element presetDefNode : presetDefNodes) {
            run(presetDefNode);
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
        return "CheckPresetDefMacroDefName";
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
