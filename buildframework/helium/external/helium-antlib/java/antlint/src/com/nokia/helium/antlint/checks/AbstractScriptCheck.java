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
import java.util.ArrayList;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.tools.ant.BuildException;

/**
 * <code>AbstractScriptCheck</code> is an abstract implementation of
 * {@link Check} and contains some concrete methods related to script.
 * 
 */
public abstract class AbstractScriptCheck extends AbstractCheck {

    /**
     * Write a script with the given name and the text.
     * 
     * @param name is the name of the script
     * @param text is the script text.
     */
    protected void writeJepFile(String name, String text) {
        if (text.contains("${")) {
            log("${ found in " + name);
        }
        try {
            String heliumpath = new File(getProject().getProperty(
                    "helium.build.dir")).getCanonicalPath();
            new File(heliumpath + File.separator + "jep").mkdirs();
            File file = new File(heliumpath + File.separator + "jep"
                    + File.separator + name + "_jep.py");
            PrintWriter output = new PrintWriter(new FileOutputStream(file));
            output.write("def abc():\n");
            output.write("    attributes = {} # pylint: disable-msg=C0103\n");
            output.write("    elements = {} # pylint: disable-msg=C0103\n");
            output.write("    project = None # pylint: disable-msg=C0103\n");
            output.write("    self = None # pylint: disable-msg=C0103\n");
            text = text.replace(" File(", " self.File(");
            for (String t : text.split("\n"))
                output.write("    " + t + "\n");
            output.close();

            if (text.contains("import ")) {
                File file2 = new File(heliumpath + File.separator
                        + "test_jython.xml");
                PrintWriter output2 = new PrintWriter(new FileOutputStream(
                        file2, true));
                output2.write("try:\n");
                for (String line : text.split("\n")) {
                    if (line.trim().startsWith("import ")
                            || line.trim().startsWith("from "))
                        output2.write("    " + line + "\n");
                }

                output2.write("except ImportError, e:\n");
                output2.write("    print '" + name
                        + " failed: ' + str(e)\n");
                output2.close();
            }
        } catch (Exception e) {
            throw new BuildException("Not able to write JEP File "
                    + name + "_jep.py");
        }
    }

    /**
     * Check for the properties in the given script text.
     * 
     * @param text is the script text to lookup.
     */
    protected void checkJepPropertiesInText(String text) {
        Pattern p1 = Pattern
                .compile("getProperty\\([\"']([a-zA-Z0-9\\.]*)[\"']\\)");
        Matcher m1 = p1.matcher(text);
        ArrayList<String> props = new ArrayList<String>();
        while (m1.find()) {
            props.add(m1.group(1));
        }
        for (String group : props)
            checkPropertyInModel(group);
    }

}
