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
 * <code>CheckTargetName</code> is used to check the naming convention of the
 * target names.
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
 *       &lt;CheckTargetName&quot; severity=&quot;error&quot; enabled=&quot;true&quot; regexp=&quot;([a-z0-9[\\d\\-]]*)&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="CheckTargetName" category="AntLint"
 * 
 */
public class CheckTargetName extends AbstractCheck {

    private String regExp;
    private File antFile;

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        if (node.getName().equals("target")) {
            String target = node.attributeValue("name");
            if (!target.equals("tearDown") && !target.equals("setUp")
                    && !target.equals("suiteTearDown")
                    && !target.equals("suiteSetUp")) {
                checkTargetName(target);
            }
        }
    }

    /*
     * (non-Javadoc)
     * 
     * @see com.nokia.helium.antlint.ant.types.Check#run(java.io.File)
     */
    public void run(File antFilename) throws AntlintException {

        List<Element> targetNodes = new ArrayList<Element>();

        this.antFile = antFilename;
        SAXReader saxReader = new SAXReader();
        Document doc;
        try {
            doc = saxReader.read(antFilename);
            elementTreeWalk(doc.getRootElement(), "target", targetNodes);
        } catch (DocumentException e) {
            throw new AntlintException("Invalid XML file " + e.getMessage());
        }
        for (Element targetNode : targetNodes) {
            run(targetNode);
        }

    }

    /**
     * Check the given target name.
     * 
     * @param targetName
     *            is the target name to check.
     */
    private void checkTargetName(String targetName) {
        if (targetName != null && !targetName.isEmpty()) {
            Pattern p1 = Pattern.compile(getRegExp());
            Matcher m1 = p1.matcher(targetName);
            if (!m1.matches()) {
                this.getReporter().report(this.getSeverity(),
                        "INVALID Target Name: " + targetName,
                        this.getAntFile(), 0);
            }
        } else {
            log("Target name not specified!");
        }
    }

    /**
     * @return the regExp
     */
    public String getRegExp() {
        return regExp;
    }

    /**
     * @param regExp
     *            the regExp to set
     */
    public void setRegExp(String regExp) {
        this.regExp = regExp;
    }

    /*
     * (non-Javadoc)
     * 
     * @see org.apache.tools.ant.types.DataType#toString()
     */
    public String toString() {
        return "CheckTargetName";
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
