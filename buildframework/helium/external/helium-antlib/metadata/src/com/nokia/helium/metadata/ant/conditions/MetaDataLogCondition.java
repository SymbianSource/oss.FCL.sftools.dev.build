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
import java.util.List;
import java.util.Map;

import com.nokia.helium.metadata.db.MetaDataDb;

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

        this.log("Looking for severity '" + severity + "' under '"
                + fileName.getAbsolutePath() + "'");
        
        MetaDataDb.Priority prty = null;
        if (severity.equalsIgnoreCase("ERROR")) {
            prty = MetaDataDb.Priority.ERROR;
        } else if (severity.equalsIgnoreCase("WARNING")) {
            prty = MetaDataDb.Priority.WARNING;
        } else if (severity.equalsIgnoreCase("FATAL")) {
            prty = MetaDataDb.Priority.FATAL;
        } else if (severity.equalsIgnoreCase("INFO")) {
            prty = MetaDataDb.Priority.INFO;
        } else if (severity.equalsIgnoreCase("REMARK")) {
            prty = MetaDataDb.Priority.REMARK;
        }
        else
            throw new BuildException("'severity' attribute is not valid");
        
        MetaDataDb db = new MetaDataDb(fileName.getAbsolutePath());
        
        String sql = "select count(data) as COUNT from metadata INNER JOIN logfiles ON logfiles.id=metadata.logpath_id where path like '%" + logFile + "%' and priority_id = " + prty.getValue();
        
        //System.out.println(sql);
        List<Map<String, Object>> records = db.getRecords(sql);
        for (Map<String, Object> map : records)
        {
            //System.out.println((Integer)map.get("COUNT"));
            return (Integer)map.get("COUNT");
        }

        return 0;
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