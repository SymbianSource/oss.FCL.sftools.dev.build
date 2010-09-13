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
import java.util.ArrayList;
import java.util.List;

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
public class CMTToolTask extends Task {

    private List<FileSet> cmtFileSetList = new ArrayList<FileSet>();
    private File input;
    private File output;
    private File htmlOutputDir;
    private boolean failOnError = true;

    /**
     * Set the fileset.
     * 
     * @param fileSet
     *            is the fileset which points to the location of source files to
     *            be measured.
     * @ant.required
     */
    public void addFileset(FileSet fileSet) {
        cmtFileSetList.add(fileSet);
    }

    /**
     * Set the name and location of the output file to contain the result of CMT
     * tool.
     * 
     * @param output
     *            is the name of the result file to be generated.
     * @ant.required
     */
    public void setOutput(File output) {
        this.output = output;
    }

    /**
     * @param failOnError the failOnError to set
     */
    public void setFailOnError(boolean failOnError) {
        this.failOnError = failOnError;
    }

    /**
     * @param htmlOutputDir the htmlOutputDir to set
     */
    public void setHtmlOutputDir(File htmlOutputDir) {
        this.htmlOutputDir = htmlOutputDir;
    }

    /**
     * Run the CMT task.
     */
    public void execute() {
        if (!Os.isFamily(Os.FAMILY_WINDOWS)) {
            throw new BuildException("CMT supported only on windows platforms.");
        }
        validate();
        try {
            input = File.createTempFile("Files", ".list");
            generateFileList();
            runCmtCommand();
            if (this.htmlOutputDir != null) {
                runCmt2HtmlCommand();
            }
        } catch (IOException ioe) {
            throw new BuildException("Not able to generate file list for 'cmt'. ", ioe);
        } catch (BuildException be) {
            if (failOnError) {
                throw new BuildException("Exception occured while running 'cmt' tool. ", be);
            }
            log("Exception occured while running 'cmt' tool. ", Project.MSG_ERR);
        } finally {
            if (input != null) {
                input.delete();
            }
        }
    }
    
    /**
     * Execute the cmt.exe command.
     */
    private void runCmtCommand() {
        String command = null;
        if (!this.output.getParentFile().exists()) {
            this.output.getParentFile().mkdirs();
        }
        ExecTask task = getExecTask("cmttool", "cmt", new File("."));
        command = "cmt";
        task.createArg().setValue("-f");
        command += " " + "-f";
        task.createArg().setValue(input.toString());
        command += " " + input.toString();
        task.createArg().setValue("-o");
        command += " " + "-o";
        task.createArg().setValue(output.toString());
        command += " " + output;
        task.setProject(getProject());
        log("run command: " + command);
        task.execute();
    }

    /**
     * Execute the cmt2html.bat command.
     */
    private void runCmt2HtmlCommand() {
        String command = null;
        if (!this.htmlOutputDir.exists()) {
            this.htmlOutputDir.mkdirs();
        }
        ExecTask task = getExecTask("cmt2html", "cmt2html.bat", this.htmlOutputDir);
        command = "cmt2html.bat"; 
        task.createArg().setValue("-i");
        command += " " + "-i";
        task.createArg().setValue(output.toString());
        command += " " + output;
        task.createArg().setValue("-nsb");
        command += " " + "-nsb";
        task.setProject(getProject());
        log("run command: " + command);
        task.execute();
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
        task.bindToOwner(this);
        task.setDir(outDir);
        task.setExecutable(cmd);
        return task;
    }

    /**
     * Method validates the required parameters and elements are set.
     */
    private void validate() {
        if (cmtFileSetList.size() == 0) {
            throw new BuildException("Nested Element 'fileset' missing for task 'cmt'.");
        }
        if (output == null) {
            throw new BuildException("Parameter 'output' missing for task 'cmt'.");
        }
    }

    /**
     * Generates a file containing a list of files.
     */
    private void generateFileList() {
        
        for (FileSet fileSet : cmtFileSetList) {
            DirectoryScanner dirScanner = fileSet.getDirectoryScanner();
            dirScanner.scan();
            String[] filelist = dirScanner.getIncludedFiles();
            String lineSeparator = System.getProperty("line.separator");
            String fileSeparator = System.getProperty("file.separator");
            
            BufferedWriter outputFile = null;
            try {
                outputFile = new BufferedWriter(new FileWriter(input));
                for (String file : filelist) {
                    outputFile.write(dirScanner.getBasedir().toString() + fileSeparator + file
                            + lineSeparator);
                }
            } catch (IOException e) {
                throw new BuildException("Not able to generate file list for 'cmt'. ", e);
            } finally {
                try {
                    if (outputFile != null) {
                        outputFile.close();
                    }
                } catch (IOException ex) {
                    // ignore exception
                    ex = null;
                }
            }
        }
    }
}
