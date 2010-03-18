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
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.tools.ant.BuildException;
import org.dom4j.Element;

/**
 * <code>CheckPresetDefMacroDefName</code> is used to check the naming
 * convention of presetdef and macrodef
 * 
 */
public class CheckPresetDefMacroDefName extends AbstractCheck {

    /**
     * {@inheritDoc}
     */
    @SuppressWarnings("unchecked")
    public void run(Element node) {
        if (node.getName().equals("presetdef")
                || node.getName().equals("macrodef")) {
            String text = node.attributeValue("name");
            if (text != null && !text.isEmpty()) {
                checkDefName(text);
            }

            List<Element> attributeList = node.elements("attribute");
            for (Element attributeElement : attributeList) {
                String attributeName = attributeElement.attributeValue("name");
                checkDefName(attributeName);
            }
        }
    }

    /**
     * Check the given text.
     * 
     * @param text
     *            is the text to check.
     */
    private void checkDefName(String text) {
        try {
            Pattern p1 = Pattern.compile(getPattern());
            Matcher m1 = p1.matcher(text);
            if (!m1.matches()) {
                log("INVALID PRESETDEF/MACRODEF Name: " + text);
            }
        } catch (Exception e) {
            throw new BuildException("Not able to match the MacroDef Name for "
                    + text);
        }
    }
}
