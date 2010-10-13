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

/**
 * <code>CheckFileName</code> is used to check the naming convention of the ant
 * files.
 * 
 * <pre>
 * Usage:
 * 
 *  &lt;antlint&gt;
 *       &lt;fileset id=&quot;antlint.files&quot; dir=&quot;${antlint.test.dir}/data&quot;&gt;
 *               &lt;include name=&quot;*.ant.xml&quot;/&gt;
 *               &lt;include name=&quot;*build.xml&quot;/&gt;
 *               &lt;include name=&quot;*.antlib.xml&quot;/&gt;
 *       &lt;/fileset&gt;
 *       &lt;checkFileName severity=&quot;error&quot; regexp=&quot;([a-z0-9[\\d\\-]]*)&quot;/&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="checkFileName" category="AntLint"
 * 
 */
public class CheckFileName extends AbstractCheck {

    private String regExp;

    /**
     * {@inheritDoc}
     */
    public void run() {
        String fileName = getAntFile().getFile().getName();
        if (!matchFound(fileName, getRegExp())) {
            report("Invalid file Name: " + fileName);
        }
    }

    /**
     * Method to set the regular expression.
     * 
     * @param regExp the regExp to set
     */
    public void setRegExp(String regExp) {
        this.regExp = regExp;
    }

    /**
     * Method returns the regular expression.
     * 
     * @return the regular expression
     */
    public String getRegExp() {
        return regExp;
    }
}
