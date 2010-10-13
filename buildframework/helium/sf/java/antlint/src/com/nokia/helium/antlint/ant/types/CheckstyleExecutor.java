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

import java.io.File;

import org.apache.tools.ant.types.FileSet;

import com.puppycrawl.tools.checkstyle.CheckStyleTask;
import com.puppycrawl.tools.checkstyle.CheckStyleTask.Formatter;

/**
 * <code>CheckstyleExecutor</code> extends {@link Executor} and is used to check
 * the coding conventions of beanshell script.
 */
public class CheckstyleExecutor extends Executor {

    private CheckStyleTask checkStyleTask;
    private ScriptDump scriptDump;
    
    /**
     * Default constructor
     */
    public CheckstyleExecutor() {
        scriptDump = new BeanshellScriptDump();
        checkStyleTask = new CheckStyleTask();
    }

    /**
     * Set the checkstyle configuration file.
     * 
     * @param config is the checkstyle configuration file.
     */
    public void setConfig(File config) {
        checkStyleTask.setConfig(config);
    }

    /**
     * Add the checkstyle formatter.
     * 
     * @param aFormatter the checkstyle formatter to add.
     */
    public void addFormatter(Formatter aFormatter) {
        checkStyleTask.addFormatter(aFormatter);
    }

    protected ScriptDump getScriptDump() {
        return scriptDump;
    }
    
    /**
     * {@inheritDoc}
     */
    public void execute() {

        FileSet fileset = new FileSet();
        fileset.setDir(getOutputDir());
        fileset.setIncludes("**/*.java");

        checkStyleTask.setTaskName(getClass().getSimpleName());
        checkStyleTask.addFileset(fileset);
        checkStyleTask.setProject(getProject());
        checkStyleTask.execute();
    }

}
