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
package com.nokia.helium.antlint.checks;

import org.dom4j.Element;

/**
 * <code>CheckUseOfEqualsTask</code> is used to check the usage of equals task
 * as against istrue task.
 * 
 */
public class CheckUseOfEqualsTask extends AbstractCheck {

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        if (node.getName().equals("equals")) {
            String text = node.attributeValue("arg2");
            if (text.equals("true") || text.equals("yes")) {
                log(node.attributeValue("arg1")
                        + " uses 'equals' should use 'istrue' task");
            }
        }
    }

}
