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

import com.nokia.helium.ant.data.TargetMeta;

/**
 * <code>CheckTargetName</code> is used to check the naming convention of the
 * target names.
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
 *       &lt;checkTargetName&quot; severity=&quot;error&quot; regexp=&quot;([a-z0-9[\\d\\-]]*)&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="checkTargetName" category="AntLint"
 * 
 */
public class CheckTargetName extends AbstractTargetCheck {

    private String regExp;

    /**
     * {@inheritDoc}
     */
    protected void run(TargetMeta targetMeta) {
        String target = targetMeta.getName();
        if (target != null && !target.isEmpty()) {
            if (!target.equals("tearDown") && !target.equals("setUp")
                    && !target.equals("suiteTearDown") && !target.equals("suiteSetUp")
                    && !matches(target, getRegExp())) {
                report("INVALID Target Name: " + target, targetMeta.getLineNumber());
            }
        } else {
            report("Target name not specified!", targetMeta.getLineNumber());
        }
    }

    /**
     * @return the regExp
     */
    public String getRegExp() {
        return regExp;
    }

    /**
     * @param regExp the regExp to set
     */
    public void setRegExp(String regExp) {
        this.regExp = regExp;
    }
}
