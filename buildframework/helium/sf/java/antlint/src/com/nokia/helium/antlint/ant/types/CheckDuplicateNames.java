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
import java.util.ArrayList;
import java.util.Hashtable;

/**
 * <code>CheckDuplicateNames</code> is used to check for duplicate macro names.
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
 *       &lt;CheckDuplicateNames&quot; severity=&quot;error&quot; enabled=&quot;true&quot;/&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="CheckDuplicateNames" category="AntLint"
 */
public class CheckDuplicateNames extends AbstractCheck {

    private File antFile;

    /*
     * (non-Javadoc)
     * 
     * @see com.nokia.helium.antlint.ant.types.Check#run(java.io.File)
     */
    @SuppressWarnings("unchecked")
    public void run(File antFilename) {
        this.antFile = antFilename;
        Hashtable<String, Class<Object>> taskdefs = getProject()
                .getTaskDefinitions();
        ArrayList<String> macros = new ArrayList<String>(taskdefs.keySet());

        for (String macroName : macros) {
            if (macros.contains(macroName + "Macro")
                    || macros.contains(macroName + "macro")) {
                this.getReporter()
                        .report(
                                this.getSeverity(),
                                macroName + " and " + macroName + "Macro"
                                        + " found duplicate name",
                                this.getAntFile(), 0);
            }
        }
    }

    /*
     * (non-Javadoc)
     * 
     * @see org.apache.tools.ant.types.DataType#toString()
     */
    public String toString() {
        return "CheckDuplicateNames";
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
