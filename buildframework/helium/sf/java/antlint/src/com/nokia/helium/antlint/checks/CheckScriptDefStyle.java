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

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.dom4j.Element;
import org.dom4j.Node;

/**
 * <code>CheckScriptDefStyle</code> is used to check the coding style of
 * scriptdef.
 * 
 */
public class CheckScriptDefStyle extends AbstractCheck {

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        if (node.getName().equals("scriptdef")) {
            String scriptdefname = node.attributeValue("name");
            checkScriptDefStyle(scriptdefname, node);
        }
    }

    /**
     * Check against the given node.
     * 
     * @param node
     *            is the node to check.
     */
    @SuppressWarnings("unchecked")
    public void checkScriptDefStyle(String name, Node node) {
        List<Node> statements = node.selectNodes("//scriptdef[@name='" + name
                + "']/attribute");
        Pattern p1 = Pattern.compile("attributes.get\\([\"']([^\"']*)[\"']\\)");
        Matcher m1 = p1.matcher(node.getText());
        ArrayList<String> props = new ArrayList<String>();
        while (m1.find()) {
            props.add(m1.group(1));
        }

        ArrayList<String> attributes = new ArrayList<String>();
        for (Node statement : statements) {
            attributes.add(statement.valueOf("@name"));
        }

        if (!statements.isEmpty() && props.isEmpty()) {
            log("Scriptdef " + name
                    + " doesn't reference attributes directly, poor style");
        }
    }
}
