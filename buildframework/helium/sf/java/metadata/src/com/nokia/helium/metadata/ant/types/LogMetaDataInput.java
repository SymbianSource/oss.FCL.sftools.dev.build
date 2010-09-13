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

package com.nokia.helium.metadata.ant.types;

import java.io.File;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.regex.Pattern;

import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;

import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.DataType;
import org.apache.tools.ant.types.Resource;
import org.apache.tools.ant.types.ResourceCollection;

import com.nokia.helium.metadata.MetaDataInput;
import com.nokia.helium.metadata.MetadataException;
import com.nokia.helium.metadata.model.metadata.LogFile;
import com.nokia.helium.metadata.model.metadata.LogFileDAO;

/**
 * Abstract base class to provide common functionality for the log parsing.
 */
public abstract class LogMetaDataInput extends DataType implements MetaDataInput {
    
    private List<ResourceCollection> resourceCollections = new ArrayList<ResourceCollection>();
    private Task task;
    private List<MetaDataFilterSet> metadataFilterSets = new ArrayList<MetaDataFilterSet>();
    private List<MetaDataFilter> completeFilterList;
    
    /**
     * Adds the fileset (list of input log files to be processed).
     *  @param fileSet fileset to be added
     * 
     */
    public void add(ResourceCollection resourceCollection) {
        resourceCollections.add(resourceCollection);
    }   
    
    /**
     * Adds the fileset (list of input log files to be processed).
     *  @param fileSet fileset to be added
     * 
     */
    public void add(MetaDataFilterSet metadataFilterSet) {
        metadataFilterSets.add(metadataFilterSet);
    } 

    /**
     * Helper function called by ant to create the new filter
     */
    public MetaDataFilterSet createMetaDataFilterSet() {
        MetaDataFilterSet filterSet =  new MetaDataFilterSet();
        add(filterSet);
        return filterSet;
    }

    /**
     * Helper function to return all the filters associated with this metadata input
     * @return all the filters merged based on the order of definition.
     */
    private synchronized List<MetaDataFilter> getMetaDataFilters() {
        if (completeFilterList == null) {
            completeFilterList = new ArrayList<MetaDataFilter>();
            for (MetaDataFilterSet filterSet : metadataFilterSets) {
                completeFilterList.addAll(filterSet.getAllFilters());
            }
        }
        return completeFilterList;
    }

    /**
     * Returns the severity matches for the log text
     * @param log text for which the severity needs to be identified.
     * @return the severity of the input text
     */
    protected SeverityEnum.Severity getSeverity(String logText) {
        for (MetaDataFilter filter : getMetaDataFilters()) {
            Pattern pattern = filter.getPattern();
            if ((pattern.matcher(logText)).matches()) {
                return filter.getSeverity();
            }
        }
        return SeverityEnum.Severity.NONE;
    }

    /**
     * Logging through the Ant task
     */
    public void log(String message) {
        log(message, Project.MSG_INFO);    
    }
    
    /**
     * Logging through the Ant task
     */
    public void log(String message, int level) {
        if (task != null) {
            task.log(message, level);
        } else {
            getProject().log(message, level);
        }
    }
    /**
     * Get the LogFile instance for the file log.
     * @param entityManager the entityManager to do the query.
     * @param file the log file locations
     * @return the LogFile entry for the file log. 
     */
    protected LogFile getLogFile(EntityManager entityManager, File file) {
        // Creating the filename
        LogFileDAO lfdao = new LogFileDAO();
        lfdao.setEntityManager(entityManager);
        LogFile logFile = lfdao.findByLogName(file);
        if (logFile == null) {
            log("Creating a logfile entry.", Project.MSG_DEBUG);
            logFile = new LogFile();
            logFile.setPath(file.getAbsolutePath());
            entityManager.getTransaction().begin();
            entityManager.persist(logFile);
            entityManager.getTransaction().commit();
        }
        return logFile;
    }
    
    /**
     * {@inheritDoc}
     * Implements default behavior, for each log file the reference inside
     * the database will first be removed, and then data will be collected. 
     */
    @SuppressWarnings("unchecked")
    public void extract(Task task, EntityManagerFactory factory)
        throws MetadataException {
        this.task = task;
        try {
            for (ResourceCollection resourceCollection : resourceCollections) {
                Iterator<Resource> ri = (Iterator<Resource>)resourceCollection.iterator();
                while (ri.hasNext()) {
                    File file = new File(ri.next().toString());
                    remove(factory, file);
                    log("Extracting data from " + file);
                    extract(factory, file);
                }
            }
        } finally {
            this.task = null;
        }
    }
    
    /**
     * Removing a file log data from the database (if any).
     * @param factory
     * @param file
     * @throws MetadataException
     */
    public void remove(EntityManagerFactory factory, File file) throws MetadataException {
        EntityManager entityManager = factory.createEntityManager();
        try {
            LogFileDAO logFileDAO = new LogFileDAO();
            logFileDAO.setEntityManager(entityManager);
            LogFile logFile = logFileDAO.findByLogName(file);
            if (logFile != null) {
                log("Removing log from database: " + file.getAbsolutePath());
                entityManager.getTransaction().begin();
                logFileDAO.remove(logFile);
                entityManager.getTransaction().commit();
            }
        } finally {
            entityManager.close();
        }
    }
    
    /**
     * Extracting the data from 
     * @param factory
     * @param file
     * @throws MetadataException
     */
    public abstract void extract(EntityManagerFactory factory, File file) throws MetadataException;
}