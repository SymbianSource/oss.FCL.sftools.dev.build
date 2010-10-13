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

import com.nokia.helium.ant.data.RootAntObjectMeta;
import com.nokia.helium.ant.data.TaskMeta;

/**
 * <code>CheckUseOfEqualsTask</code> is used to check the usage of equals task
 * as against istrue task.
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
 *       &lt;checkUseOfEqualsTask&quot; severity=&quot;error&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="checkUseOfEqualsTask" category="AntLint"
 */
public class CheckUseOfEqualsTask extends AbstractProjectCheck {

    /**
     * {@inheritDoc}
     */
    protected void run(RootAntObjectMeta root) {
        List<TaskMeta> conditions = root.getTaskDefinitions("//equals");
        for (TaskMeta taskMeta : conditions) {
            String text = taskMeta.getAttr("arg2");
            if (text.equals("true") || text.equals("yes")) {
                report(taskMeta.getAttr("arg1") + " uses 'equals', should use 'istrue' task",
                        taskMeta.getLineNumber());
            }
        }
    }
}
