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

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.taskdefs.ExecTask;
import org.apache.tools.ant.taskdefs.PathConvert;
import org.apache.tools.ant.types.Commandline;
import org.apache.tools.ant.types.Environment;
import org.apache.tools.ant.types.FileSet;

/**
 * <code>PylintExecutor</code> extends {@link Executor} and is used to check the
 * lint issues of jython/python scripts.
 */
public class PylintExecutor extends Executor {

    private ScriptDump scriptDump;
    private ExecTask execTask;

    public PylintExecutor() {
        execTask = new ExecTask();
        scriptDump = new PythonScriptDump();
    }

    /**
     * Add an environment variable to the launched process.
     * 
     * @param var new environment variable.
     */
    public void addEnv(Environment.Variable var) {
        execTask.addEnv(var);
    }

    /**
     * Adds a command-line argument.
     * 
     * @return new command line argument created.
     */
    public Commandline.Argument createArg() {
        return execTask.createArg();
    }

    @Override
    protected ScriptDump getScriptDump() {
        return scriptDump;
    }

    /**
     * {@inheritDoc}
     */
    public void execute() {
        FileSet fileset = new FileSet();
        fileset.setDir(getOutputDir());
        fileset.setIncludes("**/*.py");
        fileset.setProject(getProject());

        PathConvert pathConvert = new PathConvert();
        pathConvert.add(fileset);
        pathConvert.setPathSep(" ");
        pathConvert.setProperty("python.modules");
        pathConvert.setProject(getProject());
        pathConvert.execute();

        execTask.createArg().setLine(getProject().getProperty("python.modules"));
        execTask.setExecutable("python");
        execTask.setTaskName(getClass().getSimpleName());
        execTask.setProject(getProject());
        execTask.setResultProperty("pylint.result");
        execTask.execute();

        int result = getResult();
        if ((result & 2) == 2) {
            throw new BuildException("Error: Pylint contains errors.");
        }
    }

    private int getResult() {
        String resultString = getProject().getProperty("pylint.result");
        int result = -1;
        try {
            result = Integer.parseInt(resultString);
        } catch (NumberFormatException e) {
            log(e.getMessage(), Project.MSG_WARN);
        }
        return result;
    }
}
