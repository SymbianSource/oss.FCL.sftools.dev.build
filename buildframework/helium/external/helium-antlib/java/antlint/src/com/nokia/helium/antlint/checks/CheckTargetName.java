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

import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.tools.ant.BuildException;
import org.dom4j.Element;

/**
 * <code>CheckTargetName</code> is used to check the naming convention of the
 * target names.
 * 
 */
public class CheckTargetName extends AbstractCheck {

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        if (node.getName().equals("target")) {
            String target = node.attributeValue("name");
            checkTargetName(target);
        }
    }

    /**
     * Check the given target name.
     * 
     * @param targetName
     *            is the target name to check.
     */
    private void checkTargetName(String targetName) {
        if (targetName != null && !targetName.isEmpty()) {
            try {
                Pattern p1 = Pattern.compile(getPattern());
                Matcher m1 = p1.matcher(targetName);
                if (!m1.matches()) {
                    log("INVALID Target Name: " + targetName);
                }
            } catch (Exception e) {
                throw new BuildException(
                        "Not able to match the target name for " + targetName);
            }
        } else {
            log("Target name not specified!");
        }
    }
}
