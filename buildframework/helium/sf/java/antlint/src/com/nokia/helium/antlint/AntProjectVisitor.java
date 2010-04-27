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
package com.nokia.helium.antlint;

import java.util.Collection;

import org.dom4j.Element;
import org.dom4j.VisitorSupport;

import com.nokia.helium.antlint.checks.Check;

/**
 * <code>AntProjectVisitor</code> extends {@link VisitorSupport} and is used to
 * visit the various nodes of the given project and run the antlint checklist
 * against those nodes.
 * 
 */
public class AntProjectVisitor extends VisitorSupport {

    private Collection<Check> checks;

    /**
     * Create an instance of {@link AntProjectVisitor}.
     * 
     * @param checks is the antlint checklist.
     */
    public AntProjectVisitor(Collection<Check> checks) {
        this.checks = checks;
    }

    /**
     * Visit the given node and run the antlint checklist.
     */
    public void visit(Element node) {
        for (Check check : checks) {
            if (check.isEnabled())
                check.run(node);
        }
    }

}
