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
 
package com.nokia.helium.sbs;

import org.dom4j.Document;
import org.apache.tools.ant.BuildException;
import org.dom4j.Element;
import org.dom4j.Attribute;
import org.dom4j.ElementPath;
import org.dom4j.ElementHandler;
import org.dom4j.io.SAXReader;
import org.apache.log4j.Logger;

import java.io.*;
import java.util.*;

/**
 * Parses the sysdef config file and extracts the available configurations
 */
public class SAXSysdefParser {
    private File sysdefFile;
    private String configs = "";
    private List<String> layers;
    private boolean initialized;
    private Logger log = Logger.getLogger(SAXSysdefParser.class);

    /**
     * Constructor
     * @param fileName - name of the sysdef file to parse
     */
    public SAXSysdefParser(File fileName) {
        
        sysdefFile = fileName;
    }
    
    public List<String> getLayers() {
        if (!initialized ) {
            initialized = true;
            parseConfig("layer");
            if (layers == null) {
                throw new BuildException("No layers found from sysdef");
            }
        }
        return layers;
    }

    /**
     * Constructor
     * @return list of available configurations that can be built.
     */    
     public void parseConfig(String nodeToGet) {
        layers = new ArrayList<String>();
        SAXReader reader = new SAXReader();
            reader.addHandler( "/SystemDefinition/systemModel/" + nodeToGet,
                new ElementHandler() {
                    public void onStart(ElementPath path) {
                    }
                    public void onEnd(ElementPath path) {
                        Element row = path.getCurrent();
                        Iterator itr = row.attributeIterator();
                        while (itr.hasNext())
                        {
                            Attribute child = (Attribute) itr.next();
                            String attrName = child.getQualifiedName();
                            if (attrName.equals("name")) {
                                layers.add((String)child.getValue());
                            }
                        }
                        row.detach();
                    }
                }
            );
        try {
            Document doc = reader.read(sysdefFile);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}