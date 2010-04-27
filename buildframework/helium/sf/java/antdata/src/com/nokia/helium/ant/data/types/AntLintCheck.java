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

package com.nokia.helium.ant.data.types;

import java.io.IOException;

import org.apache.tools.ant.types.DataType;

import com.nokia.helium.ant.data.Database;
import com.nokia.helium.ant.data.taskdefs.AntConfigLintTask;

/**
 * An Ant Lint coding conventions check.
 */
public abstract class AntLintCheck extends DataType {
    public static final int SEVERITY_ERROR = 0;
    public static final int DEFAULT_SEVERITY = SEVERITY_ERROR;

    private AntConfigLintTask task;
    private String name;
    private String text;
    private int severity = DEFAULT_SEVERITY;

    /**
     * Set the pattern text.
     * 
     * @param text is the pattern text to set.
     */
    public void addText(String text) {
        this.text = text;
    }

    /**
     * Get the name of the Checker.
     * 
     * @return name of the checker.
     */
    public String getName() {
        return name;
    }

    /**
     * Set the name of the Checker.
     * 
     * @param name is the name of the checker to set.
     * @ant.required
     */
    public void setName(String name) {
        this.name = name;
    }

    /**
     * Get the pattern set for this Checker.
     * 
     * @return the pattern.
     */
    public String getPattern() {
        return text;
    }

    /**
     * Get the severity.
     * 
     * @return the severity
     */
    public int getSeverity() {
        return severity;
    }

    /**
     * Set the severity. (Valid values : error|warning)
     * 
     * @param severity is the severity to set.
     * @ant.required
     */
    public void setSeverity(int severity) {
        this.severity = severity;
    }

    public AntConfigLintTask getTask() {
        return task;
    }

    public void setTask(AntConfigLintTask task) {
        this.task = task;
    }

    protected Database getDb() {
        return task.getDatabase();
    }

    public abstract void run() throws IOException;
}
