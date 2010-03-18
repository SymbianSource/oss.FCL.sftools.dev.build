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

package com.nokia.helium.metadata.ant.taskdefs;

import java.io.File;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;
import com.nokia.helium.metadata.ant.conditions.MetaDataLogCondition;

/**
 * This class sets a property to the number of matching severity inside a Metadata db for a log.
 * Example:
 * <pre>
 *     &lt;hlm:metadataCountSeverity severity=&quot;error&quot; log=&quot;*_fixslashes_raptor.log&quot; db=&quot;${build.log.dir}/metadata.db&quot; property=&quot;fixslashes.error&quot;/&gt;
 * </pre>

 * @ant.task name="metadataCountSeverity" category="Metadata"
 */
public class MetaDataLogCount extends Task {

    private File fileName;
    private String logFile;
    private String severity;
    private String property;

    /**
     * File to be parsed.
     * 
     * @param filename
     * @ant.required
     */
    public void setDb(File filename) {
        fileName = filename;
    }
    
    public void setLog(String log) {
        logFile = log;
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
     *  Execute the task. Set the property with number of severities.  
     * @throws BuildException
     */
    public void execute() {
        if (property == null)
            throw new BuildException("'property' attribute is not defined");
        
        MetaDataLogCondition cond = new MetaDataLogCondition();
        cond.setDb(fileName);
        cond.setLog(logFile);
        cond.setSeverity(severity);
        getProject().setNewProperty(property, "" + cond.getSeverity());
    }
}