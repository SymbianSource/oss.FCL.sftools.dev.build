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

package com.nokia.helium.metadata.ant.conditions;

import java.io.File;
import com.nokia.helium.jpa.ORMReader;
import com.nokia.helium.jpa.entity.metadata.Metadata;
import org.apache.tools.ant.BuildException;
import com.nokia.helium.core.ant.types.ConditionType;

/**
 * This class implements a Ant Condition which report true if it finds any
 * matching severity inside a database for an XML log.
 * 
 * Example:
 * <pre>
 * &lt;target name=&quot;fail-on-build-error&quot;&gt;
 *   &lt;fail message=&quot;The build contains errors&quot;&gt;
 *     &lt;hlm:metadataHasSeverity log=&quot;my.log&quot; db=&quot;my.db&quot; severity=&quot;error&quot;/&gt;
 *   &lt;/fail&gt;
 * &lt;/target&gt;
 * </pre>
 * 
 * The condition will eval as true if the my.db contains error stored for my.log file.
 * 
 * @ant.type name="metadataHasSeverity" category="Metadata"
 */
public class MetaDataLogCondition extends ConditionType {

    // The severity to count
    private String severity;
    private String logFile;
    private File fileName;
    
    /**
     * Sets which severity will be counted.
     * 
     * @param severity
     * @ant.required
     */
    public void setSeverity(String severity) {
        this.severity = severity;
    }

    public void setDb(File file) {
        fileName = file;
    }
    
    public void setLog(String log) {
        logFile = log;
    }

    /**
     * Get the number of a particular severity.
     * 
     * @return the number of a particular severity.
     */
    public int getSeverity() {
        if (fileName == null || !fileName.exists() || logFile == null) {
            //this.log("Error: Log file does not exist " + fileName);
            return -1;
        }
        if (severity == null)
            throw new BuildException("'severity' attribute is not defined");

        //this.log("Looking for severity '" + severity + "' under '" + fileName.getAbsolutePath() + "'");
        
        Metadata.PriorityEnum prty = null;
        if (severity.equalsIgnoreCase("ERROR")) {
            prty = Metadata.PriorityEnum.ERROR;
        } else if (severity.equalsIgnoreCase("WARNING")) {
            prty = Metadata.PriorityEnum.WARNING;
        } else if (severity.equalsIgnoreCase("FATAL")) {
            prty = Metadata.PriorityEnum.FATAL;
        } else if (severity.equalsIgnoreCase("INFO")) {
            prty = Metadata.PriorityEnum.INFO;
        } else if (severity.equalsIgnoreCase("REMARK")) {
            prty = Metadata.PriorityEnum.REMARK;
        }
        else
            throw new BuildException("'severity' attribute is not valid");

        String query = "select Count(m.id) from MetadataEntry m JOIN  m.logFile  as l JOIN m.priority as p where l.path like '%" + logFile + "' and UPPER(p.priority) like '%" + severity.toUpperCase() + "'";
        Number number = (Number) (new ORMReader(fileName.getAbsolutePath())).executeSingleResult(query, null);
        return number.intValue();
    }

    /**
     * This method open the defined file and count the number of message tags
     * with their severity attribute matching the configured one.
     * 
     * @return if true if message with the defined severity have been found.
     */
    public boolean eval() {
        int severity = getSeverity();
        if (severity < 0) {
            return false;
        }
        return severity > 0;
    }
}