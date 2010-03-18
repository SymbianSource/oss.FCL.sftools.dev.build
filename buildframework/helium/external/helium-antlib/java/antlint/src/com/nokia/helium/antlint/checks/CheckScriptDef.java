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
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.tools.ant.BuildException;
import org.dom4j.Element;
import org.dom4j.Node;

/**
 * <code>CheckScriptDef</code> is used to check the coding convention in
 * scriptdef.
 * 
 */
public class CheckScriptDef extends AbstractScriptCheck {

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        if (node.getName().equals("scriptdef")) {
            String scriptdefname = node.attributeValue("name");
            String language = node.attributeValue("language");

            checkScriptDef(scriptdefname, node);

            if (language.equals("beanshell")) {
                writeBeanshellFile(scriptdefname, node.getText());
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
    public void checkScriptDef(String name, Node node) {
        List<Node> statements = node.selectNodes("//scriptdef[@name='" + name
                + "']/attribute");
        Pattern p1 = Pattern.compile("attributes.get\\([\"']([^\"']*)[\"']\\)");
        Matcher m1 = p1.matcher(node.getText());
        ArrayList<String> props = new ArrayList<String>();
        while (m1.find()) {
            props.add(m1.group(1));
        }

        if (!statements.isEmpty() && !props.isEmpty()) {
            for (Node statement : statements) {
                if (!props.contains(statement.valueOf("@name"))) {
                    // for (String x : props)
                    // log(x);
                    log("Scriptdef " + name + " does not use "
                            + statement.valueOf("@name"));
                }
            }
        }
    }

    /**
     * Write a bean shell file with the given text.
     * 
     * @param scriptdefname
     *            is the name of the file to be written.
     * @param text
     *            is the text to be written inside the file.
     */
    private void writeBeanshellFile(String scriptdefname, String text) {
        scriptdefname = "Beanshell" + scriptdefname;
        try {
            String heliumpath = new File(getProject().getProperty(
                    "helium.build.dir")).getCanonicalPath();
            new File(heliumpath + File.separator + "beanshell").mkdirs();
            File file = new File(heliumpath + File.separator + "beanshell"
                    + File.separator + scriptdefname + ".java");
            PrintWriter output = new PrintWriter(new FileOutputStream(file));

            for (String line : text.split("\n")) {
                if (line.trim().startsWith("import"))
                    output.write(line + "\n");
            }

            output.write("/**\n * x\n */\npublic final class " + scriptdefname
                    + " {\n");
            output.write("private " + scriptdefname + "() { }\n");
            output.write("public static void main(String[] args) {\n");
            for (String line : text.split("\n")) {
                if (!line.trim().startsWith("import"))
                    output.write(line + "\n");
            }
            output.write("} }");
            output.close();
        } catch (Exception e) {
            throw new BuildException("Not able to write Beanshell File "
                    + scriptdefname + ".java");
        }
    }
}
