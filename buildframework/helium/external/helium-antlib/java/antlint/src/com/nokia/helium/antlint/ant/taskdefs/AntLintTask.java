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
import java.util.Collections;
import java.util.List;
import java.util.Vector;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.DirectoryScanner;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.FileSet;
import org.dom4j.Document;
import org.dom4j.Element;
import org.dom4j.Visitor;
import org.dom4j.io.SAXReader;

import com.nokia.helium.antlint.AntFile;
import com.nokia.helium.antlint.AntProjectVisitor;
import com.nokia.helium.antlint.ant.types.Checker;
import com.nokia.helium.antlint.checks.Check;

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
 * <li>CheckPropertiesInDataModel : checks whether the properties are defined in
 * data model</li>
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
 *       &lt;checker name=&quot;CheckTabCharacter&quot; severity=&quot;error&quot; /&gt;
 *       .
 *       .
 *       &lt;checker name=&quot;CheckTargetName&quot; severity=&quot;warning&quot;&gt;([a-z0-9[\\d\\-]]*)&lt;/checker&gt;
 *  &lt;/antlint&gt;
 * </pre>
 * 
 * @ant.task name="antlint" category="AntLint"
 * 
 */
public class AntLintTask extends Task {

    private List<Checker> checkerList = new Vector<Checker>();
    private List<FileSet> antFileSetList = new ArrayList<FileSet>();

    private List<AntFile> antFilelist = new ArrayList<AntFile>();
    private List<Check> checkList = new ArrayList<Check>();

    /**
     * Add the given {@link Checker} to the checklist.
     * 
     * @param checker
     *            is the checker to be added.
     * @ant.required
     */
    public void addChecker(Checker checker) {
        checkerList.add(checker);
    }

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
        try {
            initialize();
            startAntLintCheck(); // trigger antlint checking
        } catch (Exception e) {
            throw new BuildException(
                    "Exception occured while running AntLint task "
                            + e.getMessage());
        }

        int errorCount = 0;
        for (AntFile antFile : antFilelist) {
            errorCount = errorCount + antFile.getErrorCount();
            log(antFile.toString());
        }
        if (errorCount > 0) {
            throw new BuildException(errorCount + " errors found.");
        }
    }

    /**
     * Initialize the checklist setting the checkers against their corresponding
     * Checks.
     */
    private void initialize() {
        Check check = null;
        for (Checker checker : checkerList) {
            check = getCheckObject(checker.getName());
            if (check != null) {
                check.setChecker(checker);
                checkList.add(check);
            }
        }
    }

    /**
     * Instantiate the given {@link Check}.
     * 
     * @param checkerName
     *            is the name of the Check object to be instantiated.
     * @return an instance of requested {@link Check}.
     */
    @SuppressWarnings("unchecked")
    private Check getCheckObject(String checkerName) {
        Check check = null;
        try {
            Class clazz = Class.forName("com.nokia.helium.antlint.checks."
                    + checkerName);
            if (clazz != null) {
                check = (Check) clazz.newInstance();
            }
        } catch (Throwable th) {
            throw new BuildException("Error in Antlint configuration:", th);
        }
        return check;
    }

    /**
     * Triggers the antlint checking.
     * 
     * @throws Exception
     *             if the checking fails.
     */
    private void startAntLintCheck() throws Exception {
        runOneTimeCheck();

        for (FileSet fs : antFileSetList) {
            DirectoryScanner ds = fs.getDirectoryScanner(getProject());
            String[] srcFiles = ds.getIncludedFiles();
            String basedir = ds.getBasedir().getPath();

            for (int i = 0; i < srcFiles.length; i++) {
                String antFileName = basedir + File.separator + srcFiles[i];
                getProject().log("*************** Ant File: " + antFileName);

                run(antFileName);

                SAXReader saxReader = new SAXReader();
                Document doc = saxReader.read(new File(antFileName));
                treeWalk(doc);
            }
            Collections.sort(antFilelist);
        }
    }

    /**
     * Parse the given document.
     * 
     * @param document
     *            is the document to be parsed.
     */
    private void treeWalk(final Document document) {
        Element rootElement = document.getRootElement();
        Visitor visitorRootElement = new AntProjectVisitor(checkList);
        rootElement.accept(visitorRootElement);
    }

    /**
     * Runs one time antlint checks.
     * 
     */
    private void runOneTimeCheck() {
        AntFile antFile = new AntFile("General");
        antFilelist.add(antFile);
        for (Check check : checkList) {
            if (check.isEnabled()) {
                check.setAntFile(antFile);
                check.run();
            }
        }
    }

    /**
     * Runs antlint checks for the given ant file.
     * 
     * @param antFileName
     *            is the name of the ant file to be checked.
     */
    private void run(String antFileName) {
        AntFile antFile = new AntFile(antFileName);
        antFilelist.add(antFile);
        for (Check check : checkList) {
            if (check.isEnabled()) {
                check.setAntFile(antFile);
                check.run(antFileName);
            }
        }
    }
}