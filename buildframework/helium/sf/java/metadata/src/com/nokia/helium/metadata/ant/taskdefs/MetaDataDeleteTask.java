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
import java.util.Date;
import java.util.Iterator;
import java.util.List;
import java.util.Vector;

import javax.persistence.EntityManager;
import javax.persistence.EntityManagerFactory;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;
import org.apache.tools.ant.types.Resource;
import org.apache.tools.ant.types.ResourceCollection;

import com.nokia.helium.metadata.FactoryManager;
import com.nokia.helium.metadata.MetadataException;
import com.nokia.helium.metadata.model.metadata.LogFile;
import com.nokia.helium.metadata.model.metadata.LogFileDAO;

/**
 * This task provide a way to delete the data from db for a log file set.
 * 
 * <pre>
 * Example 1:
 * &lt;metadadelete database=&quot;compile_log.db&quot;&gt;
 *     &lt;fileset casesensitive=&quot;false&quot; file=&quot;sbs.log.file&quot;/&gt
 * &lt;/metadadelete&gt;
 * </pre>
 * 
 * @ant.task name="metadatadelete" category="Metadata"
 */
public class MetaDataDeleteTask extends Task {

    private File database;
    
    private boolean failOnError = true;

    private List<ResourceCollection> resourceCollections = new Vector<ResourceCollection>();

    /**
     * Helper function to set the database parameter
     * 
     * @ant.required
     */
    public void setDatabase(File database) {
        this.database = database;
    }

    /**
     * Defines if the task should fail on error.
     * @param failNotify
     * @ant.not-required Default is true.
     */
    public void setFailOnError(boolean failOnError) {
        this.failOnError = failOnError;
    }

    /**
     * Adds any ResourceCollection types from Ant (list of input log files to be processed).
     *  @param resourceCollection the ResourceCollection to be added
     * 
     */
    public void add(ResourceCollection resourceCollection) {
        resourceCollections.add(resourceCollection);
    }   

    /**
     * Helper function to get the database
     * 
     */
    protected File getDatabase() {
        return database;
    }

    /**
     * {@inheritDoc}
     */
    @SuppressWarnings("unchecked")
    @Override
    public void execute() {
        if (database == null) {
            throw new BuildException("'database' attribute is not defined.");
        }
        EntityManagerFactory factory = null;
        EntityManager entityManager = null;
        try {
            factory = FactoryManager.getFactoryManager().getEntityManagerFactory(database);
            entityManager = factory.createEntityManager();
            Date before = new Date();
            log("Time before recording to db: " + before);
            for (ResourceCollection resourceCollection : resourceCollections) {
                Iterator<Resource> ri = (Iterator<Resource>)resourceCollection.iterator();
                while (ri.hasNext()) {
                    File file = new File(ri.next().toString());
                    LogFileDAO logFileDAO = new LogFileDAO();
                    logFileDAO.setEntityManager(entityManager);
                    LogFile logFile = logFileDAO.findByLogName(file);
                    if (logFile != null) {
                        log("Removing log from database: " + file.getAbsolutePath());
                        entityManager.getTransaction().begin();
                        logFileDAO.remove(logFile);
                        entityManager.getTransaction().commit();
                    }
                }
            }
            Date after = new Date();
            log("Time after recording to db: " + after);
            log("Elapsed time: " + (after.getTime() - before.getTime()) + " ms");
        } catch (MetadataException ex) {
            log(ex.getMessage(), Project.MSG_ERR);
            if (failOnError) {
                throw new BuildException(ex.getMessage(), ex);
            }
        } finally {
            if (entityManager != null) {
                entityManager.close();                
                entityManager = null;
            }
            if (factory != null) {
                factory.close();
                factory = null;
            }
        }
    }
}