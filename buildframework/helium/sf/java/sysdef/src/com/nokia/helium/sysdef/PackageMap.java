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

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;

import org.w3c.dom.Document;
import org.xml.sax.SAXException;

/**
 * This class implement the logic to parse package_map.xml files.
 *
 * Example of package_map.xml file:
 * <code>
 * &lt;?xml version="1.0"?&gt;
 * &lt;PackageMap root="sf" layer="app" /&gt;
 * </code>
 * 
 */
public class PackageMap {

    private String root;
    private String layer;
    
    /**
     * Create a PackageMapParser by loading data from an XML file.
     * 
     * @param file the file to parse
     * @throws PackageMapParsingException in case of error
     */
    public PackageMap(File file) throws PackageMapParsingException {
        try {
            DocumentBuilder builder = DocumentBuilderFactory.newInstance().newDocumentBuilder();
            Document doc = builder.parse(file);
            if (!doc.getDocumentElement().getNodeName().equals("PackageMap")) {
                throw new PackageMapParsingException("Invalid XML format for " + file.getAbsolutePath() + " root element must be PackageMap");
            }
            if (!doc.getDocumentElement().hasAttribute("root")) {
                throw new PackageMapParsingException("root attribute under element " + doc.getDocumentElement().getTagName() + " is missing in file: " + file);
            }
            if (!doc.getDocumentElement().hasAttribute("layer")) {
                throw new PackageMapParsingException("layer attribute under element " + doc.getDocumentElement().getTagName() + " is missing in file: " + file);
            }
            setRoot(doc.getDocumentElement().getAttribute("root"));
            setLayer(doc.getDocumentElement().getAttribute("layer"));
        } catch (ParserConfigurationException e) {
            throw new PackageMapParsingException("Error from the XML parser configuration: " + e.getMessage(), e);
        } catch (SAXException e) {
            throw new PackageMapParsingException("Error parsing the file: " + file + ": " + e.getMessage(), e);
        } catch (IOException e) {
            throw new PackageMapParsingException(e.getMessage(), e);
        }
    }

    public void setRoot(String root) {
        this.root = root;
    }

    public String getRoot() {
        return root;
    }

    public void setLayer(String layer) {
        this.layer = layer;
    }

    public String getLayer() {
        return layer;
    }
}
