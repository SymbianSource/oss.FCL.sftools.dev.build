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

import org.dom4j.QName;
import org.dom4j.dom.DOMElement;

/**
 * An Element that additionally stores location information about the element.
 */
@SuppressWarnings("serial")
public class ElementWithLocation extends DOMElement {
    
    private int lineNumber;
    private int columnNumber;

    public ElementWithLocation(QName qname) {
        super(qname);
    }
    void setLocation(int lineNumber, int columnNumber) {
        this.lineNumber = lineNumber;
        this.columnNumber = columnNumber;
    }

    int getLineNumber() {
        return lineNumber;
    }

    int getColumnNumber() {
        return columnNumber;
    }
}
