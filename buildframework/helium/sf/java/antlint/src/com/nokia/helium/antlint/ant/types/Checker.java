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

import org.apache.tools.ant.types.DataType;

/**
 * <code>Checker</code> is a datatype used to hold information related to
 * antlint check configurations.
 * 
 * <pre>
 * Usage:
 *  
 *      &lt;checker name=&quot;CheckTargetName&quot; severity=&quot;warning&quot;&gt;([a-z0-9[\\d\\-]]*)&lt;/checker&gt;
 * </pre>
 * 
 */
public class Checker extends DataType {

    private String name;
    private String text;
    private String severity;

    /**
     * Set the pattern text.
     * 
     * @param text
     *            is the pattern text to set.
     */
    public void addText(String text) {
        this.text = text;
    }

    /**
     * Get the name of the Checker.
     * 
     * @return name of the checker.
     */
    public String getName() {
        return name;
    }

    /**
     * Set the name of the Checker.
     * 
     * @param name
     *            is the name of the checker to set.
     * @ant.required
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * Get the pattern set for this Checker.
     * 
     * @return the pattern.
     */
    public String getPattern() {
        return text;
    }

    /**
     * Get the severity.
     * 
     * @return the severity
     */
    public String getSeverity() {
        return severity;
    }

    /**
     * Set the severity. (Valid values : error|warning)
     * 
     * @param severity
     *            is the severity to set.
     * @ant.required
     */
    public void setSeverity(String severity) {
        this.severity = severity;
    }

}
