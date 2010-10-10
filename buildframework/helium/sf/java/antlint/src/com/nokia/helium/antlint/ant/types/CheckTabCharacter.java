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

import com.nokia.helium.ant.data.MacroMeta;
import com.nokia.helium.ant.data.ProjectMeta;
import com.nokia.helium.ant.data.RootAntObjectMeta;
import com.nokia.helium.ant.data.TargetMeta;
import com.nokia.helium.antlint.ant.AntlintException;

/**
 * <code>CheckTabCharacter</code> is used to check the tab characters inside the
 * ant files.
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
 *       &lt;checkTabCharacter&quot; severity=&quot;error&quot; enabled=&quot;true&quot; /&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="checkTabCharacter" category="AntLint"
 * 
 */
public class CheckTabCharacter extends AbstractAntFileStyleCheck {

    private static final String TAB_CHAR = "\t";

    /**
     * {@inheritDoc}
     */
    public void run() throws AntlintException {
        super.run();
        RootAntObjectMeta rootObjectMeta = getAntFile().getRootObjectMeta();
        run(rootObjectMeta);
    }

    /**
     * Method runs the check against the given {@link RootAntObjectMeta}.
     * 
     * @param root is the {@link RootAntObjectMeta} against which the check is
     *            run.
     */
    private void run(RootAntObjectMeta root) {
        if (root instanceof ProjectMeta) {
            ProjectMeta projectMeta = (ProjectMeta) root;
            List<TargetMeta> targets = projectMeta.getTargets();
            for (TargetMeta targetMeta : targets) {
                run(targetMeta);
            }
        }
    }

    /**
     * {@inheritDoc}
     */
    protected void handleStartDocument() {
        // Do nothing
    }

    /**
     * {@inheritDoc}
     */
    protected void handleEndDocument() {
        // Do nothing
    }

    /**
     * {@inheritDoc}
     */
    protected void handleEndElement(String text) {
        checkTabChars(text, getLocator().getLineNumber());
    }

    /**
     * {@inheritDoc}
     */
    protected void handleStartElement(String text) {
        checkTabChars(text, getLocator().getLineNumber());
    }

    private void checkTabChars(String text, int lineNum) {
        if (text.contains(TAB_CHAR)) {
            report("Tabs should not be used!", lineNum);
        }
        clearBuffer();
    }

    /**
     * Method to run the check against the input {@link TargetMeta}.
     * 
     * @param targetMeta is the {@link TargetMeta} against whom the check is
     *            run.
     */
    private void run(TargetMeta targetMeta) {
        List<MacroMeta> macros = targetMeta.getScriptDefinitions("//target[@name='"
                + targetMeta.getName() + "']/descendant::script | //target[@name='"
                + targetMeta.getName() + "']/descendant::*[name()=\"hlm:python\"]");
        if (macros != null) {
            for (MacroMeta macroMeta : macros) {
                if (macroMeta.getText().contains(TAB_CHAR)) {
                    report("Target " + targetMeta.getName() + " has a script with tabs",
                            macroMeta.getLineNumber());
                }
            }
        }
    }
}
