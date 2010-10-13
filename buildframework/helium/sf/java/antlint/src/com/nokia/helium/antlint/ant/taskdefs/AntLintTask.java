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
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Vector;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.DirectoryScanner;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.FileSet;

import com.nokia.helium.ant.data.AntFile;
import com.nokia.helium.ant.data.Database;
import com.nokia.helium.antlint.ant.AntlintException;
import com.nokia.helium.antlint.ant.Reporter;
import com.nokia.helium.antlint.ant.Severity;
import com.nokia.helium.antlint.ant.types.Check;
import com.nokia.helium.antlint.ant.types.ConsoleReporter;
import com.nokia.helium.antlint.ant.types.Executor;

/**
 * AntLint Task. This task checks for common coding conventions and errors in
 * Ant XML script files.
 * 
 * <p>
 * The current checks include:
 * <ul>
 * <li>CheckAntCall : checks whether antcall is used with no param elements and
 * calls target with no dependencies</li>
 * <li>checkDescription : checks for project description</li>
 * <li>checkDuplicateNames : checks for duplicate macros and task names</li>
 * <li>checkFileName : checks the naming convention of ant xml files</li>
 * <li>checkIndentation : checks indentation</li>
 * <li>checkJythonScript : checks the coding convention Jython scripts</li>
 * <li>checkPresetDefMacroDefName : checks the naming convention of presetdef
 * and macrodef</li>
 * <li>checkProjectName : checks the naming convention of project</li>
 * <li>checkPropertyName : checks the naming convention of properties</li>
 * <li>checkPropertyTypeAndValueMismatch : checks for property type and value
 * mismatch</li>
 * <li>CheckPythonTasks : checks the coding convention of python tasks</li>
 * <li>checkRunTarget : checks whether runtarget calls a target that has
 * dependencies</li>
 * <li>checkScriptCondition : checks the coding convention in script condition</li>
 * <li>CheckScriptDef : checks the coding convention in scriptdef and attributes
 * used any</li>
 * <li>checkScriptSize : checks the size of scripts</li>
 * <li>checkTabCharacter : checks for tab characters</li>
 * <li>checkTargetName : checks the naming convention of targets</li>
 * <li>checkTryCatchBlock : checks for empty or more than one catch element in a
 * try-catch block</li>
 * <li>checkUseOfEqualsTask : checks the usage of equals task</li>
 * <li>checkUseOfIfInTargets : checks the usage of if task inside targets</li>
 * <li>checkVariableTask : checks whether value attribute for ant-contrib
 * variable task is set or not when unset is set to true</li>
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
 * Usage: By default, a check will be enabled. To disable a check set enabled=false.
 * 
 *  &lt;antlint&gt;
 *       &lt;fileset id=&quot;antlint.files&quot; dir=&quot;${antlint.test.dir}/data&quot;&gt;
 *               &lt;include name=&quot;*.ant.xml&quot;/&gt;
 *               &lt;include name=&quot;*build.xml&quot;/&gt;
 *               &lt;include name=&quot;*.antlib.xml&quot;/&gt;
 *       &lt;/fileset&gt;
 *       &lt;CheckTabCharacter&quot; severity=&quot;error&quot; /&gt;
 *       &lt;CheckTargetName&quot; severity=&quot;warning&amp;quot regexp=&quot;([a-z0-9[\\d\\-]]*)&quot;/&gt;
 *       &lt;CheckScriptDef&quot; severity=&quot;error&quot; enabled=&quot;false&quot; outputDir=&quot;${antlint.test.dir}/output&quot;/&gt;
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
    private List<Executor> executors = new Vector<Executor>();

    public void add(Executor executor) {
        executors.add(executor);
    }

    /**
     * Add a set of files to copy.
     * 
     * @param set a set of files to AntLintTask.
     * @ant.required
     */
    public void addFileset(FileSet set) {
        antFileSetList.add(set);
    }

    /**
     * Execute the antlint task.
     */
    public final void execute() {
        if (checkerList.size() == 0 && executors.size() == 0) {
            throw new BuildException("No antlint checks/executors are defined.");
        }

        try {
            // Adding console reported by default if no
            // other reporters are mentioned.
            if (reporters.size() == 0) {
                reporters.add(consoleReporter);
            }
            setTask(this);
            open();
            List<String> antFilePaths = new ArrayList<String>();
            for (FileSet fs : antFileSetList) {
                DirectoryScanner ds = fs.getDirectoryScanner(getProject());
                String[] srcFiles = ds.getIncludedFiles();
                String basedir = ds.getBasedir().getPath();
                for (int i = 0; i < srcFiles.length; i++) {
                    String antFilename = basedir + File.separator + srcFiles[i];
                    antFilePaths.add(antFilename);
                }
            }
            Database db = new Database(getProject(), "private");
            db.addAntFilePaths(antFilePaths);
            doAntLintCheck(db);
            triggerExternalCommands(db);
        } catch (AntlintException e) {
            throw new BuildException("Exception occured while running AntLint task "
                    + e.getMessage());
        } catch (IOException ex) {
            throw new BuildException("Exception occured while creating Ant database"
                    + ex.getMessage());
        } finally {
            // Closing all reporter sessions.
            close();
        }

        if (failOnError && (errorCount > 0)) {
            throw new BuildException("Build failed because of AntLint errors.");
        }

    }

    private void triggerExternalCommands(Database database) throws AntlintException {
        for (Executor executor : executors) {
            log("\n" + executor.getClass().getSimpleName() + " output:" + "\n");
            executor.setDatabase(database);
            executor.validateAttributes();
            executor.run();
        }
    }

    /**
     * Triggers the antlint checking.
     * 
     * @throws AntlintException if the checking fails.
     */
    private void doAntLintCheck(Database database) throws AntlintException {
        Collection<AntFile> antFiles = database.getAntFiles();
        for (AntFile antFile : antFiles) {
            for (Check check : checkerList) {
                if (check.isEnabled()) {
                    check.validateAttributes();
                    check.setReporter(this);
                    check.setAntFile(antFile);
                    check.run();
                }
            }
        }
    }

    /**
     * Method to add Antlint checkers.
     * 
     * @param check an antlint check to be added.
     */
    public void add(Check check) {
        checkerList.add(check);
    }

    /**
     * Method to add Antlint reporters.
     * 
     * @param reporter a antlint reporter to be added.
     */
    public void add(Reporter reporter) {
        reporter.setTask(this);
        reporters.add(reporter);
    }

    /**
     * Boolean flag to set whether fail on error or not.
     * 
     * @param failOnError the failOnError to set
     */
    public void setFailOnError(boolean failOnError) {
        this.failOnError = failOnError;
    }

    /*
     * (non-Javadoc)
     * @see
     * com.nokia.helium.antlint.ant.Reporter#report(com.nokia.helium.antlint
     * .ant.Severity, java.lang.String, java.io.File, int)
     */
    public void report(Severity severity, String message, File filename, int lineNo) {
        if (severity.getValue().toUpperCase().equals("ERROR")) {
            errorCount++;
        }

        for (Reporter reporter : reporters) {
            reporter.report(severity, message, filename, lineNo);
        }
    }

    /*
     * (non-Javadoc)
     * @see
     * com.nokia.helium.antlint.ant.Reporter#setTask(org.apache.tools.ant.Task)
     */
    @Override
    public void setTask(Task task) {
        for (Reporter reporter : reporters) {
            reporter.setTask(task);
        }
    }

    /*
     * (non-Javadoc)
     * @see com.nokia.helium.antlint.ant.Reporter#close()
     */
    public void close() {
        for (Reporter reporter : reporters) {
            reporter.close();
        }
    }

    /*
     * (non-Javadoc)
     * @see com.nokia.helium.antlint.ant.Reporter#open()
     */
    public void open() {
        for (Reporter reporter : reporters) {
            reporter.open();
        }
    }

}