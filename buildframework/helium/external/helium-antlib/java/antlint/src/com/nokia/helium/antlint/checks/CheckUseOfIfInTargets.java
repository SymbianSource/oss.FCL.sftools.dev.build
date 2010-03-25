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
 * <code>CheckUseOfIfInTargets</code> is used to check the usage of if task as
 * against the condition task or &lt;target if|unless="property.name"&gt; inside
 * targets.
 * 
 */
public class CheckUseOfIfInTargets extends AbstractCheck {

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        if (node.getName().equals("target")) {
            checkUseOfIf(node);
        }
    }

    /**
     * Check against the given node.
     * 
     * @param node
     *            is the node to check.
     */
    @SuppressWarnings("unchecked")
    private void checkUseOfIf(Element node) {
        String target = node.attributeValue("name");
        String targetxpath = "//target[@name='" + target + "']//if";

        List<Node> statements2 = node.selectNodes(targetxpath);
        for (Node statement : statements2) {
            List<Node> conditiontest = statement.selectNodes("./then/property");
            if (conditiontest != null && conditiontest.size() == 1) {
                List<Node> conditiontest2 = statement
                        .selectNodes("./else/property");
                if (conditiontest2 != null && conditiontest2.size() == 1) {
                    log("Target "
                            + target
                            + " poor use of if-else-property statement, use condition task");
                } else if (statement.selectNodes("./else").size() == 0) {
                    log("Target "
                            + target
                            + " poor use of if-then-property statement, use condition task");
                }
            }
        }
        List<Node> statements = node.selectNodes("//target[@name='" + target
                + "']/*");
        if (!(statements.size() > 1)) {
            if (node.selectSingleNode(targetxpath + "/else") == null) {
                if (node.selectSingleNode(targetxpath + "/isset") != null
                        || node.selectSingleNode(targetxpath + "/not/isset") != null) {
                    log("Target "
                            + target
                            + " poor use of if statement, use <target if|unless=\"prop\"");
                }
            }
        }
    }

}
