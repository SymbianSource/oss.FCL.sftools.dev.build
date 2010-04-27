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

import java.util.List;

import org.dom4j.Element;
import org.dom4j.Node;

/**
 * <code>CheckScriptSize</code> is used to check the size of script. By default,
 * the script should not contain more than 1000 characters.
 * 
 */
public class CheckScriptSize extends AbstractCheck {

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        if (node.getName().equals("target")) {
            checkSizeOfScript(node);
        }
    }

    /**
     * Check against the given node.
     * 
     * @param node is the node to check.
     */
    @SuppressWarnings("unchecked")
    private void checkSizeOfScript(Element node) {
        String target = node.attributeValue("name");

        List<Node> statements = node.selectNodes("//target[@name='" + target
                + "']/script | //target[@name='" + target
                + "']/*[name()=\"hlm:python\"]");

        for (Node statement : statements) {
            int size = statement.getText().length();
            if (size > 1000) {
                log("Target " + target + " has a script with " + size
                        + " characters, code should be inside a python file");
            }
        }
    }

}
