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

import java.io.File;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

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
 *       &lt;CheckFileName&quot; severity=&quot;error&quot; enabled=&quot;true&quot; regexp=&quot;([a-z0-9[\\d\\-]]*)&quot;/&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="CheckFileName" category="AntLint"
 * 
 */
public class CheckFileName extends AbstractCheck {

    private String regExp;
    private File antFile;

    /*
     * (non-Javadoc)
     * 
     * @see com.nokia.helium.antlint.ant.types.Check#run(java.io.File)
     */
    public void run(File antFilename) {
        if (antFilename != null) {
            this.antFile = antFilename;
            boolean found = false;
            Pattern p1 = Pattern.compile(getRegExp());
            Matcher m1 = p1.matcher(antFilename.getName());
            while (m1.find()) {
                found = true;
            }
            if (!found) {
                this.getReporter().report(this.getSeverity(),
                        "INVALID File Name: " + antFilename.getName(),
                        this.getAntFile(), 0);
            }
        }
    }

    /**
     * @param regExp
     *            the regExp to set
     */
    public void setRegExp(String regExp) {
        this.regExp = regExp;
    }

    /**
     * @return the regExp
     */
    public String getRegExp() {
        return regExp;
    }

    /*
     * (non-Javadoc)
     * 
     * @see org.apache.tools.ant.types.DataType#toString()
     */
    public String toString() {
        return "CheckFileName";
    }

    /*
     * (non-Javadoc)
     * 
     * @see com.nokia.helium.antlint.ant.types.Check#getAntFile()
     */
    public File getAntFile() {
        return this.antFile;
    }

}
