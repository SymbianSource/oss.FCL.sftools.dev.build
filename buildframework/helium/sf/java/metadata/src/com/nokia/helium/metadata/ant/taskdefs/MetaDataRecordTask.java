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
import java.util.Vector;

import javax.persistence.EntityManagerFactory;

import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Project;
import org.apache.tools.ant.Task;

import com.nokia.helium.metadata.FactoryManager;
import com.nokia.helium.metadata.MetaDataInput;
import com.nokia.helium.metadata.MetadataException;

/**
 * This task provide a way to record the data in the Database.
 * 
 * <pre>
 * Example 1:
 * &lt;metadatarecord database=&quot;compile_log.db&quot;&gt;
 *     &lt;sbsmetadatainput&gt;
 *     &lt;fileset casesensitive=&quot;false&quot; file=&quot;sbs.log.file&quot;/&gt
 *         &lt;metadatafiltelistref refid=&quot;compilation&quot;/&gt;
 *     &lt;/sbsmetadatainput&gt;
 * &lt;/metadatarecord&gt;
 * 
 * Example 2:
 * 
 * &lt;metadatarecord database=&quot;metadata.db&quot;&gt;
 *     &lt;antmetadatainput&gt;
 *     &lt;fileset casesensitive=&quot;false&quot; file=&quot;${build.id}_ant_build.log&quot;/&gt
 *         &lt;metadatafiltelistref refid=&quot;compilation&quot;/&gt;
 *     &lt;/antmetadatainput&gt;
 * &lt;/metadatarecord&gt;

 * </pre>
 * 
 * @ant.task name="metadatarecord" category="Metadata"
 */
public class MetaDataRecordTask extends Task {

    private File database;
    
    private boolean failOnError = true;
    
    private Vector<MetaDataInput> metaDataInputs = new Vector<MetaDataInput>();

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
     * @param failOnError
     * @ant.not-required Default is true.
     */
    public void setFailOnError(boolean failOnError) {
        this.failOnError = failOnError;
    }
    
    /**
     * Helper function to get the database
     * 
     */
    public File getDatabase() {
        return database;
    }

    /**
     * Helper function to return the metadatalist
     *  @return build metadata object
     * 
     */
    public Vector<MetaDataInput> getMetaDataList() throws MetadataException {
        if (metaDataInputs.isEmpty()) {
            throw new MetadataException("metadata list is empty");
        }
        return metaDataInputs;
    }

    /**
     * Helper function to add the metadatalist
     *  @param build metadata list to add
     * 
     */
    public void add(MetaDataInput metaDataInput) {
        metaDataInputs.add(metaDataInput);
    }

    /**
     * {@inheritDoc}
     */
    @Override
    public void execute() {
        if (database == null) {
            throw new BuildException("'database' attribute is not defined.");
        }
        EntityManagerFactory factory = null;
        try {
            factory = FactoryManager.getFactoryManager().getEntityManagerFactory(database);
            Date before = new Date();
            log("Time before recording to db: " + before);
            for (MetaDataInput metadataInput : metaDataInputs) {
                metadataInput.extract(this, factory);
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
            if (factory != null) {
                factory.close();
            }
            factory = null;
        }
    }
}