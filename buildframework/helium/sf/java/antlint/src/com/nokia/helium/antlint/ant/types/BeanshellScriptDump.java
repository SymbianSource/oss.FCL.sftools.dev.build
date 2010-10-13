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

import org.apache.tools.ant.BuildException;

import com.nokia.helium.ant.data.MacroMeta;

/**
 * <code>BeanshellScriptDumper</code> is used to extract and dump beanshell
 * scripts from the Ant files.
 */
public class BeanshellScriptDump extends ScriptDump {

    /**
     * {@inheritDoc}
     */
    protected String getMacroXPathExpression() {
        return "//scriptdef";
    }

    protected String getScriptXPathExpression(String targetName) {
        return null;
    }

    protected void run(MacroMeta macroMeta) {
        String language = macroMeta.getAttr("language");
        if (language.equals("beanshell")) {
            writeBeanshellFile(macroMeta.getName(), macroMeta.getText());
        }
    }

    /**
     * Write a bean shell file with the given text.
     * 
     * @param scriptdefname is the name of the file to be written.
     * @param text is the text to be written inside the file.
     */
    private void writeBeanshellFile(String scriptdefname, String text) {
        PrintWriter output = null;
        scriptdefname = "Beanshell" + scriptdefname;

        try {
            String outputPath = getOutputDir().getCanonicalPath();
            new File(outputPath).mkdirs();
            File file = new File(outputPath + File.separator + scriptdefname + ".java");
            output = new PrintWriter(new FileOutputStream(file));

            for (String line : text.split("\n")) {
                if (line.trim().startsWith("import")) {
                    output.write(line + "\n");
                }
            }
            output.write("/**\n * x\n */\npublic final class " + scriptdefname + " {\n");
            output.write("    private " + scriptdefname + "() { }\n");
            output.write("    public static void main(String[] args) {\n");
            for (String line : text.split("\n")) {
                if (!line.trim().startsWith("import")) {
                    output.write("        " + line + "\n");
                }
            }
            output.write("    }\n");
            output.write("}\n");
        } catch (IOException e) {
            throw new BuildException("Not able to write Beanshell File " + scriptdefname + ".java");
        } finally {
            if (output != null) {
                output.close();
            }
        }
    }
}
