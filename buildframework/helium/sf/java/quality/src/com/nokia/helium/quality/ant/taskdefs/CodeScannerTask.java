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
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.taskdefs.ExecTask;
import org.apache.tools.ant.types.Path;

/**
 * This task executes codescanner - and writes the results to the output directory. Codescanner
 * parses C++ code and flags any inconsistencies or errors in output files. Configuration files are
 * used to determine what passes and fails the checking e.g. maximum length of lines, whether 'C'
 * type comments are allowed as well as C++ comments, does it adhere to the company coding
 * guidelines and much more. Every person writing any C++ code should run codescanner on their code
 * to ensure it follows the coding guidelines. The output logs should have no errors and preferably
 * no warnings before the code should be checked into SCM, e.g. synergy or SVN.
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
public class CodeScannerTask extends Task {
    private Vector<Path> paths = new Vector<Path>();
    private File configuration;
    private File dest;
    private String format = "xml,html";
    private boolean auto;
    private File log;
    private boolean failonerror = true;
    private String lxrURL;
    private File sourceDir;

    /**
     * This defines if the task should fails in case of error while executing codescanner.
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
    public File getDest() {
        return this.dest;
    }

    /**
     * Set dest attribute.
     * 
     * @param dest
     * @ant.required
     */
    public void setDest(File dest) {
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
     * Set lxr URL to update the codescanner html output files.
     * @param lxrURL the lxrURL to set
     */
    public void setLxrURL(String lxrURL) {
        this.lxrURL = lxrURL;
    }

    /**
     * Set the source folder path in case lxr URL property is set. 
     * @param sourceDir the sourceDir to set
     */
    public void setSourceDir(File sourceDir) {
        this.sourceDir = sourceDir;
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void execute() {
        // creating the exec subtask
        ExecTask task = new ExecTask();
        task.bindToOwner(this);
        task.setFailonerror(failonerror);
        task.setExecutable("codescanner");
        task.setDir(new File("."));
        String commandString = "codescanner";
        if (dest == null) {
            throw new BuildException("'dest' attribute must be defined");
        }
        if (configuration != null) {
            if (!configuration.exists()) {
                throw new BuildException("Could not find the file " + configuration);
            }
            else {
                task.createArg().setValue("-c");
                task.createArg().setValue(configuration.getAbsolutePath());
                commandString += " -c " + configuration.getAbsolutePath();
            }
        }
        else {
            throw new BuildException("'configuration' attribute must be defined");
        }
        if (!format.contains("xml")) {
            setFormat("xml," + format);
        }
        this.log("Output format: " + format);
        // -t off
        task.createArg().setValue("-t");
        task.createArg().setValue(auto ? "on" : "off");
        commandString += " -t " + (auto ? "on" : "off");
        // -l log
        if (log != null) {
            this.log("Output log: " + log.getAbsolutePath());
            task.createArg().setValue("-l");
            task.createArg().setValue(log.getAbsolutePath());
        }

        // -o type
        task.createArg().setValue("-o");
        task.createArg().setValue(format);
        commandString += " -o " + format;
            
        if (this.lxrURL != null ) {
            if (this.sourceDir == null) {
                throw new BuildException("'sourceDir' attribute must be defined");
            }
            if (!paths.isEmpty() ) {
                throw new BuildException("Nested path element are not allowed when lxrURL attribute is in use.");
            }
            task.createArg().setValue("-x");
            task.createArg().setValue(this.lxrURL);
            commandString += " -x " + this.lxrURL;
            task.createArg().setValue(sourceDir.getAbsolutePath());
            commandString += " " + sourceDir.getAbsolutePath();
        } else {
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
                    commandString += " -i " + srcs.elementAt(i);
                }
                else {
                    task.createArg().setValue(srcs.elementAt(i));
                    commandString += " " + srcs.elementAt(i);
                }
            }
        }
        
        // output path
        task.createArg().setValue(dest.getAbsolutePath());
        commandString += " " + dest.getAbsolutePath();
        this.log("Output dir " + dest.getAbsolutePath());

        // Run codescanner
        try {
            log("Running codescanner with arguments '" + commandString + "'");
            task.execute();
        } catch (BuildException be) {
            if (this.failonerror) {
                throw new BuildException("Errors occured while running 'codescanner'", be);
            } else {
                log("Errors occured while running 'codescanner' " + be.getMessage(), Project.MSG_ERR);
            }
        }
        
        
        this.log("Successfully executed codescanner");
    }
}
