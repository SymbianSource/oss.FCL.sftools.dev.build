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

import org.apache.tools.ant.types.FileSet;

import org.apache.tools.ant.DirectoryScanner;
import org.apache.tools.ant.Task;
import java.util.Vector;
import java.util.ArrayList;
import java.util.List;
import org.apache.log4j.Logger;
import com.nokia.helium.metadata.db.*;

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
public class MetaDataDelete extends Task {

    private static Logger log = Logger.getLogger(MetaDataDelete.class);

    private String database;
    
    private boolean failOnError = true;

    private Vector<FileSet> fileSetList = new Vector<FileSet>();

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
     * Updates the list of filelist from the input fileset.
     *  @param fileSetList input fileset list
     *  @return the matched files including the base dir. 
     */
    private List<String> getFileListFromFileSet() {
        List<String> fileList = new ArrayList<String>();
        for (FileSet fs : fileSetList) {
            DirectoryScanner ds = fs.getDirectoryScanner(getProject());
            String[] includedFiles = ds.getIncludedFiles();
            for ( String file : includedFiles ) {
                fileList.add(file);
                log.debug("includedfiles: " + file);
            }
        }
        log.debug("fileList.size" + fileList.size());
        return fileList;
    }

    /**
     * Adds the fileset (list of input log files to be processed).
     *  @param fileSet fileset to be added
     * 
     */
    public void add(FileSet fileSet) {
        fileSetList.add(fileSet);
    }   

    /**
     * Helper function to get the database
     * 
     */
    public String getDatabase() {
        return database;
    }

    
    @Override
    public void execute() {
        /*
        MetaDataDb metadataDb = null;
        try {
            log.debug("Initializing DB: " + database + "to delete");
            log("time before removing entries from db" + new Date());
            metadataDb = new MetaDataDb(database);
            metadataDb.removeEntries(getFileListFromFileSet());
            log("time after removing entries from db" + new Date());
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
        */
    }
}