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

import java.util.List;

import com.nokia.helium.ant.data.AntObjectMeta;
import com.nokia.helium.ant.data.MacroMeta;

/**
 * 
 */
public class CheckScriptDefName extends AbstractScriptCheck {

    private String regExp;
    
    /**
     * Set the regular expression.
     * 
     * @param regExp the regExp to set
     */
    public void setRegExp(String regExp) {
        this.regExp = regExp;
    }

    /**
     * Get the regular expression.
     * 
     * @return the regExp
     */
    public String getRegExp() {
        return regExp;
    }

    /**
     * {@inheritDoc}
     */
    protected String getMacroXPathExpression() {
        return "//scriptdef";
    }

    /**
     * {@inheritDoc}
     */
    protected String getScriptXPathExpression(String targetName) {
        return null;
    }
    
    /**
     * {@inheritDoc}
     */
    protected void run(MacroMeta macroMeta) {
        validateName(macroMeta.getName(), macroMeta);
        List<String> attributes = macroMeta.getAttributes();
        for (String attrName : attributes) {
            validateName(attrName, macroMeta);
        }
    }

    private void validateName(String name, AntObjectMeta object) {
        if (name != null && !name.isEmpty() && getRegExp() != null && !matches(name, getRegExp())) {
            report("Invalid scriptdef name: " + name, object.getLineNumber());
        }
    }

}
