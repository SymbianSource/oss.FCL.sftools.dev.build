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

/**
 * <code>CheckPropertiesInDataModel</code> is used to check whether the properties are
 * defined in data model
 *
 */
public class CheckPropertiesInDataModel extends AbstractScriptCheck {

    /**
     * {@inheritDoc}
     */
    public void run(Element node) {
        if (node.getName().equals("target")) {
            checkInScripts(node);
            checkInScriptConditions(node);
            checkInPythonTasks(node);
        }
        
        if (node.getName().equals("scriptdef")) {
            String language = node.attributeValue("language");

            if (language.equals("jep") || language.equals("jython")) {
                checkJepPropertiesInText(node.getText());
            }
        }
    }

    /**
     * Check the properties defined inside script condition.
     *  
     * @param node is the node to check.
     */
    @SuppressWarnings("unchecked")
    private void checkInScriptConditions(Element node) {
        String target = node.attributeValue("name");
        List<Element> scriptList = node.selectNodes("//target[@name='" + target
                + "']/descendant::scriptcondition");
        for (Element scriptElement : scriptList) {
            String language = scriptElement.attributeValue("language");
            if (language.equals("jep") || language.equals("jython")) {
                checkJepPropertiesInText(scriptElement.getText());
            }
        }
    }

    /**
     * Check the properties defined inside scripts.
     *  
     * @param node is the node to check.
     */
    @SuppressWarnings("unchecked")
    private void checkInScripts(Element node) {
        String target = node.attributeValue("name");
        List<Element> scriptList = node.selectNodes("//target[@name='" + target
                + "']/descendant::script");
        for (Element scriptElement : scriptList) {
            String language = scriptElement.attributeValue("language");
            if (language.equals("jep") || language.equals("jython")) {
                checkJepPropertiesInText(scriptElement.getText());
            }
        }
    }
    
    /**
     * Check the properties defined inside python tasks.
     *  
     * @param node is the node to check.
     */
    @SuppressWarnings("unchecked")
    private void checkInPythonTasks(Element node) {
        String target = node.attributeValue("name");
        List<Element> pythonList = node.selectNodes("//target[@name='" + target
                + "']/descendant::*[name()=\"hlm:python\"]");
        for (Element pythonElement : pythonList) {
            checkPropertiesInText(pythonElement.getText());
        }
    }

    /**
     * Check for the properties in the given text.
     * 
     * @param text is the text to lookup.
     */
    private void checkPropertiesInText(String text) {
        Pattern p1 = Pattern.compile("r[\"']\\$\\{([a-zA-Z0-9\\.]*)\\}[\"']");
        Matcher m1 = p1.matcher(text);
        ArrayList<String> props = new ArrayList<String>();
        while (m1.find()) {
            props.add(m1.group(1));
        }
        for (String group : props)
            checkPropertyInModel(group);
    }

}
