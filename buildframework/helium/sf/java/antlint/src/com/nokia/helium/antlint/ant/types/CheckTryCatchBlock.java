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
 * <code>CheckTryCatchBlock</code> is used to check for empty and more than one
 * catch elements in a given try-catch block.
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
 *       &lt;checkTryCatchBlock&quot; severity=&quot;error&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="checkTryCatchBlock" category="AntLint"
 * 
 */
public class CheckTryCatchBlock extends AbstractTargetCheck {

    /**
     * {@inheritDoc}
     */
    protected void run(TargetMeta targetMeta) {
        List<TaskMeta> trycatches = targetMeta.getTasks("trycatch");
        List<TaskMeta> catches = targetMeta.getTasks("trycatch//catch");

        if (!trycatches.isEmpty() && catches.isEmpty()) {
            report("<trycatch> block found without <catch> element", targetMeta.getLineNumber());
        }
        if (!trycatches.isEmpty() && catches.size() > 1) {
            report("<trycatch> block found with " + catches.size() + " <catch> elements.",
                    targetMeta.getLineNumber());
        }
    }
}
