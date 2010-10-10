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
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

import org.apache.tools.ant.BuildException;

import com.nokia.helium.ant.data.MacroMeta;
import com.nokia.helium.ant.data.TargetMeta;

/**
 * <code>PythonScriptDumper</code> is used to extract and dump Python and Jython
 * scripts from the Ant files.
 */
public class PythonScriptDump extends ScriptDump {

    protected void run(TargetMeta targetMeta) {
        String xpath = "//target[@name='" + targetMeta.getName()
                + "']/descendant::*[name()=\"hlm:python\"]";
        List<MacroMeta> macros = targetMeta.getScriptDefinitions(xpath);
        int i = 0;
        for (MacroMeta macroMeta : macros) {
            writePythonFile(i + "_" + targetMeta.getName(), macroMeta.getText());
            i++;
        }
        super.run(targetMeta);
    }

    protected void run(MacroMeta macroMeta) {
        String language = macroMeta.getAttr("language");
        if (language != null && language.equals("jython")) {
            writeJythonFile(getScriptName(macroMeta), macroMeta.getText());
        }
    }

    private String getScriptName(MacroMeta macroMeta) {
        String name = macroMeta.getName();
        if (name.isEmpty()) {
            name = "target_" + macroMeta.getParent().getName();
        }
        return name;
    }

    protected String getMacroXPathExpression() {
        return "//scriptdef";
    }

    /**
     * {@inheritDoc}
     */
    protected String getScriptXPathExpression(String targetName) {
        return ".//script | .//scriptcondition";
    }

    /**
     * Writes the given text to a python file.
     * 
     * @param name is the name of the file to be written.
     * @param text is the text to be written inside the file.
     */
    private void writePythonFile(String name, String text) {
        PrintWriter output = null;
        try {
            String outputPath = getOutputDir().getCanonicalPath() + File.separator + "python";
            new File(outputPath).mkdirs();
            File file = new File(outputPath + File.separator + "target" + name + ".py");
            output = new PrintWriter(new FileOutputStream(file));
            if (!text.equals("")) {
                output.write("def abc():");
                for (String line : text.split("\n")) {
                    output.write("    " + line + "\n");
                }
            }
        } catch (IOException e) {
            throw new BuildException("IOException:Not able to write python file " + name + ".py");
        } finally {
            if (output != null) {
                output.close();
            }
        }
    }

    /**
     * Write a script with the given name and the text.
     * 
     * @param name is the name of the script
     * @param text is the script text.
     */
    private void writeJythonFile(String name, String text) {
        PrintWriter output = null, output2 = null;
        try {
            String outputPath = getOutputDir().getCanonicalPath() + File.separator + "jep";
            new File(outputPath).mkdirs();
            File file = new File(outputPath + File.separator + name + "_jep.py");
            output = new PrintWriter(new FileOutputStream(file));
            output.write("def abc():\n");
            output.write("    attributes = {} # pylint: disable=C0103\n");
            output.write("    elements = {} # pylint: disable=C0103\n");
            output.write("    project = None # pylint: disable=C0103\n");
            output.write("    self = None # pylint: disable=C0103\n");
            text = text.replace(" File(", " self.File(");

            for (String line : text.split("\n")) {
                output.write("    " + line + "\n");
            }

            if (text.contains("import ")) {
                File file2 = new File(getOutputDir().getCanonicalPath() + File.separator
                        + "test_jython.xml");
                output2 = new PrintWriter(new FileOutputStream(file2, true));
                output2.write("try:\n");
                for (String line : text.split("\n")) {
                    if (line.trim().startsWith("import ") || line.trim().startsWith("from ")) {
                        output2.write("    " + line + "\n");
                    }
                }
                output2.write("except ImportError, e:\n");
                output2.write("    print '" + name + " failed: ' + str(e)\n");
            }
        } catch (IOException e) {
            throw new BuildException("Not able to write JEP File " + name + "_jep.py");
        } finally {
            if (output != null) {
                output.close();
            }
            if (output2 != null) {
                output2.close();
            }
        }
    }
}
