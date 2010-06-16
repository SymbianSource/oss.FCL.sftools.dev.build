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
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.dom4j.Document;
import org.dom4j.DocumentException;
import org.dom4j.Element;
import org.dom4j.Node;
import org.dom4j.io.SAXReader;

import com.nokia.helium.antlint.ant.AntlintException;

/**
 * <code>CheckScriptDefStyle</code> is used to check the coding style of
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
 *       &lt;CheckScriptDefStyle&quot; severity=&quot;error&quot; enabled=&quot;true&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="CheckScriptDefStyle" category="AntLint"
 * 
 */
public class CheckScriptDefStyle extends AbstractCheck {

    private File antFile;

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        if (node.getName().equals("scriptdef")) {
            String scriptdefname = node.attributeValue("name");
            checkScriptDefStyle(scriptdefname, node);
        }
    }

    /**
     * Check against the given node.
     * 
     * @param node
     *            is the node to check.
     */
    @SuppressWarnings("unchecked")
    public void checkScriptDefStyle(String name, Node node) {
        List<Node> statements = node.selectNodes("//scriptdef[@name='" + name
                + "']/attribute");
        Pattern p1 = Pattern.compile("attributes.get\\([\"']([^\"']*)[\"']\\)");
        Matcher m1 = p1.matcher(node.getText());
        ArrayList<String> props = new ArrayList<String>();
        while (m1.find()) {
            props.add(m1.group(1));
        }

        ArrayList<String> attributes = new ArrayList<String>();
        for (Node statement : statements) {
            attributes.add(statement.valueOf("@name"));
        }

        if (!statements.isEmpty() && props.isEmpty()) {
            this
                    .getReporter()
                    .report(
                            this.getSeverity(),
                            "Scriptdef "
                                    + name
                                    + " doesn't reference attributes directly, poor style",
                            this.getAntFile(), 0);
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

    /*
     * (non-Javadoc)
     * 
     * @see org.apache.tools.ant.types.DataType#toString()
     */
    public String toString() {
        return "CheckScriptDefStyle";
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
