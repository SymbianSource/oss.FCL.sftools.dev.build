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

import java.io.*;
import java.util.Vector;

import org.apache.tools.ant.Task;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.types.Path;
import org.apache.tools.ant.taskdefs.ExecTask;

/**
 * This task executes codescanner - and writes the results to the output directory.
 * Codescanner parses C++ code and flags any inconsistencies or errors in output files. 
 * Configuration files are used to determine what passes and fails the checking e.g. maximum length of lines,
 * whether 'C' type comments are allowed as well as C++ comments, does it adhere to the company coding 
 * guidelines and much more. Every person writing any C++ code 
 * should run codescanner on their code to ensure it follows the coding guidelines. The output logs 
 * should have no errors and preferably no warnings before the code should be checked into SCM, e.g. synergy or SVN.
 *
 * Below is an example of how to use the target to run codescanner.
 *
 * <pre>
 * &lt;property name="codescanner.output.dir" location="./cs" /&gt;
 * &lt;property name="codescanner.output.type" value="html" /&gt;
 * &lt;property name="codescanner.config" location="./codescanner_config.xml" /&gt;
 *
 * &lt;hlm:codescanner dest="${codescanner.output.dir}"
 *      format="${codescanner.output.type}"
 *      failonerror="true"
 *      configuration="${codescanner.config}"&gt;
 *      &lt;path refid="src.path"/&gt;
 *  &lt;/hlm:codescanner&gt;
 *  &lt;au:assertLogContains text="Successfully executed codescanner"/&gt;
 *  &lt;au:assertLogContains text="Output format: xml,html"/&gt;
 *  &lt;au:assertFileExists file="${codescanner.output.dir}/problemIndex.xml"/&gt;
 * </pre>
 * 
 * @ant.task name="codescanner" category="Quality"
 */
public class CodeScanner extends Task {
    private Vector<Path> paths = new Vector<Path>();
    private File configuration;
    private String dest;
    private String format = "xml,html";
    private boolean auto;
    private File log;
    private boolean failonerror;

    /**
     * This defines if the task should fails in case of error while 
     * executing codescanner.
     * 
     * @param failonerror
     * @ant.not-required Default is false for backward compatibility.
     */
    public void setFailonerror(boolean failonerror) {
        this.failonerror = failonerror;
    }

    /**
     * Add path datatype to the task.
     * 
     * @param path
     */
    public void add(Path path) {
        paths.add(path);
    }

    /**
     * Get dest attribute.
     * 
     */
    public String getDest() {
        return this.dest;
    }

    /**
     * Set dest attribute.
     * 
     * @param dest
     * @ant.required
     */
    public void setDest(String dest) {
        this.dest = dest;
    }

    /**
     * Get format attribute.
     * 
     */
    public String getFormat() {
        return this.format;
    }

    /**
     * Set format attribute.
     * 
     * @param format
     * @ant.not-required Default is xml,html
     */
    public void setFormat(String format) {
        this.format = format;
    }

    /**
     * Get configuration attribute.
     * 
     */
    public File getConfiguration() {
        return this.configuration;
    }

    /**
     * Set configuration attribute.
     * 
     * @param configuration
     * @ant.required
     */
    public void setConfiguration(File configuration) {
        this.configuration = configuration;
    }

    /**
     * Set auto attribute.
     * 
     * @param auto
     * @ant.not-required Default is false.
     */
    public void setAuto(boolean auto) {
        this.auto = auto;
    }

    /**
     * Set log attribute.
     * 
     * @param log
     * @ant.not-required
     */
    public void setLog(File log) {
        this.log = log;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void execute() {
        // creating the exec subtask
        String osType = System.getProperty("os.name");
        if (!osType.toLowerCase().startsWith("win")) {
            this.log("CODESCANNER: run in windows only");
            return;
        }
        ExecTask task = new ExecTask();
        task.setProject(getProject());
        task.setTaskName(this.getTaskName());
        task.setFailonerror(failonerror);
        task.setExecutable("codescanner");
        task.setDir(new File("."));
        if (dest == null) {
            throw new BuildException("'dest' attribute must be defined");
        }
        if (configuration != null) {
            if (!configuration.exists()) {
                throw new BuildException("Could not find the file "
                        + configuration);
            } else {
                task.createArg().setValue("-c");
                task.createArg().setValue(configuration.getAbsolutePath());
            }
        } else {
            throw new BuildException(
                    "'configuration' attribute must be defined");
        }
        if (!format.contains("xml")) {
           setFormat("xml," + format);
        }
        this.log("Output format: " + format);
        // -t off
        task.createArg().setValue("-t");
        task.createArg().setValue(auto ? "on" : "off");

        // -l log
        if (log != null) {
            this.log("Output log: " + log.getAbsolutePath());
            task.createArg().setValue("-l");
            task.createArg().setValue(log.getAbsolutePath());
        }

        // -o type
        task.createArg().setValue("-o");
        task.createArg().setValue(format);
        if (paths.isEmpty()) {
            throw new BuildException("No input directory defined");
        }
        // Getting the list of source dir to scan
        Vector<String> srcs = new Vector<String>();
        for (Path path : paths) {
            if (path.isReference()) {
                path = (Path) path.getRefid().getReferencedObject();
            }
            for (String apath : path.list()) {
                srcs.add(apath);
            }
        }
        for (int i = 0; i < srcs.size(); i++) {
            if (i != srcs.size() - 1) {
                task.createArg().setValue("-i");
                task.createArg().setValue(srcs.elementAt(i));
            } else {
                task.createArg().setValue(srcs.elementAt(i));
                task.createArg().setValue(dest.toString());
            }
        }
        // output path
        this.log("Output dir " + dest);

        // Run codescanner
        task.execute();
        this.log("Successfully executed codescanner");
    }
}
