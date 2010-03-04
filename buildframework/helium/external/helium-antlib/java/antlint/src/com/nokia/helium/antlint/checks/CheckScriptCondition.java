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

/**
 * <code>CheckScriptCondition</code> is used to check the coding convention in
 * script condition
 * 
 */
public class CheckScriptCondition extends AbstractScriptCheck {

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        if (node.getName().equals("target")) {
            checkScriptConditions(node);
        }
    }

    /**
     * Check against the given node.
     * 
     * @param node
     *            is the node to check.
     */
    @SuppressWarnings("unchecked")
    private void checkScriptConditions(Element node) {
        String target = node.attributeValue("name");
        List<Element> scriptList = node.selectNodes("//target[@name='" + target
                + "']/descendant::scriptcondition");
        for (Element scriptElement : scriptList) {
            String language = scriptElement.attributeValue("language");
            if (language.equals("jep") || language.equals("jython")) {
                writeJepFile("scriptcondition_" + target, scriptElement
                        .getText());
            }
        }
    }
}
