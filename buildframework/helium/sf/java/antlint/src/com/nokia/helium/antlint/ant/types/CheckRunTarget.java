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

import org.apache.tools.ant.Target;
import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.Element;
import org.dom4j.io.SAXReader;

import com.nokia.helium.antlint.ant.AntlintException;

/**
 * <code>CheckRunTarget</code> is used to check whether runtarget calls a target
 * that has dependencies.
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
 *       &lt;CheckRunTarget&quot; severity=&quot;error&quot; enabled=&quot;true&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="CheckRunTarget" category="AntLint"
 * 
 */
public class CheckRunTarget extends AbstractCheck {

    private File antFile;

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        if (node.getName().equals("target")) {
            checkRunTargets(node);
        }
    }

    /**
     * Check against the given node.
     * 
     * @param node
     *            is the node to check.
     */
    @SuppressWarnings("unchecked")
    private void checkRunTargets(Element node) {
        if (node.elements("runtarget") != null) {
            List<Element> runTargetList = node.elements("runtarget");
            for (Element runTargetElement : runTargetList) {
                String runTargetName = runTargetElement
                        .attributeValue("target");
                if (checkTargetDependency(runTargetName)) {
                    this.getReporter().report(
                            this.getSeverity(),
                            "<runtarget> calls the target " + runTargetName
                                    + " that has dependencies!",
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
        return "CheckRunTarget";
    }

    /**
     * Check the availability dependent targets of the given target.
     * 
     * @param targetName
     *            is the target for which dependent targets to be loked up.
     * @return true, if the dependant targets are available; otherwise false
     */
    private boolean checkTargetDependency(String targetName) {
        boolean dependencyCheck = false;
        Target targetDependency = (Target) getProject().getTargets().get(
                targetName);
        dependencyCheck = targetDependency != null
                && targetDependency.getDependencies().hasMoreElements();
        return dependencyCheck;
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
