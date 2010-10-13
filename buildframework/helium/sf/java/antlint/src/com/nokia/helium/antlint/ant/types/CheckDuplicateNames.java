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

import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;

import org.apache.tools.ant.taskdefs.MacroInstance;
import org.apache.tools.ant.taskdefs.optional.script.ScriptDefBase;

import com.nokia.helium.ant.data.MacroMeta;
import com.nokia.helium.ant.data.RootAntObjectMeta;

/**
 * <code>CheckDuplicateNames</code> is used to check for duplicate macro and
 * task names.
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
 *       &lt;checkDuplicateNames severity=&quot;error&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="checkDuplicateNames" category="AntLint"
 */
public class CheckDuplicateNames extends AbstractProjectCheck {

    private static final String HELIUM_URI = "http://www.nokia.com/helium";

    private List<String> heliumTaskList;

    /**
     * {@inheritDoc}
     */
    protected void run(RootAntObjectMeta root) {
        if (heliumTaskList == null) {
            setHeliumTaskList(root);
        }
        List<MacroMeta> macros = root.getMacros();
        if (heliumTaskList != null ) {
            for (MacroMeta macroMeta : macros) {
                if (heliumTaskList.contains(macroMeta.getName())) {
                    report("Task '" + macroMeta.getName() + "' and macro '" + macroMeta.getName()
                            + "' has duplicate name.", macroMeta.getLineNumber());
                }
            }
        }
    }

    /**
     * Method sets a list of helium tasks.
     * 
     * @param root is the {@link RootAntObjectMeta} used to lookup for tasks.
     */
    @SuppressWarnings({ "unchecked", "rawtypes" })
    private void setHeliumTaskList(RootAntObjectMeta root) {
        heliumTaskList = new ArrayList<String>();
        Hashtable<String, Class<Object>> taskdefs = root.getRuntimeProject().getTaskDefinitions();
        List<String> list = new ArrayList<String>(taskdefs.keySet());
        for (String taskName : list) {
            Class clazz = taskdefs.get(taskName);
            int index = taskName.lastIndexOf(":");
            if (taskName.startsWith(HELIUM_URI)
                    && !(clazz.equals(MacroInstance.class) || clazz.equals(ScriptDefBase.class))) {
                heliumTaskList.add(taskName.substring(index + 1));
            }
        }
    }
}
