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

import java.io.File;
import java.util.List;

import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;

import org.dom4j.Element;
import org.dom4j.Node;

import com.nokia.helium.antlint.AntLintHandler;

/**
 * <code>CheckTabCharacter</code> is used to check the tab characters inside the
 * ant files.
 * 
 */
public class CheckTabCharacter extends AbstractCheck {

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        checkTabsInScript(node);
    }

    /**
     * Check against the given node.
     * 
     * @param node
     *            is the node to check.
     */
    @SuppressWarnings("unchecked")
    private void checkTabsInScript(Element node) {
        if (node.getName().equals("target")) {
            String target = node.attributeValue("name");

            List<Node> statements = node.selectNodes("//target[@name='"
                    + target + "']/script | //target[@name='" + target
                    + "']/*[name()=\"hlm:python\"]");

            for (Node statement : statements) {
                if (statement.getText().contains("\t")) {
                    log("Target " + target + " has a script with tabs");
                }
            }
        }
    }

    /**
     * {@inheritDoc}
     */
    public void run(String antFileName) {
        try {
            SAXParserFactory saxFactory = SAXParserFactory.newInstance();
            saxFactory.setNamespaceAware(true);
            saxFactory.setValidating(true);
            SAXParser parser = saxFactory.newSAXParser();
            AntLintHandler handler = new AntLintHandler(this);
            handler.setTabCharacterCheck(true);
            parser.parse(new File(antFileName), handler);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

}
