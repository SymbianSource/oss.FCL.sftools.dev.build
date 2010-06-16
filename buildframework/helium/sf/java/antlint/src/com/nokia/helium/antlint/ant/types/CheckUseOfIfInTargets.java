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

import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.Element;
import org.dom4j.Node;
import org.dom4j.io.SAXReader;

import com.nokia.helium.antlint.ant.AntlintException;

/**
 * <code>CheckUseOfIfInTargets</code> is used to check the usage of if task as
 * against the condition task or &lt;target if|unless="property.name"&gt; inside
 * targets.
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
 *       &lt;CheckUseOfIfInTargets&quot; severity=&quot;error&quot; enabled=&quot;true&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="CheckUseOfIfInTargets" category="AntLint"
 * 
 */
public class CheckUseOfIfInTargets extends AbstractCheck {

    private File antFile;

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        if (node.getName().equals("target")) {
            checkUseOfIf(node);
        }
    }

    /**
     * Check against the given node.
     * 
     * @param node
     *            is the node to check.
     */
    @SuppressWarnings("unchecked")
    private void checkUseOfIf(Element node) {
        String target = node.attributeValue("name");
        String targetxpath = "//target[@name='" + target + "']//if";

        List<Node> statements2 = node.selectNodes(targetxpath);
        for (Node statement : statements2) {
            List<Node> conditiontest = statement.selectNodes("./then/property");
            if (conditiontest != null && conditiontest.size() == 1) {
                List<Node> conditiontest2 = statement
                        .selectNodes("./else/property");
                if (conditiontest2 != null && conditiontest2.size() == 1) {
                    this
                            .getReporter()
                            .report(
                                    this.getSeverity(),
                                    "Target "
                                            + target
                                            + " poor use of if-else-property statement, use condition task",
                                    this.getAntFile(), 0);
                } else if (statement.selectNodes("./else").size() == 0) {
                    this
                            .getReporter()
                            .report(
                                    this.getSeverity(),
                                    "Target "
                                            + target
                                            + " poor use of if-then-property statement, use condition task",
                                    this.getAntFile(), 0);
                }
            }
        }
        List<Node> statements = node.selectNodes("//target[@name='" + target
                + "']/*");
        if (!(statements.size() > 1)) {
            if (node.selectSingleNode(targetxpath + "/else") == null) {
                if (node.selectSingleNode(targetxpath + "/isset") != null
                        || node.selectSingleNode(targetxpath + "/not/isset") != null) {
                    this
                            .getReporter()
                            .report(
                                    this.getSeverity(),
                                    "Target "
                                            + target
                                            + " poor use of if statement, use <target if|unless=\"prop\"",
                                    this.getAntFile(), 0);
                }
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

    /*
     * (non-Javadoc)
     * 
     * @see org.apache.tools.ant.types.DataType#toString()
     */
    public String toString() {
        return "CheckUseOfIfInTargets";
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
