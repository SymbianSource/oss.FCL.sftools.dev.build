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

package com.nokia.helium.ant.data;

import java.io.IOException;
import java.util.List;

import org.dom4j.Element;
import org.dom4j.Node;

/**
 * An Ant macro.
 */
public class MacroMeta extends TaskContainerMeta {

    public MacroMeta(AntObjectMeta parent, Element objNode) throws IOException {
        super(parent, objNode);
    }

    public String getDescription() {
        return getAttr("description");
    }

    @SuppressWarnings("unchecked")
    public String getUsage() {
        String macroName = getName();
        List<Node> statements = getNode().selectNodes(
                "//scriptdef[@name='" + macroName + "']/attribute | //macrodef[@name='" + macroName + "']/attribute");
        String usage = "";
        for (Node statement : statements) {
            String defaultval = statement.valueOf("@default");
            if (defaultval.equals("")) {
                defaultval = "value";
            }
            else {
                defaultval = "<i>" + defaultval + "</i>";
            }
            usage = usage + statement.valueOf("@name") + "=\"" + defaultval + "\"" + " ";
        }

        String macroElements = "";
        statements = getNode().selectNodes(
                "//scriptdef[@name='" + macroName + "']/element | //macrodef[@name='" + macroName + "']/element");
        for (Node statement : statements) {
            macroElements = "&lt;" + statement.valueOf("@name") + "/&gt;\n" + macroElements;
        }

        if (macroElements.equals("")) {
            return "&lt;hlm:" + macroName + " " + usage + "/&gt;";
        }
        else {
            return "&lt;hlm:" + macroName + " " + usage + "&gt;\n" + macroElements + "&lt;/hlm:" + macroName + "&gt;";
        }
    }
}
