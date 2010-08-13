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
import java.util.ArrayList;
import java.util.Date;
import java.util.Iterator;
import java.util.List;

import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;
import javax.persistence.Query;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.taskdefs.condition.Condition;
import org.apache.tools.ant.types.DataType;
import org.apache.tools.ant.types.Resource;
import org.apache.tools.ant.types.ResourceCollection;

import com.nokia.helium.metadata.FactoryManager;
import com.nokia.helium.metadata.MetadataException;
import com.nokia.helium.metadata.ant.types.SeverityEnum;

/**
 * This class implements a Ant Condition which report true if it finds any
 * matching severity inside a database for an XML log.
 * 
 * Example:
 * <pre>
 * &lt;target name=&quot;fail-on-build-error&quot;&gt;
 *   &lt;fail message=&quot;The build contains errors&quot;&gt;
 *     &lt;hlm:metadataHasSeverity log=&quot;my.log&quot; database=&quot;my.db&quot; severity=&quot;error&quot;/&gt;
 *   &lt;/fail&gt;
 * &lt;/target&gt;
 * </pre>
 * 
 * The condition will eval as true if the my.db contains error stored for my.log file.
 * 
 * @ant.type name="metadataHasSeverity" category="Metadata"
 */
public class MetaDataLogCondition extends DataType implements Condition {

    // The severity to count
    private SeverityEnum severity;
    private File log;
    private File database;
    private List<ResourceCollection> resourceCollections = new ArrayList<ResourceCollection>();
    
    /**
     * Defines which severity will be counted.
     * 
     * @param severity
     * @ant.required
     */
    public void setSeverity(SeverityEnum severity) {
        this.severity = severity;
    }

    /**
     * Defines the database to use.
     * @param database
     */
    @Deprecated
    public void setDb(File database) {
        log("The usage of the 'db' attribute is deprecated, please use the database attribute instead.", Project.MSG_WARN);
        setDatabase(database);
    }

    /**
     * Defines the database to use.
     * @param database
     */
    public void setDatabase(File database) {
        this.database = database;
    }
    
    /**
     * The log file to look severity for in the metadata. 
     * @param log the actual real log file.
     */
    public void setLog(File log) {
        this.log = log;
    }

    /**
     * Defines if missing file shall be counted (Deprecated attribute is ignored).
     * @param countMissing
     */
    @Deprecated
    public void setCountMissing(boolean countMissing) {
        log("The usage of the 'countMissing' attribute is deprecated.", Project.MSG_WARN);
        //this.countMissing = countMissing;
    }
    
    /**
     * 
     * @param resourceCollection
     */
    public void add(ResourceCollection resourceCollection) {
        resourceCollections.add(resourceCollection);
    }
    
    /**
     * Get the severity for a specific log file.
     * @param file
     * @return
     * @throws MetadataException
     */
    public int getSeverity(EntityManager em, File file) throws MetadataException {
        // log file under the DB is always represented with / and not \.
        String queryString = "select Count(m.id) from MetadataEntry m JOIN  m.logFile as l " +
                        "JOIN m.severity as p where l.path='" +
                        file.getAbsolutePath().replace('\\', '/') +
                        "' and p.severity='" + severity.getSeverity() + "'";
        log("Query: " + queryString, Project.MSG_DEBUG);
        Query query = em.createQuery(queryString);
        Number number = (Number)query.getSingleResult();
        log("Result: " + number, Project.MSG_DEBUG);
        return number.intValue();        
    }
    
    /**
     * Get the number of a particular severity.
     * 
     * @return the number of a particular severity.
     */
    @SuppressWarnings("unchecked")
    public int getSeverity() throws MetadataException {
        if (log == null && resourceCollections.isEmpty()) {
            throw new BuildException("'log' attribute not defined.");
        }
        if (database == null) {
            throw new BuildException("'database' attribute not defined.");
        }
        if (log != null && !log.exists()) {
            log("Could not find " + log + ".", Project.MSG_WARN);
        }
        if (severity == null) {
            throw new BuildException("'severity' attribute is not defined.");
        }

        EntityManagerFactory factory = null;
        EntityManager em = null;
        int result = 0;
        try {
            factory = FactoryManager.getFactoryManager().getEntityManagerFactory(database);
            em = factory.createEntityManager();
            Date before = new Date();
            if (!resourceCollections.isEmpty()) {
                for (ResourceCollection rc : resourceCollections) {
                    Iterator<Resource> ri = rc.iterator();
                    while (ri.hasNext()) {
                        Resource resource = ri.next();
                        log("Looking for severity '" + severity.getValue() + "' under '" + resource + "'");
                        result += getSeverity(em, new File(resource.toString()));
                    }
                }
            } else {
                log("Looking for severity '" + severity.getValue() + "' under '" + log.getAbsolutePath() + "'");
                result = getSeverity(em, log);
            }
            Date after = new Date();
            log("Elapsed time: " + (after.getTime() - before.getTime()) + " ms");
        } finally {
            if (em != null) {
                em.close();
            }
            if (factory != null) {
                factory.close();
            }
        }
        return result;
    }

    /**
     * This method open the defined file and count the number of message tags
     * with their severity attribute matching the configured one.
     * 
     * @return if true if message with the defined severity have been found.
     */
    public boolean eval() {
        try {
            int severity = getSeverity();
            if (severity < 0) {
                return false;
            }
            return severity > 0;
        } catch (MetadataException ex) {
            throw new BuildException(ex.getMessage(), ex);
        }
    }
}