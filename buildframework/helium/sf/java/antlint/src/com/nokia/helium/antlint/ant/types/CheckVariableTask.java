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
 * <code>CheckVariableTask</code> is used to check whether the value attribute
 * of the ant-contrib variable task is set when attribute unset is set to true.
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
 *       &lt;checkVariableTask severity=&quot;error&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="checkVariableTask" category="AntLint"
 */
public class CheckVariableTask extends AbstractProjectCheck {

    /**
     * {@inheritDoc}
     */
    protected void run(RootAntObjectMeta root) {
        List<TaskMeta> tasks = root.getTaskDefinitions("//var");
        String name, value, unset = null;
        for (TaskMeta taskMeta : tasks) {
            name = taskMeta.getAttr("name");
            value = taskMeta.getAttr("value");
            unset = taskMeta.getAttr("unset");
            if (!value.trim().isEmpty() && unset.equals("true")) {
                report("Variable '" + name + "' should not have 'value' attribute set "
                        + "when 'unset' is true.", taskMeta.getLineNumber());
            }
        }
    }
}
