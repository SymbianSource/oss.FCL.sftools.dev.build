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
 * <code>CheckRunTarget</code> is used to check whether runtarget calls a target
 * that has dependencies.
 * 
 */
public class CheckRunTarget extends AbstractCheck {

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        if (node.getName().equals("target")) {
            checkRunTargets(node);
        }
    }

    /**
     * Check against the given node.
     * 
     * @param node
     *            is the node to check.
     */
    @SuppressWarnings("unchecked")
    private void checkRunTargets(Element node) {
        if (node.elements("runtarget") != null) {
            List<Element> runTargetList = node.elements("runtarget");
            for (Element runTargetElement : runTargetList) {
                String runTargetName = runTargetElement
                        .attributeValue("target");
                if (checkTargetDependency(runTargetName)) {
                    log("<runtarget> calls the target " + runTargetName
                            + " that has dependencies!");
                }
            }
        }
    }

}
