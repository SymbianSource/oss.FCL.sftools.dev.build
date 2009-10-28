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

import com.nokia.helium.metadata.MetaDataInput;
import org.apache.tools.ant.BuildException;
import org.apache.tools.ant.Task;
import java.util.Vector;
import java.util.Iterator;
//import java.util.ArrayList;
import org.apache.log4j.Logger;
//import org.apache.tools.ant.types.FileSet;
import com.nokia.helium.metadata.db.*;

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
public class MetaDataRecord extends Task {

    private static Logger log = Logger.getLogger(MetaDataRecord.class);

    private String database;
    
    private boolean failOnError = true;

    private Vector<MetaDataInput> metadataList = new Vector<MetaDataInput>();

    /**
     * Helper function to set the database parameter
     * 
     * @ant.required
     */
    public void setDatabase(String dbFile) {
        database = dbFile;
    }

    public void setFailOnError(String failNotify) {
        if (failNotify.equals("false")) {
            failOnError = false;
        }
    }
    /**
     * Helper function to get the database
     * 
     */
    public String getDatabase() {
        return database;
    }

    /**
     * Helper function to return the metadatalist
     *  @return build metadata object
     * 
     */
    public Vector<MetaDataInput> getMetaDataList() throws Exception {
        if (metadataList.isEmpty()) {
            throw new Exception("metadata list is empty");
        }
        return metadataList;
    }

    /**
     * Helper function to add the metadatalist
     *  @param build metadata list to add
     * 
     */
    public void add(MetaDataInput interf) {
        metadataList.add(interf);
    }

    
    @Override
    public void execute() {
        MetaDataDb metadataDb = null;
        try {
            log.debug("Getting Contents to write to db: " + database);
            log.debug("Initializing DB: " + database);
            metadataDb = new MetaDataDb(database);
            log.debug("Parsing the input and writing to DB");
            for ( MetaDataInput metadataInput : metadataList ) {
                boolean removed = false;
                Iterator<MetaDataDb.LogEntry> inputIterator = metadataInput.iterator();
                while (inputIterator.hasNext()) {
                    MetaDataDb.LogEntry logEntry = inputIterator.next();
                    if (!removed)
                        metadataDb.removeLog(logEntry.getLogPath());
                    removed = true;
                    metadataDb.addLogEntry(logEntry);
                }
            }
            log.debug("Successfully writen to DB");
        } catch (BuildException ex1) {
            if (failOnError) {
                throw ex1;
            }
        } catch (Exception ex) {
            if (failOnError) {
                throw new BuildException("Failed during writing data to db");
            }
        } finally {
            log.debug("finalizing DB: " + database);
            if (metadataDb != null) {
                metadataDb.finalizeDB();
            }
        }
    }
}