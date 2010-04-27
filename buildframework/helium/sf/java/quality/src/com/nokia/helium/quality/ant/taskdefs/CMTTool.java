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

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.DirectoryScanner;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.taskdefs.ExecTask;
import org.apache.tools.ant.taskdefs.condition.Os;
import org.apache.tools.ant.types.FileSet;

/**
 * CMTTool is the task used to execute the Complexity Measures Tool for C/C++.
 * 
 * <pre>
 * Usage:
 * 
 * &lt;hlm:cmt output=&quot;${cmt.output.dir}\logs\${build.id}_${ido.name}_${componentbase}_${cmt.id}.txt&gt;
 *     &lt;fileset id=&quot;input&quot; dir=&quot;${test.data.src}&quot;&gt;
 *         &lt;include name=&quot;*&#42;/*.h&quot;/&gt;
 *         &lt;include name=&quot;*&#42;/*.cpp&quot;/&gt;
 *     &lt;/fileset&gt;
 * &lt;/hlm:cmt&gt;
 * 
 * output : Name of the file to contain the results of Complexity Measures Tool.
 * fileset: Location of the source files whose complexity is to be measured.
 * </pre>
 * 
 * @ant.task name="cmt" category="Quality".
 */
public class CMTTool extends Task {

    private FileSet fileSet;
    private String input;
    private String output;

    /**
     * Set the fileset.
     * 
     * @param fileSet
     *            is the fileset which points to the location of source files to
     *            be measured.
     * @ant.required
     */
    public void addFileset(FileSet fileSet) {
        this.fileSet = fileSet;
    }

    /**
     * Set the name and location of the output file to contain the result of CMT
     * tool.
     * 
     * @param output
     *            is the name of the result file to be generated.
     * @ant.required
     */
    public void setOutput(String output) {
        this.output = output;
    }

    /**
     * Run the CMT task.
     */
    public void execute() {
        if (!Os.isFamily(Os.FAMILY_WINDOWS)) {
            getProject()
                    .log("CMT supported only for windows", Project.MSG_WARN);
            return;
        }
        validate();
        input = fileSet.getDir().getPath();
        generateFileList();
        runCmtCommand();
        runCmt2HtmlCommand();
    }

    /**
     * Execute the cmt.exe command.
     */
    private void runCmtCommand() {
        try {
            ExecTask task = getExecTask("cmttool", "cmt.exe", new File("."));
            task.createArg().setValue("-f");
            task.createArg().setValue(
                    input + System.getProperty("file.separator") + "files.lst");
            task.createArg().setValue("-o");
            task.createArg().setValue(output);
            task.setResultProperty("cmt.status");
            task.setProject(getProject());
            task.execute();
            int status = new Integer(getProject().getProperty("cmt.status"));
            getProject().log("CMT run successfully? " + (status == 0));
        } catch (BuildException ex) {
            // We are Ignoring the errors as no need to fail the build.
            getProject().log(ex.getMessage(), Project.MSG_WARN);
        }
    }

    /**
     * Execute the cmt2html.bat command.
     */
    private void runCmt2HtmlCommand() {
        try {
            File outputdir = new File(output.replace(".txt", "_cmt"));
            outputdir.mkdir();
            ExecTask task = getExecTask("cmt2html", "cmt2html.bat", outputdir);
            task.createArg().setValue("-i");
            task.createArg().setValue(output);
            task.createArg().setValue("-nsb");
            task.setResultProperty("cmt2html.status");
            task.setProject(getProject());
            task.execute();
            int status = new Integer(getProject()
                    .getProperty("cmt2html.status"));
            getProject().log("CMT2HTML run successfully? " + (status == 0));
        } catch (BuildException ex) {
            // We are Ignoring the errors as no need to fail the build.
            getProject().log(ex.getMessage(), Project.MSG_WARN);
        }
    }

    /**
     * Return an execute task with the given inputs.
     * 
     * @param taskName
     *            is the name of the execute task.
     * @param cmd
     *            is the command to be executed by the task.
     * @param outDir
     *            is the working directory for the task.
     * @return an instance of execute task.
     */
    private ExecTask getExecTask(String taskName, String cmd, File outDir) {
        ExecTask task = new ExecTask();
        task.setDir(outDir);
        task.setTaskName(taskName);
        task.setExecutable(cmd);
        return task;
    }

    /**
     * Method validates the required parameters and elements are set.
     */
    private void validate() {
        if (fileSet == null) {
            raiseError("Nested Element 'fileset' missing for task 'cmt'.");
        }

        if (output == null || (output != null && output.isEmpty())) {
            raiseError("Parameter 'output' missing for task 'cmt'.");
        }

    }

    /**
     * Method is used to throw a BuildException.
     * 
     * @param message
     *            is the message to be thrown.
     */
    private void raiseError(String message) {
        throw new BuildException(message);
    }

    /**
     * Generates a file containing a list of files.
     */
    private void generateFileList() {
        if (fileSet != null) {
            DirectoryScanner ds = fileSet.getDirectoryScanner();
            ds.scan();
            String[] filelist = ds.getIncludedFiles();
            String fileSeparator = System.getProperty("file.separator");
            String lineSeparator = System.getProperty("line.separator");
            File fileList = new File(input + fileSeparator + "files.lst");
            BufferedWriter outputFile = null;
            try {
                outputFile = new BufferedWriter(new FileWriter(fileList));
                for (String file : filelist) {
                    outputFile.write(input + fileSeparator + file
                            + lineSeparator);
                }
            } catch (IOException e) {
                // We are Ignoring the errors as no need to fail the build.
                getProject().log(e.getMessage(), Project.MSG_WARN);
            } finally {
                try {
                    if (outputFile != null)
                        outputFile.close();
                } catch (IOException ex) {
                    // ignore exception
                    ex = null;
                }
            }
        }
    }
}
