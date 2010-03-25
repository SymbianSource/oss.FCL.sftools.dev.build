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

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;
import com.nokia.helium.core.ant.conditions.XMLLogCondition;

/**
 * This class sets a property to the number of matching severity inside a XML log.
 * 
 * @ant.task name="countSeverity" category="Core"
 */
public class XMLLogCount extends Task {

    private File fileName;
    private String severity;
    private String logRegexp;
    private String property;

    /**
     * File to be parsed.
     * 
     * @param filename
     * @ant.required
     */
    public void setFile(File filename) {
        fileName = filename;
    }

    /**
     * Defines the severity name to be counted.
     * 
     * @param severity
     * @ant.required
     */
    public void setSeverity(String severity) {
        this.severity = severity;
    }

    /**
     * Name of the property to be set.
     * @param property the property name
     * @ant.required
     */
    public void setProperty(String property) {
        this.property = property;
    }

    /**
     * Regular expression which used to match a specific log filename.
     * @param regex
     * @ant.not-required
     */
    public void setLogMatcher(String regex) {
        this.logRegexp = regex;
    }
    
    /**
     *  Execute the task. Set the property with number of severities.  
     * @throws BuildException
     */
    public void execute() {
        if (property == null)
            throw new BuildException("'property' attribute is not defined");
        
        XMLLogCondition cond = new XMLLogCondition();
        cond.setFile(fileName);
        cond.setLogMatcher(logRegexp);
        cond.setSeverity(severity);
        getProject().setNewProperty(property, "" + cond.getSeverity());
    }
}