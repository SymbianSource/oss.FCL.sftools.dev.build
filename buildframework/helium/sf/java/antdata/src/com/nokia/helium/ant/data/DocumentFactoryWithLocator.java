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

package com.nokia.helium.ant.data;

import org.dom4j.DocumentFactory;
import org.dom4j.Element;
import org.dom4j.QName;
import org.xml.sax.Locator;

/**
 * A dom4j DocumentFactory that supports adding location information into Element objects.
 */
@SuppressWarnings("serial")
public class DocumentFactoryWithLocator extends DocumentFactory {

    private SAXContentHandlerExt contentHandler;

    public Element createElement(QName qname) {
        ElementWithLocation element = new ElementWithLocation(qname);
        Locator locator = contentHandler.getDocumentLocator();
        element.setLocation(locator.getLineNumber(), locator.getColumnNumber());
        return element;
    }

    public void setContentHandler(SAXContentHandlerExt contentHandler) {
        this.contentHandler = contentHandler;
    }
}
