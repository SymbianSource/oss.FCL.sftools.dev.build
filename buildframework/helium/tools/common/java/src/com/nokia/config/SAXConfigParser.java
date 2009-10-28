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
 
package com.nokia.config;

import org.dom4j.Document;
import org.dom4j.Element;
import org.dom4j.Attribute;
import org.dom4j.ElementPath;
import org.dom4j.ElementHandler;
import org.dom4j.io.SAXReader;

import java.io.*;
import java.util.*;

/**
 * Parses the sysdef config file and extracts the available configurations
 */
public class SAXConfigParser {
    private String sysdefFile;
    private String configs = "";

    /**
     * Constructor
     * @param fileName - name of the sysdef file to parse
     */
    public SAXConfigParser(String fileName) {
        sysdefFile = fileName;
    }

    /**
     * Constructor
     * @return list of available configurations that can be built.
     */    
     public String getConfigs() {
        File file = new File(sysdefFile);
            SAXReader reader = new SAXReader();
            reader.addHandler( "/SystemDefinition/build/target",
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
                                configs += (String)child.getValue() + ",";
                            }
                        }
                        row.detach();
                    }
                }
            );
            try {
                Document doc = reader.read(file);
            } catch (Exception e) {
                e.printStackTrace();
            }
        return configs;
    }
     
}