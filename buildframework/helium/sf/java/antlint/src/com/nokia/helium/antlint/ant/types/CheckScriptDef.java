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
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.tools.ant.BuildException;
import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.Element;
import org.dom4j.Node;
import org.dom4j.io.SAXReader;

import com.nokia.helium.antlint.ant.AntlintException;

/**
 * <code>CheckScriptDef</code> is used to check the coding convention in
 * scriptdef.
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
 *       &lt;CheckScriptDef&quot; severity=&quot;error&quot; enabled=&quot;true&quot; outputDir=&quot;${antlint.test.dir}/output&quot;/&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="CheckScriptDef" category="AntLint"
 * 
 */
public class CheckScriptDef extends AbstractScriptCheck {

    private File outputDir;
    private File antFile;

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
                    this.getReporter().report(
                            this.getSeverity(),
                            "Scriptdef " + name + " does not use "
                                    + statement.valueOf("@name"),
                            this.getAntFile(), 0);
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
        if (getOutputDir() == null) {
            throw new BuildException("'output' attribute for the checker '"
                    + this.toString() + "' should be specified.");
        }
        scriptdefname = "Beanshell" + scriptdefname;
        try {
            String heliumpath = getOutputDir().getCanonicalPath();
            new File(heliumpath + File.separator + "beanshell").mkdirs();
            File file = new File(heliumpath + File.separator + "beanshell"
                    + File.separator + scriptdefname + ".java");
            PrintWriter output = new PrintWriter(new FileOutputStream(file));

            for (String line : text.split("\n")) {
                if (line.trim().startsWith("import")) {
                    output.write(line + "\n");
                }
            }

            output.write("/**\n * x\n */\npublic final class " + scriptdefname
                    + " {\n");
            output.write("    private " + scriptdefname + "() { }\n");
            output.write("    public static void main(String[] args) {\n");
            for (String line : text.split("\n")) {
                if (!line.trim().startsWith("import")) {
                    output.write("        " + line + "\n");
                }
            }
            output.write("    }\n");
            output.write("}\n");
            output.close();
        } catch (IOException e) {
            throw new BuildException("Not able to write Beanshell File "
                    + scriptdefname + ".java");
        }
    }

    /*
     * (non-Javadoc)
     * 
     * @see com.nokia.helium.antlint.ant.types.Check#run(java.io.File)
     */
    public void run(File antFilename) throws AntlintException {

        List<Element> scriptDefNodes = new ArrayList<Element>();

        this.antFile = antFilename;
        SAXReader saxReader = new SAXReader();
        Document doc;
        try {
            doc = saxReader.read(antFilename);
            elementTreeWalk(doc.getRootElement(), "scriptdef", scriptDefNodes);
        } catch (DocumentException e) {
            throw new AntlintException("Invalid XML file " + e.getMessage());
        }
        for (Element scriptDefNode : scriptDefNodes) {
            run(scriptDefNode);
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
        return "CheckScriptDef";
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
