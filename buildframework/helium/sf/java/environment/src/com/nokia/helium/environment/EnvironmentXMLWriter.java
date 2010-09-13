/*
 * Copyright (c) 2010 Nokia Corporation and/or its subsidiary(-ies).
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

package com.nokia.helium.environment;

import java.io.IOException;
import java.io.OutputStream;
import java.util.Iterator;
import java.util.List;

import org.dom4j.Document;
import org.dom4j.DocumentFactory;
import org.dom4j.Element;
import org.dom4j.io.OutputFormat;
import org.dom4j.io.XMLWriter;


/**
 * Writes the definition of an environment to an output stream.
 */
public class EnvironmentXMLWriter {
    private OutputStream out;
    private Document doc;

    public EnvironmentXMLWriter(OutputStream out) {
        this.out = out;
    }

    /**
     * Writes an environment definition in XML to output.
     * @param environment Enviroment definition.
     * @throws IOException If I/O error occurs.
     */
    public void write(Environment environment) throws IOException {
        doc = DocumentFactory.getInstance().createDocument();
        doc.addElement("environment");
        List<Executable> executables = environment.getExecutables();
        for (Iterator<Executable> iterator = executables.iterator(); iterator.hasNext();) {
            Executable executable = (Executable) iterator.next();
            write(executable);
        }
        XMLWriter writer = new XMLWriter(out, OutputFormat.createPrettyPrint());
        writer.write(doc);
        writer.close();
    }

    private void write(Executable executable) {
        Element toolsNode = doc.getRootElement();
        Element toolNode = toolsNode.addElement("tool");
        toolNode.addElement("name").setText(executable.getName());
        toolNode.addElement("version").setText(getItem(executable.getVersion()));
        toolNode.addElement("path").setText(getItem(executable.getPath()));
        if (executable.getHash() != null) {
            toolNode.addElement("hash").setText(getItem(executable.getHash()));
            toolNode.addElement("length").setText(Long.toString(executable.getLength()));
            toolNode.addElement("lastModified").setText(Long.toString(executable.getLastModified()));
        }
        toolNode.addElement("executed").setText(Boolean.toString(executable.isExecuted()));
    }
    
    private String getItem(String content) 
    {
        if (content == null) {
            return "";
        }
        return content;
    }
}



