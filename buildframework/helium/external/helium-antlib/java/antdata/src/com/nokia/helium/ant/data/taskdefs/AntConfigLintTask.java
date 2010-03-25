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

package com.nokia.helium.ant.data.taskdefs;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.DynamicElement;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;

import com.nokia.helium.ant.data.Database;
import com.nokia.helium.ant.data.types.AntLintCheck;
import com.nokia.helium.ant.data.types.LintIssue;

/**
 * Another version of AntLint that fits with the antdata API more closely.
 */
@SuppressWarnings("serial")
public class AntConfigLintTask extends Task implements DynamicElement {

    // Temporary solution, should change to scanning jar
    public static final Map<String, String> CHECKS = new HashMap<String, String>() {
        {
            put("wrongtypepropertycheck", "WrongTypePropertyCheck");
            // put("protected", new Integer(2));
            // put("private", new Integer(3));
        }
    };
    private List<AntLintCheck> checks = new ArrayList<AntLintCheck>();
    private List<LintIssue> issues = new ArrayList<LintIssue>();
    private Database db;
    private int errorsTotal;

    public AntConfigLintTask() throws IOException {
        setTaskName("antconfiglint");
    }

    @SuppressWarnings("unchecked")
    public Object createDynamicElement(String name) {
        AntLintCheck check = null;
        String className = "com.nokia.helium.ant.data.types." + CHECKS.get(name);
        log("Creating check: " + className, Project.MSG_DEBUG);
        try {
            Class<AntLintCheck> clazz = (Class<AntLintCheck>) Class.forName(className);
            if (clazz != null) {
                check = (AntLintCheck) clazz.newInstance();
                checks.add(check);
            }
        }
        catch (Throwable th) {
            th.printStackTrace();
            throw new BuildException("Error in Antlint configuration: " + th.getMessage());
        }
        return check;
    }

    public void execute() {
        errorsTotal = 0;
        try {
            System.out.println(getProject());
            db = new Database(getProject());
            if (checks.size() == 0) {
                throw new BuildException("No checks defined.");
            }
            for (AntLintCheck check : checks) {
                check.setTask(this);

                log("Running check: " + check, Project.MSG_DEBUG);
                check.run();

            }
            for (LintIssue issue : issues) {
                log(issue.toString());
            }
            if (errorsTotal > 0) {
                throw new BuildException("AntLint errors found: " + errorsTotal);
            }
        }
        catch (IOException e) {
            throw new BuildException(e.getMessage());
        }
    }

    public void addLintIssue(LintIssue issue) {
        issues.add(issue);
        if (issue.getSeverity() == AntLintCheck.SEVERITY_ERROR) {
            errorsTotal++;
        }
    }

    public Database getDatabase() {
        return db;
    }
}
