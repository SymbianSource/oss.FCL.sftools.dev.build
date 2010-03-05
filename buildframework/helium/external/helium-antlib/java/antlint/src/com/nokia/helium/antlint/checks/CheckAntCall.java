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
 * <code>CheckAntCall</code> is used to check whether antcall is used with no param
 * elements and calls the target with no dependencies
 *
 */
public class CheckAntCall extends AbstractCheck {

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        if (node.getName().equals("target")) {
            checkAntCalls(node);
        }
    }

    /**
     * Check against the given node.
     * 
     * @param node is the node to check.
     */
    @SuppressWarnings("unchecked")
    private void checkAntCalls(Element node) {
        if (node.elements("antcall") != null) {
            List<Element> antcallList = node.elements("antcall");
            for (Element antcallElement : antcallList) {
                String antcallName = antcallElement.attributeValue("target");
                if (((node.elements("param") == null) || (node
                        .elements("param") != null && node.elements("param")
                        .isEmpty()))
                        && !checkTargetDependency(antcallName)) {
                    log("<antcall> is used with no param elements and calls the target "
                            + antcallName
                            + " that has no dependencies! (<runtarget> could be used instead.)");
                }
            }
        }
    }
}
