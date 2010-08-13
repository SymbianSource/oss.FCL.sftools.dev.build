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
package com.nokia.helium.quality.ant.taskdefs;

import java.io.File;
import java.util.Vector;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.taskdefs.ExecTask;

import com.nokia.helium.core.ant.types.VariableImpl;
import com.nokia.helium.core.ant.types.VariableSet;

/**
 * To run the coverity commands.
 * 
 * 
 * <pre>
 *      &lt;hlm:coverity command=&quot;cov-link&quot; dir=&quot;${build.drive}/&quot;&gt;
 *                     &lt;hlm:arg name=&quot;--dir&quot; value=&quot;${coverity.output.dir}/intermidiate&quot;/&gt;
 *                     &lt;hlm:arg name=&quot;--compile-arg&quot; value=&quot;armv5&quot;/&gt;
 *                     &lt;hlm:arg name=&quot;--output&quot; value=&quot;${coverity.output.dir}/coveritylink/armv5.link&quot;/&gt;
 *                     &lt;hlm:arg name=&quot;${coverity.output.dir}/coveritylink/all.link&quot; value=&quot;&quot;/&gt;
 *                 &lt;/hlm:coverity &gt;
 * 
 * </pre>
 * 
 * @ant.task name="coverity" category="Quality".
 * 
 */

public class CoverityTask extends Task {

    private String command;
    private boolean failOnError;
    private boolean execute = true;
    private boolean append;
    private File error;
    private String dir;
    private Vector<VariableSet> coverityOptions = new Vector<VariableSet>();
    private Vector<VariableImpl> coverityArgs = new Vector<VariableImpl>();

    public void execute() {

        validateParameters();

        runCommand(command);

    }

    /**
     * To run the command passed into coverity task.
     * 
     * @param command
     */
    private void runCommand(String command) {

        String commandString = command;
        if (!command.startsWith("cov-")) {
            throw new BuildException(
                    "Coverity task can run only coverity prevent tool commands.");
        }

        ExecTask task = new ExecTask();
        task.setProject(getProject());
        task.setTaskName(this.getTaskName());
        task.setFailonerror(failOnError);
        task.setError(this.error);
        task.setAppend(isAppend());
        task.setExecutable(command);
        task.setDir(new File(this.dir));

        for (VariableSet coverityArg : coverityOptions) {
            task.createArg().setLine(coverityArg.getParameter(" "));
            commandString += " " + coverityArg.getParameter(" ");
        }
        for (VariableImpl coverityArg : coverityArgs) {
            task.createArg().setLine(coverityArg.getParameter(" "));
            commandString += " " + coverityArg.getParameter(" ");
        }

        try {
            log("run command: " + commandString);
            if (execute) {
                task.execute();
            }
        } catch (BuildException be) {
            if (failOnError) {
                throw new BuildException("exception during coverity command '"
                        + command + "' execution:", be);
            }
        }

    }

    /**
     * To validate the parameters passed into coverity task.
     */
    private void validateParameters() {
        if (command == null) {
            throw new BuildException(
                    "'command' parameter should not be null for coverity task.");
        }

    }

    /**
     * @param command
     *            the command to set
     * @ant.required
     */
    public void setCommand(String command) {
        this.command = command;
    }

    /**
     * @return the command
     */
    public String getCommand() {
        return command;
    }

    /**
     * @param failOnError
     *            the failOnError to set
     * @ant.not-required
     */
    public void setFailOnError(boolean failOnError) {
        this.failOnError = failOnError;
    }

    /**
     * @return the dir
     */
    public String getDir() {
        return dir;
    }

    /**
     * @param dir
     *            the dir to set
     * @ant.not-required
     */
    public void setDir(String dir) {
        this.dir = dir;
    }

    /**
     * @param execute
     *            the execute to set
     */
    public void setExecute(boolean execute) {
        this.execute = execute;
    }

    /**
     * @return the errorFile
     */
    public File getError() {
        return error;
    }

    /**
     * @param errorFile the errorFile to set
     */
    public void setError(File errorFile) {
        this.error = errorFile;
    }

    /**
     * @param append the append to set
     */
    public void setAppend(boolean append) {
        this.append = append;
    }

    /**
     * @return the append
     */
    public boolean isAppend() {
        return append;
    }

    /**
     * To read the coverity arguments for coverity commands.
     * 
     * @param variableArg
     */
    public void addCoverityOptions(VariableSet coverityArg) {
        if (!coverityOptions.contains(coverityArg)) {
            coverityOptions.add(coverityArg);
        }
    }

    /**
     * To read the individual arguments.
     * 
     * @param coverityArg
     */
    public void addArg(VariableImpl coverityArg) {
        if (!coverityArgs.contains(coverityArg)) {
            coverityArgs.add(coverityArg);
        }
    }
    

}
