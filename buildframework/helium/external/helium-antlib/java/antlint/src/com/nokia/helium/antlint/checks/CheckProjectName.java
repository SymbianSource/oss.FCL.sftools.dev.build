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
 * <code>CheckProjectName</code> is used to check the naming convention of
 * project names.
 * 
 */
public class CheckProjectName extends AbstractCheck {

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        if (node.getName().equals("project")) {
            String text = node.attributeValue("name");
            if (text != null && !text.isEmpty()) {
                checkProjectName(text);
            } else {
                log("Project name not specified!");
            }

        }
    }

    /**
     * Check the given the project name.
     * 
     * @param text is the text to check.
     */
    private void checkProjectName(String text) {
        try {
            Pattern p1 = Pattern.compile(getPattern());
            Matcher m1 = p1.matcher(text);
            if (!m1.matches()) {
                log("INVALID Project Name: " + text);
            }
        } catch (Exception e) {
            throw new BuildException("Not able to match Project Name for "
                    + text);
        }
    }

}
