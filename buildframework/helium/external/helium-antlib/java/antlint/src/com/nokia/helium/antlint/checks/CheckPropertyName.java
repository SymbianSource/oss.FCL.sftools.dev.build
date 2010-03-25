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
 * <code>CheckPropertyName</code> is used to check the naming convention of
 * property names.
 * 
 */
public class CheckPropertyName extends AbstractCheck {

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        if (node.getName().equals("property")) {
            String text = node.attributeValue("name");
            if (text != null && !text.isEmpty()) {
                checkPropertyName(text);
            }
        }
    }

    /**
     * Check the given property name.
     * 
     * @param propertyName is the property name to check.
     */
    private void checkPropertyName(String propertyName) {
        try {
            Pattern p1 = Pattern.compile(getPattern());
            Matcher m1 = p1.matcher(propertyName);
            if (!m1.matches() && !isPropertyAlreadyVisited(propertyName)) {
                log("INVALID Property Name: " + propertyName);
                getAntFile().markPropertyAsVisited(propertyName);
            }
        } catch (Exception e) {
            throw new BuildException("Not able to match the Property Name for "
                    + propertyName);
        }
    }

    /**
     * Check whether the property is already visited or not.
     * 
     * @param propertyName is the property to be checked.
     * @return true, if already been visited; otherwise false
     */
    private boolean isPropertyAlreadyVisited(String propertyName) {
        return getAntFile().isPropertyVisited(propertyName);
    }
}
