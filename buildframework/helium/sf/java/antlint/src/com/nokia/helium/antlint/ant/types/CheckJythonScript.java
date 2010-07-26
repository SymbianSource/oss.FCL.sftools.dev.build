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
import org.dom4j.io.SAXReader;

import com.nokia.helium.antlint.ant.AntlintException;

/**
 * <code>CheckJepJythonScript</code> is used to check the coding convention in
 * Jep and Jython scripts
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
 *       &lt;CheckJepJythonScript&quot; severity=&quot;error&quot; enabled=&quot;true&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="CheckJepJythonScript" category="AntLint"
 * 
 */
public class CheckJythonScript extends AbstractScriptCheck {

    private File outputDir;
    private File antFile;

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        if (node.getName().equals("target")) {
            checkScripts(node);
        }

        if (node.getName().equals("scriptdef")) {
            String scriptdefname = node.attributeValue("name");
            String language = node.attributeValue("language");
            if (language.equals("jython")) {
                writeJythonFile(scriptdefname, node.getText(), outputDir);
            }
        }
    }

    /**
     * Check against the given node.
     * 
     * @param node
     *            is the node to check.
     */
    @SuppressWarnings("unchecked")
    private void checkScripts(Element node) {
        String target = node.attributeValue("name");
        List<Element> scriptList = node.selectNodes("//target[@name='" + target
                + "']/descendant::script");
        for (Element scriptElement : scriptList) {
            String language = scriptElement.attributeValue("language");
            if (language.equals("jython")) {
                writeJythonFile("target_" + target, scriptElement.getText(),
                        outputDir);
            }
        }
    }

    /*
     * (non-Javadoc)
     * 
     * @see com.nokia.helium.antlint.ant.types.Check#run(java.io.File)
     */
    public void run(File antFilename) throws AntlintException {
        List<Element> scriptNodes = new ArrayList<Element>();

        this.antFile = antFilename;
        SAXReader saxReader = new SAXReader();
        Document doc;
        try {
            doc = saxReader.read(antFilename);
            elementTreeWalk(doc.getRootElement(), "target", scriptNodes);
            elementTreeWalk(doc.getRootElement(), "scriptdef", scriptNodes);
        } catch (DocumentException e) {
            throw new AntlintException("Invalid XML file " + e.getMessage());
        }
        for (Element targetNode : scriptNodes) {
            run(targetNode);
        }

    }

    /**
     * @param outputDir
     *            the outputDir to set
     */
    public void setOutputDir(File outputDir) {
        this.outputDir = outputDir;
    }

    /**
     * @return the outputDir
     */
    public File getOutputDir() {
        return outputDir;
    }

    /*
     * (non-Javadoc)
     * 
     * @see org.apache.tools.ant.types.DataType#toString()
     */
    public String toString() {
        return "CheckJepJythonScript";
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
