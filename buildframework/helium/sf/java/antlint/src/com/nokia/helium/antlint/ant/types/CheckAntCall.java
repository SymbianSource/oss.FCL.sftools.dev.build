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

import com.nokia.helium.ant.data.TargetMeta;
import com.nokia.helium.ant.data.TaskMeta;

/**
 * <code>CheckAntCall</code> is used to check whether antcall is used with no
 * param elements and calls the target with no dependencies
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
 *       &lt;CheckAntCall&quot; severity=&quot;error&quot; enabled=&quot;true&quot;/&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="checkAntCall" category="AntLint"
 */
public class CheckAntCall extends AbstractTargetCheck {

    /**
     * {@inheritDoc}
     */
    public void run(TargetMeta targetMeta) {
        List<TaskMeta> antCalls = targetMeta.getTasks("antcall");
        int count = 0;
        count++;
        for (TaskMeta antCallMeta : antCalls) {
            if (antCallMeta.getParams().isEmpty()
                    && !checkTargetDependency(antCallMeta.getAttr("target"))) {
                report("<antcall> is used with no param " + "elements and calls the target '"
                        + antCallMeta.getAttr("target")
                        + "' that has no dependencies! (<runtarget> could be used instead.)",
                        antCallMeta.getLineNumber());
            }
        }
    }
}
