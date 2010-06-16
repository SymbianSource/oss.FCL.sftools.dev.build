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
import java.io.FileWriter;
import java.io.IOException;
import java.io.Writer;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.DataType;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.nokia.helium.antlint.ant.Reporter;
import com.nokia.helium.antlint.ant.Severity;

/**
 * This reporter will generate a Checkstyle compatible XML to
 * report Antlint issues.
 * 
 * Usage:
 * 
 * <pre>
 *  &lt;antlint&gt;
 *       &lt;fileset id=&quot;antlint.files&quot; dir=&quot;${antlint.test.dir}/data&quot;&gt;
 *               &lt;include name=&quot;*.ant.xml&quot;/&gt;
 *               &lt;include name=&quot;*build.xml&quot;/&gt;
 *               &lt;include name=&quot;*.antlib.xml&quot;/&gt;
 *       &lt;/fileset&gt;
 *       
 *       ...
 *       
 *       &lt;antlintCheckstyleReporter file=&quot;report.xml&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 *    
 * @ant.type name="antlintCheckstyleReporter" category="AntLint"
 */
public class CheckstyleXmlReporter extends DataType implements Reporter {

    private Task task;
    private Document doc;
    private File file;
    private Element currentFileNode;
    private File currentFile;

    /**
     * {@inheritDoc}
     */
    @Override
    public void report(Severity severity, String message, File filename,
            int lineNo) {
        if (doc != null) {
            if (currentFile == null || !currentFile.equals(filename)) {
                currentFileNode = doc.createElement("file");
                doc.getDocumentElement().appendChild(currentFileNode);
                currentFile = filename;
                currentFileNode.setAttribute("name", currentFile.getAbsolutePath());
            }
            Element element = doc.createElement("error");
            element.setAttribute("severity", severity.getValue());
            element.setAttribute("message", message);
            element.setAttribute("line", "" + lineNo);
            element.setAttribute("source", "antlint");
            currentFileNode.appendChild(element);
        }
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void setTask(Task task) {
        this.task = task;
    }

    /**
     * Closing the reporting session. It will generates
     * the xml file.
     */
    @Override
    public void close() {
        task.log("Creating " + file);
        try {
            // set up a transformer
            TransformerFactory transfac = TransformerFactory.newInstance();
            Transformer trans = transfac.newTransformer();
            trans.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "yes");
            trans.setOutputProperty(OutputKeys.INDENT, "yes");

            // create string from xml tree
            Writer writer = new FileWriter(file);
            StreamResult result = new StreamResult(writer);
            DOMSource source = new DOMSource(doc);
            trans.transform(source, result);
        } catch (TransformerException e) {
            throw new BuildException(e.getMessage(), e);
        } catch (IOException e) {
            throw new BuildException(e.getMessage(), e);
        } finally {
            task = null;
        }
    }

    /**
     * {@inheritDoc}    
     */
    @Override
    public void open() {
        if (file == null) {
            throw new BuildException("'file' attribute is not defined.");
        }
        try {
            DocumentBuilderFactory builder = DocumentBuilderFactory.newInstance();
            DocumentBuilder docBuilder;
            docBuilder = builder.newDocumentBuilder();
            doc = docBuilder.newDocument();
            Element root = doc.createElement("checkstyle");
            root.setAttribute("version", "5.0");
            doc.appendChild(root);
        } catch (ParserConfigurationException e) {
            throw new BuildException(e.getMessage(), e);
        }
    }

    /**
     * Defines the output file.
     * @param file
     * @ant.required
     */
    public void setFile(File file) {
        this.file = file;
    }

}
