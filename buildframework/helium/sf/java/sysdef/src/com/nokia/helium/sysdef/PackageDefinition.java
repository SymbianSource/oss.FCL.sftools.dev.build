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
package com.nokia.helium.sysdef;

import java.io.File;
import java.io.IOException;
import java.util.Hashtable;
import java.util.Map;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import org.w3c.dom.Document;
import org.w3c.dom.NamedNodeMap;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

/**
 * Basic package_definition file parser. It is meant to extract needed data for the root system
 * definition file creation.
 * 
 */
public class PackageDefinition {
    public static final String DEFAULT_ID_NAMESPACE = "http://www.symbian.org/system-definition";

    private String idNamespace;
    private String id;
    private Map<String, String> namespaces = new Hashtable<String, String>();

    /**
     * Construct a PackageDefinition object extracting data from the 
     * file <code>file</code>.
     *  
     * @param file
     * @throws PackageDefinitionParsingException
     */
    public PackageDefinition(File file) throws PackageDefinitionParsingException {
        try {
            DocumentBuilder builder = DocumentBuilderFactory.newInstance().newDocumentBuilder();
            Document doc = builder.parse(file);
            if (!doc.getDocumentElement().getNodeName().equals("SystemDefinition")) {
                throw new PackageDefinitionParsingException("Invalid XML format for "
                    + file.getAbsolutePath() + " root element must be SystemDefinition");
            }
            // Getting information from the SystemDefinition element
            if (doc.getDocumentElement().hasAttribute("id-namespace")) {
                idNamespace = doc.getDocumentElement().getAttribute("id-namespace");
            } else {
                idNamespace = DEFAULT_ID_NAMESPACE;
            }
            NamedNodeMap attrs = doc.getDocumentElement().getAttributes();
            for (int i = 0; i < attrs.getLength(); i++) {
                if (attrs.item(i).getNodeName().startsWith("xmlns:")) {
                    namespaces.put(attrs.item(i).getNodeName(), attrs.item(i).getNodeValue());
                }
            }

            // Getting information from the package element
            NodeList nodes = doc.getDocumentElement().getChildNodes();
            for (int i = 0; i < nodes.getLength(); i++) {
                if (nodes.item(i).getNodeName().equals("package")) {
                    if (nodes.item(i).getAttributes().getNamedItem("id") == null) {
                        throw new PackageDefinitionParsingException("Invalid XML format for "
                            + file.getAbsolutePath()
                            + " the package element must have an id attribute.");
                    }
                    id = nodes.item(i).getAttributes().getNamedItem("id").getNodeValue();
                }
            }
            if (id == null) {
                throw new PackageDefinitionParsingException("Invalid XML format for "
                    + file.getAbsolutePath() + " could not find any package definition.");
            }
        }
        catch (ParserConfigurationException e) {
            throw new PackageDefinitionParsingException("Error from the XML parser configuration: "
                + e.getMessage(), e);
        }
        catch (SAXException e) {
            throw new PackageDefinitionParsingException("Error parsing the file: " + file + ": "
                + e.getMessage(), e);
        }
        catch (IOException e) {
            throw new PackageDefinitionParsingException(e.getMessage(), e);
        }
    }

    /**
     * id-namespace of current package.
     * @return always returns a string
     */
    public String getIdNamespace() {
        return idNamespace;
    }

    /**
     * Id of the package.
     * @return
     */
    public String getId() {
        return id;
    }

    /**
     * List of global namespaces.
     * @return a map of namespaces <name, uri>
     */
    public Map<String, String> getNamespaces() {
        return namespaces;
    }
}
