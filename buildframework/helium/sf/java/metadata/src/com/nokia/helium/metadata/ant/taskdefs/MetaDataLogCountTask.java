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
import java.util.ArrayList;
import java.util.List;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.ResourceCollection;

import com.nokia.helium.metadata.MetadataException;
import com.nokia.helium.metadata.ant.conditions.MetaDataLogCondition;
import com.nokia.helium.metadata.ant.types.SeverityEnum;

/**
 * This class sets a property to the number of matching severity inside a Metadata db for a log.
 * Example:
 * <pre>
 *     &lt;hlm:metadataCountSeverity severity=&quot;error&quot; 
 *                                   log=&quot;${compile.log.dir}/${build.id}_fixslashes_raptor.log&quot; 
 *                                   database=&quot;${build.log.dir}/metadata_db&quot; 
 *                                   property=&quot;fixslashes.error&quot; /&gt;
 * </pre>

 * @ant.task name="metadataCountSeverity" category="Metadata"
 */
public class MetaDataLogCountTask extends Task {

    private File database;
    private File log;
    private SeverityEnum severity;
    private String property;
    private List<ResourceCollection> resourceCollections = new ArrayList<ResourceCollection>();

    public void add(ResourceCollection resourceCollection) {
        resourceCollections.add(resourceCollection);
    }

    /**
     * Location of the database.
     * 
     * @param filename
     * @ant.required
     */
    @Deprecated
    public void setDb(File database) {
        log("The usage of the db attribute is deprecated, please use the database attribute instead.", Project.MSG_WARN);
        this.database = database;
    }

    /**
     * Location of the database.
     * 
     * @param filename
     * @ant.required
     */
    public void setDatabase(File database) {
        this.database = database;
    }
    
    public void setLog(File log) {
        this.log = log;
    }
    
    /**
     * Defines the severity name to be counted.
     * 
     * @param severity
     * @ant.required
     */
    public void setSeverity(SeverityEnum severity) {
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
     * Should the count of missing files for error severity.
     * @param countMissing enable the count of missing files 
     *                     for error severity
     * @ant.not-required Default is true
     */
    @Deprecated
    public void setCountMissing(boolean countMissing) {
        // not active anymore
    }
    
    /**
     *  Execute the task. Set the property with number of severities.  
     * @throws BuildException
     */
    public void execute() {
        if (property == null) {
            throw new BuildException("'property' attribute is not defined");
        }
        try {
            MetaDataLogCondition cond = new MetaDataLogCondition();
            cond.setProject(getProject());
            cond.setDatabase(database);
            cond.setLog(log);
            cond.setSeverity(severity);
            for (ResourceCollection rc : resourceCollections) {
                cond.add(rc);
            }
            getProject().setNewProperty(property, "" + cond.getSeverity());
        } catch (MetadataException ex) {
            throw new BuildException(ex.getMessage(), ex);
        }
    }
}