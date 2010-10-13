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
package com.nokia.helium.antlint.ant.types;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import com.nokia.helium.ant.data.AntlibMeta;
import com.nokia.helium.ant.data.MacroMeta;
import com.nokia.helium.ant.data.ProjectMeta;
import com.nokia.helium.ant.data.RootAntObjectMeta;
import com.nokia.helium.ant.data.TargetMeta;

/**
 * <code>AbstractScriptCheck</code> is an abstract implementation of
 * {@link Check} and contains some concrete methods related to script.
 * 
 */
public abstract class AbstractScriptCheck extends AbstractTargetCheck {

    /**
     * {@inheritDoc}
     */
    protected void run(RootAntObjectMeta root) {
        super.run(root);
        if (getMacroXPathExpression() != null) {
            if (root instanceof ProjectMeta) {
                ProjectMeta projectMeta = (ProjectMeta) root;
                List<MacroMeta> macros = projectMeta
                        .getScriptDefinitions(getMacroXPathExpression());
                for (MacroMeta macroMeta : macros) {
                    run(macroMeta);
                }
            }
            if (root instanceof AntlibMeta) {
                AntlibMeta antlibMeta = (AntlibMeta) root;
                List<MacroMeta> macros = antlibMeta.getScriptDefinitions(getMacroXPathExpression());
                for (MacroMeta macroMeta : macros) {
                    run(macroMeta);
                }
            }
        }
    }

    /**
     * {@inheritDoc}
     */
    protected void run(TargetMeta targetMeta) {
        String xpath = getScriptXPathExpression(targetMeta.getName());
        if (xpath != null) {
            List<MacroMeta> macros = targetMeta.getScriptDefinitions(xpath);
            for (MacroMeta macroMeta : macros) {
                run(macroMeta);
            }
        }
    }

    /**
     * Method returns the name of the macro or a constructed name for the given
     * script using its parent name.
     * 
     * @param macroMeta is an instance of Macrometa.
     * @return name of the script
     */
    protected String getScriptName(MacroMeta macroMeta) {
        String name = macroMeta.getName();
        if (name.isEmpty()) {
            name = "target_" + macroMeta.getParent().getName();
        }
        return name;
    }

    /**
     * Method runs the check against the input {@link MacroMeta}.
     * 
     * @param macroMeta is the {@link MacroMeta} against whom the check is run.
     */
    protected abstract void run(MacroMeta macroMeta);

    /**
     * Get the xpath expression of the macro.
     * 
     * @return the xpath expression of the macro.
     */
    protected abstract String getMacroXPathExpression();

    /**
     * Get the xpath expression for the input target.
     * 
     * @param targetName is the name of the target.
     * @return the xpath expression for the input target.
     */
    protected abstract String getScriptXPathExpression(String targetName);

    /**
     * Method returns a list of property names used in the given script
     * definition.
     * 
     * @param macroMeta the macrometa instance to lookup.
     * @return a list of used property names
     */
    protected List<String> getUsedProperties(MacroMeta macroMeta) {
        Pattern pattern = Pattern.compile("attributes.get\\([\"']([^\"']*)[\"']\\)");
        Matcher matcher = pattern.matcher(macroMeta.getText());
        List<String> usedPropertyList = new ArrayList<String>();
        while (matcher.find()) {
            usedPropertyList.add(matcher.group(1));
        }
        return usedPropertyList;
    }

}
