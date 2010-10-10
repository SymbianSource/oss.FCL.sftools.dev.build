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

import com.nokia.helium.ant.data.MacroMeta;

/**
 * <code>CheckScriptSize</code> is used to check the size of script. By default,
 * the script should not contain more than 1000 characters.
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
 *       &lt;checkScriptSize severity=&quot;error&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="checkScriptSize" category="AntLint"
 * 
 */
public class CheckScriptSize extends AbstractScriptCheck {

    /**
     * {@inheritDoc}
     */
    protected String getMacroXPathExpression() {
        return null;
    }

    /**
     * {@inheritDoc}
     */
    protected String getScriptXPathExpression(String targetName) {
        return ".//script | " + "//target[@name='" + targetName + "']/*[name()=\"hlm:python\"]";
    }

    /**
     * {@inheritDoc}
     */
    protected void run(MacroMeta macroMeta) {
        int size = macroMeta.getText().length();
        if (size > 1000) {
            report("Target " + macroMeta.getParent().getName() + " has a script with " + size
                    + " characters, code should be inside a python file", macroMeta.getLineNumber());
        }
    }
}
