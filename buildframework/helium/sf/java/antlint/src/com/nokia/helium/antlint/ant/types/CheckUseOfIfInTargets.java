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
 * <code>CheckUseOfIfInTargets</code> is used to check the usage of if task as
 * against the condition task or &lt;target if|unless="property.name"&gt; inside
 * targets.
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
 *       &lt;checkUseOfIfInTargets&quot; severity=&quot;error&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="checkUseOfIfInTargets" category="AntLint"
 * 
 */
public class CheckUseOfIfInTargets extends AbstractTargetCheck {

    /**
     * {@inheritDoc}
     */
    protected void run(TargetMeta targetMeta) {
        String target = targetMeta.getName();
        List<TaskMeta> conditions = targetMeta.getTasks("if");
        for (TaskMeta taskMeta : conditions) {
            List<TaskMeta> ifThenPropertyConditions = taskMeta.getTasks("./then/property");
            List<TaskMeta> ifElsePropertyConditions = taskMeta.getTasks("./else/property");
            if (ifThenPropertyConditions.size() == 1 && ifElsePropertyConditions.size() == 1) {
                report("Target " + target
                        + " poor use of if-else-property statement, use condition task",
                        taskMeta.getLineNumber());
            }
            List<TaskMeta> elseConditions = taskMeta.getTasks("./else");

            if (ifThenPropertyConditions.size() == 1 && elseConditions.size() == 0) {
                report("Target " + target
                        + " poor use of if-then-property statement, use condition task",
                        taskMeta.getLineNumber());
            }
        }

        List<TaskMeta> conditions2 = targetMeta.getTaskDefinitions("//target[@name='" + target
                + "']/*");
        if (conditions2.size() == 1) {
            List<TaskMeta> ifElseConditions = targetMeta.getTasks("./if/else");
            List<TaskMeta> isSetConds = targetMeta.getTasks("./if/isset");
            List<TaskMeta> notConds = targetMeta.getTaskDefinitions("./if/not/isset");
            if (ifElseConditions.isEmpty() && (!isSetConds.isEmpty() || !notConds.isEmpty())) {
                report("Target " + target
                        + " poor use of if statement, use <target if|unless=\"prop\"",
                        targetMeta.getLineNumber());
            }
        }
    }
}