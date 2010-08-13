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
package com.nokia.helium.metadata.ant.types.sbs;

import org.xml.sax.Attributes;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;

import com.nokia.helium.metadata.ant.types.sbs.SBSLogHandler.UncategorizedItem;
import com.nokia.helium.metadata.ant.types.sbs.SBSLogHandler.UncategorizedItemMap;

/**
 * The CategorizationHandler will try to push general 
 * make errors (UncategorizedItem) to a particular component.
 *
 */
public class CategorizationHandler extends DefaultHandler {
    private SBSLogHandler logHandler;
    private boolean record;
    private StringBuffer text = new StringBuffer();
    private String currentComponent;
    
    /**
     * Default constructor, it needs a SBSLogHandler.
     * @param logHandler the calling SBSLogHandler
     */
    public CategorizationHandler(SBSLogHandler logHandler) {
        this.logHandler = logHandler;
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void endElement(String uri, String localName, String qName) {
        if (qName.equalsIgnoreCase("clean") && currentComponent != null) {
            record = false;
            UncategorizedItemMap uncategorizedItemMap = this.logHandler.getUncategorizedItemMap();
            for (String line : text.toString().split("\n")) {
                line = line.trim().replace("\"", "");
                if (line.length() > 0) {
                    if (uncategorizedItemMap.containsKey(line)) {
                        for (UncategorizedItem item : uncategorizedItemMap.get(line)) {
                            this.logHandler.getEventHandler().add(item.getPriotity(), currentComponent, item.getText(), item.getLineNumber());
                        }
                        uncategorizedItemMap.remove(line);
                    }
                }
            }
            currentComponent = null;
            text.setLength(0);
        }
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void startElement(String uri, String localName, String qName,
            Attributes attributes) throws SAXException {
        if (qName.equalsIgnoreCase("clean")) {
            currentComponent = this.logHandler.getComponent(attributes);
            record = true;
            text.setLength(0);
        }
    }
    
    /**
     * {@inheritDoc}
     */
    @Override
    public void characters(char[] ch, int start, int length)
        throws SAXException {
        if (record) {
            text.append(ch, start, length);
        }
        super.characters(ch, start, length);
    }
    
}
