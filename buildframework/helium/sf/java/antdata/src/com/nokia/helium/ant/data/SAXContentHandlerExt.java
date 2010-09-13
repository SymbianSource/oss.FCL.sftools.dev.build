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
import org.dom4j.io.SAXContentHandler;
import org.xml.sax.Locator;

/**
 * An extension of SAXContentHandler that allows the Locator to be accessed.
 */
public class SAXContentHandlerExt extends SAXContentHandler {
    private Locator locator;

    public SAXContentHandlerExt(DocumentFactory documentFactory) {
        super(documentFactory, null);
    }

    public void setDocumentLocator(Locator documentLocator) {
        super.setDocumentLocator(documentLocator);
        this.locator = documentLocator;
    }

    public Locator getDocumentLocator() {
        return locator;
    }
}
