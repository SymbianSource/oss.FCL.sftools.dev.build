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
package com.nokia.helium.antlint.checks;

import java.io.File;
import java.io.FileOutputStream;
import java.io.PrintWriter;
import java.util.List;

import org.apache.tools.ant.BuildException;
import org.dom4j.Element;

/**
 * <code>CheckPythonTasks</code> is used to the check the coding convention of
 * python tasks.
 * 
 */
public class CheckPythonTasks extends AbstractCheck {

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
        try {
            String heliumpath = new File(getProject().getProperty(
                    "helium.build.dir")).getCanonicalPath();
            new File(heliumpath + File.separator + "python").mkdirs();
            File file = new File(heliumpath + File.separator + "python"
                    + File.separator + "target" + name + ".py");
            PrintWriter output = new PrintWriter(new FileOutputStream(file));
            if (!text.equals("")) {
                output.write("def abc():");
                for (String t : text.split("\n"))
                    output.write("    " + t + "\n");
            }
            output.close();
        } catch (Exception e) {
            e.printStackTrace();
            throw new BuildException("Not able to write python file " + name
                    + ".py");
        }
    }
}
