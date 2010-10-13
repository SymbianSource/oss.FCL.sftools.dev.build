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
 * <code>CheckRunTarget</code> is used to check whether runtarget calls a target
 * that has dependencies.
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
 *       &lt;checkRunTarget severity=&quot;error&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="checkRunTarget" category="AntLint"
 * 
 */
public class CheckRunTarget extends AbstractTargetCheck {

    /**
     * {@inheritDoc}
     */
    protected void run(TargetMeta targetMeta) {
        List<TaskMeta> runTargets = targetMeta.getTasks("runtarget");
        for (TaskMeta runTargetMeta : runTargets) {
            if (checkTargetDependency(runTargetMeta.getAttr("target"))) {
                report("<runtarget> calls the target " + runTargetMeta.getAttr("target")
                        + " that has dependencies!", runTargetMeta.getLineNumber());
            }
        }
    }
}
