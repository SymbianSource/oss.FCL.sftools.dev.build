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
 * <code>CheckJythonScript</code> is used to check the coding convention of
 * Jython scripts
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
 *       &lt;checkJythonScript severity=&quot;error&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="checkJythonScript" category="AntLint"
 * 
 */
public class CheckJythonScript extends AbstractScriptCheck {

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
        return ".//script";
    }

    /**
     * {@inheritDoc}
     */
    protected void run(MacroMeta macroMeta) {
        String language = macroMeta.getAttr("language");
        if (language != null && language.equals("jython") && macroMeta.getText().contains("${")) {
            report("${ found in " + getScriptName(macroMeta));
        }
    }
}
