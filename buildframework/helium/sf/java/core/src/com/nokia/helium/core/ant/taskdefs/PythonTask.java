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

package com.nokia.helium.core.ant.taskdefs;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.taskdefs.ExecTask;
import org.apache.tools.ant.types.Commandline;

/**
 * Embed python code in ant, generates temporary python file and executes it.
 * 
 * <pre>
 * Usage: &lt;hlm:python&gt;
 *                .
 *                .  
 *                .
 *        &lt;/hlm:python&gt;
 * </pre>
 * 
 * @ant.task name="python" category="Core"
 */
public class PythonTask extends Task {
    private String iText;
    private String outputProperty;
    private String resultProperty;
    private File script;

    private File dir;
    private File output;

    private boolean iFailonerror;

    /**
     * Sets the property name whose value should be set to the output of the
     * process.
     * 
     * @param propertyname
     *            name of property.
     * @ant.not-required
     */
    public void setOutputProperty(String propertyname) {
        outputProperty = propertyname;
    }

    /**
     * Sets the name of a property in which the return code of the command
     * should be stored. Only of interest if failonerror=false.
     * 
     * @param propertyname
     *            name of property.
     * @ant.not-required .
     */
    public void setResultProperty(String propertyname) {
        resultProperty = propertyname;
    }

    /**
     * Add python statements to execute.
     * 
     * @param text
     *            is the python statement to execute
     * @ant.required If no script.
     */
    public void addText(String text) {
        iText = getProject().replaceProperties(text);
    }

    /**
     * Set the name of the python script to execute.
     * 
     * @param scriptname
     *            name of the script to set.
     * @ant.required If no text.
     */
    public void setScript(File scriptname) {
        script = scriptname;
    }

    /**
     * Fail if the command exits with a non-zero return code.
     * 
     * @param failonerror
     *            if true fail the command on non-zero return code.
     * @ant.not-required Default is no.
     */
    public void setFailonerror(boolean failonerror) {
        iFailonerror = failonerror;
    }

    /**
     * File the output of the process is redirected to. If error is not
     * redirected, it too will appear in the output.
     * 
     * @param outputname
     *            name of a file to which output should be sent.
     * @ant.not-required
     */
    public void setOutput(File outputname) {
        output = outputname;
    }

    /**
     * Set the working directory of the process.
     * 
     * @param dirname
     *            the working directory of the process.
     * @ant.not-required
     */
    public void setDir(File dirname) {
        dir = dirname;
    }


    /**
     * Method executes current task.
     */
    public void execute() {
        if (script != null) {
            if (!script.exists()) {
                throw new BuildException("Could not find " + script);
            }
            // Run the Python script
            ExecTask execTask = new ExecTask();
            execTask.setProject(getProject());
            execTask.setTaskName(getTaskName());
            execTask.setExecutable("python");
            execTask.setFailonerror(true);
            execTask.createArg().setFile(script);
            execTask.setOutputproperty(outputProperty);
            execTask.setResultProperty(resultProperty);
            execTask.setDir(dir);
            execTask.setOutput(output);
            try {
                execTask.execute();
            } catch (BuildException t) {
                if (iFailonerror)
                    throw new BuildException(t.getMessage());
                else
                    log(t.getMessage(), 0); // MSG_ERR=0
            }
        } else if (iText != null) {
            // Write the content of the script using Echo task
            File tempfile = null;
            try {
                // Create a temporary file to contain the script
                tempfile = File.createTempFile("helium", null);
                PrintWriter out = new PrintWriter(new FileWriter(tempfile));
                out.write(iText);
                out.close();

                // Run the temporary Python script
                ExecTask execTask = new ExecTask();
                execTask.setProject(getProject());
                execTask.setTaskName(getTaskName());
                execTask.setExecutable("python");
                execTask.setFailonerror(iFailonerror);
                Commandline.Argument scriptArg = execTask.createArg();
                scriptArg.setValue(tempfile.getAbsolutePath());
                execTask.setOutputproperty(outputProperty);
                execTask.setResultProperty(resultProperty);
                execTask.setDir(dir);
                execTask.setOutput(output);
                execTask.execute();

                // Delete temporary script file
                boolean fileDeleted = tempfile.delete();
                if (!fileDeleted && iFailonerror) {
                    throw new BuildException("Could not delete script file!");
                }
            } catch (IOException e) {
                if (iFailonerror) {
                    throw new BuildException(e.getMessage());
                }
                log("Error while running python task " + e.getMessage());
            } finally {
                // make sure we delete the file anyway
                if (tempfile != null)
                    tempfile.delete();
            }
        }
    }

}