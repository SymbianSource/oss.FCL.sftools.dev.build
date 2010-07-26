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

package com.nokia.helium.antlint.ant.taskdefs;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Vector;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.DirectoryScanner;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.FileSet;
import com.nokia.helium.antlint.ant.AntlintException;
import com.nokia.helium.antlint.ant.Reporter;
import com.nokia.helium.antlint.ant.Severity;
import com.nokia.helium.antlint.ant.types.Check;
import com.nokia.helium.antlint.ant.types.ConsoleReporter;

/**
 * AntLint Task. This task checks for common coding conventions and errors in
 * Ant XML script files.
 * 
 * <p>
 * The current checks include:
 * <ul>
 * <li>CheckAntCall : checks whether antcall is used with no param elements and
 * calls target with no dependencies</li>
 * <li>CheckDescription : checks for project description</li>
 * <li>CheckDuplicateNames : checks for duplicate macros</li>
 * <li>CheckFileName : checks the naming convention of ant xml files</li>
 * <li>CheckIndentation : checks indentation</li>
 * <li>CheckJepJythonScript : checks the coding convention in Jep and Jython
 * scripts</li>
 * <li>CheckPresetDefMacroDefName : checks the naming convention of presetdef
 * and macrodef</li>
 * <li>CheckProjectName : checks the naming convention of project</li>
 * <li>CheckPropertyName : checks the naming convention of properties</li>
 * </li>
 * <li>CheckPythonTasks : checks the coding convention of python tasks</li>
 * <li>CheckRunTarget : checks whether runtarget calls a target that has
 * dependencies</li>
 * <li>CheckScriptCondition : checks the coding convention in script condition</li>
 * <li>CheckScriptDef : checks the coding convention in scriptdef</li>
 * <li>CheckScriptDefNameAttributes - checks the naming convention of scriptdef
 * name attributes</li></li>
 * <li>CheckScriptDefStyle : checks the coding style of scriptdef</li>
 * <li>CheckScriptSize : checks the size of scripts</li>
 * <li>CheckTabCharacter : checks for tab characters</li>
 * <li>CheckTargetName : checks the naming convention of targets</li>
 * <li>CheckUseOfEqualsTask : checks the usage of equals task</li>
 * <li>CheckUseOfIfInTargets : checks the usage of if task inside targets</li>
 * </ul>
 * </pre>
 * 
 * <p>
 * Checks to be added:
 * <ul>
 * <li>Help target is defined.</li>
 * <li>Optional to thrown warnings about deprecated targets (rename, copydir,
 * copyfile).</li>
 * </ul>
 * </p>
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
 *       &lt;CheckTabCharacter&quot; severity=&quot;error&quot; enabled=&quot;true&quot;/&gt;
 *       &lt;CheckTargetName&quot; severity=&quot;warning&amp;quot enabled=&quot;true&quot; regexp=&quot;([a-z0-9[\\d\\-]]*)&quot;/&gt;
 *       &lt;CheckScriptDef&quot; severity=&quot;error&quot; enabled=&quot;true&quot; outputDir=&quot;${antlint.test.dir}/output&quot;/&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="antlint" category="AntLint"
 * 
 */
public class AntLintTask extends Task implements Reporter {

    private List<Check> checkerList = new Vector<Check>();
    private List<FileSet> antFileSetList = new ArrayList<FileSet>();
    private List<Reporter> reporters = new ArrayList<Reporter>();
    private int errorCount;
    private boolean failOnError = true;
    private ConsoleReporter consoleReporter = new ConsoleReporter();

    /**
     * Add a set of files to copy.
     * 
     * @param set
     *            a set of files to AntLintTask.
     * @ant.required
     */
    public void addFileset(FileSet set) {
        antFileSetList.add(set);
    }

    /**
     * Execute the antlint task.
     */
    public final void execute() {
        if (checkerList.size() == 0) {
            throw new BuildException("No antlint checks are defined.");
        }
        try {
            // Adding console reported by default if no
            // other reporter are mentioned.
            if (reporters.size() == 0) {
                reporters.add(consoleReporter);
            }
            setTask(this);
            open();
            doAntLintCheck();
        } catch (AntlintException e) {
            throw new BuildException(
                    "Exception occured while running AntLint task "
                            + e.getMessage());
        } finally {
            // Closing all reporter session.
            close();
        }

        if (failOnError && (errorCount > 0)) {
            throw new BuildException("Build failed because of AntLint errors.");
        }

    }

    /**
     * Triggers the antlint checking.
     * 
     * @throws AntlintException
     * 
     * @throws Exception
     *             if the checking fails.
     */
    private void doAntLintCheck() throws AntlintException {

        for (FileSet fs : antFileSetList) {
            DirectoryScanner ds = fs.getDirectoryScanner(getProject());
            String[] srcFiles = ds.getIncludedFiles();
            String basedir = ds.getBasedir().getPath();
            for (int i = 0; i < srcFiles.length; i++) {
                String antFilename = basedir + File.separator + srcFiles[i];
                runChecks(new File(antFilename));
            }
        }
    }

    /**
     * Runs antlint checks for the given ant file.
     * 
     * @param antFileName
     *            is the name of the ant file to be checked.
     * @throws AntlintException
     */
    private void runChecks(File antFilename) throws AntlintException {
        for (Check check : checkerList) {
            if (check.isEnabled()) {
                check.validateAttributes();
                check.setReporter(this);
                check.run(antFilename);
            }
        }

    }

    /**
     * To add Antlint checkers.
     * 
     * @param c
     */
    public void add(Check c) {
        checkerList.add(c);
    }

    /**
     * To add reporters.
     * 
     * @param reporter
     */
    public void add(Reporter reporter) {
        reporter.setTask(this);
        reporters.add(reporter);
    }

    /**
     * @param failOnError
     *            the failOnError to set
     */
    public void setFailOnError(boolean failOnError) {
        this.failOnError = failOnError;
    }

    /*
     * (non-Javadoc)
     * 
     * @see
     * com.nokia.helium.antlint.ant.Reporter#report(com.nokia.helium.antlint
     * .ant.Severity, java.lang.String, java.io.File, int)
     */
    public void report(Severity severity, String message, File filename,
            int lineNo) {
        if (severity.getValue().toUpperCase().equals("ERROR")) {
            errorCount++;
        }

        for (Reporter reporter : reporters) {
            reporter.report(severity, message, filename, lineNo);
        }
    }

    /*
     * (non-Javadoc)
     * 
     * @see
     * com.nokia.helium.antlint.ant.Reporter#setTask(org.apache.tools.ant.Task)
     */
    @Override
    public void setTask(Task task) {
        for (Reporter reporter : reporters) {
            reporter.setTask(task);
        }
    }

    @Override
    public void close() {
        for (Reporter reporter : reporters) {
            reporter.close();
        }
    }

    @Override
    public void open() {
        for (Reporter reporter : reporters) {
            reporter.open();
        }
    }

}