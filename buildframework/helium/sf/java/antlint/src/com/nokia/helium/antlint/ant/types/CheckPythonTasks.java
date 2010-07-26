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
import java.io.FileOutputStream;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;
import java.io.IOException;

import org.apache.tools.ant.BuildException;
import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.Element;
import org.dom4j.io.SAXReader;

import com.nokia.helium.antlint.ant.AntlintException;

/**
 * <code>CheckPythonTasks</code> is used to the check the coding convention of
 * python tasks.
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
 *       &lt;CheckPythonTasks&quot; severity=&quot;error&quot; enabled=&quot;true&quot; outputDir=&quot;${antlint.test.dir}/output&quot;/&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="CheckPythonTasks" category="AntLint"
 */
public class CheckPythonTasks extends AbstractCheck {

    private File outputDir;
    private File antFile;

    /**
     * {@inheritDoc}
     */
    @SuppressWarnings("unchecked")
    public void run(Element node) {
        if (node.getName().equals("target")) {
            String target = node.attributeValue("name");
            List<Element> pythonList = node.selectNodes("//target[@name='"
                    + target + "']/descendant::*[name()=\"hlm:python\"]");
            int i = 0;
            for (Element pythonElement : pythonList) {
                writePythonFile(i + "_" + target, pythonElement.getText());
                i++;
            }
        }
    }

    /**
     * Writes the given text to a python file.
     * 
     * @param name
     *            is the name of the file to be written.
     * @param text
     *            is the text to be written inside the file.
     */
    private void writePythonFile(String name, String text) {
        if (getOutputDir() == null) {
            throw new BuildException("'output' attribute for the checker '"
                    + this.toString() + "' should be specified.");
        }
        try {
            String heliumpath = getOutputDir().getCanonicalPath();
            new File(heliumpath + File.separator + "python").mkdirs();
            File file = new File(heliumpath + File.separator + "python"
                    + File.separator + "target" + name + ".py");
            PrintWriter output = new PrintWriter(new FileOutputStream(file));
            if (!text.equals("")) {
                output.write("def abc():");
                for (String line : text.split("\n"))
                    output.write("    " + line + "\n");
            }
            output.close();
        } catch (IOException e) {
            throw new BuildException(
                    "IOException:Not able to write python file " + name + ".py");
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
        return "CheckPythonTasks";
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
