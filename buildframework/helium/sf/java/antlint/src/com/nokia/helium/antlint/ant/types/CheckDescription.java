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

import com.nokia.helium.ant.data.ProjectMeta;
import com.nokia.helium.ant.data.RootAntObjectMeta;

/**
 * <code>CheckDescription</code> is used to check whether project description is
 * present or not.
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
 *       &lt;checkDescription severity=&quot;error&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="checkDescription" category="AntLint"
 */
public class CheckDescription extends AbstractProjectCheck {

    /**
     * {@inheritDoc}
     */
    protected void run(RootAntObjectMeta root) {
        if (root instanceof ProjectMeta && ((ProjectMeta) root).getDescription().isEmpty()) {
            report("Description not specified!", root.getLineNumber());
        }
    }
}
